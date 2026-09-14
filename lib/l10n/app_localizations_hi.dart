// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Reel Saver';

  @override
  String get appTagline => 'वीडियो डाउनलोडर और प्रबंधक';

  @override
  String get navHome => 'होम';

  @override
  String get navHistory => 'डाउनलोड इतिहास';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get menuTooltip => 'मेनू';

  @override
  String get clearTooltip => 'साफ़ करें';

  @override
  String get autoDetectionTitle => 'स्वचालित पहचान';

  @override
  String get autoDetectionSubtitleActive =>
      'क्लिपबोर्ड की स्वचालित निगरानी जारी है';

  @override
  String get autoDetectionSubtitleInactive =>
      'मैन्युअल URL पेस्ट मोड सक्रिय है';

  @override
  String get invalidClipboardBanner =>
      'क्लिपबोर्ड में कोई मान्य Instagram या YouTube लिंक नहीं मिला।';

  @override
  String get dismissAction => 'हटाएं';

  @override
  String get urlInputLabel => 'वीडियो या रील URL';

  @override
  String get urlInputHint => 'YouTube या Instagram लिंक यहाँ पेस्ट करें';

  @override
  String get checkUrlButton => 'लिंक जांचें';

  @override
  String get invalidUrlError =>
      'अमान्य लिंक। कृपया एक मान्य Instagram Reel या YouTube वीडियो URL पेस्ट करें।';

  @override
  String downloadsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डाउनलोड जारी हैं',
      one: '1 डाउनलोड प्रगति पर है',
    );
    return '$_temp0';
  }

  @override
  String get downloadQueueTitle => 'डाउनलोड कतार';

  @override
  String get clearCompletedButton => 'पूर्ण हटाएं';

  @override
  String get noItemsInQueue => 'डाउनलोड कतार में कोई आइटम नहीं है।';

  @override
  String get qualityNotSelected => 'गुणवत्ता नहीं चुनी गई';

  @override
  String get selectQualityButton => 'गुणवत्ता चुनें';

  @override
  String get statusQueued => 'कतारबद्ध';

  @override
  String get statusCompleted => 'पूर्ण हुआ';

  @override
  String get statusFailed => 'विफल';

  @override
  String get retryButton => 'पुनः प्रयास करें';

  @override
  String get downloadFailedTitle => 'डाउनलोड विफल';

  @override
  String get unknownErrorMessage =>
      'इस वीडियो को डाउनलोड करते समय कोई अज्ञात त्रुटि हुई।';

  @override
  String get closeButton => 'बंद करें';

  @override
  String get retryDownloadButton => 'पुनः डाउनलोड करें';

  @override
  String get storagePermissionTitle => 'स्टोरेज अनुमति आवश्यक है';

  @override
  String get storagePermissionContent =>
      'डाउनलोड किए गए वीडियो और ऑडियो को सहेजने के लिए स्टोरेज की अनुमति आवश्यक है। कृपया ऐप सेटिंग्स में अनुमति दें।';

  @override
  String get cancelButton => 'रद्द करें';

  @override
  String get openSettingsButton => 'सेटिंग्स खोलें';

  @override
  String get fetchingDetailsTitle => 'विवरण लाया जा रहा है';

  @override
  String get selectFormatTitle => 'प्रारूप चुनें';

  @override
  String get fetchingLabel => 'लोड हो रहा है...';

  @override
  String get fetchErrorDescription =>
      'वीडियो विवरण प्राप्त नहीं हो सका। कृपया लिंक जांचें और पुनः प्रयास करें।';

  @override
  String downloadFormatTooltip(String label) {
    return '$label डाउनलोड करें';
  }

  @override
  String downloadingFormatSnackbar(String label) {
    return '$label डाउनलोड हो रहा है...';
  }

  @override
  String get downloadSelectedButton => 'चयनित डाउनलोड करें';

  @override
  String downloadSelectedWithCountButton(int count) {
    return 'चयनित डाउनलोड करें ($count)';
  }

  @override
  String startedDownloadingFormatsSnackbar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count प्रारूपों',
      one: '1 प्रारूप',
    );
    return '$_temp0 का डाउनलोड शुरू हुआ...';
  }

  @override
  String get downloadHistoryTitle => 'डाउनलोड इतिहास';

  @override
  String fileNotFoundAt(String filePath) {
    return 'फ़ाइल यहाँ नहीं मिली: $filePath';
  }

  @override
  String couldNotOpenFile(String error) {
    return 'फ़ाइल नहीं खोली जा सकी: $error';
  }

  @override
  String get deleteDownloadTitle => 'डाउनलोड हटाएं';

  @override
  String get deleteConfirmationMessage =>
      'क्या इस फ़ाइल को हमेशा के लिए हटाना चाहते हैं? इसे वापस नहीं लाया जा सकता।';

  @override
  String get deleteButton => 'हटाएं';

  @override
  String deletedItemSnackbar(String title) {
    return '\"$title\" हटाया गया';
  }

  @override
  String get noDownloadsYet => 'अभी कोई डाउनलोड नहीं है।';

  @override
  String get playOpenTooltip => 'चलाएं / खोलें';

  @override
  String get deleteTooltip => 'हटाएं';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get sectionAppearance => 'रूप-रंग';

  @override
  String get themeMidnight => 'मिडनाइट';

  @override
  String get themeClassicLight => 'क्लासिक लाइट';

  @override
  String get themeSunset => 'सनसेट';

  @override
  String get sectionPreferences => 'प्राथमिकताएं';

  @override
  String get autoDetectionSettingTitle => 'स्वचालित URL पहचान';

  @override
  String get autoDetectionSettingSubtitle =>
      'वीडियो लिंक को स्वचालित रूप से पहचानने के लिए क्लिपबोर्ड जांचें।';

  @override
  String get appLanguageTitle => 'ऐप की भाषा';

  @override
  String get sectionStorageManagement => 'स्टोरेज प्रबंधन';

  @override
  String get clearCacheTitle => 'कैश साफ़ करें';

  @override
  String get clearCacheSubtitle =>
      'पूर्ण डाउनलोड को प्रभावित किए बिना अस्थायी फ़ाइलें हटाएं।';

  @override
  String get clearCacheDialogTitle => 'कैश साफ़ करें';

  @override
  String get clearCacheDialogContent =>
      'यह वीडियो खोज के दौरान बनी अस्थायी फ़ाइलों को हटा देगा। आपके डाउनलोड और इतिहास पर असर नहीं पड़ेगा। जारी रखें?';

  @override
  String get noButton => 'नहीं';

  @override
  String get yesButton => 'हाँ';

  @override
  String get cacheClearedSnackbar => 'अस्थायी कैश सफलतापूर्वक साफ़ किया गया।';

  @override
  String cacheClearFailedSnackbar(String error) {
    return 'कैश साफ़ करने में विफल: $error';
  }

  @override
  String get clearStorageTitle => 'स्टोरेज साफ़ करें';

  @override
  String get clearStorageSubtitle =>
      'सभी डाउनलोड किए गए वीडियो और इतिहास को हमेशा के लिए हटाएं।';

  @override
  String get clearStorageDialogTitle => 'स्टोरेज साफ़ करें';

  @override
  String get clearStorageDialogContent =>
      'यह सभी डाउनलोड की गई फ़ाइलों और इतिहास को स्थायी रूप से हटा देगा। इसे पूर्ववत नहीं किया जा सकता। क्या आप निश्चित हैं?';

  @override
  String get storageClearedSnackbar =>
      'सभी डाउनलोड की गई फ़ाइलें और इतिहास साफ़ कर दिए गए हैं।';

  @override
  String storageClearFailedSnackbar(String error) {
    return 'स्टोरेज साफ़ करने में विफल: $error';
  }
}
