import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/clipboard_engine/share_intent_service.dart';
import 'features/history/history_screen.dart';
import 'features/home/screens/fetching_details_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/settings/providers/locale_provider.dart';
import 'features/settings/settings_screen.dart';
import 'l10n/app_localizations.dart';

CustomTransitionPage<void> buildFadeSlideTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation);

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(curvedAnimation);

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => buildFadeSlideTransitionPage(
        context: context,
        state: state,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/fetching-details',
      pageBuilder: (context, state) => buildFadeSlideTransitionPage(
        context: context,
        state: state,
        child: FetchingDetailsScreen(
          videoUrl: state.extra as String?,
        ),
      ),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) => buildFadeSlideTransitionPage(
        context: context,
        state: state,
        child: const HistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => buildFadeSlideTransitionPage(
        context: context,
        state: state,
        child: const SettingsScreen(),
      ),
    ),
  ],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ReelSaverApp(),
    ),
  );
}

class ReelSaverApp extends ConsumerStatefulWidget {
  const ReelSaverApp({super.key});

  @override
  ConsumerState<ReelSaverApp> createState() => _ReelSaverAppState();
}

class _ReelSaverAppState extends ConsumerState<ReelSaverApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shareIntentServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocale = ref.watch(localeProvider);
    final selectedThemeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Reel Saver',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      locale: appLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppThemes.getThemeData(selectedThemeMode, locale: appLocale),
    );
  }
}
