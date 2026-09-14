import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../download_engine/download_execution_service.dart';
import '../history/history_service.dart';

/// Settings screen offering application cache cleanup and complete storage wiping options.
class SettingsScreen extends ConsumerWidget {
  final Directory? customTempDirectory;
  final Directory? customDownloadsDirectory;
  final HistoryService? customHistoryService;

  const SettingsScreen({
    super.key,
    this.customTempDirectory,
    this.customDownloadsDirectory,
    this.customHistoryService,
  });

  Future<void> _handleClearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text(
            'This will delete temporary files created during video fetching (thumbnails preview cache, partial downloads). Your completed downloads and history will NOT be affected. Continue?',
          ),
          actions: [
            ElevatedButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final tempDirectory =
            customTempDirectory ?? await getTemporaryDirectory();
        if (tempDirectory.existsSync()) {
          for (final fileEntity in tempDirectory.listSync(followLinks: false)) {
            try {
              fileEntity.deleteSync(recursive: true);
            } catch (deleteError) {
              debugPrint(
                  '[SettingsScreen] Could not delete temp item: $deleteError');
            }
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Temporary cache cleared successfully.'),
              duration: Duration(milliseconds: 1500),
            ),
          );
        }
      } catch (cacheClearError) {
        debugPrint('[SettingsScreen] Failed to clear cache: $cacheClearError');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear cache: $cacheClearError'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleClearStorage(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Storage'),
          content: const Text(
            'This will permanently delete ALL downloaded files and your entire download history. This cannot be undone. Are you sure?',
          ),
          actions: [
            ElevatedButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final Directory downloadsDirectory;
        if (customDownloadsDirectory != null) {
          downloadsDirectory = customDownloadsDirectory!;
        } else {
          final executionService = ref.read(downloadExecutionServiceProvider);
          downloadsDirectory = await executionService.getDownloadsDirectory();
        }

        if (downloadsDirectory.existsSync()) {
          for (final fileEntity
              in downloadsDirectory.listSync(followLinks: false)) {
            try {
              fileEntity.deleteSync(recursive: true);
            } catch (deleteError) {
              debugPrint(
                  '[SettingsScreen] Could not delete download item: $deleteError');
            }
          }
        }

        final HistoryService activeHistoryService =
            customHistoryService ?? ref.read(historyServiceProvider);
        await activeHistoryService.clearHistory();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('All downloaded files and history have been cleared.'),
              duration: Duration(milliseconds: 1500),
            ),
          );
        }
      } catch (storageClearError) {
        debugPrint(
            '[SettingsScreen] Failed to clear storage: $storageClearError');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear storage: $storageClearError'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Text(
            'Storage Management',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cached_rounded),
                  title: const Text(
                    'Clear Cache',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Delete temporary thumbnails and partial fetch files without affecting completed downloads.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _handleClearCache(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Clear Storage',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: const Text(
                    'Permanently delete all downloaded videos and wipe your download history.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _handleClearStorage(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
