import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../models/recording.dart';
import '../repositories/recording_store.dart';

class BundledSyncResult {
  const BundledSyncResult({
    this.available = 0,
    this.added = 0,
    this.updated = 0,
    this.removed = 0,
    this.warning,
  });

  final int available;
  final int added;
  final int updated;
  final int removed;
  final String? warning;

  bool get changed => added > 0 || updated > 0 || removed > 0;
}

/// Registers audio files that ship inside `assets/audio/`.
///
/// A `recordings.json` file may supply titles and verified Surah metadata. Any
/// supported audio asset that is not listed is still registered automatically,
/// so dropping a file into the folder and rebuilding is enough.
class BundledLibraryService {
  BundledLibraryService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const metadataPath = 'assets/audio/recordings.json';
  static const audioDirectory = 'assets/audio/';
  static const supportedExtensions = {
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'opus',
    'flac',
  };

  Future<BundledSyncResult> sync(RecordingStore store) async {
    var manifestLoaded = false;
    var warning = <String>[];
    final available = <String>{};

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
      for (final asset in manifest.listAssets()) {
        if (_isAudioAsset(asset)) available.add(asset);
      }
      manifestLoaded = true;
    } catch (error) {
      warning.add('The bundled audio manifest could not be read.');
    }

    final metadata = await _readMetadata(warning);
    if (!manifestLoaded) {
      available.addAll(metadata.keys);
    }

    var added = 0;
    var updated = 0;
    final now = DateTime.now();
    final existing = {
      for (final item in await store.fetchAll()) item.id: item,
    };

    final ordered = available.toList()..sort();
    for (var index = 0; index < ordered.length; index++) {
      final path = ordered[index];
      final meta = metadata[path];
      final title = (meta?.title?.trim().isNotEmpty ?? false)
          ? meta!.title!.trim()
          : titleFromFileName(path);
      final recording = Recording(
        id: bundledRecordingId(path),
        title: title,
        surahName: _clean(meta?.surahName),
        surahNumber: meta?.surahNumber,
        verseRange: _clean(meta?.verseRange),
        source: RecordingSource.bundledAsset,
        sourcePath: path,
        durationMs: meta?.durationMs,
        dateAdded: now.add(Duration(milliseconds: index)),
      );
      if (existing.containsKey(recording.id)) {
        updated += 1;
      } else {
        added += 1;
      }
      await store.upsertBundled(recording);
    }

    var removed = 0;
    if (manifestLoaded) {
      final before = existing.length;
      await store.pruneBundledAssets(ordered.toSet());
      final after = (await store.fetchAll()).length;
      removed = before - after > 0 ? before - after : 0;
    }

    return BundledSyncResult(
      available: ordered.length,
      added: added,
      updated: updated,
      removed: removed,
      warning: warning.isEmpty ? null : warning.join(' '),
    );
  }

  static String bundledRecordingId(String assetPath) => 'bundled:$assetPath';

  static bool _isAudioAsset(String path) {
    if (!path.startsWith(audioDirectory)) return false;
    final dot = path.lastIndexOf('.');
    if (dot < 0) return false;
    return supportedExtensions.contains(path.substring(dot + 1).toLowerCase());
  }

  Future<Map<String, _BundledMetadata>> _readMetadata(
    List<String> warning,
  ) async {
    final result = <String, _BundledMetadata>{};
    try {
      final raw = await _bundle.loadString(metadataPath);
      if (raw.trim().isEmpty) return result;
      final decoded = jsonDecode(raw);
      final entries = switch (decoded) {
        List<dynamic> list => list,
        Map<String, dynamic> map when map['recordings'] is List<dynamic> =>
          map['recordings']! as List<dynamic>,
        _ => <dynamic>[],
      };
      for (final entry in entries) {
        if (entry is! Map<String, dynamic>) continue;
        final file = entry['file']?.toString();
        if (file == null || file.trim().isEmpty) continue;
        final path = _normaliseAssetPath(file);
        result[path] = _BundledMetadata(
          title: entry['title']?.toString(),
          surahName: entry['surahName']?.toString(),
          surahNumber: _asInt(entry['surahNumber']),
          verseRange: entry['verseRange']?.toString(),
          durationMs: _asInt(entry['durationMs']),
        );
      }
    } catch (error) {
      warning.add('Bundled recording metadata could not be read.');
    }
    return result;
  }

  static String _normaliseAssetPath(String file) {
    var path = file.trim().replaceAll('\\', '/');
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.startsWith(audioDirectory)) return path;
    return '$audioDirectory$path';
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

class _BundledMetadata {
  const _BundledMetadata({
    this.title,
    this.surahName,
    this.surahNumber,
    this.verseRange,
    this.durationMs,
  });

  final String? title;
  final String? surahName;
  final int? surahNumber;
  final String? verseRange;
  final int? durationMs;
}
