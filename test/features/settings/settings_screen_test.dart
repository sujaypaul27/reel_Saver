import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/core/theme/app_theme.dart';
import 'package:reel_saver/core/theme/theme_provider.dart';
import 'package:reel_saver/features/history/history_service.dart';
import 'package:reel_saver/features/history/models/history_item.dart';
import 'package:reel_saver/features/home/providers/auto_mode_provider.dart';
import 'package:reel_saver/features/settings/providers/locale_provider.dart';
import 'package:reel_saver/features/settings/settings_screen.dart';
import 'package:reel_saver/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempTestDirectory;
  late Directory mockCacheDirectory;
  late Directory mockDownloadsDirectory;
  late File historyStoreFile;
  late HistoryService testHistoryService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

  Widget createTestWidget({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        historyServiceProvider.overrideWithValue(testHistoryService),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          customTempDirectory: mockCacheDirectory,
          customDownloadsDirectory: mockDownloadsDirectory,
          customHistoryService: testHistoryService,
        ),
      ),
    );
  }

  group('SettingsScreen Widget Tests - Preferences', () {
    testWidgets(
        'renders Preferences section with Automatic URL Detection and App Language',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Automatic URL Detection'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('App Language'), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.byType(DropdownButton<Locale>), findsOneWidget);
    });

    testWidgets('toggling Automatic URL Detection switch updates autoModeProvider',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Tap toggle to disable
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool(AutoModeNotifier.preferencesKey), isFalse);
    });

    testWidgets('selecting a new language from dropdown updates localeProvider',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open language dropdown
      await tester.tap(find.byType(DropdownButton<Locale>));
      await tester.pumpAndSettle();

      // Verify all 5 language options appear in dropdown menu
      expect(find.text('English').hitTestable(), findsOneWidget);
      expect(find.text('Hindi').hitTestable(), findsOneWidget);
      expect(find.text('Tamil').hitTestable(), findsOneWidget);
      expect(find.text('Spanish').hitTestable(), findsOneWidget);
      expect(find.text('French').hitTestable(), findsOneWidget);

      // Select Spanish
      await tester.tap(find.text('Spanish').hitTestable());
      await tester.pumpAndSettle();

      // Verify selected language changed to Spanish
      expect(find.text('Spanish'), findsWidgets);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(LocaleNotifier.preferencesKey), 'es');
    });
  });

  group('SettingsScreen Widget Tests - Storage Management', () {
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
      await tester.ensureVisible(find.text('Clear Storage'));
      await tester.pumpAndSettle();
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
      await tester.ensureVisible(find.text('Clear Storage'));
      await tester.pumpAndSettle();
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

  group('SettingsScreen Widget Tests - Appearance', () {
    testWidgets('renders Appearance section with theme cards for all 3 modes',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Midnight'), findsOneWidget);
      expect(find.text('Classic Light'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
    });

    testWidgets('tapping theme card updates themeProvider and active selection',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(
              customTempDirectory: mockCacheDirectory,
              customDownloadsDirectory: mockDownloadsDirectory,
              customHistoryService: testHistoryService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default theme is midnight
      expect(container.read(themeProvider), AppThemeMode.midnight);

      // Tap Classic Light card
      await tester.tap(find.text('Classic Light'));
      await tester.pumpAndSettle();

      expect(container.read(themeProvider), AppThemeMode.classicLight);

      // Tap Sunset card
      await tester.tap(find.text('Sunset'));
      await tester.pumpAndSettle();

      expect(container.read(themeProvider), AppThemeMode.sunset);
    });

    testWidgets('dynamic language switching re-renders SettingsScreen without restart',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyServiceProvider.overrideWithValue(testHistoryService),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(localeProvider);
              return MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: SettingsScreen(
                  customTempDirectory: mockCacheDirectory,
                  customDownloadsDirectory: mockDownloadsDirectory,
                  customHistoryService: testHistoryService,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially English
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);

      // Open language dropdown and select Hindi
      await tester.tap(find.byType(DropdownButton<Locale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hindi').hitTestable());
      await tester.pumpAndSettle();

      // Verify strings re-rendered into Hindi
      expect(find.text('रूप-रंग'), findsOneWidget);
      expect(find.text('प्राथमिकताएं'), findsOneWidget);

      // Switch to Spanish
      await tester.tap(find.byType(DropdownButton<Locale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spanish').hitTestable());
      await tester.pumpAndSettle();

      // Verify strings re-rendered into Spanish
      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.text('Preferencias'), findsOneWidget);
    });
  });
}
