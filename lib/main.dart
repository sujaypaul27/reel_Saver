import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('Reel Saver - Phase 0 Complete'),
        ),
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
