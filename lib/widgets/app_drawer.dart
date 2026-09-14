import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation drawer providing direct access to Home, Download History, and Settings.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoutePath = GoRouterState.of(context).uri.toString();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.video_collection_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  'Reel Saver',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Video Downloader & Manager',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            selected: currentRoutePath == '/',
            onTap: () {
              Navigator.of(context).pop();
              if (currentRoutePath != '/') {
                context.go('/');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Download History'),
            selected: currentRoutePath == '/history',
            onTap: () {
              Navigator.of(context).pop();
              if (currentRoutePath != '/history') {
                context.push('/history');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            selected: currentRoutePath == '/settings',
            onTap: () {
              Navigator.of(context).pop();
              if (currentRoutePath != '/settings') {
                context.push('/settings');
              }
            },
          ),
        ],
      ),
    );
  }
}
