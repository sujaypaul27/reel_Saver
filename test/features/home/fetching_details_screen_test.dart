import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/download_engine/extraction_service.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';
import 'package:reel_saver/features/home/screens/fetching_details_screen.dart';

import 'package:reel_saver/l10n/app_localizations.dart';

import 'package:reel_saver/features/auth/instagram_session_service.dart';

class MockExtractionService extends ExtractionService {
  final VideoInfo? response;
  final bool shouldThrow;
  final Object? errorToThrow;

  const MockExtractionService({
    this.response,
    this.shouldThrow = false,
    this.errorToThrow,
  });

  @override
  Future<VideoInfo> fetchDetails(String url) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    if (shouldThrow) {
      throw Exception('Extraction failed');
    }
    return response ??
        const VideoInfo(
          title: 'Mock Reel Video',
          thumbnailUrl: '',
          durationSeconds: 125,
          formats: [
            VideoFormat(
              label: '1080p',
              type: FormatType.videoAndAudio,
              fileExtension: 'mp4',
              estimatedSizeMB: 42.5,
              height: 1080,
            ),
            VideoFormat(
              label: '720p',
              type: FormatType.videoOnly,
              fileExtension: 'mp4',
              estimatedSizeMB: 20.0,
              height: 720,
            ),
            VideoFormat(
              label: '128kbps',
              type: FormatType.audioOnly,
              fileExtension: 'mp3',
              estimatedSizeMB: 4.2,
              bitrate: 128,
            ),
          ],
        );
  }
}

Widget createTestApp({required ExtractionService extractionService}) {
  return ProviderScope(
    overrides: [
      extractionServiceProvider.overrideWithValue(extractionService),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FetchingDetailsScreen(
        videoUrl: 'https://www.youtube.com/watch?v=sample123',
      ),
    ),
  );
}

void main() {
  group('FetchingDetailsScreen UI', () {
    testWidgets('shows loading view then transitions smoothly to results view', (tester) async {
      final mockService = MockExtractionService();
      await tester.pumpWidget(createTestApp(extractionService: mockService));

      // Initial loading state
      expect(find.text('Fetching...'), findsOneWidget);

      // Advance through loading animation & completion
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Results view displayed
      expect(find.text('Mock Reel Video'), findsOneWidget);
      expect(find.text('02:05'), findsOneWidget);

      // Verify format row labels match pattern: "{quality} ({type description})"
      expect(find.text('1080p (Video + Audio)'), findsOneWidget);
      expect(find.text('720p (Video Only)'), findsOneWidget);
      expect(find.text('128kbps (Audio Only - MP3)'), findsOneWidget);

      // Direct single download icons present
      expect(find.byIcon(Icons.download_rounded), findsNWidgets(3));

      // Bottom "Download Selected" button initially disabled
      final downloadSelectedFinder = find.widgetWithText(ElevatedButton, 'Download Selected');
      expect(downloadSelectedFinder, findsOneWidget);
      expect(tester.widget<ElevatedButton>(downloadSelectedFinder).enabled, isFalse);

      // Select first format checkbox
      final firstCheckbox = find.byType(Checkbox).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      // Now "Download Selected (1)" button should be enabled
      final enabledButtonFinder = find.widgetWithText(ElevatedButton, 'Download Selected (1)');
      expect(enabledButtonFinder, findsOneWidget);
      expect(tester.widget<ElevatedButton>(enabledButtonFinder).enabled, isTrue);

      // Tap single download icon
      await tester.tap(find.byIcon(Icons.download_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('shows error state with Retry button when extraction fails', (tester) async {
      const failingService = MockExtractionService(shouldThrow: true);
      await tester.pumpWidget(createTestApp(extractionService: failingService));

      // Advance to trigger error
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't fetch video details. Please check the link and try again."),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows Instagram Login Required error state and login button when auth required', (tester) async {
      const authRequiredService = MockExtractionService(
        errorToThrow: InstagramAuthRequiredException(),
      );
      await tester.pumpWidget(createTestApp(extractionService: authRequiredService));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Instagram Login Required'), findsOneWidget);
      expect(
        find.text('This Instagram Reel requires login to download. Please log in with Instagram.'),
        findsOneWidget,
      );
      expect(find.text('Log in with Instagram'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock_rounded), findsOneWidget);
    });

    testWidgets('shows Instagram Session Expired error state and login button when session expired', (tester) async {
      const sessionExpiredService = MockExtractionService(
        errorToThrow: InstagramSessionExpiredException(),
      );
      await tester.pumpWidget(createTestApp(extractionService: sessionExpiredService));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Instagram Session Expired'), findsOneWidget);
      expect(
        find.text('Your Instagram session has expired. Please log in again to access this Reel.'),
        findsOneWidget,
      );
      expect(find.text('Log in with Instagram'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock_rounded), findsOneWidget);
    });
  });
}
