import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/clipboard_engine/share_intent_service.dart';
import 'features/home/screens/fetching_details_screen.dart';
import 'features/home/screens/home_screen.dart';

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
    return MaterialApp.router(
      title: 'Reel Saver',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
