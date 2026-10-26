import 'package:flutter_test/flutter_test.dart';
import 'package:werenga/core/utils/formatters.dart';

void main() {
  group('formatDuration', () {
    test('formats minutes and seconds', () {
      expect(formatDuration(const Duration(seconds: 65)), '1:05');
      expect(formatDuration(const Duration(seconds: 9)), '0:09');
    });

    test('formats hours', () {
      expect(formatDuration(const Duration(hours: 1, minutes: 1, seconds: 1)),
          '1:01:01');
    });

    test('uses the empty label for missing values', () {
      expect(formatDuration(null), '—');
      expect(formatDuration(null, empty: '0:00'), '0:00');
    });

    test('formats player time with a zero default', () {
      expect(formatPlayerTime(null), '0:00');
      expect(formatPlayerTime(const Duration(seconds: 75)), '1:15');
    });
  });

  group('formatBytes', () {
    test('formats units', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    });

    test('handles missing values', () {
      expect(formatBytes(null), '—');
      expect(formatBytes(0), '—');
    });
  });

  group('titles', () {
    test('turns file names into readable titles', () {
      expect(titleFromFileName('al-fatihah_01.mp3'), 'Al Fatihah 01');
      expect(titleFromFileName('01-al-baqarah.mp3'), '01 Al Baqarah');
      expect(titleFromFileName(''), 'Untitled recording');
    });
  });

  group('relative time', () {
    final now = DateTime(2026, 6, 15, 12);

    test('describes recent moments', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(seconds: 10)), now: now),
        'Just now',
      );
      expect(
        formatRelativeTime(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now),
        '3 hours ago',
      );
    });

    test('describes days and older dates', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 1)), now: now),
        'Yesterday',
      );
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 3)), now: now),
        '3 days ago',
      );
      expect(
        formatRelativeTime(DateTime(2025, 1, 2), now: now),
        '2 Jan 2025',
      );
    });
  });

  group('progress and metadata', () {
    test('formats playback progress', () {
      expect(formatPlaybackProgress(30000, 120000), '25% listened');
      expect(formatPlaybackProgress(0, null), '0% listened');
    });

    test('formats count and Surah metadata', () {
      expect(formatRecordingCount(1), '1 recording');
      expect(formatRecordingCount(3), '3 recordings');
      expect(
        formatSurahMeta(surahNumber: 2, surahName: 'Al-Baqarah'),
        'Surah 2 · Al-Baqarah',
      );
      expect(formatSurahMeta(), "Qur'an · Chichewa");
    });
  });
}
