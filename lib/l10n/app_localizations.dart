import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ta'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Reel Saver'**
  String get appName;

  /// Application subtitle / tagline shown in navigation drawer
  ///
  /// In en, this message translates to:
  /// **'Video Downloader & Manager'**
  String get appTagline;

  /// Navigation link label for Home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Navigation link label for History screen
  ///
  /// In en, this message translates to:
  /// **'Download History'**
  String get navHistory;

  /// Navigation link label for Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Tooltip for drawer menu icon
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// Tooltip for clear text button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearTooltip;

  /// Title for automatic clipboard detection switch
  ///
  /// In en, this message translates to:
  /// **'Automatic Detection'**
  String get autoDetectionTitle;

  /// Subtitle when clipboard automatic detection is enabled
  ///
  /// In en, this message translates to:
  /// **'Clipboard is monitored automatically'**
  String get autoDetectionSubtitleActive;

  /// Subtitle when clipboard automatic detection is disabled
  ///
  /// In en, this message translates to:
  /// **'Manual URL paste mode active'**
  String get autoDetectionSubtitleInactive;

  /// Banner message when clipboard text is not a valid video link
  ///
  /// In en, this message translates to:
  /// **'No valid Instagram or YouTube link found in clipboard.'**
  String get invalidClipboardBanner;

  /// Action label to dismiss the banner
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissAction;

  /// Label for the URL text input
  ///
  /// In en, this message translates to:
  /// **'Video or Reel URL'**
  String get urlInputLabel;

  /// Hint text inside the URL text input
  ///
  /// In en, this message translates to:
  /// **'Paste YouTube or Instagram link here'**
  String get urlInputHint;

  /// Button to validate and fetch details for entered URL
  ///
  /// In en, this message translates to:
  /// **'Check URL'**
  String get checkUrlButton;

  /// Inline error message when invalid URL is submitted
  ///
  /// In en, this message translates to:
  /// **'Invalid link. Please paste a valid Instagram Reel or YouTube video URL.'**
  String get invalidUrlError;

  /// Banner text indicating number of active downloads in progress
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 download in progress} other{{count} downloads in progress}}'**
  String downloadsInProgress(int count);

  /// Title of the download queue bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Download Queue'**
  String get downloadQueueTitle;

  /// Button to clear completed items from queue
  ///
  /// In en, this message translates to:
  /// **'Clear Completed'**
  String get clearCompletedButton;

  /// Empty state text in the download queue sheet
  ///
  /// In en, this message translates to:
  /// **'No items in download queue.'**
  String get noItemsInQueue;

  /// Label for items added from share sheet without chosen quality
  ///
  /// In en, this message translates to:
  /// **'Quality not selected'**
  String get qualityNotSelected;

  /// Button to choose quality for shared item
  ///
  /// In en, this message translates to:
  /// **'Select Quality'**
  String get selectQualityButton;

  /// Queue item status label: queued
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// Queue item status label: completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Queue item status label: failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// Button label to retry an operation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Title of download failure dialog
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get downloadFailedTitle;

  /// Fallback error message when error reason is unavailable
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred while downloading this video.'**
  String get unknownErrorMessage;

  /// Button label to close a dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// Button label to retry a failed download
  ///
  /// In en, this message translates to:
  /// **'Retry Download'**
  String get retryDownloadButton;

  /// Title of storage permission dialog
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Required'**
  String get storagePermissionTitle;

  /// Explanation why storage permission is required
  ///
  /// In en, this message translates to:
  /// **'Reel Saver requires storage access to save downloaded videos and audio to your device. Please grant permission in App Settings.'**
  String get storagePermissionContent;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Button label to open app settings in device settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettingsButton;

  /// App bar title while fetching video details
  ///
  /// In en, this message translates to:
  /// **'Fetching Details'**
  String get fetchingDetailsTitle;

  /// App bar title when video details and formats are ready
  ///
  /// In en, this message translates to:
  /// **'Select Format'**
  String get selectFormatTitle;

  /// Progress label during video details extraction
  ///
  /// In en, this message translates to:
  /// **'Fetching...'**
  String get fetchingLabel;

  /// Error message when details extraction fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fetch video details. Please check the link and try again.'**
  String get fetchErrorDescription;

  /// Tooltip on format download icon button
  ///
  /// In en, this message translates to:
  /// **'Download {label}'**
  String downloadFormatTooltip(String label);

  /// Snackbar shown when single format download starts
  ///
  /// In en, this message translates to:
  /// **'Downloading {label}...'**
  String downloadingFormatSnackbar(String label);

  /// Button label to download selected formats when empty
  ///
  /// In en, this message translates to:
  /// **'Download Selected'**
  String get downloadSelectedButton;

  /// Button label to download selected formats with count
  ///
  /// In en, this message translates to:
  /// **'Download Selected ({count})'**
  String downloadSelectedWithCountButton(int count);

  /// Snackbar shown when batch downloading formats
  ///
  /// In en, this message translates to:
  /// **'Started downloading {count, plural, =1{1 format} other{{count} formats}}...'**
  String startedDownloadingFormatsSnackbar(int count);

  /// App bar title on download history screen
  ///
  /// In en, this message translates to:
  /// **'Download History'**
  String get downloadHistoryTitle;

  /// Snackbar when local file does not exist
  ///
  /// In en, this message translates to:
  /// **'File not found at: {filePath}'**
  String fileNotFoundAt(String filePath);

  /// Snackbar when opening file in external player fails
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String couldNotOpenFile(String error);

  /// Title of download deletion dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Download'**
  String get deleteDownloadTitle;

  /// Confirmation message when permanently deleting a file
  ///
  /// In en, this message translates to:
  /// **'Delete this file permanently? This cannot be undone.'**
  String get deleteConfirmationMessage;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// Snackbar confirming item was deleted
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String deletedItemSnackbar(String title);

  /// Empty state label on history screen
  ///
  /// In en, this message translates to:
  /// **'No downloads yet.'**
  String get noDownloadsYet;

  /// Tooltip on play button
  ///
  /// In en, this message translates to:
  /// **'Play / Open'**
  String get playOpenTooltip;

  /// Tooltip on delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// App bar title for Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Appearance section header in settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// Display name for Midnight theme
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get themeMidnight;

  /// Display name for Classic Light theme
  ///
  /// In en, this message translates to:
  /// **'Classic Light'**
  String get themeClassicLight;

  /// Display name for Sunset theme
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get themeSunset;

  /// Preferences section header in settings
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get sectionPreferences;

  /// Title of automatic detection setting tile
  ///
  /// In en, this message translates to:
  /// **'Automatic URL Detection'**
  String get autoDetectionSettingTitle;

  /// Subtitle describing automatic detection behavior
  ///
  /// In en, this message translates to:
  /// **'Inspect clipboard on app resume to detect video links automatically.'**
  String get autoDetectionSettingSubtitle;

  /// Title of application language setting tile
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguageTitle;

  /// Storage management section header in settings
  ///
  /// In en, this message translates to:
  /// **'Storage Management'**
  String get sectionStorageManagement;

  /// Title of clear cache setting
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCacheTitle;

  /// Subtitle describing clear cache functionality
  ///
  /// In en, this message translates to:
  /// **'Delete temporary thumbnails and partial fetch files without affecting completed downloads.'**
  String get clearCacheSubtitle;

  /// Title of clear cache confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCacheDialogTitle;

  /// Message in clear cache dialog
  ///
  /// In en, this message translates to:
  /// **'This will delete temporary files created during video fetching (thumbnails preview cache, partial downloads). Your completed downloads and history will NOT be affected. Continue?'**
  String get clearCacheDialogContent;

  /// No button label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noButton;

  /// Yes button label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesButton;

  /// Snackbar confirming cache cleanup
  ///
  /// In en, this message translates to:
  /// **'Temporary cache cleared successfully.'**
  String get cacheClearedSnackbar;

  /// Snackbar reporting cache cleanup failure
  ///
  /// In en, this message translates to:
  /// **'Failed to clear cache: {error}'**
  String cacheClearFailedSnackbar(String error);

  /// Title of clear storage setting
  ///
  /// In en, this message translates to:
  /// **'Clear Storage'**
  String get clearStorageTitle;

  /// Subtitle describing clear storage functionality
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all downloaded videos and wipe your download history.'**
  String get clearStorageSubtitle;

  /// Title of clear storage confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear Storage'**
  String get clearStorageDialogTitle;

  /// Message in clear storage confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL downloaded files and your entire download history. This cannot be undone. Are you sure?'**
  String get clearStorageDialogContent;

  /// Snackbar confirming storage wiped
  ///
  /// In en, this message translates to:
  /// **'All downloaded files and history have been cleared.'**
  String get storageClearedSnackbar;

  /// Snackbar reporting storage clear failure
  ///
  /// In en, this message translates to:
  /// **'Failed to clear storage: {error}'**
  String storageClearFailedSnackbar(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
