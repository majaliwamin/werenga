import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werenga/core/theme/app_theme.dart';
import 'package:werenga/core/widgets/recording_tile.dart';
import 'package:werenga/data/models/recording.dart';

Recording _recording({bool completed = false}) {
  return Recording(
    id: 'fatihah',
    title: 'Al-Fatihah',
    surahNumber: 1,
    surahName: 'Al-Fatihah',
    source: RecordingSource.localFile,
    sourcePath: 'C:/recordings/fatihah.mp3',
    dateAdded: DateTime(2026, 1, 1),
    durationMs: 65000,
    lastPositionMs: 30000,
    completed: completed,
  );
}

void main() {
  testWidgets('RecordingTile shows its title and metadata', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: RecordingTile(recording: _recording()),
          ),
        ),
      ),
    );

    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(find.textContaining('Surah 1'), findsOneWidget);
    expect(find.text('1:05'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('RecordingTile can show a completed recording', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RecordingTile(recording: _recording(completed: true)),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  test('both themes can be constructed', () {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
  });
}
