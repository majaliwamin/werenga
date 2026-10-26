import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/utils/formatters.dart';
import '../models/recording.dart';
import '../repositories/recording_store.dart';
import 'recording_importer.dart';

/// Android/desktop implementation: copies each picked file into the app's
/// private support directory, hashes it for duplicate detection and probes its
/// duration.
class FileRecordingImporter implements RecordingImporter {
  FileRecordingImporter({
    required RecordingStore store,
    AudioProbe? probe,
  }) : _store = store,
       _probe = probe ?? AudioProbe();

  final RecordingStore _store;
  final AudioProbe _probe;

  static const supportedExtensions = [
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'opus',
    'flac',
  ];

  @override
  bool get isSupported => true;

  @override
  Future<List<ImportCandidate>> pickCandidates() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Select Quran recordings',
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );
    final candidates = <ImportCandidate>[];
    for (final file in files) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;
      int? size;
      try {
        size = await file.length();
      } catch (_) {
        size = null;
      }
      candidates.add(
        ImportCandidate(path: path, fileName: file.name, sizeBytes: size),
      );
    }
    return candidates;
  }

  @override
  Future<ImportResult> importAll(List<ImportRequest> requests) async {
    final imported = <Recording>[];
    final skipped = <String>[];
    final failures = <String>[];
    if (requests.isEmpty) {
      return const ImportResult();
    }

    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      '${support.path}${Platform.pathSeparator}recordings',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    for (final request in requests) {
      final source = File(request.candidate.path);
      if (!await source.exists()) {
        failures.add(
          '${request.title}: the selected file is no longer available.',
        );
        continue;
      }

      final suggested = titleFromFileName(request.candidate.fileName);
      final title = request.title.trim().isEmpty
          ? suggested
          : request.title.trim();
      final destination = await _uniqueDestination(
        directory,
        request.candidate.fileName,
      );

      try {
        await source.copy(destination.path);
        final hash = await _sha256(destination);
        final duplicate = await _store.findByContentHash(hash);
        if (duplicate != null) {
          await destination.delete();
          skipped.add('$title (already in your library)');
          continue;
        }

        final duration = await _probe.durationMs(destination.path);
        final recording = Recording(
          id: 'local:${DateTime.now().microsecondsSinceEpoch}:'
              '${_randomSuffix()}',
          title: title,
          surahName: _clean(request.surahName),
          surahNumber: request.surahNumber,
          verseRange: _clean(request.verseRange),
          source: RecordingSource.localFile,
          sourcePath: destination.path,
          durationMs: duration,
          sizeBytes: await destination.length(),
          dateAdded: DateTime.now(),
          contentHash: hash,
        );
        await _store.insert(recording);
        imported.add(recording);
      } catch (error) {
        if (await destination.exists()) {
          try {
            await destination.delete();
          } catch (_) {
            // Best effort cleanup only.
          }
        }
        failures.add('$title: ${_friendlyError(error)}');
      }
    }

    return ImportResult(
      imported: imported,
      skipped: skipped,
      failures: failures,
    );
  }

  Future<File> _uniqueDestination(Directory directory, String fileName) async {
    final separator = Platform.pathSeparator;
    final safe = _safeFileName(fileName);
    var candidate = File('${directory.path}$separator$safe');
    if (!await candidate.exists()) return candidate;
    final dot = safe.lastIndexOf('.');
    final stem = dot > 0 ? safe.substring(0, dot) : safe;
    final extension = dot > 0 ? safe.substring(dot) : '';
    var counter = 1;
    while (await candidate.exists()) {
      candidate = File(
        '${directory.path}$separator${stem}_$counter$extension',
      );
      counter += 1;
    }
    return candidate;
  }

  static String _safeFileName(String fileName) {
    var name = fileName.replaceAll('\\', '/').split('/').last.trim();
    name = name.replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_');
    name = name.replaceAll(RegExp(r'\s+'), '_');
    if (name.isEmpty) name = 'recording.mp3';
    if (name.length > 96) {
      final dot = name.lastIndexOf('.');
      final extension = dot > 0 ? name.substring(dot) : '';
      name = '${name.substring(0, 90)}$extension';
    }
    return name;
  }

  static Future<String> _sha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  static String _randomSuffix() {
    final value = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return value.substring(value.length > 6 ? value.length - 6 : 0);
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String _friendlyError(Object error) {
    if (error is FileSystemException) {
      return 'the file could not be copied.';
    }
    if (error is PlayerException) {
      return 'the audio format could not be read.';
    }
    if (error is TimeoutException) {
      return 'reading the audio timed out.';
    }
    return 'the recording could not be imported.';
  }
}

class AudioProbe {
  Future<int?> durationMs(String path) async {
    final player = AudioPlayer();
    try {
      final duration = await player
          .setFilePath(path)
          .timeout(const Duration(seconds: 20));
      return duration?.inMilliseconds;
    } catch (error) {
      debugPrint('Duration probe failed for $path: $error');
      return null;
    } finally {
      await player.dispose();
    }
  }
}
