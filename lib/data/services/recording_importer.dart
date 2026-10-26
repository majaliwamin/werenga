import '../../core/utils/formatters.dart';
import '../models/recording.dart';

/// A single file offered by the system file picker.
class ImportCandidate {
  const ImportCandidate({
    required this.path,
    required this.fileName,
    this.sizeBytes,
  });

  final String path;
  final String fileName;
  final int? sizeBytes;

  String get suggestedTitle => titleFromFileName(fileName);
}

class ImportRequest {
  const ImportRequest({
    required this.candidate,
    required this.title,
    this.surahName,
    this.surahNumber,
    this.verseRange,
  });

  final ImportCandidate candidate;
  final String title;
  final String? surahName;
  final int? surahNumber;
  final String? verseRange;
}

class ImportResult {
  const ImportResult({
    this.imported = const [],
    this.skipped = const [],
    this.failures = const [],
  });

  final List<Recording> imported;
  final List<String> skipped;
  final List<String> failures;

  bool get hasChanges => imported.isNotEmpty;
}

/// Copies picked files into the application's own storage.
///
/// The implementation is selected by the composition root: Android uses the
/// filesystem, while the browser preview offers no import at all. This file
/// stays free of `dart:io` so both builds can share it.
abstract interface class RecordingImporter {
  bool get isSupported;

  Future<List<ImportCandidate>> pickCandidates();

  Future<ImportResult> importAll(List<ImportRequest> requests);
}

/// Browser-safe stand-in that explains why importing is unavailable.
class UnsupportedRecordingImporter implements RecordingImporter {
  const UnsupportedRecordingImporter();

  @override
  bool get isSupported => false;

  @override
  Future<List<ImportCandidate>> pickCandidates() async => const [];

  @override
  Future<ImportResult> importAll(List<ImportRequest> requests) async {
    return const ImportResult(
      failures: [
        'Importing is available in the Android app. The browser preview keeps '
            'its library in memory only.',
      ],
    );
  }
}
