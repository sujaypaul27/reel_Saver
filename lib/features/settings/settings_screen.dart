import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../download_engine/download_execution_service.dart';
import '../history/history_service.dart';
import '../home/providers/auto_mode_provider.dart';
import 'providers/locale_provider.dart';

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

  Future<void> _handleClearCache(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.clearCacheDialogTitle),
          content: Text(
            l10n.clearCacheDialogContent,
          ),
          actions: [
            ElevatedButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.noButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.yesButton),
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
            SnackBar(
              content: Text(l10n.cacheClearedSnackbar),
              duration: const Duration(milliseconds: 1500),
            ),
          );
        }
      } catch (cacheClearError) {
        debugPrint('[SettingsScreen] Failed to clear cache: $cacheClearError');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.cacheClearFailedSnackbar(
                  formatFriendlyErrorMessage(cacheClearError),
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleClearStorage(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.clearStorageDialogTitle),
          content: Text(
            l10n.clearStorageDialogContent,
          ),
          actions: [
            ElevatedButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.noButton),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.yesButton),
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
            SnackBar(
              content: Text(l10n.storageClearedSnackbar),
              duration: const Duration(milliseconds: 1500),
            ),
          );
        }
      } catch (storageClearError) {
        debugPrint(
            '[SettingsScreen] Failed to clear storage: $storageClearError');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.storageClearFailedSnackbar(
                  formatFriendlyErrorMessage(storageClearError),
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  static String formatFriendlyErrorMessage(Object error) {
    if (error is FileSystemException) {
      final osMessage = error.osError?.message;
      if (osMessage != null && osMessage.isNotEmpty) {
        return osMessage;
      }
      return error.message;
    }
    final rawString = error.toString().replaceFirst('Exception: ', '').trim();
    return rawString.split('\n').first;
  }

  String _getLocalizedThemeName(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.midnight:
        return l10n.themeMidnight;
      case AppThemeMode.classicLight:
        return l10n.themeClassicLight;
      case AppThemeMode.sunset:
        return l10n.themeSunset;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAutomaticDetectionEnabled = ref.watch(autoModeProvider);
    final activeLocale = ref.watch(localeProvider);
    final activeThemeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Text(
            l10n.sectionAppearance,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: AppThemeMode.values.map((themeMode) {
              final isSelected = themeMode == activeThemeMode;
              final previewTheme = AppThemes.getThemeData(themeMode);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      ref
                          .read(themeProvider.notifier)
                          .setThemeMode(themeMode);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: previewTheme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isSelected ? 0.2 : 0.06),
                            blurRadius: isSelected ? 6 : 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: previewTheme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: previewTheme.colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: previewTheme.scaffoldBackgroundColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getLocalizedThemeName(themeMode, l10n),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: previewTheme.colorScheme.onSurface,
                                ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.sectionPreferences,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                SwitchListTile(
                  secondary: const Icon(Icons.flash_on_rounded),
                  title: Text(
                    l10n.autoDetectionSettingTitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    l10n.autoDetectionSettingSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: isAutomaticDetectionEnabled,
                  onChanged: (newValue) {
                    ref.read(autoModeProvider.notifier).setAutoMode(newValue);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(
                    l10n.appLanguageTitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    AppLanguage.fromLocale(activeLocale).displayName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<Locale>(
                      value: activeLocale,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      onChanged: (Locale? newLocale) {
                        if (newLocale != null) {
                          ref
                              .read(localeProvider.notifier)
                              .setLocale(newLocale);
                        }
                      },
                      items: AppLanguage.values.map((language) {
                        return DropdownMenuItem<Locale>(
                          value: language.locale,
                          child: Text(language.displayName),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.sectionStorageManagement,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                  title: Text(
                    l10n.clearCacheTitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    l10n.clearCacheSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _handleClearCache(context, l10n),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    l10n.clearStorageTitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  subtitle: Text(
                    l10n.clearStorageSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _handleClearStorage(context, ref, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
