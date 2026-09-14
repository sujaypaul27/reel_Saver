import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reel_saver/features/clipboard_engine/clipboard_watcher.dart';
import 'package:reel_saver/features/clipboard_engine/models/clipboard_state.dart';
import 'package:reel_saver/features/clipboard_engine/models/clipboard_status.dart';
import 'package:reel_saver/features/clipboard_engine/models/url_type.dart';
import 'package:reel_saver/features/home/providers/auto_mode_provider.dart';
import 'package:reel_saver/features/home/screens/fetching_details_screen.dart';
import 'package:reel_saver/features/home/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestWidget({
  List<Override> overrides = const [],
}) {
  final testRouter = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/fetching-details',
        builder: (context, state) => FetchingDetailsScreen(
          videoUrl: state.extra as String?,
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: testRouter,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeScreen UI & Modes', () {
    testWidgets('renders top-left menu icon and Automatic Detection switch', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.text('Automatic Detection'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('toggling Automatic Detection switches mode and persists state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Starts in auto mode
      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      expect(find.byType(TextField), findsNothing);

      // Toggle to manual mode
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Check URL'), findsOneWidget);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool(AutoModeNotifier.preferencesKey), isFalse);
    });

    testWidgets('in Auto Mode: displays dismissible banner when invalid URL is detected', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger invalid clipboard state on watcher
      container.read(clipboardWatcherProvider.notifier).updateState(
            const ClipboardState(
              status: ClipboardDetectionStatus.invalid,
              url: 'not a valid video link',
              type: UrlType.invalid,
            ),
          );
      await tester.pumpAndSettle();

      expect(
        find.text('No valid Instagram or YouTube link found in clipboard.'),
        findsOneWidget,
      );
      expect(find.text('Dismiss'), findsOneWidget);

      // Dismiss banner
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(
        find.text('No valid Instagram or YouTube link found in clipboard.'),
        findsNothing,
      );
    });

    testWidgets('in Auto Mode: navigates to FetchingDetailsScreen when valid URL is detected', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
                GoRoute(path: '/fetching-details', builder: (_, __) => const FetchingDetailsScreen()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger valid URL found on watcher
      container.read(clipboardWatcherProvider.notifier).updateState(
            const ClipboardState(
              status: ClipboardDetectionStatus.newUrlFound,
              url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
              type: UrlType.youtube,
            ),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FetchingDetailsScreen), findsOneWidget);
      expect(find.text('Fetching...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('in Manual Mode: shows inline error text on invalid URL submission', (tester) async {
      SharedPreferences.setMockInitialValues({
        AutoModeNotifier.preferencesKey: false,
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'https://twitter.com/post/123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Check URL'));
      await tester.pumpAndSettle();

      expect(
        find.text('Invalid link. Please paste a valid Instagram Reel or YouTube video URL.'),
        findsOneWidget,
      );
    });

    testWidgets('in Manual Mode: navigates to FetchingDetailsScreen on valid URL submission', (tester) async {
      SharedPreferences.setMockInitialValues({
        AutoModeNotifier.preferencesKey: false,
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https://www.instagram.com/reel/C8XYZ123/');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Check URL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FetchingDetailsScreen), findsOneWidget);
      expect(find.text('Fetching...'), findsOneWidget);
    });
  });
}
