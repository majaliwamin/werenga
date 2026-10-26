import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import '../core/platform/local_files.dart';
import '../data/models/recording.dart';
import '../data/repositories/recording_store.dart';
import 'library_controller.dart';
import 'preferences_controller.dart';

/// A single shared playback session for the whole application.
///
/// The controller keeps the full player and the mini-player in sync, persists
/// listening positions, and never creates a second audio engine when the user
/// navigates between screens.
class PlaybackController extends ChangeNotifier {
  PlaybackController({
    required RecordingStore store,
    required PreferencesController preferences,
    required LibraryController library,
  }) : _store = store,
       _preferences = preferences,
       _library = library;

  final RecordingStore _store;
  final PreferencesController _preferences;
  final LibraryController _library;

  final AudioPlayer _player = AudioPlayer();

  AudioSession? _session;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerException>? _errorSubscription;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<void>? _noisySubscription;
  AppLifecycleListener? _lifecycleListener;
  Timer? _saveTimer;

  Recording? _current;
  List<Recording> _queue = const [];
  bool _isLoading = false;
  String? _error;
  int _errorId = 0;
  int _loadToken = 0;
  bool _initialized = false;
  bool _disposed = false;
  bool _resumeAfterInterruption = false;
  bool _ducked = false;
  bool _handlingCompletion = false;

  Recording? get current => _current;

  List<Recording> get queue => _queue;

  bool get isLoading => _isLoading;

  bool get isPlaying => _player.playing;

  bool get isBuffering =>
      _player.processingState == ProcessingState.loading ||
      _player.processingState == ProcessingState.buffering;

  bool get hasError => _error != null;

  String? get errorMessage => _error;

  int get errorId => _errorId;

  bool get isCompleted => _current?.completed ?? false;

  Duration get position => _player.position;

  Duration? get totalDuration {
    final playerDuration = _player.duration;
    if (playerDuration != null && playerDuration > Duration.zero) {
      return playerDuration;
    }
    final stored = _current?.durationMs;
    if (stored != null && stored > 0) {
      return Duration(milliseconds: stored);
    }
    return null;
  }

