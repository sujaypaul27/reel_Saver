// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'Reel Saver';

  @override
  String get appTagline => 'வீடியோ பதிவிறக்கி & மேலாளர்';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navHistory => 'பதிவிறக்க வரலாறு';

  @override
  String get navSettings => 'அமைப்புகள்';

  @override
  String get navDownloads => 'பதிவிறக்கங்கள்';

  @override
  String get startDownloadsButton => 'அனைத்தையும் பதிவிறக்குக';

  @override
  String get menuTooltip => 'மெனு';

  @override
  String get clearTooltip => 'அழி';

  @override
  String get autoDetectionTitle => 'தானியங்கி கண்டறிதல்';

  @override
  String get autoDetectionSubtitleActive =>
      'கிளிப்போர்டு தானாக கண்காணிக்கப்படுகிறது';

  @override
  String get autoDetectionSubtitleInactive =>
      'கைமுறை URL ஒட்டுதல் பயன்முறை செயலில் உள்ளது';

  @override
  String get invalidClipboardBanner =>
      'கிளிப்போர்டில் சரியான Instagram அல்லது YouTube இணைப்பு இல்லை.';

  @override
  String get dismissAction => 'நிராகரி';

  @override
  String get urlInputLabel => 'வீடியோ அல்லது ரீல் URL';

  @override
  String get urlInputHint => 'YouTube அல்லது Instagram இணைப்பை இங்கே ஒட்டவும்';

  @override
  String get checkUrlButton => 'URL சரிபார்';

  @override
  String get invalidUrlError =>
      'தவறான இணைப்பு. சரியான Instagram Reel அல்லது YouTube வீடியோ இணைப்பை ஒட்டவும்.';

  @override
  String downloadsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பதிவிறக்கங்கள் செயலில் உள்ளன',
      one: '1 பதிவிறக்கம் செயலில் உள்ளது',
    );
    return '$_temp0';
  }

  @override
  String get downloadQueueTitle => 'பதிவிறக்க வரிசை';

  @override
  String get clearCompletedButton => 'முடிந்ததை அழி';

  @override
  String get noItemsInQueue => 'பதிவிறக்க வரிசையில் உருப்படிகள் இல்லை.';

  @override
  String get qualityNotSelected => 'தரம் தேர்ந்தெடுக்கப்படவில்லை';

  @override
  String get selectQualityButton => 'தரம் தேர்ந்தெடு';

  @override
  String get statusQueued => 'வரிசையில்';

  @override
  String get statusCompleted => 'முடிந்தது';

  @override
  String get statusFailed => 'தோல்வி';

  @override
  String get retryButton => 'மீண்டும் முயல்க';

  @override
  String get downloadFailedTitle => 'பதிவிறக்கம் தோல்வியடைந்தது';

  @override
  String get unknownErrorMessage =>
      'இந்த வீடியோவைப் பதிவிறக்கும் போது எதிர்பாராத பிழை ஏற்பட்டது.';

  @override
  String get closeButton => 'மூடு';

  @override
  String get retryDownloadButton => 'மீண்டும் பதிவிறக்கு';

  @override
  String get storagePermissionTitle => 'சேமிப்பக அனுமதி தேவை';

  @override
  String get storagePermissionContent =>
      'பதிவிறக்கம் செய்த கோப்புகளைச் சேமிக்க Reel Saver-க்கு சேமிப்பக அனுமதி தேவை. அமைப்புகளில் அனுமதியை இயக்கவும்.';

  @override
  String get cancelButton => 'ரத்து';

  @override
  String get openSettingsButton => 'அமைப்புகளைத் திற';

  @override
  String get fetchingDetailsTitle => 'விவரங்கள் பெறப்படுகின்றன';

  @override
  String get selectFormatTitle => 'வடிவத்தைத் தேர்ந்தெடு';

  @override
  String get fetchingLabel => 'பெறுகிறது...';

  @override
  String get fetchErrorDescription =>
      'வீடியோ விவரங்களைப் பெற முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String downloadFormatTooltip(String label) {
    return '$label பதிவிறக்கு';
  }

  @override
  String downloadingFormatSnackbar(String label) {
    return '$label பதிவிறக்கப்படுகிறது...';
  }

  @override
  String get downloadSelectedButton => 'தேர்ந்தெடுத்ததை பதிவிறக்கு';

  @override
  String downloadSelectedWithCountButton(int count) {
    return 'தேர்ந்தெடுத்ததை பதிவிறக்கு ($count)';
  }

  @override
  String startedDownloadingFormatsSnackbar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count வடிவங்கள்',
      one: '1 வடிவம்',
    );
    return '$_temp0 பதிவிறக்கம் தொடங்கப்பட்டது...';
  }

  @override
  String get downloadHistoryTitle => 'பதிவிறக்க வரலாறு';

  @override
  String fileNotFoundAt(String filePath) {
    return 'கோப்பு காணப்படவில்லை: $filePath';
  }

  @override
  String couldNotOpenFile(String error) {
    return 'கோப்பைத் திறக்க முடியவில்லை: $error';
  }

  @override
  String get deleteDownloadTitle => 'பதிவிறக்கத்தை நீக்கு';

  @override
  String get deleteConfirmationMessage =>
      'இந்தக் கோப்பை நிரந்தரமாக நீக்கவா? இதை செயல்தவிர்க்க முடியாது.';

  @override
  String get deleteButton => 'நீக்கு';

  @override
  String deletedItemSnackbar(String title) {
    return '\"$title\" நீக்கப்பட்டது';
  }

  @override
  String get noDownloadsYet => 'பதிவிறக்கங்கள் எதுவும் இல்லை.';

  @override
  String get playOpenTooltip => 'இயக்கு / திற';

  @override
  String get deleteTooltip => 'நீக்கு';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get sectionAppearance => 'தோற்றம்';

  @override
  String get themeMidnight => 'நள்ளிரவு';

  @override
  String get themeClassicLight => 'கிளாசிக் வெளிச்சம்';

  @override
  String get themeSunset => 'அந்திப்பொழுது';

  @override
  String get sectionPreferences => 'விருப்பத்தேர்வுகள்';

  @override
  String get autoDetectionSettingTitle => 'தானியங்கி URL கண்டறிதல்';

  @override
  String get autoDetectionSettingSubtitle =>
      'வீடியோ இணைப்புகளைத் தானாகக் கண்டறிய கிளிப்போர்டை ஆய்வு செய்கிறது.';

  @override
  String get appLanguageTitle => 'பயன்பாட்டு மொழி';

  @override
  String get sectionStorageManagement => 'சேமிப்பக மேலாண்மை';

  @override
  String get clearCacheTitle => 'தற்காலிக சேமிப்பை அழி';

  @override
  String get clearCacheSubtitle =>
      'பதிவிறக்கங்களைப் பாதிக்காமல் தற்காலிகக் கோப்புகளை நீக்குகிறது.';

  @override
  String get clearCacheDialogTitle => 'தற்காலிக சேமிப்பை அழி';

  @override
  String get clearCacheDialogContent =>
      'இது வீடியோ தேடலின் போது உருவாக்கப்பட்ட தற்காலிகக் கோப்புகளை நீக்கும். பதிவிறக்கங்கள் பாதிக்கப்படாது. தொடரவா?';

  @override
  String get noButton => 'இல்லை';

  @override
  String get yesButton => 'ஆம்';

  @override
  String get cacheClearedSnackbar =>
      'தற்காலிக சேமிப்பு வெற்றிகரமாக அழிக்கப்பட்டது.';

  @override
  String cacheClearFailedSnackbar(String error) {
    return 'தற்காலிக சேமிப்பை அழிக்க முடியவில்லை: $error';
  }

  @override
  String get clearStorageTitle => 'சேமிப்பகத்தை அழி';

  @override
  String get clearStorageSubtitle =>
      'பதிவிறக்கம் செய்த அனைத்து வீடியோக்களையும் வரலாற்றையும் நிரந்தரமாக நீக்குகிறது.';

  @override
  String get clearStorageDialogTitle => 'சேமிப்பகத்தை அழி';

  @override
  String get clearStorageDialogContent =>
      'இது பதிவிறக்கம் செய்த அனைத்து கோப்புகளையும் வரலாற்றையும் நிரந்தரமாக நீக்கும். இதை மாற்ற முடியாது. நிச்சயமாக நீக்கவா?';

  @override
  String get storageClearedSnackbar =>
      'அனைத்து கோப்புகளும் வரலாறும் வெற்றிகரமாக அழிக்கப்பட்டன.';

  @override
  String storageClearFailedSnackbar(String error) {
    return 'சேமிப்பகத்தை அழிக்க முடியவில்லை: $error';
  }
}
