import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/clipboard_engine/share_intent_service.dart';
import 'features/history/history_screen.dart';
import 'features/home/screens/fetching_details_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/settings/providers/locale_provider.dart';
import 'features/settings/settings_screen.dart';

final appRouter = GoRouter(
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
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

void main() {
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

    return MaterialApp.router(
      title: 'Reel Saver',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      locale: appLocale,
      supportedLocales: AppLanguage.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
