// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Reel Saver';

  @override
  String get appTagline => 'Video Downloader & Manager';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'Download History';

  @override
  String get navSettings => 'Settings';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get clearTooltip => 'Clear';

  @override
  String get autoDetectionTitle => 'Automatic Detection';

  @override
  String get autoDetectionSubtitleActive =>
      'Clipboard is monitored automatically';

  @override
  String get autoDetectionSubtitleInactive => 'Manual URL paste mode active';

  @override
  String get invalidClipboardBanner =>
      'No valid Instagram or YouTube link found in clipboard.';

  @override
  String get dismissAction => 'Dismiss';

  @override
  String get urlInputLabel => 'Video or Reel URL';

  @override
  String get urlInputHint => 'Paste YouTube or Instagram link here';

  @override
  String get checkUrlButton => 'Check URL';

  @override
  String get invalidUrlError =>
      'Invalid link. Please paste a valid Instagram Reel or YouTube video URL.';

  @override
  String downloadsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads in progress',
      one: '1 download in progress',
    );
    return '$_temp0';
  }

  @override
  String get downloadQueueTitle => 'Download Queue';

  @override
  String get clearCompletedButton => 'Clear Completed';

  @override
  String get noItemsInQueue => 'No items in download queue.';

  @override
  String get qualityNotSelected => 'Quality not selected';

  @override
  String get selectQualityButton => 'Select Quality';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get retryButton => 'Retry';

  @override
  String get downloadFailedTitle => 'Download Failed';

  @override
  String get unknownErrorMessage =>
      'An unknown error occurred while downloading this video.';

  @override
  String get closeButton => 'Close';

  @override
  String get retryDownloadButton => 'Retry Download';

  @override
  String get storagePermissionTitle => 'Storage Permission Required';

  @override
  String get storagePermissionContent =>
      'Reel Saver requires storage access to save downloaded videos and audio to your device. Please grant permission in App Settings.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String get fetchingDetailsTitle => 'Fetching Details';

  @override
  String get selectFormatTitle => 'Select Format';

  @override
  String get fetchingLabel => 'Fetching...';

  @override
  String get fetchErrorDescription =>
      'Couldn\'t fetch video details. Please check the link and try again.';

  @override
  String downloadFormatTooltip(String label) {
    return 'Download $label';
  }

  @override
  String downloadingFormatSnackbar(String label) {
    return 'Downloading $label...';
  }

  @override
  String get downloadSelectedButton => 'Download Selected';

  @override
  String downloadSelectedWithCountButton(int count) {
    return 'Download Selected ($count)';
  }

  @override
  String startedDownloadingFormatsSnackbar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count formats',
      one: '1 format',
    );
    return 'Started downloading $_temp0...';
  }

  @override
  String get downloadHistoryTitle => 'Download History';

  @override
  String fileNotFoundAt(String filePath) {
    return 'File not found at: $filePath';
  }

  @override
  String couldNotOpenFile(String error) {
    return 'Could not open file: $error';
  }

  @override
  String get deleteDownloadTitle => 'Delete Download';

  @override
  String get deleteConfirmationMessage =>
      'Delete this file permanently? This cannot be undone.';

  @override
  String get deleteButton => 'Delete';

  @override
  String deletedItemSnackbar(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String get noDownloadsYet => 'No downloads yet.';

  @override
  String get playOpenTooltip => 'Play / Open';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeMidnight => 'Midnight';

  @override
  String get themeClassicLight => 'Classic Light';

  @override
  String get themeSunset => 'Sunset';

  @override
  String get sectionPreferences => 'Preferences';

  @override
  String get autoDetectionSettingTitle => 'Automatic URL Detection';

  @override
  String get autoDetectionSettingSubtitle =>
      'Inspect clipboard on app resume to detect video links automatically.';

  @override
  String get appLanguageTitle => 'App Language';

  @override
  String get sectionStorageManagement => 'Storage Management';

  @override
  String get clearCacheTitle => 'Clear Cache';

  @override
  String get clearCacheSubtitle =>
      'Delete temporary thumbnails and partial fetch files without affecting completed downloads.';

  @override
  String get clearCacheDialogTitle => 'Clear Cache';

  @override
  String get clearCacheDialogContent =>
      'This will delete temporary files created during video fetching (thumbnails preview cache, partial downloads). Your completed downloads and history will NOT be affected. Continue?';

  @override
  String get noButton => 'No';

  @override
  String get yesButton => 'Yes';

  @override
  String get cacheClearedSnackbar => 'Temporary cache cleared successfully.';

  @override
  String cacheClearFailedSnackbar(String error) {
    return 'Failed to clear cache: $error';
  }

  @override
  String get clearStorageTitle => 'Clear Storage';

  @override
  String get clearStorageSubtitle =>
      'Permanently delete all downloaded videos and wipe your download history.';

  @override
  String get clearStorageDialogTitle => 'Clear Storage';

  @override
  String get clearStorageDialogContent =>
      'This will permanently delete ALL downloaded files and your entire download history. This cannot be undone. Are you sure?';

  @override
  String get storageClearedSnackbar =>
      'All downloaded files and history have been cleared.';

  @override
  String storageClearFailedSnackbar(String error) {
    return 'Failed to clear storage: $error';
  }
}
