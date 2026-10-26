enum RecordingSource {
  bundledAsset('asset'),
  localFile('file');

  const RecordingSource(this.storageValue);

  final String storageValue;

  static RecordingSource fromStorage(String value) {
    return RecordingSource.values.firstWhere(
      (source) => source.storageValue == value,
      orElse: () => RecordingSource.localFile,
    );
  }
}

/// A single locally owned recitation recording.
///
/// Each file already contains the Arabic recitation followed by its Chichewa
/// translation. Werenga never splits, transcribes, translates or otherwise
/// alters the supplied audio.
class Recording {
  const Recording({
    required this.id,
    required this.title,
    required this.source,
    required this.sourcePath,
    required this.dateAdded,
    this.surahName,
    this.surahNumber,
    this.verseRange,
    this.durationMs,
    this.sizeBytes,
    this.lastPositionMs = 0,
    this.lastPlayedAt,
    this.completed = false,
    this.contentHash,
    this.isUnavailable = false,
  });

  final String id;
  final String title;
  final String? surahName;
  final int? surahNumber;
  final String? verseRange;
  final RecordingSource source;
  final String sourcePath;
  final int? durationMs;
  final int? sizeBytes;
  final DateTime dateAdded;
  final int lastPositionMs;
  final DateTime? lastPlayedAt;
  final bool completed;
  final String? contentHash;

  /// Transient flag set when a locally imported file can no longer be found.
  final bool isUnavailable;

  bool get isBundled => source == RecordingSource.bundledAsset;
  bool get hasDuration => (durationMs ?? 0) > 0;
  bool get wasPlayed => lastPlayedAt != null;
  bool get hasSurahMetadata => surahName != null || surahNumber != null;

  double get progress {
    final duration = durationMs ?? 0;
    if (duration <= 0) return 0;
    return (lastPositionMs / duration).clamp(0.0, 1.0);
  }

  bool get isInProgress => !completed && lastPositionMs > 5000;

  bool get isFinished => completed;

  String get surahLine {
    if (surahName == null && surahNumber == null) {
      return "Qur'an · Chichewa";
    }
    final parts = <String>[];
    if (surahNumber != null) parts.add('Surah $surahNumber');
    if (surahName != null) parts.add(surahName!);
    final label = parts.join(' · ');
    if (verseRange != null && verseRange!.trim().isNotEmpty) {
      return '$label · Ayah ${verseRange!.trim()}';
    }
    return label;
  }

  String get metadataLine {
    if (!hasSurahMetadata) return "Qur'an · Chichewa";
    return surahLine;
  }

  String get searchHaystack {
    return [
      title,
      surahName ?? '',
      surahNumber?.toString() ?? '',
      verseRange ?? '',
      sourcePath,
    ].join(' ').toLowerCase();
  }

  Recording copyWithPlayback({
    int? lastPositionMs,
    DateTime? lastPlayedAt,
    bool clearLastPlayedAt = false,
    bool? completed,
  }) {
    return Recording(
      id: id,
      title: title,
      surahName: surahName,
      surahNumber: surahNumber,
      verseRange: verseRange,
      source: source,
      sourcePath: sourcePath,
      durationMs: durationMs,
      sizeBytes: sizeBytes,
      dateAdded: dateAdded,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      lastPlayedAt: clearLastPlayedAt ? null : (lastPlayedAt ?? this.lastPlayedAt),
      completed: completed ?? this.completed,
      contentHash: contentHash,
      isUnavailable: isUnavailable,
    );
  }

  Recording copyWithDuration(int? durationMs) {
    return Recording(
      id: id,
      title: title,
      surahName: surahName,
      surahNumber: surahNumber,
      verseRange: verseRange,
      source: source,
      sourcePath: sourcePath,
      durationMs: durationMs,
      sizeBytes: sizeBytes,
      dateAdded: dateAdded,
      lastPositionMs: lastPositionMs,
      lastPlayedAt: lastPlayedAt,
      completed: completed,
      contentHash: contentHash,
      isUnavailable: isUnavailable,
    );
  }

  Recording copyWithMetadata({
    required String title,
    String? surahName,
    int? surahNumber,
    String? verseRange,
  }) {
    return Recording(
      id: id,
      title: title,
      surahName: surahName,
      surahNumber: surahNumber,
      verseRange: verseRange,
      source: source,
      sourcePath: sourcePath,
      durationMs: durationMs,
      sizeBytes: sizeBytes,
      dateAdded: dateAdded,
      lastPositionMs: lastPositionMs,
      lastPlayedAt: lastPlayedAt,
      completed: completed,
      contentHash: contentHash,
      isUnavailable: isUnavailable,
    );
  }

  Recording copyWithAvailability(bool isUnavailable) {
    return Recording(
      id: id,
      title: title,
      surahName: surahName,
      surahNumber: surahNumber,
      verseRange: verseRange,
      source: source,
      sourcePath: sourcePath,
      durationMs: durationMs,
      sizeBytes: sizeBytes,
      dateAdded: dateAdded,
      lastPositionMs: lastPositionMs,
      lastPlayedAt: lastPlayedAt,
      completed: completed,
      contentHash: contentHash,
      isUnavailable: isUnavailable,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'surah_name': surahName,
      'surah_number': surahNumber,
      'verse_range': verseRange,
      'source': source.storageValue,
      'source_path': sourcePath,
      'duration_ms': durationMs,
      'size_bytes': sizeBytes,
      'date_added': dateAdded.millisecondsSinceEpoch,
      'last_position_ms': lastPositionMs,
      'last_played_at': lastPlayedAt?.millisecondsSinceEpoch,
      'completed': completed ? 1 : 0,
      'content_hash': contentHash,
    };
  }

  factory Recording.fromMap(Map<String, Object?> map) {
    final lastPlayed = map['last_played_at'] as int?;
    return Recording(
      id: map['id']! as String,
      title: map['title']! as String,
      surahName: map['surah_name'] as String?,
      surahNumber: map['surah_number'] as int?,
      verseRange: map['verse_range'] as String?,
      source: RecordingSource.fromStorage(map['source']! as String),
      sourcePath: map['source_path']! as String,
      durationMs: map['duration_ms'] as int?,
      sizeBytes: map['size_bytes'] as int?,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
        map['date_added']! as int,
      ),
      lastPositionMs: (map['last_position_ms'] as int?) ?? 0,
      lastPlayedAt: lastPlayed == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastPlayed),
      completed: (map['completed'] as int? ?? 0) == 1,
      contentHash: map['content_hash'] as String?,
    );
  }
}
