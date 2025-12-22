// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Gestor de Proyectos DAW';

  @override
  String get projectDetails => 'Detalles del Proyecto';

  @override
  String get back => 'Volver';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get launch => 'Abrir';

  @override
  String get view => 'Ver';

  @override
  String get openFolder => 'Abrir Carpeta';

  @override
  String get openInDaw => 'Lanzar en DAW';

  @override
  String get extract => 'Extraer';

  @override
  String get extracting => 'Extrayendo…';

  @override
  String get extractingMetadata => 'Extrayendo metadatos...';

  @override
  String get deepScan => 'Escaneo Profundo';

  @override
  String get rescan => 'Reescanear';

  @override
  String get scanning => 'Escaneando…';

  @override
  String get projectName => 'Nombre del Proyecto';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tonalidad (ej: C#m, F mayor)';

  @override
  String get notes => 'Notas';

  @override
  String get projectPhase => 'Fase del Proyecto';

  @override
  String get failedToLoad => 'Error al cargar';

  @override
  String get fileMissing => 'Archivo faltante.';

  @override
  String launchingProject(String projectName) {
    return 'Abriendo $projectName…';
  }

  @override
  String get clearLibrary => 'Limpiar Biblioteca';

  @override
  String get clearLibraryMessage =>
      'Esto eliminará todos los proyectos guardados y carpetas de origen. ¿Continuar?';

  @override
  String get clear => 'Limpiar';

  @override
  String get roots => 'Carpetas de Proyectos';

  @override
  String get projects => 'Proyectos';

  @override
  String get hidden => 'ocultos';

  @override
  String get profileManager => 'Administrador de Perfiles';

  @override
  String get createNewProfile => 'Crear Nuevo Perfil';

  @override
  String get profileName => 'Nombre del Perfil';

  @override
  String get create => 'Crear';

  @override
  String get profiles => 'Perfiles';

  @override
  String get active => 'Activo';

  @override
  String get switchProfile => 'Cambiar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get addFolder => 'Agregar Carpeta';

  @override
  String get searchProjects => 'Buscar proyectos...';

  @override
  String get deepScanTooltip =>
      'El Escaneo Profundo extrae metadatos completos de los archivos de proyecto:\n• BPM (Pulsos Por Minuto)\n• Tonalidad Musical\n• Versión del DAW\nEsto es más lento pero proporciona información completa.';

  @override
  String get deepScanConfirm =>
      'Esto escaneará todos los proyectos y extraerá metadatos completos (BPM, Tonalidad, Versión del DAW). Esto puede tardar un tiempo. ¿Continuar?';

  @override
  String get metadataExtractedSuccessfully =>
      'Metadatos extraídos exitosamente';

  @override
  String failedToExtractMetadata(String error) {
    return 'Error al extraer metadatos: $error';
  }

  @override
  String get saved => 'Guardado';

  @override
  String get failedToLaunchDaw => 'Error al abrir DAW';

  @override
  String get releaseDetails => 'Detalles del Lanzamiento';

  @override
  String get releaseNotFound => 'Lanzamiento No Encontrado';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Cargando...';

  @override
  String get deleteProfile => 'Eliminar Perfil';

  @override
  String deleteProfileMessage(String profileName) {
    return '¿Está seguro de que desea eliminar \"$profileName\"? Esto eliminará todos los proyectos, carpetas de proyectos y lanzamientos de este perfil.';
  }

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get changePhoto => 'Cambiar Foto';

  @override
  String get remove => 'Eliminar';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return '¿Está seguro de que desea eliminar \"$trackName\" de este lanzamiento?';
  }

  @override
  String get saveName => 'Guardar Nombre';

  @override
  String get profilePhotoUpdated => 'Foto de perfil actualizada.';

  @override
  String get profilePhotoRemoved => 'Foto de perfil eliminada.';

  @override
  String profileRenamed(String newName) {
    return 'Perfil renombrado a \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Perfil \"$name\" creado exitosamente';
  }

  @override
  String profileDeleted(String name) {
    return 'Perfil \"$name\" eliminado';
  }

  @override
  String get pleaseEnterProfileName => 'Por favor, ingrese un nombre de perfil';

  @override
  String failedToCreateProfile(String error) {
    return 'Error al crear perfil: $error';
  }

  @override
  String get noProfilesFound => 'No se encontraron perfiles. Cree uno arriba.';

  @override
  String get clearLibraryTooltip =>
      'Limpiar Biblioteca (proyectos y carpetas de proyectos)';

  @override
  String lastModified(String date) {
    return 'Última modificación: $date';
  }

  @override
  String get name => 'Nombre';

  @override
  String get status => 'Estado';

  @override
  String get phase => 'Fase';

  @override
  String get filterByPhase => 'Filtrar por Fase';

  @override
  String get allPhases => 'Todas las Fases';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Última Modificación';

  @override
  String get actions => 'Acciones';

  @override
  String get hide => 'Ocultar';

  @override
  String get unhide => 'Mostrar';

  @override
  String get extractMetadata => 'Extraer Metadatos';

  @override
  String get createRelease => 'Crear Lanzamiento';

  @override
  String get clearSelection => 'Limpiar Selección';

  @override
  String get selectAllProjects => 'Seleccionar todos los proyectos';

  @override
  String get switchingProfiles => 'Cambiando perfiles...';

  @override
  String get scanningProjects => 'Escaneando proyectos...';

  @override
  String get projectsTab => 'Proyectos';

  @override
  String get releasesTab => 'Lanzamientos';

  @override
  String get showHidden => 'Mostrar Ocultos';

  @override
  String get showAll => 'Mostrar Todos';

  @override
  String get showOnlyHidden => 'Mostrar Solo Ocultos';

  @override
  String get deleteRootPath => 'Eliminar Ruta Raíz';

  @override
  String deleteRootPathMessage(String path) {
    return '¿Está seguro de que desea eliminar \"$path\"? Esto también eliminará todos los proyectos de esta carpeta que no están en lanzamientos.';
  }

  @override
  String rootsCount(int count) {
    return 'Carpetas de Proyectos: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Proyectos: $count';
  }

  @override
  String get hiddenOnly => '(solo ocultos)';

  @override
  String hiddenCount(int count) {
    return '($count ocultos)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count proyecto$plural oculto$plural.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count proyecto$plural mostrado$plural.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Error al ocultar proyectos: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Error al mostrar proyectos: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return '¿Está seguro de que desea ocultar \"$projectName\"?';
  }

  @override
  String releaseCreated(String title) {
    return 'Lanzamiento \"$title\" creado exitosamente.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Error al crear lanzamiento: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Error al agregar carpeta: $error';
  }

  @override
  String get noProjectsFoundInRoots =>
      'No se encontraron proyectos en las carpetas de proyectos seleccionadas.';

  @override
  String get selectProjectsFolder => 'Seleccione una carpeta de proyectos';

  @override
  String get enterReleaseTitle => 'Ingrese el Título del Lanzamiento';

  @override
  String get releaseTitle => 'Título del Lanzamiento';

  @override
  String get enterReleaseTitleHint => 'Ingrese el título del lanzamiento';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Metadatos extraídos para $count proyecto$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count falló$plural.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Error al escribir archivo BPM: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Error al escribir archivo de tonalidad: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Error al abrir: $error';
  }

  @override
  String get libraryCleared => 'Biblioteca limpiada.';

  @override
  String scanType(String type) {
    return 'Escaneo $type';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type completado: $count proyecto$plural agregado$plural/actualizado$plural.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count proyecto$plural seleccionado$plural';
  }

  @override
  String openingFolder(String projectName) {
    return 'Abriendo carpeta para $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Error al abrir carpeta: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Sistema operativo no compatible para abrir carpeta.';

  @override
  String get noProjectsAvailable =>
      'No hay proyectos disponibles. Por favor, agregue proyectos primero.';

  @override
  String get createNewRelease => 'Crear Nuevo Lanzamiento';

  @override
  String get deleteRelease => 'Eliminar Lanzamiento';

  @override
  String deleteReleaseMessage(String title) {
    return '¿Está seguro de que desea eliminar \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Lanzamiento \"$title\" eliminado.';
  }

  @override
  String get selectTracks => 'Seleccionar Pistas';

  @override
  String get continueButton => 'Continuar';

  @override
  String get noReleasesYet => 'Aún no hay lanzamientos';

  @override
  String get createFirstRelease =>
      'Cree su primer lanzamiento seleccionando pistas de sus proyectos';

  @override
  String releasesCount(int count) {
    return 'Lanzamientos ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Error al cargar lanzamientos: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Pistas ($count)';
  }

  @override
  String get addTracks => 'Agregar Pistas';

  @override
  String get allProjectsAlreadyInRelease =>
      'Todos los proyectos ya están en este lanzamiento.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Agregada$plural $count pista$plural al lanzamiento.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Archivos del Lanzamiento ($count)';
  }

  @override
  String get addFiles => 'Agregar Archivos';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Agregado$plural $count archivo$plural al lanzamiento.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Error al agregar archivos: $error';
  }

  @override
  String get noFilesToDownload => 'No hay archivos para descargar.';

  @override
  String zipFileSaved(String path) {
    return 'Archivo ZIP guardado en: $path';
  }

  @override
  String get creatingZipFile => 'Creando archivo ZIP...';

  @override
  String failedToCreateZip(String error) {
    return 'Error al crear ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'El archivo seleccionado no existe.';

  @override
  String get imageSavedSuccessfully => '¡Imagen guardada exitosamente!';

  @override
  String failedToSaveImage(String error) {
    return 'Error al guardar imagen: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Error al cargar lanzamiento: $error';
  }

  @override
  String errorLoadingProjects(String error) {
    return 'Error al cargar proyectos: $error';
  }

  @override
  String get releaseSaved => 'Lanzamiento guardado.';

  @override
  String get releaseDate => 'Fecha del Lanzamiento';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Error al guardar fecha del lanzamiento: $error';
  }

  @override
  String get releaseDateSaved => 'Fecha del lanzamiento guardada.';

  @override
  String get releaseDateCleared => 'Fecha del lanzamiento limpiada.';

  @override
  String get saveReleaseFilesZip => 'Guardar archivos ZIP del lanzamiento';

  @override
  String failedToOpenFile(String error) {
    return 'Error al abrir archivo: $error';
  }

  @override
  String failedToPlayAudio(String error) {
    return 'Error al reproducir audio: $error';
  }

  @override
  String get renameFile => 'Renombrar Archivo';

  @override
  String get selectTracksToAdd => 'Seleccionar Pistas para Agregar';

  @override
  String get fileNameUpdated => 'Nombre del archivo actualizado.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Error al actualizar nombre del archivo: $error';
  }

  @override
  String get deleteFile => 'Eliminar Archivo';

  @override
  String deleteFileMessage(String fileName) {
    return '¿Está seguro de que desea eliminar \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'Archivo \"$fileName\" eliminado.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Error al eliminar archivo: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'No se pudo abrir la carpeta: $error';
  }

  @override
  String get artwork => 'Arte';

  @override
  String get title => 'Título';

  @override
  String get tracks => 'Pistas';

  @override
  String get description => 'Descripción';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Seleccionar pistas para incluir en el lanzamiento ($count seleccionada$plural)';
  }

  @override
  String get searchTracks => 'Buscar pistas';

  @override
  String get searchTracksHint => 'Buscar por nombre o tipo de DAW';

  @override
  String get noTracksFound => 'No se encontraron pistas';

  @override
  String get unknown => 'Desconocido';

  @override
  String get fileNotFound => 'Archivo no encontrado';

  @override
  String get fileName => 'Nombre del Archivo';

  @override
  String get editTodo => 'Editar Tarea';

  @override
  String get todoText => 'Texto de la tarea';

  @override
  String get enterTodoText => 'Ingrese el texto de la tarea';

  @override
  String get addNewTodo => 'Agregar nueva tarea';

  @override
  String get enterTodoItem => 'Ingrese el item de la tarea';

  @override
  String get todoList => 'Lista de Tareas';

  @override
  String get addToRelease => 'Agregar al Lanzamiento';

  @override
  String get createNew => 'Crear Nuevo';

  @override
  String get addToExisting => 'Agregar al Existente';

  @override
  String get createAndAdd => 'Crear y Agregar';

  @override
  String get selectRelease => 'Seleccione un lanzamiento';

  @override
  String get noExistingReleasesFound =>
      'No se encontraron lanzamientos existentes.';

  @override
  String get addToSelectedRelease => 'Agregar al Lanzamiento Seleccionado';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Error al guardar foto de perfil: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Error al eliminar foto de perfil: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Error al renombrar perfil: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Error al eliminar perfil: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Error al cargar perfiles: $error';
  }

  @override
  String get projectPhaseIdea => 'Idea';

  @override
  String get projectPhaseArranging => 'Arreglo';

  @override
  String get projectPhaseMixing => 'Mezcla';

  @override
  String get projectPhaseMastering => 'Masterización';

  @override
  String get projectPhaseFinished => 'Finalizado';

  @override
  String get changeStatus => 'Cambiar Fase';

  @override
  String get selectNewStatus => 'Seleccione la nueva fase:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Fase cambiada a \"$status\" para $count proyecto$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Fase cambiada a \"$status\" para $successCount proyecto$successPlural, $failCount falló$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Error al cambiar fase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Editar nombre del perfil';

  @override
  String get tooltipAddTodo => 'Agregar tarea';

  @override
  String get tooltipClearDate => 'Limpiar fecha';

  @override
  String get tooltipPickDate => 'Elegir fecha';

  @override
  String get tooltipViewDetails => 'Ver Detalles';

  @override
  String get tooltipLaunchInDaw => 'Abrir en DAW';

  @override
  String get tooltipRemoveFromRelease => 'Eliminar del Lanzamiento';

  @override
  String get profile => 'Perfil';

  @override
  String get noDateSet => 'No se ha establecido fecha';

  @override
  String get imageNotFound => 'Imagen no encontrada';

  @override
  String get clickToBrowseArtwork => 'Haga clic para buscar arte';

  @override
  String get noFilesAddedYet =>
      'No se han agregado archivos todavía.\nHaga clic en \"Agregar Archivos\" para subir archivos del lanzamiento.';

  @override
  String get noTodosYet => 'No hay tareas todavía. Agregue una arriba.';

  @override
  String get done => 'Hecho';

  @override
  String get backupAndRestore => 'Respaldo y Restauración';

  @override
  String get exportBackup => 'Exportar Respaldo';

  @override
  String get importBackup => 'Importar Respaldo';

  @override
  String get backupExportedSuccessfully => 'Respaldo exportado exitosamente';

  @override
  String failedToExportBackup(String error) {
    return 'Error al exportar respaldo: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Respaldo importado exitosamente: $projectsCount proyectos, $rootsCount carpetas de proyectos, $releasesCount lanzamientos';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Error al importar respaldo: $error';
  }

  @override
  String get importBackupMessage => 'Elija cómo importar el respaldo:';

  @override
  String get mergeWithCurrentProfile => 'Combinar con el perfil activo actual';

  @override
  String get replaceCurrentProfile =>
      'Reemplazar completamente el perfil actual (ADVERTENCIA: Esto eliminará todos los datos del perfil actual)';

  @override
  String get createNewProfileForImport =>
      'Crear un nuevo perfil para estos datos';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Respaldo importado al nuevo perfil \"$profileName\": $projectsCount proyectos, $rootsCount carpetas de proyectos, $releasesCount lanzamientos';
  }

  @override
  String get noProfileSelected => 'No hay perfil seleccionado';

  @override
  String get exportBackupDialogTitle => 'Exportar Respaldo';

  @override
  String get importBackupDialogTitle => 'Importar Respaldo';

  @override
  String get invalidBackupFileFormat =>
      'Formato de archivo de respaldo inválido: falta la versión';

  @override
  String get profileNameRequiredForNewProfile =>
      'El nombre del perfil es obligatorio al crear un nuevo perfil';

  @override
  String get currentProfileRequired =>
      'El perfil actual es obligatorio para el modo combinar o reemplazar';
}
