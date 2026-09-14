import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reel_saver/widgets/app_drawer.dart';

void main() {
  Widget createTestWidget({required String initialLocation}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              leading: Builder(
                builder: (scaffoldContext) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                ),
              ),
            ),
            drawer: const AppDrawer(),
            body: const Text('Home Page'),
          ),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => Scaffold(
            appBar: AppBar(),
            drawer: const AppDrawer(),
            body: const Text('History Page'),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => Scaffold(
            appBar: AppBar(),
            drawer: const AppDrawer(),
            body: const Text('Settings Page'),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  group('AppDrawer Widget Tests', () {
    testWidgets('renders drawer header and navigation options', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLocation: '/'));
      await tester.pumpAndSettle();

      // Open the drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify header and links
      expect(find.text('Reel Saver'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Download History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('navigates to Download History and Settings from drawer',
        (tester) async {
      await tester.pumpWidget(createTestWidget(initialLocation: '/'));
      await tester.pumpAndSettle();

      // Open drawer and tap Download History
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Download History'));
      await tester.pumpAndSettle();

      expect(find.text('History Page'), findsOneWidget);

      // Open drawer from history page and tap Settings
      final ScaffoldState historyScaffold =
          tester.state(find.byType(Scaffold));
      historyScaffold.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings Page'), findsOneWidget);
    });
  });
}
