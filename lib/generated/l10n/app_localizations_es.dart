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
  String get enable => 'Habilitar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get undo => 'Deshacer';

  @override
  String get customInterval => 'Personalizado';

  @override
  String get close => 'Cerrar';

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
  String get refreshProject => 'Actualizar';

  @override
  String get scanning => 'Escaneando…';

  @override
  String get newProjectBadge => 'NUEVO';

  @override
  String get projectName => 'Nombre del Proyecto';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tonalidad (ej: C#m, F mayor)';

  @override
  String get notes => 'Notas';

  @override
  String get expandNotes => 'Expandir';

  @override
  String get collapseNotes => 'Contraer';

  @override
  String get projectNotesFromDaw => 'Notas del Proyecto (del archivo DAW)';

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
  String failedToLaunchProject(String projectName) {
    return 'Error al abrir $projectName';
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
  String get pathsSettingsDangerZoneTitle => 'Biblioteca';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Borra todos los proyectos y carpetas de proyectos del perfil actual.';

  @override
  String get projectFoldersSectionTitle => 'Carpetas de proyectos';

  @override
  String get projectFoldersSectionSubtitle =>
      'Carpetas que se escanearán para encontrar proyectos de DAW.';

  @override
  String get projectFoldersEmptyTitle => 'Aún no hay carpetas de proyectos';

  @override
  String get projectFoldersEmptySubtitle =>
      'Agrega al menos una carpeta para comenzar a escanear proyectos.';

  @override
  String get notScannedYet => 'Aún no escaneado';

  @override
  String lastScan(String date) {
    return 'Último escaneo: $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Carpetas excluidas';

  @override
  String get excludedFoldersSectionSubtitle =>
      'Estas carpetas se omitirán durante el escaneo, incluso si están dentro de una carpeta de proyectos.';

  @override
  String get addExcludedFolder => 'Agregar excluida';

  @override
  String get selectExcludedFolder => 'Selecciona una carpeta para excluir';

  @override
  String get excludedFoldersEmptyTitle => 'No hay carpetas excluidas';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Opcional: agrega carpetas que nunca quieras escanear.';

  @override
  String get removeExcludedFolderTitle => '¿Quitar carpeta excluida?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'Esta carpeta ya no será excluida:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'Esta carpeta ya no será excluida.';

  @override
  String get desktopOnlyPathsSettings =>
      'Esta página está disponible solo en la app de escritorio.';

  @override
  String get renameProjectFolderTitle => 'Nombre para Mostrar';

  @override
  String get flatpakPortalPathExplanation =>
      'Esta ruta es una ubicación en espacio aislado (sandbox), no la ubicación real de la carpeta — Flatpak no comparte esa información con la app. Usa el nombre de arriba para identificarla.';

  @override
  String get removeProjectFolderTitle => '¿Quitar carpeta de proyectos?';

  @override
  String removeProjectFolderMessage(String path) {
    return '¿Estás seguro de que quieres quitar \"$path\"? Esto también eliminará todos los proyectos de esta carpeta que no estén en lanzamientos.';
  }

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
  String get searchReleases => 'Buscar lanzamientos...';

  @override
  String get searchPlaylists => 'Buscar listas de reproducción...';

  @override
  String get noReleasesFound => 'No se encontraron lanzamientos';

  @override
  String get noPlaylistsFound => 'No se encontraron listas de reproducción';

  @override
  String get tryDifferentSearch =>
      'Intenta con un término de búsqueda diferente';

  @override
  String get deepScanConfirm =>
      'El Escaneo Profundo extrae metadatos completos de los archivos de proyecto:\n• BPM (Pulsos Por Minuto)\n• Tonalidad Musical\n• Versión del DAW\n• Notas del Proyecto (donde sea compatible)\n\nEsto es más lento que un escaneo regular y puede tardar un tiempo. ¿Continuar?';

  @override
  String get deepScanViewSupportedDaws => 'Ver DAWs y campos admitidos';

  @override
  String get deepScanOnlyUnscanned => 'Solo escanear proyectos sin metadatos';

  @override
  String get metadataExtractionTitle => 'Extracción de Metadatos';

  @override
  String get metadataExtractionSubtitle => 'Vea qué datos admite cada DAW';

  @override
  String get metadataExtractionIntro =>
      'El Escaneo Profundo puede leer automáticamente algunos de estos campos directamente desde un archivo de proyecto — el resto debe introducirse manualmente. Esta tabla muestra qué es automático hoy para cada DAW compatible.';

  @override
  String get metadataFieldKey => 'Tonalidad';

  @override
  String get metadataFieldVersion => 'Versión de DAW';

  @override
  String get metadataExtractionManualNote =>
      'Cualquier campo sin soporte automático se puede introducir manualmente en el Detalle del Proyecto. Para BPM y Tonalidad en particular, colocar un archivo bpm.txt o key.txt junto al proyecto también se detecta en el siguiente escaneo.';

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
  String get filters => 'Filtros';

  @override
  String get allPhases => 'Todas las Fases';

  @override
  String get filterByDaw => 'Filtrar por DAW';

  @override
  String get allDaws => 'Todos los DAW';

  @override
  String get daw => 'DAW';

  @override
  String get clearDaw => 'Borrar DAW';

  @override
  String get filterByKey => 'Filtrar por Tonalidad';

  @override
  String get allKeys => 'Todas las Tonalidades';

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
  String scanProgressLabel(int current, int total) {
    return 'Cargando proyecto $current de $total…';
  }

  @override
  String get search => 'Buscar';

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
  String get deleteRootPath => 'Quitar carpeta de proyectos';

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
  String get deleteMissingProjects => 'Eliminar faltantes';

  @override
  String get deleteMissingProjectsTitle => '¿Eliminar proyectos faltantes?';

  @override
  String deleteMissingProjectsConfirm(int count, String plural) {
    return '$count proyecto$plural cuyo archivo no se pudo encontrar en esta máquina se eliminarán permanentemente, junto con todas las notas, plazos e historial de sesiones. Esto no se puede deshacer.';
  }

  @override
  String get deleteMissingProjectsConfirmButton => 'Eliminar permanentemente';

  @override
  String missingProjectsDeleted(int count, String plural) {
    return '$count proyecto$plural faltante eliminado.';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(
    int count,
    String plural,
  ) {
    return 'Eliminar también $count proyecto$plural que forman parte de un lanzamiento (también los elimina de ese lanzamiento)';
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
  String get folderAlreadyAdded => 'Esta carpeta ya ha sido añadida.';

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
  String get scanCancelled => 'Escaneo cancelado.';

  @override
  String scanFailuresSnackbar(int count, String plural) {
    return '$count proyecto$plural no se pudo/pudieron cargar.';
  }

  @override
  String get scanFailuresSnackbarAction => 'Detalles';

  @override
  String get scanFailuresDialogTitle => 'Errores de Escaneo';

  @override
  String get scanFailuresDialogIntro =>
      'Estos archivos no se pudieron leer durante el escaneo (es posible que se hayan eliminado, movido o estén bloqueados por otro programa):';

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
  String releasesSelected(int count, String plural) {
    return '$count lanzamiento$plural seleccionado$plural';
  }

  @override
  String get deleteSelectedReleases => 'Eliminar selección';

  @override
  String deleteSelectedReleasesConfirm(int count, String plural) {
    return '¿Seguro que quieres eliminar $count lanzamiento$plural?';
  }

  @override
  String releasesDeleted(int count, String plural) {
    return '$count lanzamiento$plural eliminado$plural';
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
  String get errorLoadingProjects => 'Error al cargar proyectos: null';

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
  String get failedToOpenFile => 'Error al abrir archivo';

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
  String addTodoAtTimestamp(String timestamp) {
    return 'Añadir tarea en $timestamp';
  }

  @override
  String todoAddedAtTimestamp(String timestamp) {
    return 'Tarea añadida en $timestamp';
  }

  @override
  String get todoList => 'Lista de Tareas';

  @override
  String get todoTemplates => 'Plantillas de TODO';

  @override
  String get createTemplate => 'Crear Plantilla';

  @override
  String get editTemplate => 'Editar Plantilla';

  @override
  String get deleteTemplate => 'Eliminar Plantilla';

  @override
  String deleteTemplateConfirm(String name) {
    return '¿Estás seguro de eliminar la plantilla \"$name\"?';
  }

  @override
  String get templateName => 'Nombre de la Plantilla';

  @override
  String get templateNameHint => 'ej. Lista de Mezcla';

  @override
  String get templateItems => 'Elementos de la Plantilla';

  @override
  String get templateItemsHint => 'Un elemento por línea';

  @override
  String get templateNameAndItemsRequired =>
      'El nombre y los elementos son obligatorios';

  @override
  String get templateItemsRequired => 'Se requiere al menos un elemento';

  @override
  String get templateCreated => 'Plantilla creada';

  @override
  String get templateUpdated => 'Plantilla actualizada';

  @override
  String get templateDeleted => 'Plantilla eliminada';

  @override
  String get noTemplatesYet => 'Aún no hay plantillas';

  @override
  String get createFirstTemplate => 'Crea tu primera plantilla TODO';

  @override
  String templateItemCount(int count) {
    return '$count elemento(s)';
  }

  @override
  String get selectTemplate => 'Seleccionar Plantilla';

  @override
  String get importFromTemplate => 'Importar desde Plantilla';

  @override
  String get manageTemplates => 'Gestionar Plantillas';

  @override
  String get noTemplatesAvailable =>
      'No hay plantillas disponibles. Crea una primero.';

  @override
  String templateImported(String name, int count) {
    return 'Plantilla \"$name\" importada ($count elementos)';
  }

  @override
  String get errorLoadingTemplates => 'Error al cargar plantillas';

  @override
  String get createProjectStartFrom => '¿Cómo quieres empezar?';

  @override
  String get createProjectStartFromHint =>
      'Empieza desde una carpeta vacía o copia una plantilla registrada.';

  @override
  String get createProjectEmptyFolder => 'Carpeta Vacía';

  @override
  String get createProjectFromTemplate => 'Desde Plantilla';

  @override
  String get selectTemplateMainFile =>
      'Selecciona el Archivo Principal de la Plantilla';

  @override
  String get registerTemplate => 'Registrar Plantilla';

  @override
  String get projectTemplates => 'Plantillas de Proyecto';

  @override
  String get searchTemplates => 'Buscar plantillas...';

  @override
  String get createFirstProjectTemplate =>
      'Registra una carpeta de plantilla para reutilizar en nuevos proyectos';

  @override
  String get noMatchingTemplates => 'No hay plantillas coincidentes';

  @override
  String get templateSourceMissing =>
      'Carpeta de origen de la plantilla no encontrada';

  @override
  String get useTemplate => 'Usar';

  @override
  String get selectTemplatesParentFolder =>
      'Selecciona la Carpeta Principal de Plantillas';

  @override
  String get templateSourceFolder => 'Carpeta de Origen';

  @override
  String get dateCreatedColumn => 'Creado';

  @override
  String get dateModifiedColumn => 'Modificado';

  @override
  String get manageTemplateFolders => 'Gestionar Carpetas';

  @override
  String get addTemplateFolder => 'Añadir Carpeta';

  @override
  String get removeTemplateFolder => 'Eliminar Carpeta de Plantillas';

  @override
  String removeTemplateFolderConfirm(String path) {
    return '¿Eliminar \"$path\" de tus carpetas de plantillas registradas? Las plantillas ya importadas no se eliminarán.';
  }

  @override
  String get noTemplateFoldersRegistered =>
      'No hay carpetas de plantillas registradas';

  @override
  String get refreshTemplateFolders =>
      'Actualizar plantillas desde las carpetas registradas';

  @override
  String lastRefreshed(String date) {
    return 'Última actualización $date';
  }

  @override
  String templatesRefreshedSummary(int count) {
    return '$count plantilla(s) nueva(s) añadida(s)';
  }

  @override
  String templatesSelected(int count, String plural) {
    return '$count plantilla$plural seleccionada$plural';
  }

  @override
  String get deleteSelectedTemplates => 'Eliminar selección';

  @override
  String deleteSelectedTemplatesConfirm(int count, String plural) {
    return '¿Seguro que quieres eliminar $count plantilla$plural?';
  }

  @override
  String templatesDeleted(int count, String plural) {
    return '$count plantilla$plural eliminada$plural';
  }

  @override
  String get templateDetailTitle => 'Template';

  @override
  String get templateNotFound => 'Plantilla no encontrada';

  @override
  String get saveAsTemplate => 'Guardar como Plantilla';

  @override
  String get newTemplateNameLabel => 'Nombre de la plantilla';

  @override
  String get savedAsTemplate => 'Guardado como plantilla';

  @override
  String get duplicateTemplate => 'Duplicar';

  @override
  String get templateDuplicated => 'Plantilla duplicada';

  @override
  String get fileInfo => 'Información del Archivo';

  @override
  String get fileSize => 'Tamaño del Archivo';

  @override
  String get filePath => 'Ruta';

  @override
  String get fileModified => 'Última Modificación';

  @override
  String projectsFromThisTemplate(int count) {
    return 'Proyectos Creados a Partir de esta Plantilla ($count)';
  }

  @override
  String get noProjectsFromThisTemplate =>
      'Aún no se han creado proyectos a partir de esta plantilla';

  @override
  String get importTodos => 'Importar Tareas desde Archivo';

  @override
  String get noTodosInFile => 'No se encontraron tareas en el archivo';

  @override
  String todosImported(int count) {
    return '$count tarea(s) importada(s) exitosamente';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Error al importar tareas: $error';
  }

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
  String get dropImageHere => 'Suelta la imagen aquí';

  @override
  String get removeArtwork => 'Eliminar arte';

  @override
  String get removeArtworkConfirm =>
      '¿Eliminar este arte? El archivo de imagen se eliminará.';

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
  String get backupTabLabel => 'Respaldo';

  @override
  String get aboutTabLabel => 'Acerca de';

  @override
  String get localBackup => 'Respaldo Local';

  @override
  String get appearanceTabLabel => 'Apariencia';

  @override
  String get exportBackup => 'Exportar Respaldo';

  @override
  String get importBackup => 'Importar Respaldo';

  @override
  String get exportProjectInfo => 'Exportar información';

  @override
  String get exportProjectInfoTooltip =>
      'Guardar la información de este proyecto en un archivo de texto';

  @override
  String get exportAllProjectsInfo => 'Exportar todos los proyectos a TXT';

  @override
  String get exportAllProjectsInfoSubtitle =>
      'Guarda un registro de texto con la información de todos los proyectos, para conservarla aunque elimines el archivo del DAW';

  @override
  String get projectInfoExported => 'Información del proyecto exportada';

  @override
  String allProjectsInfoExported(int count) {
    return 'Información exportada de $count proyectos';
  }

  @override
  String failedToExportProjectInfo(String error) {
    return 'Error al exportar la información del proyecto: $error';
  }

  @override
  String get projectExportHeaderTitle => 'DAW PROJECT MANAGER — PROJECT EXPORT';

  @override
  String projectExportExportedLabel(String dateTime) {
    return 'Exportado: $dateTime';
  }

  @override
  String projectExportTotalProjectsLabel(int count) {
    return 'Total de proyectos: $count';
  }

  @override
  String projectExportProjectLabel(String name) {
    return 'Proyecto: $name';
  }

  @override
  String projectExportDawLabel(String dawType) {
    return 'DAW: $dawType';
  }

  @override
  String projectExportDawWithVersionLabel(String dawType, String version) {
    return 'DAW: $dawType $version';
  }

  @override
  String projectExportStatusLabel(String status) {
    return 'Estado: $status';
  }

  @override
  String projectExportBpmLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String projectExportKeyLabel(String key) {
    return 'Tonalidad: $key';
  }

  @override
  String projectExportKeyWithCamelotLabel(String key, String code) {
    return 'Tonalidad: $key (Camelot $code)';
  }

  @override
  String projectExportFilePathLabel(String path) {
    return 'Ruta del archivo: $path';
  }

  @override
  String projectExportFileSizeLabel(String size) {
    return 'Tamaño del archivo: $size';
  }

  @override
  String projectExportFileCreatedLabel(String date) {
    return 'Archivo creado: $date';
  }

  @override
  String projectExportAddedToLibraryLabel(String date) {
    return 'Añadido a la biblioteca: $date';
  }

  @override
  String projectExportLastModifiedLabel(String date) {
    return 'Última modificación: $date';
  }

  @override
  String projectExportDeadlineLabel(String date) {
    return 'Fecha límite: $date';
  }

  @override
  String projectExportDeadlineWithStatusLabel(String date, String status) {
    return 'Fecha límite: $date ($status)';
  }

  @override
  String projectExportTotalTimeWorkedLabel(String duration) {
    return 'Tiempo total trabajado: $duration';
  }

  @override
  String get projectExportNotesLabel => 'Notas:';

  @override
  String get projectExportTodosLabel => 'Tareas:';

  @override
  String projectExportWorkSessionsLabel(int count) {
    return 'Sesiones de trabajo ($count):';
  }

  @override
  String get noProjectsToExport => 'No hay proyectos para exportar';

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

  @override
  String get previewSong => 'Canción de Vista Previa';

  @override
  String get noPreviewSongTitle => 'Sin canción de vista previa';

  @override
  String get noPreviewSongMessage =>
      'Este proyecto no tiene una canción de vista previa configurada. Selecciona un archivo de audio para cargarlo y reproducirlo.';

  @override
  String get noPreviewSongDragHint =>
      'También puedes arrastrar y soltar un archivo de audio directamente en la fila del proyecto en la tabla.';

  @override
  String get previewSongRemoved => 'Canción de vista previa eliminada';

  @override
  String get previewSongAdded => 'Canción de vista previa agregada';

  @override
  String get previewSongFileNotFound =>
      'Archivo de canción de vista previa no encontrado';

  @override
  String get previewSongFileNotFoundMessage =>
      'No se encontró el archivo de canción de vista previa en el disco. ¿Desea seleccionar un nuevo archivo o eliminar la entrada?';

  @override
  String get selectNewFile => 'Seleccionar nuevo archivo';

  @override
  String failedToPlayPreview(String error) {
    return 'Error al reproducir vista previa: $error';
  }

  @override
  String get removePreviewSong => 'Eliminar canción de vista previa';

  @override
  String get removePreviewSongConfirm =>
      '¿Está seguro de que desea eliminar la canción de vista previa? Esta acción no se puede deshacer.';

  @override
  String get noPreviewSongSelected =>
      'No se ha seleccionado ninguna canción de vista previa';

  @override
  String get changePreviewSong => 'Cambiar Canción de Vista Previa';

  @override
  String get selectPreviewSong => 'Seleccionar Canción de Vista Previa';

  @override
  String get dropAudioFileHere => 'Suelte el archivo de audio aquí';

  @override
  String projectAge(String age) {
    return 'Antigüedad del proyecto: $age';
  }

  @override
  String createdDate(String date) {
    return 'creado $date';
  }

  @override
  String completedIn(String duration) {
    return 'Completado en: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'finalizado $date';
  }

  @override
  String get dateToday => 'hoy';

  @override
  String get dateYesterday => 'ayer';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count semanas',
      one: 'hace 1 semana',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count meses',
      one: 'hace 1 mes',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count años',
      one: 'hace 1 año',
    );
    return '$_temp0';
  }

  @override
  String ageYearsMonths(
    int years,
    String yearPlural,
    int months,
    String monthPlural,
  ) {
    return '$years año$yearPlural, $months meses';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years año$plural';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months meses, $days día$dayPlural';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months meses';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days día$plural';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours hora$plural';
  }

  @override
  String get ageJustNow => 'Ahora mismo';

  @override
  String get ageLessThanHour => 'Menos de una hora';

  @override
  String get viewProfile => 'Ver Perfil';

  @override
  String get googleDriveSync => 'Sincronización de Google Drive';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Sincroniza tus datos con Google Drive para hacer copias de seguridad y restaurar entre dispositivos.';

  @override
  String get manageGoogleDriveSync =>
      'Gestionar Sincronización de Google Drive';

  @override
  String get signInToGoogleDrive => 'Iniciar sesión en Google Drive';

  @override
  String get syncNow => 'Sincronizar Ahora';

  @override
  String get uploadBackup => 'Subir Copia de Seguridad';

  @override
  String get downloadBackup => 'Descargar Copia de Seguridad';

  @override
  String get newerBackupAvailable =>
      'Nueva copia de seguridad disponible en la nube';

  @override
  String get restoreProjectFromDrive => 'Restaurar desde Drive';

  @override
  String get restoringProjectFromDrive => 'Restaurando desde Drive...';

  @override
  String get projectRestoredFromDrive => 'Proyecto restaurado desde Drive';

  @override
  String get projectNotFoundInBackup =>
      'Este proyecto no se encontró en la copia de seguridad de Drive';

  @override
  String get signInToGoogleDriveFirst =>
      'Por favor, inicia sesión en Google Drive primero (abre la configuración de Drive Sync)';

  @override
  String get signOut => 'Cerrar Sesión';

  @override
  String get downloadPreviewSongs => 'Descargar canciones de vista previa';

  @override
  String get downloadPreviewSongsExplanation =>
      'Si está desmarcado, se omitirán las canciones de vista previa (ahorra tiempo y almacenamiento). Puedes descargarlas más tarde si es necesario.';

  @override
  String get replaceLocalData => 'Reemplazar Datos Locales';

  @override
  String get downloadBackupConfirmation =>
      'Esto reemplazará tus datos locales con la copia de seguridad de Google Drive.\n\n¿Estás seguro de que deseas continuar?';

  @override
  String get enterAuthorizationCode => 'Ingresar Código de Autorización';

  @override
  String get authorizationCode => 'Código de Autorización';

  @override
  String get pasteCodeFromBrowser => 'Pega el código del navegador';

  @override
  String get sessionActive => 'Sesión activa';

  @override
  String get signedIn => 'Conectado';

  @override
  String get creatingInitialBackup => 'Creando copia de seguridad inicial...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Inicio de sesión exitoso y copia de seguridad creada en Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      '¡Inicio de sesión exitoso y copia de seguridad creada en Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Inicio de sesión exitoso en Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      '¡Inicio de sesión exitoso en Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Inicio de sesión cancelado o fallido. Consulta la consola para más detalles.';

  @override
  String get failedToLaunchBrowser => 'Error al abrir el navegador';

  @override
  String get signInCancelled => 'Inicio de sesión cancelado';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Error al intercambiar código de autorización';

  @override
  String errorSigningIn(String error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get googleSignInError => 'Error de Inicio de Sesión de Google';

  @override
  String get developerConsoleNotSetUp =>
      'La consola de desarrollador no está configurada correctamente. Por favor, verifica tu configuración OAuth en Google Cloud Console.';

  @override
  String get platformError => 'Error de Plataforma';

  @override
  String get signedOutFromGoogleDrive => 'Sesión cerrada en Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Error al cerrar sesión: $error';
  }

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get errorNoProfileSelected =>
      'Error: No se ha seleccionado ningún perfil';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return '¡Sincronización completada! Proyectos: +$projectsAdded ~$projectsUpdated, Lanzamientos: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Error al sincronizar: $error';
  }

  @override
  String get uploadingBackup => 'Subiendo copia de seguridad...';

  @override
  String get backupUploadedSuccessfully =>
      '¡Copia de seguridad subida con éxito!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      '¡Copia de seguridad subida con éxito a Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Error al subir copia de seguridad: $error';
  }

  @override
  String get downloadingBackup => 'Descargando copia de seguridad...';

  @override
  String get checkingForBackup => 'Verificando copia de seguridad...';

  @override
  String get backupUpToDate => 'La copia de seguridad está actualizada';

  @override
  String errorCheckingBackup(String error) {
    return 'Error al verificar copia de seguridad: $error';
  }

  @override
  String get download => 'Descargar';

  @override
  String get remoteBackupIsNewer =>
      'La copia de seguridad remota es más reciente que los datos locales. Cargar sobrescribirá.';

  @override
  String get confirmUpload => 'Confirmar Carga';

  @override
  String get noBackupFileFound =>
      'No se encontró ningún archivo de copia de seguridad en Google Drive. Crea una copia de seguridad primero sincronizando tus datos.';

  @override
  String get noBackupFileFoundStatus =>
      'No se encontró ningún archivo de copia de seguridad. Crea una copia de seguridad primero.';

  @override
  String get downloadCancelled => 'Descarga cancelada';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return '¡Copia de seguridad descargada! Proyectos: +$projectsAdded ~$projectsUpdated, Lanzamientos: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String backupDownloadedDetailed(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
    int previewSongsDownloaded,
    int previewSongsUpdated,
  ) {
    return '¡Copia de seguridad descargada!\n\nProyectos:\n  • $projectsAdded agregados\n  • $projectsUpdated actualizados\n\nLanzamientos:\n  • $releasesAdded agregados\n  • $releasesUpdated actualizados\n\nPreview Songs:\n  • $previewSongsDownloaded descargadas\n  • $previewSongsUpdated actualizadas';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Error al descargar copia de seguridad: $error';
  }

  @override
  String get notSignedInYet => 'No conectado';

  @override
  String get never => 'Nunca';

  @override
  String signedInAs(String email) {
    return 'Conectado como: $email';
  }

  @override
  String lastSync(String date) {
    return 'Última sincronización: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Copia de seguridad remota: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Última subida: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Última descarga: $date';
  }

  @override
  String get checkForBackup => 'Verificar Copia de Seguridad';

  @override
  String get notificationSettings => 'Configuración de Notificaciones';

  @override
  String get notificationsOnlyOnAndroid =>
      'Las notificaciones de plazos solo están disponibles en dispositivos Android.';

  @override
  String get notificationPermissionRequired =>
      'Permiso de Notificación Requerido';

  @override
  String get notificationPermissionDescription =>
      'Por favor, habilite las notificaciones para recibir recordatorios de plazos.';

  @override
  String get notificationPermissionDenied =>
      'Permiso de notificación denegado. Por favor, habilítelo en la configuración.';

  @override
  String get notificationSettingsSaved =>
      'Configuración de notificaciones guardada exitosamente';

  @override
  String get errorSavingSettings => 'Error al guardar la configuración';

  @override
  String get enableDeadlineNotifications =>
      'Habilitar Notificaciones de Plazos';

  @override
  String get receiveRemindersForDeadlines =>
      'Recibir recordatorios para plazos de proyectos';

  @override
  String get notificationTime => 'Hora de Notificación';

  @override
  String get timeToReceiveNotifications =>
      'Hora del día para recibir notificaciones';

  @override
  String get reminderDays => 'Días de Recordatorio';

  @override
  String get selectDaysBeforeDeadline =>
      'Seleccione cuántos días antes del plazo desea ser notificado';

  @override
  String get notifyOnDeadlineDay => 'Notificar en el Día del Plazo';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'También recibir una notificación en el día del plazo mismo';

  @override
  String get howItWorks => 'Cómo Funciona';

  @override
  String get deadlineNotificationsHelp =>
      'Recibirá notificaciones a la hora especificada en los días seleccionados antes de cada plazo del proyecto. Toque una notificación para abrir los detalles del proyecto.';

  @override
  String get oneDay => '1 día';

  @override
  String xDays(int count) {
    return '$count días';
  }

  @override
  String get settings => 'Configuración';

  @override
  String get searchSettings => 'Buscar en la configuración';

  @override
  String noSettingsFoundFor(String query) {
    return 'No se encontraron ajustes para \"$query\"';
  }

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get languageSettingDescription =>
      'El idioma utilizado en toda la aplicación.';

  @override
  String get themeSettingDescription => 'El tema de color de la aplicación.';

  @override
  String get waveformStyle => 'Estilo de forma de onda';

  @override
  String get waveformStyleSettingDescription =>
      'Cómo se dibuja la forma de onda de la vista previa de audio.';

  @override
  String get waveformStyleDetailed => 'Detallado';

  @override
  String get waveformStyleDetailedDescription =>
      'Barras por píxel con cuerpo sombreado, como en una DAW.';

  @override
  String get waveformStyleClassic => 'Clásico';

  @override
  String get waveformStyleClassicDescription => 'Un único contorno relleno.';

  @override
  String get waveformChannels => 'Canales';

  @override
  String get waveformChannelsSettingDescription =>
      'Si la forma de onda divide el estéreo en dos pistas.';

  @override
  String get waveformChannelsSingle => 'Único';

  @override
  String get waveformChannelsDual => 'Doble';

  @override
  String get waveformChannelsSingleDescription =>
      'Una pista con la mezcla estéreo.';

  @override
  String get waveformChannelsDualDescription =>
      'Izquierda y derecha apiladas en pistas separadas.';

  @override
  String get waveformChannelsUnavailable => 'Este archivo solo tiene un canal';

  @override
  String get support => 'Apoyar';

  @override
  String get shareDiagnosticLog => 'Compartir Registro de Diagnóstico';

  @override
  String get shareDiagnosticLogEmpty => 'Aún no hay registro de diagnóstico';

  @override
  String get shareDiagnosticLogFolderOpened =>
      'Compartir no está disponible aquí. Se abrió la carpeta del registro para que puedas adjuntar el archivo manualmente.';

  @override
  String get enableDiagnosticLogging => 'Activar registro de diagnóstico';

  @override
  String get enableDiagnosticLoggingDescription =>
      'Mantiene un pequeño registro de fallos y errores en este dispositivo, para que puedas compartirlo si algo sale mal. Desactivado de forma predeterminada.';

  @override
  String get clearDiagnosticLog => 'Borrar registro de diagnóstico';

  @override
  String get clearDiagnosticLogConfirmTitle =>
      '¿Borrar registro de diagnóstico?';

  @override
  String get clearDiagnosticLogConfirmMessage =>
      'Esto eliminará permanentemente el archivo de registro de diagnóstico. Esta acción no se puede deshacer.';

  @override
  String get diagnosticLogCleared => 'Registro de diagnóstico borrado';

  @override
  String get supportTheProject => 'Apoya el proyecto';

  @override
  String couldNotOpenBrowser(String url) {
    return 'No se pudo abrir el navegador. Por favor, visite: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Error al abrir el navegador: $error';
  }

  @override
  String get generateTestingDatabase => 'Generar Base de Datos de Prueba';

  @override
  String get generateTestingDatabaseMessage =>
      'Esto creará (o actualizará) un perfil dedicado \"Demo — Screenshots\" lleno de una gran variedad de proyectos, lanzamientos y listas de reproducción de ejemplo para todos los DAW compatibles, y cambiará a él. Tus otros perfiles no se verán afectados. ¿Continuar?';

  @override
  String get testingDatabaseGenerated =>
      '¡Perfil de demostración listo — cambiado a él!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Error al generar base de datos de prueba: $error';
  }

  @override
  String get removeTestingDatabase => 'Eliminar base de datos de prueba';

  @override
  String get removeTestingDatabaseMessage =>
      'Esto eliminará permanentemente el perfil \"Demo — Screenshots\" y todos sus proyectos, lanzamientos, listas de reproducción y archivos de audio de vista previa de ejemplo. ¿Continuar?';

  @override
  String get testingDatabaseRemoved => 'Datos de demostración eliminados.';

  @override
  String get noTestingDatabaseFound =>
      'No se encontraron datos de demostración para eliminar.';

  @override
  String failedToRemoveTestingDatabase(String error) {
    return 'Error al eliminar la base de datos de prueba: $error';
  }

  @override
  String get playlists => 'Listas de Reproducción';

  @override
  String get playlistsDesktopOnly =>
      'Las listas de reproducción solo están disponibles en Android.';

  @override
  String get noPlaylistsYet => 'Aún no hay listas';

  @override
  String get createFirstPlaylist =>
      'Toca el botón + para crear tu primera lista';

  @override
  String playlistSongCount(int count) {
    return '$count canciones';
  }

  @override
  String get createPlaylist => 'Crear Lista';

  @override
  String get playlistName => 'Nombre de la Lista';

  @override
  String get playlistNameHint => 'Mi Lista';

  @override
  String get playlistNameRequired => 'Se requiere nombre de lista';

  @override
  String get editPlaylist => 'Editar Lista';

  @override
  String get stopPlaybackBeforeEditing =>
      'Por favor, detenga la reproducción antes de editar la lista de reproducción';

  @override
  String get selectPreviewSongs => 'Seleccionar Vistas Previas';

  @override
  String get deletePlaylist => 'Eliminar Lista';

  @override
  String deletePlaylistConfirm(String name) {
    return '¿Estás seguro de eliminar \"$name\"?';
  }

  @override
  String get playlistDeleted => 'Lista eliminada';

  @override
  String get errorDeletingPlaylist => 'Error al eliminar la lista';

  @override
  String get playlistUpdated => 'Lista actualizada';

  @override
  String get changeSong => 'Cambiar Canción';

  @override
  String get changeSongConfirm =>
      'Hay una canción reproduciéndose. ¿Desea cambiar a esta canción?';

  @override
  String get changeSongButton => 'Cambiar';

  @override
  String playlistProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String get noPreviewSongsInPlaylist =>
      'No hay canciones de vista previa en esta lista';

  @override
  String get tapEditToAddSongs =>
      'Toca editar para agregar canciones a esta lista de reproducción';

  @override
  String get noProjectsAvailableForPlaylist =>
      'No hay proyectos con canciones de vista previa disponibles para agregar';

  @override
  String get noProjectsInDatabase =>
      'No se encontraron proyectos en la base de datos. Por favor sincronice sus proyectos primero.';

  @override
  String get firstTimeSyncTitle => '¡Parece que es tu primera vez aquí!';

  @override
  String get firstTimeSyncMessage =>
      'Sincronicemos tus datos desde Google Drive para comenzar';

  @override
  String get syncWithGoogleDrive => 'Sincronizar con Google Drive';

  @override
  String get errorLoadingPlaylists => 'Error al cargar listas';

  @override
  String get playlistItems => 'Elementos de la Lista';

  @override
  String get addSongs => 'Añadir Canciones';

  @override
  String get addAudioFiles => 'Añadir Archivos de Audio';

  @override
  String get selectAudioFiles => 'Seleccionar Archivos de Audio';

  @override
  String get selectFromProjects => 'Seleccionar de Proyectos';

  @override
  String get add => 'Añadir';

  @override
  String get addTaskAtTimestamp => 'Añadir tarea en el momento actual';

  @override
  String get taskDescriptionHint => 'Descripción de la tarea';

  @override
  String get taskAdded => 'Tarea añadida';

  @override
  String get fromProject => 'Del Proyecto';

  @override
  String get projectDeadline => 'Fecha Límite del Proyecto';

  @override
  String get noDeadlineSet => 'Sin fecha límite';

  @override
  String get camelotCode => 'Código Camelot';

  @override
  String get deadline => 'Fecha Límite';

  @override
  String get dueToday => 'Vence hoy';

  @override
  String daysLate(int days) {
    return '${days}d atrasado';
  }

  @override
  String daysLeft(int days) {
    return '${days}d restantes';
  }

  @override
  String get hideFinished => 'Ocultar Finalizados';

  @override
  String get showOnlyDeadlines => 'Mostrar plazo';

  @override
  String get filterByDeadline => 'Filtrar por Fecha Límite';

  @override
  String get allDeadlines => 'Todas las Fechas';

  @override
  String get hasDeadline => 'Con Fecha Límite';

  @override
  String get overdue => 'Atrasado';

  @override
  String get dueSoon => 'Próximo a Vencer (7d)';

  @override
  String get today => 'Hoy';

  @override
  String get noPreviewSong => 'Sin vista previa';

  @override
  String get playPreview => 'Reproducir Vista Previa';

  @override
  String get uploadCancelled => 'Subida cancelada';

  @override
  String get backupUploadCancelledByUser =>
      'Subida de copia de seguridad cancelada por el usuario';

  @override
  String get collectingData => 'Recopilando datos...';

  @override
  String get uploadingPreviewSongs => 'Subiendo canciones de vista previa...';

  @override
  String get uploadingProfilePhotos => 'Subiendo fotos de perfil...';

  @override
  String get uploadingReleaseArtwork => 'Subiendo arte de lanzamientos...';

  @override
  String get uploadingDatabase => 'Subiendo base de datos...';

  @override
  String get completed => '¡Completado!';

  @override
  String get cancelling => 'Cancelando...';

  @override
  String get uploadingBackupTitle => 'Subiendo Copia de Seguridad';

  @override
  String get cancellingUpload => 'Cancelando subida...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Por favor espere mientras detenemos la subida...';

  @override
  String get downloadingDatabase => 'Descargando base de datos...';

  @override
  String get downloadingPreviewSongs =>
      'Descargando canciones de vista previa...';

  @override
  String get downloadingProfilePhotos => 'Descargando fotos de perfil...';

  @override
  String get downloadingReleaseArtwork => 'Descargando arte de lanzamientos...';

  @override
  String get mergingData => 'Fusionando datos...';

  @override
  String get downloadingBackupTitle => 'Descargando Copia de Seguridad';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Archivo fuente no encontrado en esta máquina';

  @override
  String get metadataExtractionNotSupportedForDaw =>
      'La extracción de metadatos no es compatible con este DAW';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Archivo fuente no encontrado en esta máquina — modo solo metadatos. Aún puedes editar y exportar metadatos.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Canción de vista previa no disponible. Por favor, descarga el backup primero.';

  @override
  String get sharePreviewSong => 'Compartir canción de vista previa';

  @override
  String get shareAsZip => 'Compartir como ZIP';

  @override
  String get share => 'Compartir';

  @override
  String get convertingAudioForSharing => 'Preparando el audio para compartir…';

  @override
  String get shareSheetUnavailable =>
      'El menú de compartir del sistema no está disponible aquí — usa el botón \"Arrastrar para Compartir\" en la vista previa de la canción para arrastrar el archivo a otra app.';

  @override
  String get dragToShare => 'Arrastrar para Compartir';

  @override
  String get dragToShareTooltip =>
      'Arrastra esto a la ventana de otra app (ej: WhatsApp) para compartir el archivo directamente — útil cuando el botón Compartir no abre un menú de compartir.';

  @override
  String get mp3ConversionFailed =>
      'La conversión de audio no está disponible en este sistema — se compartirá el archivo original, que algunas apps como WhatsApp pueden rechazar.';

  @override
  String get shareZip => 'Compartir ZIP';

  @override
  String get saveCopy => 'Guardar copia';

  @override
  String savedCopyTo(String path) {
    return 'Guardado en $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Error al compartir canción de vista previa: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Error al compartir canción de vista previa como ZIP: $error';
  }

  @override
  String get biographySaved => 'Biografía guardada';

  @override
  String failedToSaveBiography(String error) {
    return 'Error al guardar biografía: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'Archivo guardado en $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Error al descargar archivo: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'Todos los archivos guardados en $filename';
  }

  @override
  String get artworkAdded => 'Arte agregada';

  @override
  String failedToAddArtwork(String error) {
    return 'Error al agregar arte: $error';
  }

  @override
  String get artworkRemoved => 'Arte eliminada';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Error al eliminar arte: $error';
  }

  @override
  String get pressKitFileAdded => 'Archivo de press kit agregado';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Error al agregar archivo de press kit: $error';
  }

  @override
  String get pressKitFileRemoved => 'Archivo de press kit eliminado';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Error al eliminar archivo de press kit: $error';
  }

  @override
  String get selectFilesToDownload => 'Seleccionar Archivos para Descargar';

  @override
  String get biography => 'Biografía';

  @override
  String get biographyWillBeSaved => 'Se guardará como biography.txt';

  @override
  String get artworkFiles => 'Archivos de Arte';

  @override
  String get pressKitFiles => 'Archivos de Press Kit';

  @override
  String get additionalAssets => 'Activos Adicionales';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Descargar $count archivo$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count archivo$plural guardado en $filename';
  }

  @override
  String get addAsset => 'Agregar Activo';

  @override
  String get assetNameLabel => 'Nombre del Activo';

  @override
  String get assetNameHint => 'ej., Logo, Banner, Foto';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName agregado exitosamente';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Error al agregar activo: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName eliminado';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Error al eliminar activo: $error';
  }

  @override
  String get profileNotFound => 'Perfil no encontrado';

  @override
  String get downloadFilesSectionTitle => 'Descargar Archivos';

  @override
  String get downloadFilesSectionDescription =>
      'Descarga todos los archivos de este perfil — biografía, arte, kit de prensa y activos adicionales — como un único ZIP, o selecciona cuáles incluir.';

  @override
  String get selectFiles => 'Seleccionar Archivos';

  @override
  String get downloadAll => 'Descargar Todo';

  @override
  String get saveBiographyTooltip => 'Guardar Biografía';

  @override
  String get enterBiographyHint => 'Ingrese la biografía del perfil...';

  @override
  String get addArtwork => 'Agregar Arte';

  @override
  String get addFile => 'Agregar Archivo';

  @override
  String get openFile => 'Abrir Archivo';

  @override
  String get menuView => 'Ver';

  @override
  String get menuAbout => 'Acerca de DAW Project Manager';

  @override
  String get menuDocumentation => 'Documentación';

  @override
  String get menuLanguage => 'Idioma';

  @override
  String get menuWarnBeforeQuit => 'Advertir Antes de Salir (⌘+Q)';

  @override
  String get menuQuit => 'Salir de DAW Project Manager';

  @override
  String get quitConfirmTitle => '¿Salir de DAW Project Manager?';

  @override
  String get quitConfirmMessage => '¿Seguro que quieres salir?';

  @override
  String get quit => 'Salir';

  @override
  String get trayNoticeTitle => 'Sigue ejecutándose en segundo plano';

  @override
  String get trayNoticeBody =>
      'DAW Project Manager se minimizó a la bandeja del sistema. Usa el icono de la bandeja para reabrirlo o salir.';

  @override
  String get trayShowWindow => 'Mostrar DAW Project Manager';

  @override
  String trayLastBackup(String when) {
    return 'Última copia de seguridad: $when';
  }

  @override
  String get trayNeverBackedUp => 'Aún no hay copias de seguridad';

  @override
  String get trayBackupNow => 'Hacer Copia de Seguridad Ahora';

  @override
  String get trayPauseSession => 'Pausar Sesión';

  @override
  String get trayResumeSession => 'Reanudar Sesión';

  @override
  String get closeToTray => 'Cerrar a la bandeja';

  @override
  String get closeToTrayDescription =>
      'Seguir ejecutándose en segundo plano (icono en la bandeja) al cerrar la ventana, para que la copia de seguridad automática y las notificaciones sigan funcionando';

  @override
  String get autoStart => 'Iniciar con el sistema';

  @override
  String get autoStartDescription =>
      'Abrir DAW Project Manager automáticamente al iniciar sesión en el equipo';

  @override
  String get startMinimized => 'Iniciar minimizado en la bandeja';

  @override
  String get startMinimizedDescription =>
      'Cuando la app se inicie con el equipo, abrirla oculta en la bandeja en lugar de mostrar la ventana';

  @override
  String get onboardingStartMinimized => 'Iniciar minimizado';

  @override
  String get autoStartFailed =>
      'No se pudo cambiar la configuración de inicio. Puede que tu sistema no lo permita.';

  @override
  String get onboardingStartupTitle => 'Iniciar con el Sistema';

  @override
  String get onboardingStartupBody =>
      'Haz que DAW Project Manager se abra automáticamente al iniciar sesión, para que las copias de seguridad y los recordatorios de fechas límite sigan funcionando.';

  @override
  String get menuWindow => 'Ventana';

  @override
  String get donate => 'Donar';

  @override
  String get website => 'Sitio Web';

  @override
  String get license => 'Licencia';

  @override
  String get reportIssue => 'Reportar un problema';

  @override
  String get switchToClassicDark => 'Cambiar a Classic Dark';

  @override
  String get switchToNeonDark => 'Cambiar a Neon Dark';

  @override
  String get switchToClassicTheme => 'Cambiar al Tema Clásico';

  @override
  String get switchToNeonTheme => 'Cambiar al Tema Neón';

  @override
  String get switchToStudioLight => 'Cambiar a Studio Light';

  @override
  String get menuTheme => 'Tema';

  @override
  String get appDescription =>
      'Un gestor de proyectos para productores musicales y diseñadores de sonido.';

  @override
  String get neonDarkThemeName => 'Neón Oscuro';

  @override
  String get classicDarkThemeName => 'Clásico Oscuro';

  @override
  String get studioLightThemeName => 'Studio Claro';

  @override
  String get statisticsTab => 'Estadísticas';

  @override
  String get statsTotalProjects => 'Total de Proyectos';

  @override
  String get statsInProgress => 'En curso';

  @override
  String get statsFinished => 'Terminados';

  @override
  String get statsAvgCompletion => 'Finalización media';

  @override
  String get statsPhaseDistribution => 'Proyectos por Fase';

  @override
  String get statsAvgTimePerPhase => 'Días medios por Fase';

  @override
  String get statsProductivity => 'Productividad';

  @override
  String get statsCreatedSeries => 'Creados';

  @override
  String get statsProjectHealth => 'Edad y Salud de Proyectos';

  @override
  String get statsCatalogInsights => 'Análisis del Catálogo';

  @override
  String get statsBpmDistribution => 'Distribución de BPM';

  @override
  String get statsTopKeys => 'Tonalidades principales';

  @override
  String get statsDawTypes => 'Tipos de DAW';

  @override
  String get statsProjectActivity => 'Actividad de Proyectos';

  @override
  String get statsSingleProjectActivity => 'Actividad del Proyecto';

  @override
  String get statsNoData => 'Sin datos aún';

  @override
  String get statsNoPhaseData =>
      'Los datos de fases aparecerán cuando los proyectos cambien de fase.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Última actividad: hace $days días';
  }

  @override
  String get statsLastActivityToday => 'Activo hoy';

  @override
  String get statsNoEvents => 'Aún no hay eventos registrados';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Fase: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Actualizado: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Completado: $text';
  }

  @override
  String get statsEventFileModified => 'Archivo modificado en disco';

  @override
  String get statsClearHistory => 'Borrar historial';

  @override
  String get statsClearHistoryConfirm =>
      '¿Borrar todos los eventos registrados para este proyecto?';

  @override
  String get statsSearchProjects => 'Buscar proyectos…';

  @override
  String statsEventCount(int count) {
    return '$count eventos';
  }

  @override
  String get statsViewHistory => 'Estadísticas del Proyecto';

  @override
  String get statsPhaseHistory => 'Historial de Fases';

  @override
  String get statsEventBreakdown => 'Desglose de Eventos';

  @override
  String statsDaysSoFar(int days) {
    return '${days}d hasta ahora';
  }

  @override
  String get statsNoProjectsFound => 'No se encontraron proyectos';

  @override
  String statsNotTouchedDays(int days) {
    return 'Sin cambios en $days días';
  }

  @override
  String get sortByLastModified => 'Última modificación';

  @override
  String get sortByName => 'Nombre';

  @override
  String get sortByPhase => 'Fase';

  @override
  String get sortByCreatedAt => 'Fecha de creación';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get sortNewestFirst => 'Más recientes primero';

  @override
  String get sortOldestFirst => 'Más antiguos primero';

  @override
  String get sortTitleAZ => 'Título A–Z';

  @override
  String get sortTitleZA => 'Título Z–A';

  @override
  String get musicPlayerTab => 'Reproductor de música';

  @override
  String get previewAudioChangedRefreshing =>
      'El audio de vista previa cambió en el disco — actualizando la forma de onda…';

  @override
  String get audioFileChangedRefreshing =>
      'El archivo de audio cambió en el disco — actualizando la forma de onda…';

  @override
  String get autoFitAllColumns => 'Ajustar columnas';

  @override
  String get uploadAutoDetectedPreviewSongs =>
      'Subir canciones de vista previa detectadas automáticamente';

  @override
  String get uploadAutoDetectedPreviewSongsSubtitle =>
      'Incluir canciones encontradas automáticamente por el escáner, no solo las que estableciste manualmente.';

  @override
  String get monoGenerating => 'Mono…';

  @override
  String errorHandlingDroppedFiles(String error) {
    return 'Error al procesar los archivos soltados: $error';
  }

  @override
  String get resetOnboardingConfirm =>
      'Esto reiniciará el asistente de configuración. ¿Continuar?';

  @override
  String couldNotLaunchDaw(String daw, String error) {
    return 'No se pudo iniciar $daw: $error';
  }

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace.';

  @override
  String get githubButtonLabel => 'GitHub';

  @override
  String get monoLabel => 'Mono';

  @override
  String get monoToggleTooltip => 'Alternar reproducción mono';

  @override
  String get monoRequiresWav => 'La mezcla mono requiere un archivo WAV';

  @override
  String get monoUnsupportedFormat =>
      'No se pudo crear la mezcla mono — formato no compatible';

  @override
  String monoSwitchFailed(String error) {
    return 'Error al cambiar a mono: $error';
  }

  @override
  String get analyzeLabel => 'Analizar';

  @override
  String get reAnalyzeLabel => 'Re-analizar';

  @override
  String get analysisRequiresWav => 'El análisis requiere un archivo WAV';

  @override
  String get noResultsForFilter => 'Sin resultados para el filtro actual';

  @override
  String get noResultsForFilterHint =>
      'Intenta ajustar la búsqueda o los filtros.';

  @override
  String get noProjectsFound => 'No se encontraron proyectos';

  @override
  String get noProjectsFoundHint =>
      'Añade una carpeta raíz en la configuración para empezar.';

  @override
  String get noProjectsFoundInFoldersHint =>
      'Intenta añadir otra carpeta que contenga proyectos de DAW.';

  @override
  String get queueTab => 'Tareas';

  @override
  String get queueSearchHint => 'Buscar tareas...';

  @override
  String get queueNoPendingTasks => '¡Todo al día!';

  @override
  String get queueNoPendingTasksHint =>
      'Sin tareas pendientes en tus proyectos.';

  @override
  String get queueNoMatchingTasks => 'No se encontraron tareas';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks tareas pendientes en $projects proyectos';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager $version';
  }

  @override
  String versionLabel(String version) {
    return 'Versión $version';
  }

  @override
  String get renameProjectFileTitle => 'Renombrar archivo de proyecto';

  @override
  String get renameFileButtonLabel => 'Renombrar archivo';

  @override
  String get newFileNameLabel => 'Nuevo nombre de archivo (sin extensión)';

  @override
  String renameAlreadyExists(String name) {
    return 'Ya existe un archivo llamado \"$name\".';
  }

  @override
  String renameSuccess(String name) {
    return 'Renombrado a \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Error al renombrar: $error';
  }

  @override
  String get nameCannotBeEmpty => 'El nombre no puede estar vacío';

  @override
  String get nameInvalidCharacters => 'El nombre no puede contener / \\ :';

  @override
  String get alsoRenameContainingFolder =>
      'También renombrar la carpeta contenedora';

  @override
  String get renameButton => 'Renombrar';

  @override
  String get previewMixdownFolderTitle => 'Carpetas de mezcla de vista previa';

  @override
  String get previewMixdownFolderSubtitle =>
      'Nombres de subcarpetas dentro de cada carpeta de proyecto a verificar primero, en orden, al detectar canciones de vista previa. Dejar vacío para usar los valores predeterminados del DAW.';

  @override
  String get previewMixdownFolderHint => 'p.ej. Mezclas';

  @override
  String get mixdownFoldersInfoTooltip => 'Cómo funciona esto';

  @override
  String get mixdownFoldersInfoDialogTitle =>
      'Cómo funciona la detección de vista previa';

  @override
  String get mixdownFoldersInfoDialogBody =>
      'Cuando un proyecto no tiene una canción de vista previa elegida manualmente, la app busca el archivo de audio modificado más recientemente para usarlo como vista previa. Primero verifica tus carpetas personalizadas a continuación, en orden, y luego recurre a una lista de nombres de carpetas predeterminados según el DAW del proyecto.';

  @override
  String get mixdownFoldersDawDefaultsHeading =>
      'Carpetas predeterminadas por DAW';

  @override
  String get mixdownFoldersOtherDawLabel => 'Otro / DAW no reconocido';

  @override
  String get addMixdownFolder => 'Añadir';

  @override
  String get noCustomMixdownFolders =>
      'No se agregaron carpetas personalizadas — se usarán los valores predeterminados del DAW.';

  @override
  String get mixdownFoldersTabLabel => 'Carpetas de Mezcla';

  @override
  String get mixdownFoldersSectionDescription =>
      'Controla en qué carpeta busca la app el audio exportado/mezclado de un proyecto, usado como canción de vista previa cuando no se ha establecido ninguna manualmente. Expande un DAW abajo para ver los nombres de carpeta que ya comprueba por defecto, y añade los tuyos si tu configuración usa un nombre diferente.';

  @override
  String get mixdownFoldersDefaultsLabel => 'Carpetas comprobadas por defecto:';

  @override
  String get mixdownFoldersCustomLabel => 'Tus adiciones para este DAW:';

  @override
  String get dawLaunchCommandsTabLabel => 'DAW Locations';

  @override
  String get dawLaunchCommandsSectionDescription =>
      '\"Launch in DAW\" normally hands the project to the system\'s default application. When that doesn\'t work, point it here at the exact DAW program to run — an executable on Windows and Linux (or an AppImage), or the .app on macOS — and the app will open projects of that type with it directly. On Linux this is usually required; on Windows and macOS it\'s a fallback for when the standard launch fails. You can add more than one location per DAW (e.g. two versions); the app asks which to use when you launch.';

  @override
  String get dawLaunchCommandNotConfigured => 'Not configured';

  @override
  String get dawLaunchCommandMissingTooltip => 'This location no longer exists';

  @override
  String get dawLaunchCommandConfigureButton => 'Configure';

  @override
  String get dawLaunchCommandAddButton => 'Add location';

  @override
  String dawLaunchCommandDialogTitle(String dawType) {
    return 'Launch command for $dawType';
  }

  @override
  String dawLaunchCommandDialogBody(String dawType) {
    return 'Point this at the $dawType program — an executable on Windows and Linux (or an AppImage), or the .app on macOS. The app will run it directly with the project file as its only argument.';
  }

  @override
  String dawLaunchCommandDialogLaunchFailedBanner(String dawType) {
    return 'DAW Project Manager couldn\'t open this project through the system. Point it at the $dawType program below and it will try launching the project with it directly.';
  }

  @override
  String dawLaunchCommandDialogMissingBanner(String dawType, String path) {
    return 'The saved location(s) for $dawType no longer exist:\n$path';
  }

  @override
  String dawLaunchPickerTitle(String dawType) {
    return 'Which $dawType?';
  }

  @override
  String dawLaunchPickerBody(String dawType, String project) {
    return 'Choose which $dawType location to open “$project” with.';
  }

  @override
  String get dawLaunchCommandDialogDetectedHeading => 'Detected on this system';

  @override
  String get dawLaunchCommandDialogManualHint => '/path/to/executable';

  @override
  String get dawLaunchCommandDialogBrowseButton => 'Browse…';

  @override
  String get dawLaunchCommandDialogSaveButton => 'Save';

  @override
  String get dawLaunchCommandDialogSaveAndLaunchButton => 'Save & Launch';

  @override
  String get dawLaunchCommandDialogInvalidPath => 'This file doesn\'t exist';

  @override
  String get dawLaunchCommandsEmptyState =>
      'DAWs will appear here once you scan projects for them.';

  @override
  String dawInfoLabel(String daw) {
    return 'DAW: $daw';
  }

  @override
  String bpmInfoLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String keyInfoLabel(String key) {
    return 'Tono: $key';
  }

  @override
  String get audioFileNotFound => 'Archivo de audio no encontrado';

  @override
  String errorPlayingAudio(String error) {
    return 'Error al reproducir audio: $error';
  }

  @override
  String get notificationTestTitle =>
      'Probar notificaciones para verificar zona horaria y programación:';

  @override
  String get notificationSendNow => 'Enviar ahora';

  @override
  String get notificationSchedule30s => 'Programar +30s';

  @override
  String get notificationShowDebugInfo => 'Mostrar información de depuración';

  @override
  String get notificationRescheduleAll => 'Reprogramar todo';

  @override
  String get notificationTestSent => '✅ ¡Notificación de prueba enviada!';

  @override
  String get notificationTestScheduled =>
      '✅ ¡Notificación de prueba programada para 30 segundos! Revisa los registros.';

  @override
  String notificationTestError(String error) {
    return '❌ Error: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Información de depuración';

  @override
  String get autoDetected => 'Detectado automáticamente';

  @override
  String get matchedInDescription => 'Encontrado en la descripción';

  @override
  String get matchedInProjectNotes =>
      'Encontrado en las notas del proyecto del DAW';

  @override
  String get relocateFolderDialogTitle => 'Reubicar carpeta';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rutas de proyecto actualizadas',
      one: '1 ruta de proyecto actualizada',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Personalizar pestanas';

  @override
  String get alwaysVisible => '(siempre visible)';

  @override
  String get customizeTabsDescription =>
      'Elige que pestanas mostrar en la barra de navegacion. La pestana Proyectos siempre es visible.';

  @override
  String get keyboardShortcuts => 'Atajos de teclado';

  @override
  String get shortcutGroupGlobal => 'Global';

  @override
  String get shortcutGroupProjectsTable =>
      'Tabla de proyectos (la tabla debe estar enfocada)';

  @override
  String get shortcutGroupReleasesTable =>
      'Tabla de lanzamientos (la tabla debe estar enfocada)';

  @override
  String get shortcutGroupNavigation => 'Navegación';

  @override
  String get shortcutFocusSearch => 'Enfocar barra de búsqueda';

  @override
  String get shortcutRescan => 'Reescanear carpetas de proyectos';

  @override
  String get shortcutFocusTable => 'Enfocar tabla de proyectos';

  @override
  String get shortcutPlayPause => 'Reproducir / pausar canción de vista previa';

  @override
  String get shortcutOpenInDaw => 'Abrir proyecto en DAW';

  @override
  String get shortcutViewDetails => 'Ver detalles del proyecto';

  @override
  String get shortcutOpenFolder => 'Abrir carpeta del proyecto';

  @override
  String get shortcutNavigateRows => 'Navegar filas';

  @override
  String get shortcutEditCell => 'Abrir detalles del proyecto';

  @override
  String get shortcutViewRelease => 'Ver detalles del lanzamiento';

  @override
  String get shortcutGoBack => 'Volver';

  @override
  String get shortcutGroupProjectsTableStandardMode => 'Modo estándar';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'Modo sesión';

  @override
  String get shortcutToggleSession => 'Iniciar / Terminar sesión';

  @override
  String get shortcutGroupPreviewPlayer => 'Reproductor de vista previa';

  @override
  String get shortcutPlayerPlayPause => 'Reproducir / pausar';

  @override
  String get shortcutPlayerSeek5 => 'Adelantar/Retroceder ±5 segundos';

  @override
  String get shortcutPlayerSeek30 => 'Adelantar/Retroceder ±30 segundos';

  @override
  String get startupDialogTitle => 'Bienvenido a DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Comienza añadiendo una carpeta de proyectos o restaurando una copia de Google Drive.';

  @override
  String get startupAddFolderTitle => 'Añadir carpeta de proyectos';

  @override
  String get startupAddFolderSubtitle =>
      'Selecciona una carpeta con tus proyectos DAW.';

  @override
  String get startupGoogleDriveTitle => 'Sincronizar copia de Google Drive';

  @override
  String get startupGoogleDriveSubtitle =>
      'Restaura tus proyectos desde una copia de seguridad en Google Drive.';

  @override
  String get startupDontShowAgain => 'No mostrar esto al iniciar';

  @override
  String get pinnedLibraryWarningTitle => 'Biblioteca de prueba en uso';

  @override
  String get pinnedLibraryWarningBody =>
      'Esta versión guarda sus datos en una biblioteca de prueba independiente, por lo que no puede modificar la biblioteca que usa la copia instalada de la aplicación. Los proyectos, perfiles y ajustes que cambies aquí no aparecerán allí.';

  @override
  String get pinnedLibraryWarningLibraryLabel => 'Biblioteca';

  @override
  String get pinnedLibraryWarningLocationLabel => 'Ubicación';

  @override
  String get pinnedLibraryWarningDontShowAgain =>
      'No volver a avisarme sobre esta biblioteca';

  @override
  String get deleteAllData => 'Eliminar todos los datos';

  @override
  String get deleteAllDataSubtitle =>
      'Eliminar todos los perfiles, proyectos, lanzamientos, listas de reproducción y ajustes de este dispositivo.';

  @override
  String get deleteAllDataConfirm1Title => '¿Eliminar todos los datos?';

  @override
  String get deleteAllDataConfirm1Message =>
      'Esto borrará permanentemente todos los perfiles, proyectos, lanzamientos, listas de reproducción y ajustes de este dispositivo. Tu copia de seguridad en Google Drive (si existe) no se verá afectada.';

  @override
  String get deleteAllDataConfirm2Title => '¿Estás absolutamente seguro?';

  @override
  String get deleteAllDataConfirm2Message =>
      'Esta acción no se puede deshacer. La aplicación volverá a su estado inicial.';

  @override
  String get deleteEverything => 'Eliminar todo';

  @override
  String get allDataDeleted => 'Todos los datos han sido eliminados.';

  @override
  String get newerExportFound => 'Exportación más reciente encontrada';

  @override
  String newerExportFoundMessage(String filename) {
    return 'Se encontró un archivo más reciente en la misma carpeta:\n$filename\n\n¿Reemplazar la canción de vista previa?';
  }

  @override
  String get replaceAndPlay => 'Reemplazar y reproducir';

  @override
  String get keepCurrent => 'Mantener actual';

  @override
  String get autoBackup => 'Respaldo Automático';

  @override
  String get autoBackupDescription =>
      'Sube automáticamente un respaldo a Google Drive en el intervalo seleccionado.';

  @override
  String get autoBackupInterval => 'Intervalo de respaldo';

  @override
  String get autoBackupOff => 'Desactivado';

  @override
  String get autoBackupEvery30Min => 'Cada 30 minutos';

  @override
  String get autoBackupHourly => 'Cada hora';

  @override
  String get autoBackupEvery6Hours => 'Cada 6 horas';

  @override
  String get autoBackupDaily => 'Diariamente';

  @override
  String autoBackupNextBackup(String time) {
    return 'Próxima copia: $time';
  }

  @override
  String get autoBackupNextSoon => 'pronto';

  @override
  String autoBackupNextInMinutes(int count) {
    return 'en $count min';
  }

  @override
  String get autoBackupNextInOneHour => 'en 1 hora';

  @override
  String autoBackupNextInHours(int count) {
    return 'en $count horas';
  }

  @override
  String get autoBackupNextInOneDay => 'en 1 día';

  @override
  String autoBackupNextInDays(int count) {
    return 'en $count días';
  }

  @override
  String get playerTitle => 'Reproductor de música';

  @override
  String get playerToggleQueue => 'Alternar cola';

  @override
  String get playerSearchHint => 'Buscar pistas…';

  @override
  String playerTrackCount(int count) {
    return '$count pistas';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'No se encontraron pistas de vista previa.\nAbre un proyecto y establece una vista previa.';

  @override
  String playerNoTracksMatch(String query) {
    return 'Ninguna pista coincide con\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay =>
      'Doble clic en una pista para reproducir';

  @override
  String get playerSingleClickToPreview =>
      'Clic simple para vista previa en la barra inferior';

  @override
  String get playerQueueTitle => 'Cola';

  @override
  String get playerClearQueue => 'Vaciar cola';

  @override
  String get playerQueueEmptyHint =>
      'Doble clic para comenzar,\no arrastra pistas aquí para la cola.';

  @override
  String get playerPrev => 'Anterior';

  @override
  String get playerNext => 'Siguiente';

  @override
  String get playerGoToProject => 'Ir al proyecto';

  @override
  String get playerAddToQueue => 'Añadir a la cola';

  @override
  String get playerRemoveFromQueue => 'Quitar de la cola';

  @override
  String get playerDismissDetail => 'Cerrar detalle';

  @override
  String get playerNotes => 'NOTAS';

  @override
  String get playerTasks => 'TAREAS';

  @override
  String get playerNoTasks => 'Sin tareas aún.';

  @override
  String get playerAddTaskHint => 'Añadir una tarea…';

  @override
  String playerCompletedTasks(int count) {
    return '$count completada(s)';
  }

  @override
  String get playerPreviousTrack => 'Pista anterior';

  @override
  String get playerNextTrack => 'Siguiente pista';

  @override
  String get playerOpenProject => 'Abrir proyecto';

  @override
  String get playerRepeatAll => 'Repetir todo';

  @override
  String get playerShuffle => 'Aleatorio';

  @override
  String get volumeMute => 'Silenciar';

  @override
  String get volumeUnmute => 'Activar sonido';

  @override
  String totalWorkTime(String time) {
    return 'Trabajo total: $time';
  }

  @override
  String sessionTime(String time) {
    return 'Sesión: $time';
  }

  @override
  String headerAgeOld(String age) {
    return '$age de antigüedad';
  }

  @override
  String headerEdited(String when) {
    return 'editado $when';
  }

  @override
  String headerWorked(String time) {
    return '$time trabajado';
  }

  @override
  String get sessionHistory => 'Historial de sesiones';

  @override
  String get noSessionsYet => 'Aún no hay sesiones registradas';

  @override
  String get removeSessionTitle => '¿Eliminar sesión?';

  @override
  String get editSessionTitle => 'Editar duración de la sesión';

  @override
  String get editSessionHours => 'Horas';

  @override
  String get editSessionInvalid => 'La duración debe ser al menos 1 minuto';

  @override
  String get sessionTableDate => 'Fecha';

  @override
  String get sessionTableTime => 'Hora';

  @override
  String get sessionTableDuration => 'Duración';

  @override
  String get sessionTableTotal => 'Total';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '1 sesión',
    );
    return '$_temp0';
  }

  @override
  String get sessionByPhase => 'Trabajo por fase';

  @override
  String get tabPosition => 'Posición de pestañas';

  @override
  String get tabPositionTop => 'Arriba';

  @override
  String get tabPositionLeft => 'Izquierda';

  @override
  String updateAvailableMessage(String version) {
    return 'Versión $version disponible';
  }

  @override
  String get dismiss => 'Descartar';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String get checkForUpdatesDescription =>
      'Recibe notificaciones cuando haya una nueva versión disponible.';

  @override
  String get checkNow => 'Verificar ahora';

  @override
  String updateAvailable(String version) {
    return 'Actualización disponible: v$version';
  }

  @override
  String get upToDate => 'La app está actualizada';

  @override
  String get updateAvailableTitle => 'Actualización disponible';

  @override
  String updateAvailableVersion(String version) {
    return 'La versión $version está lista.';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Estás usando v$version.';
  }

  @override
  String get viewUpdateDetails => 'Ver detalles';

  @override
  String get getOnMicrosoftStore => 'Obtener en Microsoft Store';

  @override
  String get downloadFromGitHub => 'Descargar desde GitHub';

  @override
  String get updateWindowsInstructions =>
      'Abre Microsoft Store y actualiza DAW Project Manager, o haz clic abajo.';

  @override
  String get updateMacInstructions =>
      'Descarga la última versión desde GitHub y reemplaza la app actual.';

  @override
  String get updateAppImageSourceLabel => 'AppImage';

  @override
  String get updateAppImageInstructions =>
      'Se actualiza en el mismo lugar y se reinicia.';

  @override
  String get updateNowButtonLabel => 'Actualizar ahora';

  @override
  String get appImageUpdateFetching => 'Buscando la actualización…';

  @override
  String get appImageUpdateDownloading => 'Descargando actualización…';

  @override
  String appImageUpdateDownloadingProgress(int percent) {
    return 'Descargando actualización… $percent%';
  }

  @override
  String get appImageUpdateVerifying => 'Verificando e instalando…';

  @override
  String get appImageUpdateReadyTitle => 'Actualización lista';

  @override
  String appImageUpdateReadyMessage(String version) {
    return 'Actualizado a la versión $version. Reinicia ahora para terminar.';
  }

  @override
  String get appImageUpdateRestartNow => 'Reiniciar ahora';

  @override
  String get appImageUpdateFailedTitle => 'Error al actualizar';

  @override
  String get appImageUpdateRetry => 'Reintentar';

  @override
  String get appImageUpdateErrorMessage =>
      'Ocurrió un error durante la actualización. Puedes intentarlo de nuevo o revisar los detalles del error a continuación.';

  @override
  String get appImageUpdateErrorDetailsLabel => 'Detalles del error';

  @override
  String get appImageUpdateCopyErrorDetails => 'Copiar detalles del error';

  @override
  String get appImageUpdateErrorDetailsCopied => 'Detalles del error copiados';

  @override
  String get resetOnboarding => 'Restablecer configuración inicial';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido a DAW Project Manager';

  @override
  String get onboardingWelcomeBody =>
      'Organiza todos tus proyectos musicales en un solo lugar.';

  @override
  String get onboardingFeatureScanFolders =>
      'Escanea automáticamente las carpetas de proyectos DAW';

  @override
  String get onboardingFeatureTrackMetadata =>
      'Registra BPM, tonalidad, estado y plazos';

  @override
  String get onboardingFeatureSyncDrive =>
      'Sincroniza metadatos con Google Drive';

  @override
  String get onboardingFeatureTrackTime =>
      'Registra el tiempo dedicado a cada proyecto';

  @override
  String get onboardingLanguageTitle => 'Elige tu idioma';

  @override
  String get onboardingThemeTitle => 'Elige un tema';

  @override
  String get onboardingFoldersTitle => 'Añadir carpetas de proyectos';

  @override
  String get onboardingFoldersBody =>
      'Añade la carpeta raíz donde se almacenan tus proyectos DAW.';

  @override
  String get onboardingDriveTitle => 'Sincronización con Google Drive';

  @override
  String get onboardingDriveBody =>
      'Haz copias de seguridad y sincroniza los metadatos con Google Drive.';

  @override
  String get onboardingUpdatesTitle => 'Buscar actualizaciones';

  @override
  String get onboardingUpdatesBody =>
      'Recibe notificaciones cuando haya una nueva versión disponible.';

  @override
  String get onboardingDoneTitle => '¡Todo listo!';

  @override
  String get onboardingDoneBody => 'Empieza a explorar tus proyectos.';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingBack => 'Atrás';

  @override
  String get onboardingGetStarted => 'Comenzar';

  @override
  String get dawSession => 'Sesión DAW';

  @override
  String get clearDawSession => 'Cerrar sesión';

  @override
  String get stop => 'Parar';

  @override
  String get pause => 'Pausar';

  @override
  String get playPauseTooltip => 'Reproducir / Pausar';

  @override
  String get resume => 'Reanudar';

  @override
  String get workTimerSection => 'Recordatorios de sesión de trabajo';

  @override
  String get workTimerSectionDesc =>
      'Recibe notificaciones periódicamente mientras tienes una sesión de trabajo activa';

  @override
  String get workTimerRequiresSessionMode =>
      'Activa el Modo Sesión arriba para usar los recordatorios de sesión de trabajo';

  @override
  String get workTimerEnabled => 'Activar recordatorios de sesión de trabajo';

  @override
  String get workTimerIntervalLabel => 'Notificar cada';

  @override
  String get minutes => 'minutos';

  @override
  String workTimerNotifBody(String time) {
    return 'Llevas trabajando $time';
  }

  @override
  String get sendTestNotification => 'Enviar notificación de prueba';

  @override
  String get testNotificationTitle => 'Notificación de prueba';

  @override
  String get testNotificationBody =>
      'Esta es una notificación de prueba de DAW Project Manager.';

  @override
  String get general => 'General';

  @override
  String get expand => 'Expandir';

  @override
  String get collapse => 'Contraer';

  @override
  String get lastModifiedColors => 'Colores de fecha de última modificación';

  @override
  String get lastModifiedColorsDescription =>
      'Colorea la fecha de última modificación según la antigüedad y el estado. Verde = Terminado. Las fechas más antiguas se desvanecen de amarillo a rojo — un rojo más intenso significa que el proyecto no ha sido modificado en más tiempo.';

  @override
  String get sessionMode => 'Modo sesión';

  @override
  String get sessionModeDescription =>
      'Inicia una sesión en un proyecto para registrar tu tiempo de trabajo y gestionarlo desde la barra de herramientas';

  @override
  String get workSessionsTabLabel => 'Sesiones de Trabajo';

  @override
  String get normalMode => 'Modo Normal';

  @override
  String get normalModeDescription =>
      'Los proyectos se abren directamente en su DAW al iniciarlos.';

  @override
  String get sessionModeCardDescription =>
      'Inicia una sesión para registrar tu actividad y tiempo en el proyecto.';

  @override
  String get startSession => 'Iniciar sesión';

  @override
  String get endSession => 'Finalizar sesión';

  @override
  String get switchSession => 'Cambiar sesión';

  @override
  String get switchSessionBody =>
      '¿Detener la sesión actual e iniciar una nueva?';

  @override
  String switchSessionCurrent(String project) {
    return 'Actual: $project';
  }

  @override
  String switchSessionNew(String project) {
    return 'Nueva: $project';
  }

  @override
  String get sessionDuration => 'Tiempo de sesión';

  @override
  String get scanModeLabel => 'Modo de escaneo:';

  @override
  String get scanModeSectionTitle => 'Modo de escaneo';

  @override
  String get scanModeSectionDescription =>
      'Controla cómo se muestran los proyectos de cada carpeta en la tabla: como una lista plana o agrupados por subcarpeta.';

  @override
  String get smartFolderOptionsSectionTitle =>
      'Opciones de carpetas inteligentes';

  @override
  String get smartFolderOptionsSectionDescription =>
      'Ajusta cómo se comportan los grupos de carpetas inteligentes en la tabla de proyectos.';

  @override
  String get excludeSmartFoldersFromSort =>
      'Mantener las carpetas inteligentes fuera del orden';

  @override
  String get excludeSmartFoldersFromSortDescription =>
      'Al ordenar la tabla de proyectos por una columna, los grupos de carpetas inteligentes permanecen en su lugar en vez de moverse con el orden — solo se reordenan los proyectos que contienen (y los proyectos sin agrupar). Experimental: desactivado de forma predeterminada.';

  @override
  String get mergeSmartFoldersByName =>
      'Combinar carpetas inteligentes con el mismo nombre';

  @override
  String get mergeSmartFoldersByNameDescription =>
      'Cuando dos carpetas raíz de escaneo (por ejemplo, distintos DAW) tienen una carpeta de nivel superior con el mismo nombre, se tratan como un único grupo combinado en la tabla de proyectos en lugar de dos independientes.';

  @override
  String get alwaysShowSmartFolders =>
      'Mostrar siempre las carpetas inteligentes';

  @override
  String get alwaysShowSmartFoldersDescription =>
      'Muestra una carpeta inteligente como su propia fila de grupo incluso cuando solo uno de sus proyectos está visible actualmente (por ejemplo, tras una búsqueda o un filtro), en lugar de reducirla a una simple fila sin agrupar.';

  @override
  String get scanModeFlat => 'Simple';

  @override
  String get scanModeSmartFolder => 'Carpeta inteligente';

  @override
  String get scanModeFlatDescription =>
      'Muestra cada proyecto como una lista simple. Sencillo y rápido.';

  @override
  String get scanModeSmartFolderDescription =>
      'Agrupa los proyectos por carpeta cuando una carpeta contiene más de un proyecto.';

  @override
  String get skip => 'Omitir';

  @override
  String get suggestionsLabel => 'Sugerencias';

  @override
  String get suggestionsRefresh => 'Actualizar';

  @override
  String get suggestionsEmptyState =>
      'No hay sugerencias por ahora. Toca Actualizar para restablecer los elementos descartados.';

  @override
  String get suggestionNewProject => 'Nuevo';

  @override
  String get showSuggestions => 'Mostrar sugerencias';

  @override
  String get showSuggestionsDescription =>
      'Muestra sugerencias inteligentes en la barra de herramientas cuando no hay sesión activa';

  @override
  String get onboardingSuggestionsTitle => 'Sugerencias inteligentes';

  @override
  String get onboardingSuggestionsBody =>
      'Obtén recomendaciones personalizadas de proyectos en la barra de herramientas mientras trabajas';

  @override
  String get onboardingSessionModeTitle => 'Modo sesión';

  @override
  String get onboardingSessionModeBody =>
      'Inicia sesiones de trabajo enfocadas y realiza un seguimiento automático del tiempo dedicado a cada proyecto';

  @override
  String get suggestionsFeatureDeadlines =>
      'Recordatorios de plazos para proyectos próximos';

  @override
  String get suggestionsFeatureResume =>
      'Retomar el último proyecto en el que trabajaste';

  @override
  String get suggestionsFeatureRecentlyModified =>
      'Continuar con las pistas modificadas recientemente';

  @override
  String get suggestionsEnableToggle => 'Activar sugerencias inteligentes';

  @override
  String get canBeChangedInSettings =>
      'Se puede cambiar más tarde en Configuración';

  @override
  String get next => 'Siguiente';

  @override
  String get createProject => 'Crear';

  @override
  String get createProjectTooltip => 'Crear una nueva carpeta de proyecto';

  @override
  String get createProjectSelectFolder => 'Elegir ubicación';

  @override
  String get createProjectSelectFolderHint =>
      'Selecciona en qué carpeta crear el nuevo proyecto';

  @override
  String get createProjectNameTitle => 'Nombra tu proyecto';

  @override
  String get createProjectNameHint =>
      'Elige un esquema de nomenclatura para la nueva carpeta';

  @override
  String get createProjectSchemeArtistTrack => 'Artista — Pista';

  @override
  String get createProjectSchemeCollab => 'Colaboración';

  @override
  String get createProjectSchemeDate => 'Fecha — Pista';

  @override
  String get createProjectSchemeCustom => 'Personalizado';

  @override
  String get createProjectSchemeRemix => 'Remix';

  @override
  String get createProjectArtistName => 'Nombre del artista';

  @override
  String get createProjectTrackName => 'Nombre de la pista';

  @override
  String get createProjectCustomName => 'Nombre de carpeta';

  @override
  String get createProjectAddArtist => 'Añadir artista';

  @override
  String get createProjectOriginalArtist => 'Artista original';

  @override
  String get createProjectRemixerName => 'Remixer';

  @override
  String get createProjectAddRemixer => 'Añadir remixer';

  @override
  String get createProjectSelectDaw => 'Abrir en DAW';

  @override
  String get createProjectSelectDawHint =>
      'Elige qué DAW abrir para trabajar en este proyecto';

  @override
  String get createProjectDetectDaws => 'Detectar DAWs instaladas';

  @override
  String get createProjectSkipDaw => 'Solo crear la carpeta';

  @override
  String get createProjectNoDawsFound =>
      'No se encontraron DAWs. La carpeta se creará de todas formas.';

  @override
  String get createProjectCreateOnly => 'Crear carpeta';

  @override
  String get createProjectCreateAndOpen => 'Crear y abrir';

  @override
  String get createProjectFolderExists =>
      'Ya existe una carpeta con este nombre';

  @override
  String get createProjectInvalidChars =>
      'El nombre contiene caracteres no válidos';

  @override
  String get createProjectError => 'No se pudo crear la carpeta';

  @override
  String get createProjectIncludeDate => 'Incluir prefijo de fecha';

  @override
  String get createProjectCreatedTitle => 'Carpeta creada';

  @override
  String get createProjectCreatedMessage =>
      'Tu carpeta de proyecto ha sido creada:';

  @override
  String get createProjectCopyName => 'Copiar nombre de carpeta';

  @override
  String get createProjectNameCopied => 'Nombre de carpeta copiado';

  @override
  String get createProjectTrackSession => 'Registrar sesión desde ahora';

  @override
  String get pendingFolderSessionTitle => 'Sesión de trabajo detectada';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return 'Has trabajado en \"$projectName\" durante $duration.';
  }

  @override
  String get pendingFolderSessionContinue => 'Continuar sesión';

  @override
  String get pendingFolderSessionEndRecord => 'Terminar y registrar';

  @override
  String get activeSessionSwitchTitle => 'Sesión ya activa';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return 'Hay una sesión activa para \"$current\". ¿Cambiar a \"$next\" y guardar la sesión actual?';
  }

  @override
  String get activeSessionSwitch => 'Cambiar';

  @override
  String get pendingProjectWaiting => 'Esperando archivo de proyecto…';

  @override
  String get pendingProjectDelete => 'Eliminar carpeta vacía';

  @override
  String get pendingProjectDeleteTitle => '¿Eliminar carpeta?';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return '¿Eliminar \"$folderName\" y su contenido?';
  }

  @override
  String get pendingProjectDismiss => 'Dejar de rastrear esta carpeta';

  @override
  String get pendingProjectDismissTitle => '¿Dejar de seguir?';

  @override
  String get pendingProjectDismissKeep => 'Mantener carpeta';

  @override
  String get pendingProjectDismissDelete => 'Eliminar y cerrar';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'La carpeta no está vacía';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '\"$folderName\" contiene archivos. ¿Eliminar todo permanentemente?';
  }

  @override
  String get pendingProjectRefresh => 'Buscar archivo de proyecto';

  @override
  String get pendingProjectNotFound => 'Aún no se encontró archivo de proyecto';

  @override
  String get phases => 'Fases';

  @override
  String get phasesSubtitle =>
      'Agregar, eliminar y reordenar fases del proyecto';

  @override
  String get phasesDescription =>
      'Las fases rastrean la etapa de cada proyecto en tu flujo de trabajo (p. ej., Idea → Mezcla → Masterización). Arrastra para reordenar, toca un punto de color para recolorear, y marca una fase como finalizada para tratarla como completa en toda la app.';

  @override
  String get resetToDefaults => 'Restablecer predeterminados';

  @override
  String get addPhase => 'Agregar fase';

  @override
  String get phaseNameHint => 'Nombre de fase';

  @override
  String get phaseDuplicateError => 'Ya existe una fase con ese nombre';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proyectos usan esta fase',
      one: '1 proyecto usa esta fase',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => 'Seleccionar color';

  @override
  String get markAsFinished => 'Marcar como fase finalizada';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proyectos usan fases que ya no existirán.',
      one: '1 proyecto usa una fase que ya no existirá.',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      'Esos proyectos conservarán su estado actual pero no aparecerán en los filtros de fase. Siempre puedes volver a añadir esas fases.';

  @override
  String get resetPhasesConfirm =>
      '¿Restablecer todas las fases personalizadas, colores y marcas de fase finalizada a los valores predeterminados?';

  @override
  String get camelotGenerateButton => 'Generar mezcla';

  @override
  String get camelotDialogTitle => 'Mezcla Camelot';

  @override
  String get camelotDialogDescription =>
      'Ordena tus pistas por compatibilidad armónica usando la rueda Camelot. La proximidad de BPM se usa como criterio de desempate.';

  @override
  String camelotEligibleTracks(int count) {
    return '$count pistas elegibles (tonalidad definida)';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$count se omitirán (sin tonalidad)';
  }

  @override
  String get camelotNoEligibleTracks =>
      'Ninguna pista tiene tonalidad definida. Abre un proyecto y define su tonalidad.';

  @override
  String get camelotGenerate => 'Generar';

  @override
  String camelotQueueGenerated(int count) {
    return 'Cola llenada con $count pistas en orden armónico';
  }

  @override
  String get camelotWheelGuideTooltip => 'Guía de la rueda Camelot';

  @override
  String get camelotWheelGuideTitle => 'Guía de la Rueda Camelot';

  @override
  String get camelotGuideRingsTitle => 'Los Anillos';

  @override
  String get camelotGuideRingsBody =>
      'Anillo interior (A)  →  tonos menores\nAnillo exterior (B)  →  tonos mayores';

  @override
  String get camelotGuideNumbersTitle => 'Números 1–12';

  @override
  String get camelotGuideNumbersBody =>
      'Posiciones ordenadas en sentido horario. Cada número representa un vecindario armónico — los vecinos comparten fuertes relaciones tonales.';

  @override
  String get camelotGuideColoursTitle => 'Guía de Colores';

  @override
  String get camelotGuideColoursBody =>
      '● Brillante  →  el tono de tu canción\n● Suavemente iluminado  →  compatible para mezclar\n● Tenue  →  evitar para mezclas suaves';

  @override
  String get camelotGuideTransitionsTitle => 'Transiciones Compatibles';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  (mismo número, cambiar anillo)\n  Mayor/menor relativa — prácticamente sin costuras.\n\n8A → 7A o 9A  (±1, mismo anillo)\n  Tono adyacente — cambio suave y sutil.\n\n8A → 1A o 3A  (±7, mismo anillo)\n  Impulso o caída de energía — cambio más dramático.';

  @override
  String get playerMixSuggestions => 'SUGERENCIAS DE MIX';

  @override
  String get nowPlaying => 'Reproduciendo ahora';

  @override
  String get noPreviewSongsAvailable =>
      'No hay canciones de vista previa disponibles';

  @override
  String get upNext => 'A continuación';

  @override
  String get playbackModeNormal => 'Normal';

  @override
  String get playbackModeRepeat => 'Repetir';

  @override
  String get playbackModeShuffle => 'Aleatorio';

  @override
  String get hideDatesInNames => 'Ocultar fechas en los nombres de proyecto';

  @override
  String get hideDatesInNamesDescription =>
      'Algunas DAW añaden la fecha de creación al principio del nombre del archivo de proyecto (por ejemplo \"2026-08-02 - Mi Pista\"). Ocúltala para mostrar solo el título. Los archivos nunca se renombran.';

  @override
  String get findPreviewAutomatically => 'Buscar automáticamente';

  @override
  String get noPreviewSongFoundAutomatically =>
      'No se encontró ninguna canción de vista previa en las carpetas de mezcla de este proyecto.';

  @override
  String get selectProjects => 'Seleccionar';

  @override
  String sharePreviewSongText(String name) {
    return 'Canción de vista previa: $name';
  }

  @override
  String sharePreviewSongZipText(String name) {
    return 'Canción de vista previa (ZIP): $name';
  }

  @override
  String get songParts => 'Instrumentos y partes';

  @override
  String partsProgress(int done, int total) {
    return '$done de $total tomas finales';
  }

  @override
  String get noPartsYet => 'Aún no hay partes registradas';

  @override
  String get noPartsYetHint =>
      'Anota los instrumentos que necesita la canción, quién los toca y en qué punto está cada toma.';

  @override
  String get addPart => 'Añadir parte';

  @override
  String get addPartHint => 'p. ej. Batería, Voz principal, Bajo';

  @override
  String get partNameLabel => 'Parte';

  @override
  String get partNameRequired => 'El nombre de la parte es obligatorio';

  @override
  String get partPerformerLabel => 'Intérprete';

  @override
  String get partPerformerHint => 'Quién la toca';

  @override
  String get partNotesLabel => 'Notas de la parte';

  @override
  String get partStatusLabel => 'Estado de la toma';

  @override
  String get partStatusNeeded => 'Pendiente';

  @override
  String get partStatusRecording => 'Grabando';

  @override
  String get partStatusEarlyTake => 'Toma preliminar';

  @override
  String get partStatusFinalTake => 'Toma final';

  @override
  String get editPart => 'Editar parte';

  @override
  String get deletePart => 'Eliminar parte';

  @override
  String get partsUnassignedPerformer => 'Sin asignar';

  @override
  String get partTemplates => 'Plantillas de partes';

  @override
  String get importPartsFromTemplate => 'Importar partes desde una plantilla';

  @override
  String get managePartTemplates => 'Gestionar plantillas de partes';

  @override
  String get selectPartTemplate => 'Selecciona una plantilla de partes';

  @override
  String get noPartTemplatesAvailable =>
      'No hay plantillas de partes disponibles';

  @override
  String get noPartTemplatesYet => 'Aún no hay plantillas de partes';

  @override
  String get createFirstPartTemplate =>
      'Crea una para reutilizar la misma formación en varias canciones';

  @override
  String get createPartTemplate => 'Crear plantilla de partes';

  @override
  String get editPartTemplate => 'Editar plantilla de partes';

  @override
  String get deletePartTemplate => 'Eliminar plantilla de partes';

  @override
  String deletePartTemplateConfirm(String name) {
    return '¿Seguro que quieres eliminar la plantilla de partes \"$name\"?';
  }

  @override
  String get partTemplateCreated => 'Plantilla de partes creada';

  @override
  String get partTemplateUpdated => 'Plantilla de partes actualizada';

  @override
  String get partTemplateDeleted => 'Plantilla de partes eliminada';

  @override
  String get partTemplateItems => 'Partes (una por línea)';

  @override
  String get partTemplateItemsHint =>
      'Batería — Alex\nBajo — Sam\nVoz principal';

  @override
  String get partTemplateItemsHelp =>
      'Una parte por línea. Indica el intérprete tras un guión: Batería — Alex';

  @override
  String get partTemplateItemsRequired => 'Añade al menos una parte';

  @override
  String get partTemplateNameAndItemsRequired =>
      'Se requieren un nombre y al menos una parte';

  @override
  String partTemplateItemCount(int count) {
    return '$count parte(s)';
  }

  @override
  String partTemplateImported(String name, int count) {
    return 'Plantilla de partes \"$name\" importada ($count partes)';
  }

  @override
  String get errorLoadingPartTemplates =>
      'Error al cargar las plantillas de partes';

  @override
  String get exportPartsCsv => 'Exportar partes como CSV';

  @override
  String get exportAllPartsCsv =>
      'Exportar las partes de todas las canciones como CSV';

  @override
  String get exportAllPartsCsvSubtitle =>
      'Una fila de hoja de cálculo por parte, de todos los proyectos, para compartir el progreso con colaboradores';

  @override
  String get noPartsToExport => 'No hay partes que exportar';

  @override
  String partsCsvExported(int count) {
    return '$count partes exportadas';
  }

  @override
  String get projectExportPartsLabel => 'Partes:';

  @override
  String get csvHeaderProject => 'Proyecto';

  @override
  String get csvHeaderPart => 'Parte';

  @override
  String get csvHeaderPerformer => 'Intérprete';

  @override
  String get csvHeaderStatus => 'Estado';

  @override
  String get csvHeaderNotes => 'Notas';

  @override
  String get exportPartsXlsx => 'Exportar partes como Excel (.xlsx)';

  @override
  String get exportAllPartsXlsx =>
      'Exportar las partes de todas las canciones como Excel (.xlsx)';

  @override
  String get exportAllPartsXlsxSubtitle =>
      'La misma hoja que el CSV, con encabezado fijo, filtros de columna y estados de toma en color';

  @override
  String get importPartsFromSpreadsheet =>
      'Importar partes desde una hoja de cálculo';

  @override
  String get partsImportPickerTitle => 'Selecciona un archivo CSV o Excel';

  @override
  String partsImported(int added, int updated) {
    return '$added partes añadidas, $updated actualizadas';
  }

  @override
  String get partsImportNothingFound =>
      'No se han encontrado partes en ese archivo';

  @override
  String partsImportFailed(String error) {
    return 'No se pudo leer esa hoja de cálculo: $error';
  }

  @override
  String get partsMoreActions => 'Más acciones de partes';

  @override
  String partsPageTitle(String name) {
    return '$name — Partes';
  }

  @override
  String get manageParts => 'Gestionar partes';

  @override
  String partsMoreCount(int count) {
    return '+$count más';
  }

  @override
  String get searchParts => 'Buscar partes';

  @override
  String get allStatuses => 'Todos los estados';

  @override
  String get allPerformers => 'Todos los intérpretes';

  @override
  String partsSelectedCount(int count) {
    return '$count seleccionadas';
  }

  @override
  String get setPartStatus => 'Establecer estado';

  @override
  String get assignPartPerformer => 'Asignar intérprete';

  @override
  String get deleteSelectedParts => 'Eliminar seleccionadas';

  @override
  String deleteSelectedPartsConfirm(int count) {
    return '¿Eliminar $count partes de esta canción?';
  }

  @override
  String partsDeleted(int count) {
    return '$count partes eliminadas';
  }

  @override
  String get noPartsMatchFilters => 'Ninguna parte coincide con estos filtros';

  @override
  String get reorderNeedsUnfilteredList =>
      'Borra la búsqueda, los filtros y la ordenación para arrastrar las partes';

  @override
  String get projectMarkers => 'Marcadores';

  @override
  String projectMarkerUnnamed(int index) {
    return 'Marcador $index';
  }

  @override
  String projectRegionUnnamed(int index) {
    return 'Región $index';
  }

  @override
  String get projectMarkerJumpTooltip =>
      'Saltar a este punto de la canción de vista previa';

  @override
  String get projectMarkerNoPreviewSong =>
      'Añade una canción de vista previa para saltar a los marcadores';

  @override
  String get projectDetailLayout => 'Diseño de Detalles del Proyecto';

  @override
  String get projectDetailLayoutSettingDescription =>
      'Cómo se organiza la página de detalles del proyecto.';

  @override
  String get projectDetailLayoutClassic => 'Clásico';

  @override
  String get projectDetailLayoutClassicDescription =>
      'Todo en un solo desplazamiento.';

  @override
  String get projectDetailLayoutSectioned => 'Secciones';

  @override
  String get projectDetailLayoutSectionedDescription =>
      'Una barra a la izquierda elige una sección a la vez.';

  @override
  String get stackAsVersions => 'Apilar como versiones';

  @override
  String get stackNeedsTwoVersions =>
      'Selecciona al menos dos proyectos para apilarlos como versiones de un proyecto principal.';

  @override
  String stackCreatedMessage(int count) {
    return '$count versiones apiladas en un proyecto principal.';
  }

  @override
  String get stackVersionsTitle => 'Versiones';

  @override
  String stackVersionCount(int count) {
    return '$count versiones';
  }

  @override
  String get stackAddVersion => 'Añadir versión';

  @override
  String get stackAddVersionTitle => 'Añadir una versión';

  @override
  String get stackAddVersionEmpty =>
      'No hay proyectos sin apilar disponibles para añadir.';

  @override
  String get stackRemoveVersion => 'Quitar de la pila';

  @override
  String get stackRemoveVersionMessage =>
      'El archivo del proyecto permanece en el disco y vuelve a la lista como un proyecto propio.';

  @override
  String get stackUnstack => 'Desapilar';

  @override
  String get stackUnstackTitle => '¿Desapilar este proyecto principal?';

  @override
  String get stackUnstackMessage =>
      'Cada versión vuelve a ser un proyecto propio con los metadatos que tenía antes de apilarse. Las notas, tareas y la fecha límite compartidas en el proyecto principal se eliminan.';

  @override
  String get stackDefaultVersion => 'Se abre por defecto';

  @override
  String get stackSetDefaultVersion => 'Abrir esta versión por defecto';

  @override
  String get stackChooseVersionToOpen => '¿Qué versión quieres abrir?';

  @override
  String get stackMemberOf => 'Versión de';

  @override
  String get stackMemberNotice =>
      'Este archivo es una versión de un proyecto apilado. Los metadatos, tareas y tiempo de trabajo compartidos están en el proyecto principal, no aquí.';

  @override
  String get stackOpenMainProject => 'Abrir proyecto principal';

  @override
  String get stackWorkTimeAcrossVersions => 'Total en todas las versiones';

  @override
  String get scanModeVersionStack => 'Pila de versiones';

  @override
  String get scanModeVersionStackDescription =>
      'Todos los archivos de proyecto de una carpeta se convierten en un proyecto principal que comparte metadatos, tareas y tiempo de trabajo. Los archivos nuevos se unen automáticamente.';

  @override
  String stackTooltipStacked(int count) {
    return '$count versiones apiladas en un proyecto principal';
  }

  @override
  String get stackMetadataSourceTitle =>
      '¿Qué proyecto debe convertirse en el proyecto principal?';

  @override
  String get stackMetadataSourceBody =>
      'Más de uno ya tiene detalles propios. El que elijas se convierte en el proyecto principal: su nombre, BPM, tonalidad, notas, tareas y fecha límite serán los que use la pila. Nada se fusiona ni se pierde: los demás conservan sus detalles y desapilar los devuelve.';

  @override
  String get stackMetadataSourceOldestHint => 'La más antigua — sugerida';

  @override
  String get stackMetadataNoneLabel => 'Aún sin detalles';

  @override
  String stackMetadataTodosLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas',
      one: '1 tarea',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataNotesLabel => 'notas';

  @override
  String get stackNotStackedYet => 'Aún sin apilar';

  @override
  String get stackStartFromHere =>
      'Añade otros archivos de proyecto y se convertirán en versiones de un proyecto principal, compartiendo metadatos, tareas y tiempo de trabajo.';

  @override
  String get stackSearchProjects => 'Buscar proyectos';

  @override
  String get stackSearchNoMatches =>
      'Ningún proyecto coincide con tu búsqueda.';

  @override
  String get stackStartedMessage => 'Apilado en un proyecto principal.';

  @override
  String get stackDefaultVersionTooltip =>
      'Esta versión se abre por defecto al iniciar la DAW.';

  @override
  String stackAddVersionsConfirm(int count) {
    return 'Añadir $count';
  }

  @override
  String get stackAddVersionMultiTitle => 'Añadir versiones';

  @override
  String get stackSelectAll => 'Seleccionar todo';

  @override
  String get stackClearSelection => 'Borrar';

  @override
  String stackMetadataPartsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partes',
      one: '1 parte',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataDeadlineLabel => 'fecha límite';

  @override
  String get stackMetadataRenamedLabel => 'nombre personalizado';

  @override
  String stackMetadataWorkHours(String hours) {
    return '$hours h registradas';
  }

  @override
  String get stackUnstackReleaseTitle =>
      '¿Qué versión permanece en el lanzamiento?';

  @override
  String stackUnstackReleaseBody(String releases) {
    return 'Este proyecto es una pista en $releases. Desapilar elimina la entrada apilada, así que una de sus versiones debe ocupar ese lugar: elige a cuál debe apuntar el lanzamiento.';
  }

  @override
  String get stackAutoConfirmTitle => '¿Apilar estas versiones?';

  @override
  String stackAutoConfirmBody(int projects, int folders) {
    return 'La Pila de versiones agrupará $projects proyectos en $folders carpetas. Cada carpeta se convierte en un proyecto principal que comparte metadatos, tareas y tiempo de trabajo. No se elimina nada y puedes desapilarlos después.';
  }

  @override
  String get stackAutoConfirmApply => 'Apilar';

  @override
  String stackAutoFolderEntry(String folder, int count) {
    return '$folder — $count versiones';
  }

  @override
  String get stackAutoJoinsExisting => 'se une al proyecto principal existente';

  @override
  String get untitledTheme => 'Tema sin nombre';

  @override
  String switchToTheme(String themeName) {
    return 'Cambiar a $themeName';
  }

  @override
  String get newTheme => 'Nuevo tema';

  @override
  String get editTheme => 'Editar tema';

  @override
  String get duplicateTheme => 'Duplicar';

  @override
  String get deleteThemeTitle => '¿Eliminar tema?';

  @override
  String deleteThemeMessage(String name) {
    return '\"$name\" se eliminará. Esta acción no se puede deshacer.';
  }

  @override
  String get themeNameLabel => 'Nombre del tema';

  @override
  String get themeNameHint => 'p. ej. Ámbar de estudio';

  @override
  String get themeNameRequired => 'Ponle un nombre al tema.';

  @override
  String get themeColorAccent => 'Acento';

  @override
  String get themeColorSecondaryAccent => 'Acento secundario';

  @override
  String get themeColorBackground => 'Fondo';

  @override
  String get themeColorCards => 'Tarjetas y paneles';

  @override
  String get themeCardRoundness => 'Redondeo de las tarjetas';

  @override
  String get themeButtonRoundness => 'Redondeo de los botones';

  @override
  String themeLowContrastWarning(String ratio) {
    return 'Contraste bajo ($ratio:1). El texto puede costar de leer.';
  }

  @override
  String get exportTheme => 'Exportar tema';

  @override
  String get importTheme => 'Importar tema';

  @override
  String themeExported(String path) {
    return 'Tema exportado a $path';
  }

  @override
  String themeImported(String name) {
    return '\"$name\" importado';
  }

  @override
  String get themeImportFailed => 'Ese archivo no es un tema válido.';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexInvalid => 'Usa #RRGGBB';

  @override
  String get apply => 'Aplicar';

  @override
  String themeCopyName(String name) {
    return '$name copia';
  }

  @override
  String get suggestedColorsLabel => 'Colores Sugeridos';

  @override
  String get projectAppearance => 'Apariencia';

  @override
  String get projectAppearanceTooltip => 'Cambiar portada, color e icono';

  @override
  String get projectCoverArt => 'Portada';

  @override
  String get chooseCoverArt => 'Elegir imagen…';

  @override
  String get replaceCoverArt => 'Reemplazar imagen…';

  @override
  String get removeCoverArt => 'Quitar portada';

  @override
  String get removeCoverArtConfirm =>
      '¿Quitar la portada de este proyecto? Se eliminará la imagen guardada.';

  @override
  String get coverArtRemoved => 'Portada eliminada';

  @override
  String failedToRemoveCoverArt(String error) {
    return 'No se pudo quitar la portada: $error';
  }

  @override
  String get projectAccentColor => 'Color de acento';

  @override
  String get projectIcon => 'Icono';

  @override
  String get appearanceNone => 'Ninguno';

  @override
  String get appearanceNoneHint =>
      'Los proyectos no muestran color ni icono hasta que elijas uno. Toca de nuevo el icono seleccionado para quitarlo.';

  @override
  String get clearColorAndIcon => 'Quitar color e icono';

  @override
  String get dropCoverArtHere => 'Suelta una imagen para definir la portada';

  @override
  String get uploadingProjectCoverArt => 'Subiendo portadas de proyectos...';

  @override
  String get downloadingProjectCoverArt =>
      'Descargando portadas de proyectos...';
}
