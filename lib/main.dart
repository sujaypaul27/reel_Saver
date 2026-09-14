import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class ReelSaverApp extends StatelessWidget {
  const ReelSaverApp({super.key});

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
