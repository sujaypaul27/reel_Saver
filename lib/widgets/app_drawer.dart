import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// Navigation drawer providing direct access to Home, Download History, and Settings.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoutePath = GoRouterState.of(context).uri.toString();
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  l10n.appTagline,
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
            title: Text(l10n.navHome),
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
            title: Text(l10n.navHistory),
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
            title: Text(l10n.navSettings),
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
