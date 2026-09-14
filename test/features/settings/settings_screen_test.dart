import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/history/history_service.dart';
import 'package:reel_saver/features/history/models/history_item.dart';
import 'package:reel_saver/features/settings/settings_screen.dart';

void main() {
  late Directory tempTestDirectory;
  late Directory mockCacheDirectory;
  late Directory mockDownloadsDirectory;
  late File historyStoreFile;
  late HistoryService testHistoryService;

  setUp(() {
    tempTestDirectory =
        Directory.systemTemp.createTempSync('settings_screen_test_');
    mockCacheDirectory =
        Directory('${tempTestDirectory.path}/mock_cache')..createSync(recursive: true);
    mockDownloadsDirectory =
        Directory('${tempTestDirectory.path}/ReelSaver/Downloads')
          ..createSync(recursive: true);
    historyStoreFile =
        File('${tempTestDirectory.path}/test_download_history.json');
    testHistoryService =
        HistoryService(customHistoryFile: historyStoreFile);
  });

  tearDown(() {
    if (tempTestDirectory.existsSync()) {
      tempTestDirectory.deleteSync(recursive: true);
    }
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        historyServiceProvider.overrideWithValue(testHistoryService),
      ],
      child: MaterialApp(
        home: SettingsScreen(
          customTempDirectory: mockCacheDirectory,
          customDownloadsDirectory: mockDownloadsDirectory,
          customHistoryService: testHistoryService,
        ),
      ),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders Clear Cache and Clear Storage options',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Clear Cache'), findsOneWidget);
      expect(find.text('Clear Storage'), findsOneWidget);
    });

    testWidgets(
        'Clear Cache dialog has exact text, highlights No by default, and cancels on No',
        (tester) async {
      final dummyCacheFile = File('${mockCacheDirectory.path}/thumb_preview.jpg');
      dummyCacheFile.writeAsStringSync('cached thumbnail data');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Clear Cache
      await tester.tap(find.text('Clear Cache'));
      await tester.pumpAndSettle();

      // Verify exact explanation dialog text
      expect(
        find.text(
          'This will delete temporary files created during video fetching (thumbnails preview cache, partial downloads). Your completed downloads and history will NOT be affected. Continue?',
        ),
        findsOneWidget,
      );

      // Verify buttons
      final noButton = find.widgetWithText(ElevatedButton, 'No');
      final yesButton = find.widgetWithText(TextButton, 'Yes');
      expect(noButton, findsOneWidget);
      expect(yesButton, findsOneWidget);

      // Tap No
      await tester.tap(noButton);
      await tester.pumpAndSettle();

      // Ensure cache file was NOT deleted
      expect(dummyCacheFile.existsSync(), isTrue);
    });

    testWidgets(
        'Clear Cache confirms on Yes and deletes temporary cache files',
        (tester) async {
      final dummyCacheFile = File('${mockCacheDirectory.path}/thumb_preview.jpg');
      dummyCacheFile.writeAsStringSync('cached thumbnail data');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Clear Cache
      await tester.tap(find.text('Clear Cache'));
      await tester.pumpAndSettle();

      // Tap Yes
      await tester.tap(find.widgetWithText(TextButton, 'Yes'));
      await tester.pumpAndSettle();

      // Verify cache file is deleted
      expect(dummyCacheFile.existsSync(), isFalse);
      expect(
        find.text('Temporary cache cleared successfully.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Clear Storage dialog has exact text, highlights No by default, and cancels on No',
        (tester) async {
      final downloadedVideo =
          File('${mockDownloadsDirectory.path}/my_reel.mp4');
      downloadedVideo.writeAsStringSync('video data');

      await testHistoryService.addHistoryEntry(
        HistoryItem(
          id: '1',
          title: 'Stored Reel',
          thumbnailUrl: '',
          filePath: downloadedVideo.path,
          format: '1080p',
          fileSizeMB: 15.0,
          downloadedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Clear Storage
      await tester.tap(find.text('Clear Storage'));
      await tester.pumpAndSettle();

      // Verify exact explanation dialog text
      expect(
        find.text(
          'This will permanently delete ALL downloaded files and your entire download history. This cannot be undone. Are you sure?',
        ),
        findsOneWidget,
      );

      // Verify buttons: No is safer default (ElevatedButton)
      final noButton = find.widgetWithText(ElevatedButton, 'No');
      final yesButton = find.widgetWithText(TextButton, 'Yes');
      expect(noButton, findsOneWidget);
      expect(yesButton, findsOneWidget);

      // Tap No
      await tester.tap(noButton);
      await tester.pumpAndSettle();

      // Ensure file and history remain intact
      expect(downloadedVideo.existsSync(), isTrue);
      expect(await testHistoryService.getHistory(), isNotEmpty);
    });

    testWidgets(
        'Clear Storage confirms on Yes, deletes downloaded files and wipes history store',
        (tester) async {
      final downloadedVideo =
          File('${mockDownloadsDirectory.path}/my_reel.mp4');
      downloadedVideo.writeAsStringSync('video data');

      await testHistoryService.addHistoryEntry(
        HistoryItem(
          id: '1',
          title: 'Stored Reel',
          thumbnailUrl: '',
          filePath: downloadedVideo.path,
          format: '1080p',
          fileSizeMB: 15.0,
          downloadedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Clear Storage
      await tester.tap(find.text('Clear Storage'));
      await tester.pumpAndSettle();

      // Tap Yes
      await tester.tap(find.widgetWithText(TextButton, 'Yes'));
      await tester.pumpAndSettle();

      // Ensure downloaded files in ReelSaver/Downloads are deleted
      expect(downloadedVideo.existsSync(), isFalse);

      // Ensure history store is wiped clean
      final history = await testHistoryService.getHistory();
      expect(history, isEmpty);

      // Verify confirmation snackbar
      expect(
        find.text('All downloaded files and history have been cleared.'),
        findsOneWidget,
      );
    });
  });
}
