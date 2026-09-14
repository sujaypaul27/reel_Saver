// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Reel Saver';

  @override
  String get appTagline => 'Descargador y gestor de videos';

  @override
  String get navHome => 'Inicio';

  @override
  String get navHistory => 'Historial de descargas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get menuTooltip => 'Menú';

  @override
  String get clearTooltip => 'Borrar';

  @override
  String get autoDetectionTitle => 'Detección automática';

  @override
  String get autoDetectionSubtitleActive =>
      'El portapapeles se monitorea automáticamente';

  @override
  String get autoDetectionSubtitleInactive =>
      'Modo manual de pegado de URL activo';

  @override
  String get invalidClipboardBanner =>
      'No se encontró ningún enlace válido de Instagram o YouTube en el portapapeles.';

  @override
  String get dismissAction => 'Descartar';

  @override
  String get urlInputLabel => 'URL del video o Reel';

  @override
  String get urlInputHint => 'Pega el enlace de YouTube o Instagram aquí';

  @override
  String get checkUrlButton => 'Comprobar URL';

  @override
  String get invalidUrlError =>
      'Enlace no válido. Pega una URL válida de Instagram Reel o video de YouTube.';

  @override
  String downloadsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count descargas en curso',
      one: '1 descarga en curso',
    );
    return '$_temp0';
  }

  @override
  String get downloadQueueTitle => 'Cola de descargas';

  @override
  String get clearCompletedButton => 'Borrar completados';

  @override
  String get noItemsInQueue => 'No hay elementos en la cola de descargas.';

  @override
  String get qualityNotSelected => 'Calidad no seleccionada';

  @override
  String get selectQualityButton => 'Elegir calidad';

  @override
  String get statusQueued => 'En cola';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusFailed => 'Fallido';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get downloadFailedTitle => 'Descarga fallida';

  @override
  String get unknownErrorMessage =>
      'Ocurrió un error desconocido al descargar este video.';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get retryDownloadButton => 'Reintentar descarga';

  @override
  String get storagePermissionTitle => 'Permiso de almacenamiento necesario';

  @override
  String get storagePermissionContent =>
      'Reel Saver necesita acceso al almacenamiento para guardar videos y audios. Concede el permiso en Ajustes de la app.';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get openSettingsButton => 'Abrir ajustes';

  @override
  String get fetchingDetailsTitle => 'Obteniendo detalles';

  @override
  String get selectFormatTitle => 'Seleccionar formato';

  @override
  String get fetchingLabel => 'Obteniendo...';

  @override
  String get fetchErrorDescription =>
      'No se pudieron obtener los detalles del video. Revisa el enlace e inténtalo de nuevo.';

  @override
  String downloadFormatTooltip(String label) {
    return 'Descargar $label';
  }

  @override
  String downloadingFormatSnackbar(String label) {
    return 'Descargando $label...';
  }

  @override
  String get downloadSelectedButton => 'Descargar selección';

  @override
  String downloadSelectedWithCountButton(int count) {
    return 'Descargar ($count)';
  }

  @override
  String startedDownloadingFormatsSnackbar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count formatos',
      one: '1 formato',
    );
    return 'Iniciando descarga de $_temp0...';
  }

  @override
  String get downloadHistoryTitle => 'Historial de descargas';

  @override
  String fileNotFoundAt(String filePath) {
    return 'Archivo no encontrado en: $filePath';
  }

  @override
  String couldNotOpenFile(String error) {
    return 'No se pudo abrir el archivo: $error';
  }

  @override
  String get deleteDownloadTitle => 'Eliminar descarga';

  @override
  String get deleteConfirmationMessage =>
      '¿Eliminar este archivo de forma permanente? Esta acción no se puede deshacer.';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String deletedItemSnackbar(String title) {
    return '\"$title\" eliminado';
  }

  @override
  String get noDownloadsYet => 'Aún no hay descargas.';

  @override
  String get playOpenTooltip => 'Reproducir / Abrir';

  @override
  String get deleteTooltip => 'Eliminar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get themeMidnight => 'Medianoche';

  @override
  String get themeClassicLight => 'Clásico claro';

  @override
  String get themeSunset => 'Atardecer';

  @override
  String get sectionPreferences => 'Preferencias';

  @override
  String get autoDetectionSettingTitle => 'Detección automática de URL';

  @override
  String get autoDetectionSettingSubtitle =>
      'Inspecciona el portapapeles al reanudar la app para detectar enlaces automáticamente.';

  @override
  String get appLanguageTitle => 'Idioma de la aplicación';

  @override
  String get sectionStorageManagement => 'Gestión de almacenamiento';

  @override
  String get clearCacheTitle => 'Borrar caché';

  @override
  String get clearCacheSubtitle =>
      'Elimina miniaturas temporales y archivos parciales sin afectar las descargas completadas.';

  @override
  String get clearCacheDialogTitle => 'Borrar caché';

  @override
  String get clearCacheDialogContent =>
      'Esto eliminará los archivos temporales creados al obtener videos. Las descargas completadas y el historial no se verán afectados. ¿Continuar?';

  @override
  String get noButton => 'No';

  @override
  String get yesButton => 'Sí';

  @override
  String get cacheClearedSnackbar => 'Caché temporal borrada con éxito.';

  @override
  String cacheClearFailedSnackbar(String error) {
    return 'Error al borrar la caché: $error';
  }

  @override
  String get clearStorageTitle => 'Borrar almacenamiento';

  @override
  String get clearStorageSubtitle =>
      'Elimina permanentemente todos los videos descargados y borra el historial.';

  @override
  String get clearStorageDialogTitle => 'Borrar almacenamiento';

  @override
  String get clearStorageDialogContent =>
      'Esto eliminará permanentemente TODOS los archivos descargados y todo el historial. No se puede deshacer. ¿Seguro?';

  @override
  String get storageClearedSnackbar =>
      'Se han eliminado todos los archivos e historial de descargas.';

  @override
  String storageClearFailedSnackbar(String error) {
    return 'Error al borrar el almacenamiento: $error';
  }
}
