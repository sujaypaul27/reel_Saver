import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/history/history_screen.dart';
import 'package:reel_saver/features/history/history_service.dart';
import 'package:reel_saver/features/history/models/history_item.dart';
import 'package:reel_saver/l10n/app_localizations.dart';

void main() {
  late Directory tempTestDirectory;
  late File historyStoreFile;
  late HistoryService testHistoryService;

  setUp(() {
    tempTestDirectory =
        Directory.systemTemp.createTempSync('history_screen_test_');
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

  Widget createTestWidget({
    required HistoryService historyService,
    Future<void> Function(String filePath)? onOpenFile,
    List<HistoryItem>? initialItems,
  }) {
    return ProviderScope(
      overrides: [
        historyServiceProvider.overrideWithValue(historyService),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HistoryScreen(
          customHistoryService: historyService,
          onOpenFile: onOpenFile,
          initialItems: initialItems,
        ),
      ),
    );
  }

  group('HistoryScreen Widget Tests', () {
    testWidgets('displays empty state when history contains no items',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          historyService: testHistoryService,
          initialItems: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No downloads yet.'), findsOneWidget);
      expect(find.byIcon(Icons.history_toggle_off_rounded), findsOneWidget);
    });

    testWidgets('renders list of downloaded items with metadata',
        (tester) async {
      final sampleItem = HistoryItem(
        id: '12345',
        title: 'Amazing Nature Reel',
        thumbnailUrl: '',
        filePath: '${tempTestDirectory.path}/nature.mp4',
        format: '1080p (Video + Audio)',
        fileSizeMB: 18.5,
        downloadedAt: DateTime(2026, 9, 14, 12, 30),
      );
      await testHistoryService.addHistoryEntry(sampleItem);

      await tester.pumpWidget(
        createTestWidget(
          historyService: testHistoryService,
          initialItems: [sampleItem],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Amazing Nature Reel'), findsOneWidget);
      expect(find.textContaining('1080p (Video + Audio)'), findsOneWidget);
      expect(find.textContaining('18.5 MB'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('play/open button calls onOpenFile with file path',
        (tester) async {
      final dummyVideoFile = File('${tempTestDirectory.path}/nature.mp4');
      dummyVideoFile.writeAsStringSync('video data');

      final sampleItem = HistoryItem(
        id: '12345',
        title: 'Playable Reel',
        thumbnailUrl: '',
        filePath: dummyVideoFile.path,
        format: '720p',
        fileSizeMB: 10.0,
        downloadedAt: DateTime.now(),
      );
      await testHistoryService.addHistoryEntry(sampleItem);

      String? openedPath;
      await tester.pumpWidget(
        createTestWidget(
          historyService: testHistoryService,
          initialItems: [sampleItem],
          onOpenFile: (filePath) async {
            openedPath = filePath;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_circle_fill_rounded));
      await tester.pumpAndSettle();

      expect(openedPath, dummyVideoFile.path);
    });

    testWidgets('delete button displays confirmation dialog with safe defaults',
        (tester) async {
      final dummyVideoFile = File('${tempTestDirectory.path}/sample.mp4');
      dummyVideoFile.writeAsStringSync('video data');

      final sampleItem = HistoryItem(
        id: 'del_123',
        title: 'Reel To Delete',
        thumbnailUrl: '',
        filePath: dummyVideoFile.path,
        format: '1080p',
        fileSizeMB: 5.0,
        downloadedAt: DateTime.now(),
      );
      await testHistoryService.addHistoryEntry(sampleItem);

      await tester.pumpWidget(
        createTestWidget(
          historyService: testHistoryService,
          initialItems: [sampleItem],
        ),
      );
      await tester.pumpAndSettle();

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Verify exact dialog text and buttons
      expect(
        find.text('Delete this file permanently? This cannot be undone.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Verify Cancel is an ElevatedButton (safer default highlighted)
      final cancelFinder = find.widgetWithText(ElevatedButton, 'Cancel');
      expect(cancelFinder, findsOneWidget);

      // Cancel deletion
      await tester.tap(cancelFinder);
      await tester.pumpAndSettle();

      // Ensure file and history entry remain
      expect(dummyVideoFile.existsSync(), isTrue);
      expect(await testHistoryService.getHistory(), isNotEmpty);
      expect(find.text('Reel To Delete'), findsOneWidget);
    });

    testWidgets(
        'confirming delete removes file from storage and wipes history entry',
        (tester) async {
      final dummyVideoFile = File('${tempTestDirectory.path}/delete_target.mp4');
      dummyVideoFile.writeAsStringSync('video data');

      final sampleItem = HistoryItem(
        id: 'del_confirmed',
        title: 'Permanently Deleted Reel',
        thumbnailUrl: '',
        filePath: dummyVideoFile.path,
        format: '1080p',
        fileSizeMB: 12.0,
        downloadedAt: DateTime.now(),
      );
      await testHistoryService.addHistoryEntry(sampleItem);

      await tester.pumpWidget(
        createTestWidget(
          historyService: testHistoryService,
          initialItems: [sampleItem],
        ),
      );
      await tester.pumpAndSettle();

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      // Verify file is deleted on disk
      expect(dummyVideoFile.existsSync(), isFalse);

      // Verify history store is empty
      final updatedHistory = await testHistoryService.getHistory();
      expect(updatedHistory, isEmpty);

      // Verify empty state is displayed
      expect(find.text('No downloads yet.'), findsOneWidget);
      expect(find.text('Deleted "Permanently Deleted Reel"'), findsOneWidget);
    });
  });
}