  double get progress {
    final total = totalDuration;
    if (total == null || total.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get canSkipNext {
    final current = _current;
    if (current == null) return false;
    final index = _queue.indexWhere((item) => item.id == current.id);
    return index >= 0 && index < _queue.length - 1;
  }

  bool get canSkipPrevious {
    final current = _current;
    if (current == null) return false;
    final index = _queue.indexWhere((item) => item.id == current.id);
    return index > 0;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        unawaited(_persistNow());
      },
      onDetach: () {
        unawaited(_persistNow());
      },
    );

    if (!kIsWeb) {
      try {
        _session = await AudioSession.instance;
        await _session!.configure(const AudioSessionConfiguration.music());
        _interruptionSubscription = _session!.interruptionEventStream.listen(
          (event) => unawaited(_handleInterruption(event)),
        );
        _noisySubscription = _session!.becomingNoisyEventStream.listen((_) {
          unawaited(_pauseForInterruption());
        });
      } catch (error) {
        debugPrint('Audio session configuration failed: $error');
      }
    }

    _stateSubscription = _player.playerStateStream.listen(_handlePlayerState);
    _durationSubscription = _player.durationStream.listen(_handleDuration);
    _errorSubscription = _player.errorStream.listen((error) {
      if (_isLoading) return;
      _setError(_friendlyPlaybackError(error));
    });

    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_player.playing) unawaited(_persistNow());
    });
  }

  Future<bool> open(
    Recording recording, {
    List<Recording>? queue,
    bool autoplay = true,
    bool resume = true,
  }) async {
    if (recording.isUnavailable) {
      _setError(
        'This recording is no longer available. The file may have been moved '
        'or deleted from the device.',
      );
      return false;
    }

    final sameRecording = _current?.id == recording.id;
    if (sameRecording &&
        !_isLoading &&
        _player.processingState != ProcessingState.idle) {
      _queue = _normaliseQueue(recording, queue ?? _queue);
      if (!resume) {
        await _seekInternal(Duration.zero);
      }
      _current = _current!.copyWithPlayback(completed: false);
      _safeNotify();
      if (autoplay) {
        await play();
      } else {
        await pause();
      }
      return true;
    }

    await _persistNow();
    final token = ++_loadToken;
    _current = recording;
    _queue = _normaliseQueue(recording, queue);
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      if (recording.source == RecordingSource.localFile) {
        final exists = await localFiles.exists(recording.sourcePath);
        if (!exists) {
          throw const _MissingRecordingException();
        }
      }

      final Duration? probed;
      if (recording.isBundled && kIsWeb) {
        // The browser player turns `setAsset` into a base64 `data:` URL built
        // from the whole file, which stalls on large recordings. The build
        // serves the same file under `assets/`, so stream it over HTTP.
        probed = await _player.setUrl(
          Uri.base.resolve('assets/${recording.sourcePath}').toString(),
        );
      } else if (recording.isBundled) {
        probed = await _player.setAsset(recording.sourcePath);
      } else {
        probed = await _player.setFilePath(recording.sourcePath);
      }

      if (token != _loadToken) return false;

      if (probed != null && probed.inMilliseconds > 0) {
        _current = _current!.copyWithDuration(probed.inMilliseconds);
        unawaited(_store.updateDuration(recording.id, probed.inMilliseconds));
      }

      final total = probed ?? totalDuration;
      final wantsResume =
          resume &&
          _preferences.resumeFromLastPosition &&
          !recording.completed;
      final startMs = wantsResume
          ? _safeStartPosition(recording.lastPositionMs, total)
          : 0;
      if (startMs > 0) {
        await _player.seek(Duration(milliseconds: startMs));
      }

      final now = DateTime.now();
      _current = _current!.copyWithPlayback(
        lastPositionMs: startMs,
        lastPlayedAt: now,
        completed: false,
      );
      await _store.updatePlayback(
        id: recording.id,
        positionMs: startMs,
        lastPlayedAt: now,
        completed: false,
      );
      _library.applyPlaybackState(
        id: recording.id,
        positionMs: startMs,
        lastPlayedAt: now,
        completed: false,
        durationMs: _current!.durationMs,
      );

      _isLoading = false;
      _safeNotify();
      if (autoplay) {
        await _beginPlayback();
      }
      return true;
    } on PlayerInterruptedException {
      return false;
    } catch (error) {
      if (token != _loadToken) return false;
      _isLoading = false;
      if (error is _MissingRecordingException) {
        final libraryCopy = _library.byId(recording.id);
        if (libraryCopy != null) {
          _library.applyMetadata(libraryCopy.copyWithAvailability(true));
          _current = libraryCopy.copyWithAvailability(true);
        }
      }
      _setError(
        error is _MissingRecordingException
            ? 'This recording is no longer available. The file may have been '
                  'moved or deleted from the device.'
            : _friendlyPlaybackError(error),
      );
      return false;
    }
  }

  Future<void> toggle() async {
    if (_current == null) return;
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    final recording = _current;
    if (recording == null) return;

    if (_error != null) {
      _error = null;
      _safeNotify();
    }

    if (_player.processingState == ProcessingState.idle) {
      await open(recording, queue: _queue, autoplay: true, resume: true);
      return;
    }

    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      _current = recording.copyWithPlayback(
        lastPositionMs: 0,
        completed: false,
      );
      await _markStarted(_current!);
    }

    _resumeAfterInterruption = false;
    await _beginPlayback();
  }

  Future<void> pause() async {
    if (_current == null) return;
    _resumeAfterInterruption = false;
    try {
      await _player.pause();
    } catch (error) {
      debugPrint('Pause failed: $error');
    }
    await _persistNow();
    _safeNotify();
  }

  Future<void> seek(Duration target) async {
    final recording = _current;
    if (recording == null) return;
    final total = totalDuration;
    var clamped = target;
    if (clamped < Duration.zero) clamped = Duration.zero;
    if (total != null && clamped > total) clamped = total;
    await _seekInternal(clamped);
    if (recording.completed &&
        (total == null || clamped < total - const Duration(seconds: 1))) {
      _current = recording.copyWithPlayback(
        lastPositionMs: clamped.inMilliseconds,
        completed: false,
      );
      unawaited(
        _store.updatePlayback(
          id: recording.id,
          positionMs: clamped.inMilliseconds,
          lastPlayedAt: recording.lastPlayedAt,
          completed: false,
        ),
      );
      _library.applyPlaybackState(
        id: recording.id,
        positionMs: clamped.inMilliseconds,
        completed: false,
      );
      _safeNotify();
    }
  }

  Future<void> restart() async {
    final recording = _current;
    if (recording == null) return;
    await _seekInternal(Duration.zero);
    _current = recording.copyWithPlayback(
      lastPositionMs: 0,
      completed: false,
    );
    await _markStarted(_current!);
    await _beginPlayback();
  }

  Future<void> next() async {
    final recording = _current;
    if (recording == null) return;
    final index = _queue.indexWhere((item) => item.id == recording.id);
    if (index < 0 || index >= _queue.length - 1) return;
    await open(
      _queue[index + 1],
      queue: _queue,
      autoplay: true,
      resume: false,
    );
  }

  Future<void> previous() async {
    final recording = _current;
    if (recording == null) return;
    final index = _queue.indexWhere((item) => item.id == recording.id);
    if (index <= 0) return;
    await open(
      _queue[index - 1],
      queue: _queue,
      autoplay: true,
      resume: false,
    );
  }

  /// Stops playback and clears the mini-player, while keeping history intact.
  Future<void> stop() async {
    if (_current == null) return;
    await _persistNow();
    try {
      await _player.stop();
    } catch (error) {
      debugPrint('Stop failed: $error');
    }
    _current = null;
    _queue = const [];
    _isLoading = false;
    _error = null;
    _safeNotify();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _safeNotify();
  }

  Future<void> _beginPlayback() async {
    final recording = _current;
    if (recording == null) return;
    try {
      await _session?.setActive(true);
    } catch (error) {
      debugPrint('Audio session activation failed: $error');
    }
    try {
      unawaited(
        _player.play().catchError((Object error) {
          _setError(_friendlyPlaybackError(error));
        }),
      );
      await _markStartedIfNeeded(recording);
      _safeNotify();
    } catch (error) {
      _setError(_friendlyPlaybackError(error));
    }
  }

  Future<void> _markStartedIfNeeded(Recording recording) async {
    if (recording.lastPlayedAt != null && !recording.completed) return;
    await _markStarted(recording);
  }

  Future<void> _markStarted(Recording recording) async {
    final now = DateTime.now();
    final positionMs = _player.position.inMilliseconds;
    _current = recording.copyWithPlayback(
      lastPlayedAt: now,
      completed: false,
      lastPositionMs: positionMs,
    );
    try {
      await _store.updatePlayback(
        id: recording.id,
        positionMs: positionMs,
        lastPlayedAt: now,
        completed: false,
      );
      _library.applyPlaybackState(
        id: recording.id,
        positionMs: positionMs,
        lastPlayedAt: now,
        completed: false,
      );
    } catch (error) {
      debugPrint('Could not record playback start: $error');
    }
  }

  Future<void> _pauseForInterruption() async {
    if (!_player.playing) return;
    _resumeAfterInterruption = false;
    await _player.pause();
    await _persistNow();
    _safeNotify();
  }

  Future<void> _handleInterruption(AudioInterruptionEvent event) async {
    if (event.begin) {
      if (event.type == AudioInterruptionType.duck) {
        _ducked = true;
        await _player.setVolume(0.25);
        return;
      }
      if (_player.playing) {
        _resumeAfterInterruption = true;
        await _player.pause();
        await _persistNow();
        _safeNotify();
      }
      return;
    }
    if (_ducked) {
      _ducked = false;
      await _player.setVolume(1.0);
    }
    if (_resumeAfterInterruption) {
      _resumeAfterInterruption = false;
      await play();
    }
  }

  void _handlePlayerState(PlayerState state) {
    if (_disposed) return;
    if (state.processingState == ProcessingState.completed &&
        _current != null &&
        !_current!.completed &&
        !_handlingCompletion) {
      unawaited(_handleCompletion());
    }
    _safeNotify();
  }

  Future<void> _handleCompletion() async {
    final recording = _current;
    if (recording == null) return;
    _handlingCompletion = true;
    final now = DateTime.now();
    _current = recording.copyWithPlayback(
      lastPositionMs: 0,
      lastPlayedAt: now,
      completed: true,
    );
    try {
      await _store.updatePlayback(
        id: recording.id,
        positionMs: 0,
        lastPlayedAt: now,
        completed: true,
      );
      _library.applyPlaybackState(
        id: recording.id,
        positionMs: 0,
        lastPlayedAt: now,
        completed: true,
        durationMs: _current!.durationMs,
      );
    } catch (error) {
      debugPrint('Could not record completion: $error');
    } finally {
      _handlingCompletion = false;
      _safeNotify();
    }
  }

  void _handleDuration(Duration? duration) {
    if (duration == null || duration.inMilliseconds <= 0) return;
    final recording = _current;
    if (recording == null) return;
    final existing = recording.durationMs;
    if (existing != null &&
        (existing - duration.inMilliseconds).abs() < 500) {
      return;
    }
    _current = recording.copyWithDuration(duration.inMilliseconds);
    unawaited(_store.updateDuration(recording.id, duration.inMilliseconds));
    _library.applyPlaybackState(
      id: recording.id,
      positionMs: recording.lastPositionMs,
      durationMs: duration.inMilliseconds,
    );
    _safeNotify();
  }

  Future<void> _persistNow() async {
    final recording = _current;
    if (recording == null) return;
    if (_player.processingState == ProcessingState.idle) return;

    final duration = totalDuration;
    final rawPosition = _player.position;
    final isComplete =
        duration != null &&
        duration.inMilliseconds > 0 &&
        rawPosition >= duration - const Duration(milliseconds: 1200);
    final positionMs = isComplete ? 0 : rawPosition.inMilliseconds;
    final completed = isComplete || recording.completed;
    final now = DateTime.now();

    _current = recording.copyWithPlayback(
      lastPositionMs: positionMs,
      lastPlayedAt: now,
      completed: completed,
    );

    try {
      await _store.updatePlayback(
        id: recording.id,
        positionMs: positionMs,
        lastPlayedAt: now,
        completed: completed,
      );
      _library.applyPlaybackState(
        id: recording.id,
        positionMs: positionMs,
        lastPlayedAt: now,
        completed: completed,
        durationMs: duration?.inMilliseconds ?? recording.durationMs,
      );
    } catch (error) {
      debugPrint('Could not persist playback position: $error');
    }
  }

  Future<void> _seekInternal(Duration target) async {
    try {
      await _player.seek(target);
    } catch (error) {
      debugPrint('Seek failed: $error');
    }
  }

  List<Recording> _normaliseQueue(
    Recording recording,
    List<Recording>? queue,
  ) {
    final items = <Recording>[];
    for (final item in queue ?? const <Recording>[]) {
      if (items.every((existing) => existing.id != item.id)) {
        items.add(item);
      }
    }
    if (items.every((item) => item.id != recording.id)) {
      items.insert(0, recording);
    }
    if (items.isEmpty) items.add(recording);
    return List.unmodifiable(items);
  }

  int _safeStartPosition(int savedMs, Duration? total) {
    if (savedMs <= 3000) return 0;
    if (total != null &&
        total.inMilliseconds > 0 &&
        savedMs > total.inMilliseconds - 5000) {
      return 0;
    }
    return savedMs;
  }

  void _setError(String message) {
    if (_error == message) return;
    _error = message;
    _errorId += 1;
    _isLoading = false;
    _safeNotify();
  }

  static String _friendlyPlaybackError(Object error) {
    if (error is PlayerException) {
      return 'This recording could not be played. The file may be damaged or '
          'saved in a format that is not supported.';
    }
    return 'Playback could not start. Please try again.';
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    _saveTimer = null;
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _errorSubscription?.cancel();
    _interruptionSubscription?.cancel();
    _noisySubscription?.cancel();
    _lifecycleListener?.dispose();
    unawaited(_persistNow());
    unawaited(_session?.setActive(false));
    unawaited(_player.dispose());
    super.dispose();
  }
}

class _MissingRecordingException implements Exception {
  const _MissingRecordingException();
}
