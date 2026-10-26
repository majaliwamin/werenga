import 'dart:math' as math;

String formatDuration(Duration? duration, {String empty = '—'}) {
  if (duration == null || duration.inMilliseconds < 0) return empty;
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final paddedSeconds = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
  }
  return '$minutes:$paddedSeconds';
}

String formatDurationMs(int? milliseconds, {String empty = '—'}) {
  if (milliseconds == null) return empty;
  return formatDuration(Duration(milliseconds: milliseconds), empty: empty);
}

String formatPlayerTime(Duration? duration) =>
    formatDuration(duration, empty: '0:00');

String formatPlaybackProgress(int positionMs, int? durationMs) {
  if (durationMs == null || durationMs <= 0) return '0% listened';
  final percent = ((positionMs / durationMs) * 100).clamp(0, 100).round();
  return '$percent% listened';
}

String formatRelativeTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(time);
  if (difference.isNegative || difference.inSeconds < 45) return 'Just now';
  if (difference.inMinutes < 60) {
    final minutes = math.max(1, difference.inMinutes);
    return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
  }
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  }
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays} days ago';
  if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
  }
  return formatDate(time);
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  final rounded = value >= 100 || unit == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$rounded ${units[unit]}';
}

String formatStorageSummary(int? bytes) {
  final formatted = formatBytes(bytes);
  return formatted == '—' ? 'No audio stored yet' : '$formatted stored';
}

String formatRecordingCount(int count) {
  if (count == 1) return '1 recording';
  return '$count recordings';
}

String titleFromFileName(String fileName) {
  var name = fileName.replaceAll('\\', '/').split('/').last;
  final dot = name.lastIndexOf('.');
  if (dot > 0) name = name.substring(0, dot);
  name = name.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  name = name.replaceAll(RegExp(r'\s+'), ' ');
  if (name.isEmpty) return 'Untitled recording';
  return name
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        if (word.length <= 3 && word.toUpperCase() == word) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}

String formatSurahMeta({String? surahName, int? surahNumber, String? verseRange}) {
  final parts = <String>[];
  if (surahNumber != null) parts.add('Surah $surahNumber');
  if (surahName != null && surahName.trim().isNotEmpty) {
    parts.add(surahName.trim());
  }
  if (verseRange != null && verseRange.trim().isNotEmpty) {
    parts.add('Ayah ${verseRange.trim()}');
  }
  if (parts.isEmpty) return "Qur'an · Chichewa";
  return parts.join(' · ');
}
