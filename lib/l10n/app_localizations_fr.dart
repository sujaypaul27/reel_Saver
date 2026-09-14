// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Reel Saver';

  @override
  String get appTagline => 'Téléchargeur et gestionnaire de vidéos';

  @override
  String get navHome => 'Accueil';

  @override
  String get navHistory => 'Historique des téléchargements';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navDownloads => 'Téléchargements';

  @override
  String get startDownloadsButton => 'Tout télécharger';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get clearTooltip => 'Effacer';

  @override
  String get autoDetectionTitle => 'Détection automatique';

  @override
  String get autoDetectionSubtitleActive =>
      'Le presse-papiers est surveillé automatiquement';

  @override
  String get autoDetectionSubtitleInactive => 'Mode de collage manuel actif';

  @override
  String get invalidClipboardBanner =>
      'Aucun lien Instagram ou YouTube valide trouvé dans le presse-papiers.';

  @override
  String get dismissAction => 'Ignorer';

  @override
  String get urlInputLabel => 'URL de la vidéo ou Reel';

  @override
  String get urlInputHint => 'Collez le lien YouTube ou Instagram ici';

  @override
  String get checkUrlButton => 'Vérifier l\'URL';

  @override
  String get invalidUrlError =>
      'Lien non valide. Veuillez coller une URL valide de Reel Instagram ou de vidéo YouTube.';

  @override
  String downloadsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count téléchargements en cours',
      one: '1 téléchargement en cours',
    );
    return '$_temp0';
  }

  @override
  String get downloadQueueTitle => 'File de téléchargement';

  @override
  String get clearCompletedButton => 'Effacer terminés';

  @override
  String get noItemsInQueue => 'Aucun élément dans la file d\'attente.';

  @override
  String get qualityNotSelected => 'Qualité non sélectionnée';

  @override
  String get selectQualityButton => 'Choisir la qualité';

  @override
  String get statusQueued => 'En attente';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusFailed => 'Échoué';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get downloadFailedTitle => 'Échec du téléchargement';

  @override
  String get unknownErrorMessage =>
      'Une erreur inconnue est survenue lors du téléchargement de cette vidéo.';

  @override
  String get closeButton => 'Fermer';

  @override
  String get retryDownloadButton => 'Réessayer le téléchargement';

  @override
  String get storagePermissionTitle => 'Autorisation de stockage requise';

  @override
  String get storagePermissionContent =>
      'Reel Saver a besoin de l\'accès au stockage pour enregistrer vos vidéos et audios. Veuillez accorder la permission dans les paramètres.';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get openSettingsButton => 'Ouvrir les paramètres';

  @override
  String get fetchingDetailsTitle => 'Récupération des détails';

  @override
  String get selectFormatTitle => 'Choisir le format';

  @override
  String get fetchingLabel => 'Récupération...';

  @override
  String get fetchErrorDescription =>
      'Impossible de récupérer les détails de la vidéo. Vérifiez le lien et réessayez.';

  @override
  String downloadFormatTooltip(String label) {
    return 'Télécharger $label';
  }

  @override
  String downloadingFormatSnackbar(String label) {
    return 'Téléchargement de $label...';
  }

  @override
  String get downloadSelectedButton => 'Télécharger sélection';

  @override
  String downloadSelectedWithCountButton(int count) {
    return 'Télécharger ($count)';
  }

  @override
  String startedDownloadingFormatsSnackbar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count formats',
      one: '1 format',
    );
    return 'Démarrage du téléchargement de $_temp0...';
  }

  @override
  String get downloadHistoryTitle => 'Historique des téléchargements';

  @override
  String fileNotFoundAt(String filePath) {
    return 'Fichier introuvable à : $filePath';
  }

  @override
  String couldNotOpenFile(String error) {
    return 'Impossible d\'ouvrir le fichier : $error';
  }

  @override
  String get deleteDownloadTitle => 'Supprimer le téléchargement';

  @override
  String get deleteConfirmationMessage =>
      'Supprimer définitivement ce fichier ? Cette action est irréversible.';

  @override
  String get deleteButton => 'Supprimer';

  @override
  String deletedItemSnackbar(String title) {
    return '\"$title\" supprimé';
  }

  @override
  String get noDownloadsYet => 'Aucun téléchargement pour le moment.';

  @override
  String get playOpenTooltip => 'Lire / Ouvrir';

  @override
  String get deleteTooltip => 'Supprimer';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get themeMidnight => 'Minuit';

  @override
  String get themeClassicLight => 'Lumière classique';

  @override
  String get themeSunset => 'Coucher de soleil';

  @override
  String get sectionPreferences => 'Préférences';

  @override
  String get autoDetectionSettingTitle => 'Détection automatique des URL';

  @override
  String get autoDetectionSettingSubtitle =>
      'Vérifie le presse-papiers à l\'ouverture pour détecter automatiquement les liens vidéo.';

  @override
  String get appLanguageTitle => 'Langue de l\'application';

  @override
  String get sectionStorageManagement => 'Gestion du stockage';

  @override
  String get clearCacheTitle => 'Vider le cache';

  @override
  String get clearCacheSubtitle =>
      'Supprime les miniatures temporaires et fichiers partiels sans affecter les téléchargements.';

  @override
  String get clearCacheDialogTitle => 'Vider le cache';

  @override
  String get clearCacheDialogContent =>
      'Cela supprimera les fichiers temporaires créés lors de la récupération des vidéos. Vos téléchargements et l\'historique ne seront pas affectés. Continuer ?';

  @override
  String get noButton => 'Non';

  @override
  String get yesButton => 'Oui';

  @override
  String get cacheClearedSnackbar => 'Cache temporaire vidé avec succès.';

  @override
  String cacheClearFailedSnackbar(String error) {
    return 'Échec du vidage du cache : $error';
  }

  @override
  String get clearStorageTitle => 'Effacer le stockage';

  @override
  String get clearStorageSubtitle =>
      'Supprime définitivement toutes les vidéos téléchargées et efface l\'historique.';

  @override
  String get clearStorageDialogTitle => 'Effacer le stockage';

  @override
  String get clearStorageDialogContent =>
      'Cela supprimera définitivement TOUS les fichiers téléchargés et tout l\'historique. Cette action est irréversible. Êtes-vous sûr ?';

  @override
  String get storageClearedSnackbar =>
      'Tous les fichiers téléchargés et l\'historique ont été effacés.';

  @override
  String storageClearFailedSnackbar(String error) {
    return 'Échec de l\'effacement du stockage : $error';
  }
}
