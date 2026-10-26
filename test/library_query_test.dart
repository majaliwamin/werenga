import 'package:flutter_test/flutter_test.dart';
import 'package:werenga/data/models/library_query.dart';
import 'package:werenga/data/models/recording.dart';

Recording _recording({
  required String id,
  required String title,
  DateTime? dateAdded,
  DateTime? lastPlayedAt,
  int lastPositionMs = 0,
  bool completed = false,
  int durationMs = 120000,
  String? surahName,
  int? surahNumber,
  String? verseRange,
  RecordingSource source = RecordingSource.localFile,
}) {
  return Recording(
    id: id,
    title: title,
    source: source,
    sourcePath: 'assets/audio/$id.mp3',
    dateAdded: dateAdded ?? DateTime(2026, 1, 1),
    lastPlayedAt: lastPlayedAt,
    lastPositionMs: lastPositionMs,
    completed: completed,
    durationMs: durationMs,
    surahName: surahName,
    surahNumber: surahNumber,
    verseRange: verseRange,
  );
}

void main() {
  final fatihah = _recording(
    id: 'fatihah',
    title: 'Al-Fatihah',
    surahName: 'Al-Fatihah',
    surahNumber: 1,
    verseRange: '1–7',
    dateAdded: DateTime(2026, 1, 2),
    lastPlayedAt: DateTime(2026, 1, 5, 10),
    lastPositionMs: 45000,
  );
  final baqarah = _recording(
    id: 'baqarah',
    title: 'Al-Baqarah',
    surahName: 'Al-Baqarah',
    surahNumber: 2,
    dateAdded: DateTime(2026, 1, 4),
    lastPlayedAt: DateTime(2026, 1, 6, 9),
    lastPositionMs: 0,
    completed: true,
  );
  final ikhlas = _recording(
    id: 'ikhlas',
    title: 'Al-Ikhlas',
    dateAdded: DateTime(2026, 1, 1),
    lastPositionMs: 8000,
  );
  final kahf = _recording(
    id: 'kahf',
    title: 'Al-Kahf',
    surahName: 'Al-Kahf',
    surahNumber: 18,
    dateAdded: DateTime(2026, 1, 3),
  );
  final all = [fatihah, baqarah, ikhlas, kahf];

  group('queryRecordings', () {
    test('returns everything by default', () {
      final result = queryRecordings(all);
      expect(result, hasLength(4));
    });

    test('searches titles and Surah metadata case-insensitively', () {
      expect(queryRecordings(all, search: 'fatihah'), [fatihah]);
      expect(queryRecordings(all, search: '18'), [kahf]);
      expect(queryRecordings(all, search: 'missing'), isEmpty);
    });

    test('filters in-progress and completed recordings', () {
      final inProgress = queryRecordings(
        all,
        filter: RecordingFilter.inProgress,
      );
      expect(inProgress, containsAll([fatihah, ikhlas]));
      expect(inProgress, isNot(contains(baqarah)));

      final completed = queryRecordings(
        all,
        filter: RecordingFilter.completed,
      );
      expect(completed, [baqarah]);
    });

    test('sorts by title and most recently added', () {
      final byTitle = queryRecordings(all, sort: RecordingSort.title);
      expect(
        byTitle.map((item) => item.title),
        ['Al-Baqarah', 'Al-Fatihah', 'Al-Ikhlas', 'Al-Kahf'],
      );

      final byAdded = queryRecordings(all, sort: RecordingSort.recentlyAdded);
      expect(byAdded.first, baqarah);
      expect(byAdded.last, ikhlas);
    });

    test('sorts by mushaf order and leaves unnumbered recordings last', () {
      final bySurah = queryRecordings(all, sort: RecordingSort.surah);
      expect(bySurah.map((item) => item.id), [
        'fatihah',
        'baqarah',
        'kahf',
        'ikhlas',
      ]);
    });

    test('sorts by recent playback with unplayed recordings last', () {
      final byPlayed = queryRecordings(
        all,
        sort: RecordingSort.recentlyPlayed,
      );
      expect(byPlayed.first, baqarah);
      expect(byPlayed[1], fatihah);
      expect(byPlayed.sublist(2), containsAll([ikhlas, kahf]));
    });
  });

  group('curated collections', () {
    test('featured prefers the most recently played recording', () {
      expect(featuredRecording(all), baqarah);
      expect(featuredRecording(all, preferHistory: false), fatihah);
      expect(featuredRecording(const []), isNull);
    });

    test('continue listening keeps played recordings in date order', () {
      final items = continueListening(all);
      expect(items.first, baqarah);
      expect(items.map((item) => item.id), containsAll(['fatihah', 'ikhlas']));
      expect(items, isNot(contains(kahf)));
    });

    test('history only contains recordings that were played', () {
      final items = historyRecordings(all);
      expect(items, [baqarah, fatihah]);
    });
  });

  group('Recording', () {
    test('formats Surah metadata', () {
      expect(fatihah.surahLine, 'Surah 1 · Al-Fatihah · Ayah 1–7');
      expect(kahf.surahLine, 'Surah 18 · Al-Kahf');
      expect(ikhlas.surahLine, "Qur'an · Chichewa");
    });

    test('computes progress safely', () {
      expect(fatihah.progress, closeTo(0.375, 0.0001));
      expect(ikhlas.progress, closeTo(8000 / 120000, 0.0001));
      expect(
        _recording(id: 'x', title: 'X', durationMs: 0).progress,
        0,
      );
    });

    test('copies playback and availability without losing metadata', () {
      final updated = fatihah.copyWithPlayback(
        lastPositionMs: 1000,
        completed: true,
      );
      expect(updated.lastPositionMs, 1000);
      expect(updated.completed, isTrue);
      expect(updated.surahName, 'Al-Fatihah');

      final unavailable = updated.copyWithAvailability(true);
      expect(unavailable.isUnavailable, isTrue);
      expect(unavailable.title, 'Al-Fatihah');
    });
  });
}
