import 'recording.dart';

enum RecordingSort {
  recentlyAdded,
  surah,
  title,
  recentlyPlayed,
}

enum RecordingFilter {
  all,
  inProgress,
  completed,
}

extension RecordingSortLabel on RecordingSort {
  String get label => switch (this) {
    RecordingSort.recentlyAdded => 'Recently added',
    RecordingSort.surah => 'Mushaf order',
    RecordingSort.title => 'Title A–Z',
    RecordingSort.recentlyPlayed => 'Recently played',
  };
}

extension RecordingFilterLabel on RecordingFilter {
  String get label => switch (this) {
    RecordingFilter.all => 'All',
    RecordingFilter.inProgress => 'In progress',
    RecordingFilter.completed => 'Completed',
  };
}

/// Applies the library's local search, filter and sort rules.
///
/// Living outside the widgets keeps the behaviour deterministic and easy to
/// test without a database or audio engine.
List<Recording> queryRecordings(
  List<Recording> recordings, {
  String search = '',
  RecordingSort sort = RecordingSort.recentlyAdded,
  RecordingFilter filter = RecordingFilter.all,
}) {
  final query = search.trim().toLowerCase();
  final filtered = recordings.where((recording) {
    final matchesFilter = switch (filter) {
      RecordingFilter.all => true,
      RecordingFilter.inProgress => recording.isInProgress,
      RecordingFilter.completed => recording.isFinished,
    };
    if (!matchesFilter) return false;
    if (query.isEmpty) return true;
    return recording.searchHaystack.contains(query);
  }).toList();

  filtered.sort((a, b) {
    switch (sort) {
      case RecordingSort.surah:
        return _compareSurah(a, b);
      case RecordingSort.title:
        return _compareTitle(a, b);
      case RecordingSort.recentlyPlayed:
        final aPlayed = a.lastPlayedAt;
        final bPlayed = b.lastPlayedAt;
        if (aPlayed == null && bPlayed == null) return _compareTitle(a, b);
        if (aPlayed == null) return 1;
        if (bPlayed == null) return -1;
        return bPlayed.compareTo(aPlayed);
      case RecordingSort.recentlyAdded:
        final byDate = b.dateAdded.compareTo(a.dateAdded);
        return byDate != 0 ? byDate : _compareTitle(a, b);
    }
  });
  return filtered;
}

int _compareTitle(Recording a, Recording b) {
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

/// Mushaf order: numbered surahs first, in revelation-of-mushaf sequence,
/// then anything without a verified surah number alphabetically.
int _compareSurah(Recording a, Recording b) {
  final aNumber = a.surahNumber;
  final bNumber = b.surahNumber;
  if (aNumber != null && bNumber != null && aNumber != bNumber) {
    return aNumber.compareTo(bNumber);
  }
  if (aNumber != null && bNumber == null) return -1;
  if (aNumber == null && bNumber != null) return 1;
  return _compareTitle(a, b);
}

Recording? featuredRecording(
  List<Recording> recordings, {
  bool preferHistory = true,
}) {
  if (recordings.isEmpty) return null;
  if (preferHistory) {
    final played = recordings.where((item) => item.wasPlayed).toList()
      ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
    if (played.isNotEmpty) return played.first;
  }
  return recordings.first;
}

List<Recording> continueListening(List<Recording> recordings) {
  final items = recordings
      .where((recording) => recording.wasPlayed || recording.isInProgress)
      .toList()
    ..sort((a, b) {
      final aDate = a.lastPlayedAt ?? a.dateAdded;
      final bDate = b.lastPlayedAt ?? b.dateAdded;
      return bDate.compareTo(aDate);
    });
  return items;
}

List<Recording> historyRecordings(List<Recording> recordings) {
  final items = recordings.where((recording) => recording.wasPlayed).toList()
    ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
  return items;
}
