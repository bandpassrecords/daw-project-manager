// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Gestore Progetti DAW';

  @override
  String get projectDetails => 'Dettagli del Progetto';

  @override
  String get back => 'Indietro';

  @override
  String get save => 'Salva';

  @override
  String get enable => 'Abilita';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get undo => 'Annulla';

  @override
  String get customInterval => 'Personalizzato';

  @override
  String get close => 'Chiudi';

  @override
  String get launch => 'Apri';

  @override
  String get view => 'Visualizza';

  @override
  String get openFolder => 'Apri Cartella';

  @override
  String get openInDaw => 'Avvia nel DAW';

  @override
  String get extract => 'Estrai';

  @override
  String get extracting => 'Estrazione…';

  @override
  String get extractingMetadata => 'Estrazione metadati...';

  @override
  String get deepScan => 'Scansione Approfondita';

  @override
  String get rescan => 'Riesegui Scansione';

  @override
  String get refreshProject => 'Aggiorna';

  @override
  String get scanning => 'Scansione in corso…';

  @override
  String get newProjectBadge => 'NUOVO';

  @override
  String get projectName => 'Nome del Progetto';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tonalità (es: C#m, F maggiore)';

  @override
  String get notes => 'Note';

  @override
  String get expandNotes => 'Espandi';

  @override
  String get collapseNotes => 'Comprimi';

  @override
  String get projectNotesFromDaw => 'Note del Progetto (dal file DAW)';

  @override
  String get projectPhase => 'Fase del Progetto';

  @override
  String get failedToLoad => 'Caricamento fallito';

  @override
  String get fileMissing => 'File mancante.';

  @override
  String launchingProject(String projectName) {
    return 'Apertura di $projectName…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return 'Impossibile aprire $projectName';
  }

  @override
  String get clearLibrary => 'Svuota Libreria';

  @override
  String get clearLibraryMessage =>
      'Questo rimuoverà tutti i progetti salvati e le cartelle sorgente. Continuare?';

  @override
  String get clear => 'Svuota';

  @override
  String get roots => 'Cartelle Progetti';

  @override
  String get pathsSettingsDangerZoneTitle => 'Libreria';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Svuota tutti i progetti e le cartelle di progetti del profilo corrente.';

  @override
  String get projectFoldersSectionTitle => 'Cartelle di progetti';

  @override
  String get projectFoldersSectionSubtitle =>
      'Cartelle che verranno scansionate per trovare progetti DAW.';

  @override
  String get projectFoldersEmptyTitle => 'Nessuna cartella di progetti';

  @override
  String get projectFoldersEmptySubtitle =>
      'Aggiungi almeno una cartella per iniziare a scansionare i progetti.';

  @override
  String get notScannedYet => 'Non ancora scansionato';

  @override
  String lastScan(String date) {
    return 'Ultima scansione: $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Cartelle escluse';

  @override
  String get excludedFoldersSectionSubtitle =>
      'Queste cartelle verranno saltate durante la scansione, anche se sono dentro una cartella di progetti.';

  @override
  String get addExcludedFolder => 'Aggiungi esclusa';

  @override
  String get selectExcludedFolder => 'Seleziona una cartella da escludere';

  @override
  String get excludedFoldersEmptyTitle => 'Nessuna cartella esclusa';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Opzionale: aggiungi cartelle che non vuoi mai scansionare.';

  @override
  String get removeExcludedFolderTitle => 'Rimuovere la cartella esclusa?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'Questa cartella non sarà più esclusa:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'Questa cartella non sarà più esclusa.';

  @override
  String get desktopOnlyPathsSettings =>
      'Questa pagina è disponibile solo nell’app desktop.';

  @override
  String get renameProjectFolderTitle => 'Display Name';

  @override
  String get flatpakPortalPathExplanation =>
      'This path is a sandboxed location, not the real folder location — Flatpak doesn\'t share that with the app. Use the name above to identify it instead.';

  @override
  String get removeProjectFolderTitle => 'Rimuovere la cartella di progetti?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Sei sicuro di voler rimuovere \"$path\"? Questo rimuoverà anche tutti i progetti in questa cartella che non sono nelle pubblicazioni.';
  }

  @override
  String get projects => 'Progetti';

  @override
  String get hidden => 'nascosti';

  @override
  String get profileManager => 'Gestore Profili';

  @override
  String get createNewProfile => 'Crea Nuovo Profilo';

  @override
  String get profileName => 'Nome del Profilo';

  @override
  String get create => 'Crea';

  @override
  String get profiles => 'Profili';

  @override
  String get active => 'Attivo';

  @override
  String get switchProfile => 'Cambia';

  @override
  String get edit => 'Modifica';

  @override
  String get delete => 'Elimina';

  @override
  String get addFolder => 'Aggiungi Cartella';

  @override
  String get searchProjects => 'Cerca progetti...';

  @override
  String get searchReleases => 'Cerca pubblicazioni...';

  @override
  String get searchPlaylists => 'Cerca playlist...';

  @override
  String get noReleasesFound => 'Nessuna pubblicazione trovata';

  @override
  String get noPlaylistsFound => 'Nessuna playlist trovata';

  @override
  String get tryDifferentSearch => 'Prova un termine di ricerca diverso';

  @override
  String get deepScanConfirm =>
      'La Scansione Approfondita estrae metadati completi dai file di progetto:\n• BPM (Battiti Per Minuto)\n• Tonalità Musicale\n• Versione del DAW\n• Note del Progetto (dove supportato)\n\nÈ più lenta di una scansione normale e potrebbe richiedere del tempo. Continuare?';

  @override
  String get deepScanViewSupportedDaws => 'Visualizza DAW e campi supportati';

  @override
  String get deepScanOnlyUnscanned =>
      'Scansiona solo i progetti senza metadati';

  @override
  String get metadataExtractionTitle => 'Estrazione Metadati';

  @override
  String get metadataExtractionSubtitle =>
      'Scopri quali dati supporta ciascuna DAW';

  @override
  String get metadataExtractionIntro =>
      'Deep Scan can automatically read some of these fields straight from a project file — the rest have to be entered by hand. This table shows what\'s automatic for each supported DAW today.';

  @override
  String get metadataFieldKey => 'Tonalità';

  @override
  String get metadataFieldVersion => 'Versione DAW';

  @override
  String get metadataExtractionManualNote =>
      'Qualsiasi campo senza supporto automatico può comunque essere inserito manualmente nel Dettaglio Progetto. In particolare per BPM e Tonalità, anche l\'inserimento di un file bpm.txt o key.txt accanto al progetto viene rilevato alla scansione successiva.';

  @override
  String get metadataExtractedSuccessfully => 'Metadati estratti con successo';

  @override
  String failedToExtractMetadata(String error) {
    return 'Estrazione metadati fallita: $error';
  }

  @override
  String get saved => 'Salvato';

  @override
  String get failedToLaunchDaw => 'Apertura DAW fallita';

  @override
  String get releaseDetails => 'Dettagli della Pubblicazione';

  @override
  String get releaseNotFound => 'Pubblicazione Non Trovata';

  @override
  String get error => 'Errore';

  @override
  String get loading => 'Caricamento...';

  @override
  String get deleteProfile => 'Elimina Profilo';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Sei sicuro di voler eliminare \"$profileName\"? Questo eliminerà tutti i progetti, cartelle progetti e pubblicazioni di questo profilo.';
  }

  @override
  String get editProfile => 'Modifica Profilo';

  @override
  String get changePhoto => 'Cambia Foto';

  @override
  String get remove => 'Rimuovi';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Sei sicuro di voler rimuovere \"$trackName\" da questa pubblicazione?';
  }

  @override
  String get saveName => 'Salva Nome';

  @override
  String get profilePhotoUpdated => 'Foto del profilo aggiornata.';

  @override
  String get profilePhotoRemoved => 'Foto del profilo rimossa.';

  @override
  String profileRenamed(String newName) {
    return 'Profilo rinominato in \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Profilo \"$name\" creato con successo';
  }

  @override
  String profileDeleted(String name) {
    return 'Profilo \"$name\" eliminato';
  }

  @override
  String get pleaseEnterProfileName => 'Inserisci un nome per il profilo';

  @override
  String failedToCreateProfile(String error) {
    return 'Creazione profilo fallita: $error';
  }

  @override
  String get noProfilesFound => 'Nessun profilo trovato. Creane uno sopra.';

  @override
  String get clearLibraryTooltip =>
      'Svuota Libreria (progetti e cartelle progetti)';

  @override
  String lastModified(String date) {
    return 'Ultima modifica: $date';
  }

  @override
  String get name => 'Nome';

  @override
  String get status => 'Stato';

  @override
  String get phase => 'Fase';

  @override
  String get filterByPhase => 'Filtra per Fase';

  @override
  String get filters => 'Filtri';

  @override
  String get allPhases => 'Tutte le Fasi';

  @override
  String get filterByDaw => 'Filtra per DAW';

  @override
  String get allDaws => 'Tutte le DAW';

  @override
  String get daw => 'DAW';

  @override
  String get clearDaw => 'Cancella DAW';

  @override
  String get filterByKey => 'Filtra per Tonalità';

  @override
  String get allKeys => 'Tutte le Tonalità';

  @override
  String get lastModifiedColumn => 'Ultima Modifica';

  @override
  String get actions => 'Azioni';

  @override
  String get hide => 'Nascondi';

  @override
  String get unhide => 'Mostra';

  @override
  String get extractMetadata => 'Estrai Metadati';

  @override
  String get createRelease => 'Crea Pubblicazione';

  @override
  String get clearSelection => 'Cancella Selezione';

  @override
  String get selectAllProjects => 'Seleziona tutti i progetti';

  @override
  String get switchingProfiles => 'Cambio profili...';

  @override
  String get scanningProjects => 'Scansione progetti...';

  @override
  String scanProgressLabel(int current, int total) {
    return 'Caricamento progetto $current di $total…';
  }

  @override
  String get search => 'Cerca';

  @override
  String get projectsTab => 'Progetti';

  @override
  String get releasesTab => 'Pubblicazioni';

  @override
  String get showHidden => 'Mostra Nascosti';

  @override
  String get showAll => 'Mostra Tutti';

  @override
  String get showOnlyHidden => 'Mostra Solo Nascosti';

  @override
  String get deleteRootPath => 'Rimuovi cartella di progetti';

  @override
  String deleteRootPathMessage(String path) {
    return 'Sei sicuro di voler rimuovere \"$path\"? Questo rimuoverà anche tutti i progetti da questa cartella che non sono nelle pubblicazioni.';
  }

  @override
  String rootsCount(int count) {
    return 'Cartelle Progetti: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Progetti: $count';
  }

  @override
  String get hiddenOnly => '(solo nascosti)';

  @override
  String hiddenCount(int count) {
    return '($count nascosti)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count progetto$plural nascosto$plural.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count progetto$plural mostrato$plural.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Errore nel nascondere progetti: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Errore nel mostrare progetti: $error';
  }

  @override
  String get deleteMissingProjects => 'Elimina mancanti';

  @override
  String get deleteMissingProjectsTitle => 'Eliminare i progetti mancanti?';

  @override
  String deleteMissingProjectsConfirm(int count, String plural) {
    return '$count progetto$plural il cui file non è stato trovato su questo computer verranno eliminati permanentemente, insieme a tutte le note, scadenze e cronologia delle sessioni. Questa azione non può essere annullata.';
  }

  @override
  String get deleteMissingProjectsConfirmButton => 'Elimina definitivamente';

  @override
  String missingProjectsDeleted(int count, String plural) {
    return '$count progetto$plural mancante eliminato.';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(
    int count,
    String plural,
  ) {
    return 'Elimina anche $count progetto$plural che fanno parte di una release (li rimuove anche da quella release)';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Sei sicuro di voler nascondere \"$projectName\"?';
  }

  @override
  String releaseCreated(String title) {
    return 'Pubblicazione \"$title\" creata con successo.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Creazione pubblicazione fallita: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Errore nell\'aggiungere cartella: $error';
  }

  @override
  String get folderAlreadyAdded => 'Questa cartella è già stata aggiunta.';

  @override
  String get noProjectsFoundInRoots =>
      'Nessun progetto trovato nelle cartelle progetti selezionate.';

  @override
  String get selectProjectsFolder => 'Seleziona una cartella di progetti';

  @override
  String get enterReleaseTitle => 'Inserisci il Titolo della Pubblicazione';

  @override
  String get releaseTitle => 'Titolo della Pubblicazione';

  @override
  String get enterReleaseTitleHint => 'Inserisci il titolo della pubblicazione';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Metadati estratti per $count progetto$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count fallito$plural.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Errore nella scrittura del file BPM: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Errore nella scrittura del file di tonalità: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Apertura fallita: $error';
  }

  @override
  String get libraryCleared => 'Libreria svuotata.';

  @override
  String scanType(String type) {
    return 'Scansione $type';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type completata: $count progetto$plural aggiunto$plural/aggiornato$plural.';
  }

  @override
  String get scanCancelled => 'Scan cancelled.';

  @override
  String scanFailuresSnackbar(int count, String plural) {
    return '$count progetto$plural non caricato/i.';
  }

  @override
  String get scanFailuresSnackbarAction => 'Dettagli';

  @override
  String get scanFailuresDialogTitle => 'Errori di Scansione';

  @override
  String get scanFailuresDialogIntro =>
      'Questi file non hanno potuto essere letti durante la scansione (potrebbero essere stati eliminati, spostati o bloccati da un altro programma):';

  @override
  String projectsSelected(int count, String plural) {
    return '$count progetto$plural selezionato$plural';
  }

  @override
  String openingFolder(String projectName) {
    return 'Apertura cartella per $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Errore nell\'apertura della cartella: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Sistema operativo non supportato per aprire la cartella.';

  @override
  String get noProjectsAvailable =>
      'Nessun progetto disponibile. Aggiungi prima dei progetti.';

  @override
  String get createNewRelease => 'Crea Nuova Pubblicazione';

  @override
  String get deleteRelease => 'Elimina Pubblicazione';

  @override
  String deleteReleaseMessage(String title) {
    return 'Sei sicuro di voler eliminare \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Pubblicazione \"$title\" eliminata.';
  }

  @override
  String get selectTracks => 'Seleziona Tracce';

  @override
  String get continueButton => 'Continua';

  @override
  String get noReleasesYet => 'Nessuna pubblicazione ancora';

  @override
  String get createFirstRelease =>
      'Crea la tua prima pubblicazione selezionando tracce dai tuoi progetti';

  @override
  String releasesCount(int count) {
    return 'Pubblicazioni ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Errore nel caricamento delle pubblicazioni: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Tracce ($count)';
  }

  @override
  String get addTracks => 'Aggiungi Tracce';

  @override
  String get allProjectsAlreadyInRelease =>
      'Tutti i progetti sono già in questa pubblicazione.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Aggiunta$plural $count traccia$plural alla pubblicazione.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'File della Pubblicazione ($count)';
  }

  @override
  String get addFiles => 'Aggiungi File';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Aggiunto$plural $count file$plural alla pubblicazione.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Errore nell\'aggiunta dei file: $error';
  }

  @override
  String get noFilesToDownload => 'Nessun file da scaricare.';

  @override
  String zipFileSaved(String path) {
    return 'File ZIP salvato in: $path';
  }

  @override
  String get creatingZipFile => 'Creazione del file ZIP...';

  @override
  String failedToCreateZip(String error) {
    return 'Errore nella creazione del ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'Il file selezionato non esiste.';

  @override
  String get imageSavedSuccessfully => 'Immagine salvata con successo!';

  @override
  String failedToSaveImage(String error) {
    return 'Errore nel salvataggio dell\'immagine: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Errore nel caricamento della pubblicazione: $error';
  }

  @override
  String get errorLoadingProjects =>
      'Errore nel caricamento dei progetti: null';

  @override
  String get releaseSaved => 'Pubblicazione salvata.';

  @override
  String get releaseDate => 'Data della Pubblicazione';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Errore nel salvataggio della data di pubblicazione: $error';
  }

  @override
  String get releaseDateSaved => 'Data di pubblicazione salvata.';

  @override
  String get releaseDateCleared => 'Data di pubblicazione cancellata.';

  @override
  String get saveReleaseFilesZip => 'Salva file ZIP della pubblicazione';

  @override
  String get failedToOpenFile => 'Impossibile aprire il file';

  @override
  String failedToPlayAudio(String error) {
    return 'Errore nella riproduzione audio: $error';
  }

  @override
  String get renameFile => 'Rinomina File';

  @override
  String get selectTracksToAdd => 'Seleziona Tracce da Aggiungere';

  @override
  String get fileNameUpdated => 'Nome del file aggiornato.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Errore nell\'aggiornamento del nome del file: $error';
  }

  @override
  String get deleteFile => 'Elimina File';

  @override
  String deleteFileMessage(String fileName) {
    return 'Sei sicuro di voler eliminare \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'File \"$fileName\" eliminato.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Errore nell\'eliminazione del file: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Impossibile aprire la cartella: $error';
  }

  @override
  String get artwork => 'Copertina';

  @override
  String get title => 'Titolo';

  @override
  String get tracks => 'Tracce';

  @override
  String get description => 'Descrizione';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Seleziona tracce da includere nella pubblicazione ($count selezionata$plural)';
  }

  @override
  String get searchTracks => 'Cerca tracce';

  @override
  String get searchTracksHint => 'Cerca per nome o tipo di DAW';

  @override
  String get noTracksFound => 'Nessuna traccia trovata';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get fileNotFound => 'File non trovato';

  @override
  String get fileName => 'Nome del File';

  @override
  String get editTodo => 'Modifica Attività';

  @override
  String get todoText => 'Testo dell\'attività';

  @override
  String get enterTodoText => 'Inserisci il testo dell\'attività';

  @override
  String get addNewTodo => 'Aggiungi nuova attività';

  @override
  String get enterTodoItem => 'Inserisci l\'elemento dell\'attività';

  @override
  String addTodoAtTimestamp(String timestamp) {
    return 'Aggiungi attività a $timestamp';
  }

  @override
  String todoAddedAtTimestamp(String timestamp) {
    return 'Attività aggiunta a $timestamp';
  }

  @override
  String get todoList => 'Lista Attività';

  @override
  String get todoTemplates => 'Modelli TODO';

  @override
  String get createTemplate => 'Crea Modello';

  @override
  String get editTemplate => 'Modifica Modello';

  @override
  String get deleteTemplate => 'Elimina Modello';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Sei sicuro di voler eliminare il modello \"$name\"?';
  }

  @override
  String get templateName => 'Nome Modello';

  @override
  String get templateNameHint => 'es. Lista di Mixaggio';

  @override
  String get templateItems => 'Elementi del Modello';

  @override
  String get templateItemsHint => 'Un elemento per riga';

  @override
  String get templateNameAndItemsRequired => 'Nome e elementi sono obbligatori';

  @override
  String get templateItemsRequired => 'È richiesto almeno un elemento';

  @override
  String get templateCreated => 'Modello creato';

  @override
  String get templateUpdated => 'Modello aggiornato';

  @override
  String get templateDeleted => 'Modello eliminato';

  @override
  String get noTemplatesYet => 'Nessun modello ancora';

  @override
  String get createFirstTemplate => 'Crea il tuo primo modello TODO';

  @override
  String templateItemCount(int count) {
    return '$count elemento/i';
  }

  @override
  String get selectTemplate => 'Seleziona Modello';

  @override
  String get importFromTemplate => 'Importa da Modello';

  @override
  String get manageTemplates => 'Gestisci Modelli';

  @override
  String get noTemplatesAvailable =>
      'Nessun modello disponibile. Creane uno prima.';

  @override
  String templateImported(String name, int count) {
    return 'Modello \"$name\" importato ($count elementi)';
  }

  @override
  String get errorLoadingTemplates => 'Errore caricamento modelli';

  @override
  String get createProjectStartFrom => 'Come vuoi iniziare?';

  @override
  String get createProjectStartFromHint =>
      'Inizia da una cartella vuota o copia un modello registrato.';

  @override
  String get createProjectEmptyFolder => 'Cartella Vuota';

  @override
  String get createProjectFromTemplate => 'Da Modello';

  @override
  String get selectTemplateMainFile =>
      'Seleziona il File Principale del Modello';

  @override
  String get registerTemplate => 'Registra Modello';

  @override
  String get projectTemplates => 'Modelli di Progetto';

  @override
  String get searchTemplates => 'Cerca modelli...';

  @override
  String get createFirstProjectTemplate =>
      'Registra una cartella modello da riutilizzare per nuovi progetti';

  @override
  String get noMatchingTemplates => 'Nessun modello corrispondente';

  @override
  String get templateSourceMissing =>
      'Cartella di origine del modello non trovata';

  @override
  String get useTemplate => 'Usa';

  @override
  String get selectTemplatesParentFolder =>
      'Seleziona la Cartella Principale dei Modelli';

  @override
  String get templateSourceFolder => 'Cartella di Origine';

  @override
  String get dateCreatedColumn => 'Creato';

  @override
  String get dateModifiedColumn => 'Modificato';

  @override
  String get manageTemplateFolders => 'Gestisci Cartelle';

  @override
  String get addTemplateFolder => 'Aggiungi Cartella';

  @override
  String get removeTemplateFolder => 'Rimuovi Cartella Modello';

  @override
  String removeTemplateFolderConfirm(String path) {
    return 'Rimuovere \"$path\" dalle cartelle modello registrate? I modelli già importati non verranno eliminati.';
  }

  @override
  String get noTemplateFoldersRegistered =>
      'Nessuna cartella modello registrata';

  @override
  String get refreshTemplateFolders =>
      'Aggiorna i modelli dalle cartelle registrate';

  @override
  String lastRefreshed(String date) {
    return 'Ultimo aggiornamento $date';
  }

  @override
  String templatesRefreshedSummary(int count) {
    return '$count nuovo/i modello/i aggiunto/i';
  }

  @override
  String templatesSelected(int count, String plural) {
    return '$count modello$plural selezionato$plural';
  }

  @override
  String get deleteSelectedTemplates => 'Elimina selezione';

  @override
  String deleteSelectedTemplatesConfirm(int count, String plural) {
    return 'Eliminare $count modello$plural?';
  }

  @override
  String templatesDeleted(int count, String plural) {
    return '$count modello$plural eliminato$plural';
  }

  @override
  String get templateDetailTitle => 'Template';

  @override
  String get templateNotFound => 'Template not found';

  @override
  String get saveAsTemplate => 'Save as Template';

  @override
  String get newTemplateNameLabel => 'Template name';

  @override
  String get savedAsTemplate => 'Saved as template';

  @override
  String get duplicateTemplate => 'Duplicate';

  @override
  String get templateDuplicated => 'Template duplicated';

  @override
  String get fileInfo => 'File Info';

  @override
  String get fileSize => 'File Size';

  @override
  String get filePath => 'Path';

  @override
  String get fileModified => 'Last Modified';

  @override
  String projectsFromThisTemplate(int count) {
    return 'Projects Created From This Template ($count)';
  }

  @override
  String get noProjectsFromThisTemplate =>
      'No projects created from this template yet';

  @override
  String get importTodos => 'Importa Attività da File';

  @override
  String get noTodosInFile => 'Nessuna attività trovata nel file';

  @override
  String todosImported(int count) {
    return '$count attività importata/e con successo';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Errore nell\'importazione: $error';
  }

  @override
  String get addToRelease => 'Aggiungi alla Pubblicazione';

  @override
  String get createNew => 'Crea Nuovo';

  @override
  String get addToExisting => 'Aggiungi all\'Esistente';

  @override
  String get createAndAdd => 'Crea e Aggiungi';

  @override
  String get selectRelease => 'Seleziona una pubblicazione';

  @override
  String get noExistingReleasesFound =>
      'Nessuna pubblicazione esistente trovata.';

  @override
  String get addToSelectedRelease => 'Aggiungi alla Pubblicazione Selezionata';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Errore nel salvataggio della foto del profilo: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Errore nella rimozione della foto del profilo: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Errore nel rinominare il profilo: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Errore nell\'eliminazione del profilo: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Errore nel caricamento dei profili: $error';
  }

  @override
  String get projectPhaseIdea => 'Idea';

  @override
  String get projectPhaseArranging => 'Arrangiamento';

  @override
  String get projectPhaseMixing => 'Mixaggio';

  @override
  String get projectPhaseMastering => 'Masterizzazione';

  @override
  String get projectPhaseFinished => 'Completato';

  @override
  String get changeStatus => 'Cambia Fase';

  @override
  String get selectNewStatus => 'Seleziona la nuova fase:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Fase cambiata in \"$status\" per $count progetto$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Fase cambiata in \"$status\" per $successCount progetto$successPlural, $failCount fallito$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Errore nel cambiare fase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Modifica nome profilo';

  @override
  String get tooltipAddTodo => 'Aggiungi attività';

  @override
  String get tooltipClearDate => 'Cancella data';

  @override
  String get tooltipPickDate => 'Scegli data';

  @override
  String get tooltipViewDetails => 'Visualizza Dettagli';

  @override
  String get tooltipLaunchInDaw => 'Apri nel DAW';

  @override
  String get tooltipRemoveFromRelease => 'Rimuovi dalla Pubblicazione';

  @override
  String get profile => 'Profilo';

  @override
  String get noDateSet => 'Nessuna data impostata';

  @override
  String get imageNotFound => 'Immagine non trovata';

  @override
  String get clickToBrowseArtwork => 'Clicca per cercare artwork';

  @override
  String get dropImageHere => 'Trascina l\'immagine qui';

  @override
  String get removeArtwork => 'Rimuovi copertina';

  @override
  String get removeArtworkConfirm =>
      'Rimuovere questa copertina? Il file immagine verrà eliminato.';

  @override
  String get noFilesAddedYet =>
      'Nessun file aggiunto ancora.\nClicca su \"Aggiungi File\" per caricare i file della pubblicazione.';

  @override
  String get noTodosYet => 'Nessuna attività ancora. Aggiungine una sopra.';

  @override
  String get done => 'Fatto';

  @override
  String get backupAndRestore => 'Backup e Ripristino';

  @override
  String get backupTabLabel => 'Backup';

  @override
  String get aboutTabLabel => 'Informazioni';

  @override
  String get localBackup => 'Backup Locale';

  @override
  String get appearanceTabLabel => 'Aspetto';

  @override
  String get exportBackup => 'Esporta Backup';

  @override
  String get importBackup => 'Importa Backup';

  @override
  String get exportProjectInfo => 'Esporta info';

  @override
  String get exportProjectInfoTooltip =>
      'Salva le informazioni di questo progetto in un file di testo';

  @override
  String get exportAllProjectsInfo => 'Esporta tutti i progetti in TXT';

  @override
  String get exportAllProjectsInfoSubtitle =>
      'Salva un registro testuale delle informazioni di tutti i progetti, conservato anche dopo l\'eliminazione del file DAW';

  @override
  String get projectInfoExported => 'Informazioni del progetto esportate';

  @override
  String allProjectsInfoExported(int count) {
    return 'Informazioni esportate per $count progetti';
  }

  @override
  String failedToExportProjectInfo(String error) {
    return 'Impossibile esportare le informazioni del progetto: $error';
  }

  @override
  String get projectExportHeaderTitle => 'DAW PROJECT MANAGER — PROJECT EXPORT';

  @override
  String projectExportExportedLabel(String dateTime) {
    return 'Esportato: $dateTime';
  }

  @override
  String projectExportTotalProjectsLabel(int count) {
    return 'Progetti totali: $count';
  }

  @override
  String projectExportProjectLabel(String name) {
    return 'Progetto: $name';
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
    return 'Stato: $status';
  }

  @override
  String projectExportBpmLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String projectExportKeyLabel(String key) {
    return 'Tonalità: $key';
  }

  @override
  String projectExportKeyWithCamelotLabel(String key, String code) {
    return 'Tonalità: $key (Camelot $code)';
  }

  @override
  String projectExportFilePathLabel(String path) {
    return 'Percorso file: $path';
  }

  @override
  String projectExportFileSizeLabel(String size) {
    return 'Dimensione file: $size';
  }

  @override
  String projectExportFileCreatedLabel(String date) {
    return 'File creato: $date';
  }

  @override
  String projectExportAddedToLibraryLabel(String date) {
    return 'Aggiunto alla libreria: $date';
  }

  @override
  String projectExportLastModifiedLabel(String date) {
    return 'Ultima modifica: $date';
  }

  @override
  String projectExportDeadlineLabel(String date) {
    return 'Scadenza: $date';
  }

  @override
  String projectExportDeadlineWithStatusLabel(String date, String status) {
    return 'Scadenza: $date ($status)';
  }

  @override
  String projectExportTotalTimeWorkedLabel(String duration) {
    return 'Tempo totale lavorato: $duration';
  }

  @override
  String get projectExportNotesLabel => 'Note:';

  @override
  String get projectExportTodosLabel => 'Attività:';

  @override
  String projectExportWorkSessionsLabel(int count) {
    return 'Sessioni di lavoro ($count):';
  }

  @override
  String get noProjectsToExport => 'Nessun progetto da esportare';

  @override
  String get backupExportedSuccessfully => 'Backup esportato con successo';

  @override
  String failedToExportBackup(String error) {
    return 'Errore nell\'esportazione del backup: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup importato con successo: $projectsCount progetti, $rootsCount cartelle progetti, $releasesCount pubblicazioni';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Errore nell\'importazione del backup: $error';
  }

  @override
  String get importBackupMessage => 'Scegli come importare il backup:';

  @override
  String get mergeWithCurrentProfile => 'Unisci con il profilo attivo corrente';

  @override
  String get replaceCurrentProfile =>
      'Sostituisci completamente il profilo corrente (ATTENZIONE: Questo eliminerà tutti i dati del profilo corrente)';

  @override
  String get createNewProfileForImport =>
      'Crea un nuovo profilo per questi dati';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup importato nel nuovo profilo \"$profileName\": $projectsCount progetti, $rootsCount cartelle progetti, $releasesCount pubblicazioni';
  }

  @override
  String get noProfileSelected => 'Nessun profilo selezionato';

  @override
  String get exportBackupDialogTitle => 'Esporta Backup';

  @override
  String get importBackupDialogTitle => 'Importa Backup';

  @override
  String get invalidBackupFileFormat =>
      'Formato file di backup non valido: versione mancante';

  @override
  String get profileNameRequiredForNewProfile =>
      'Il nome del profilo è obbligatorio quando si crea un nuovo profilo';

  @override
  String get currentProfileRequired =>
      'Il profilo corrente è obbligatorio per la modalità unisci o sostituisci';

  @override
  String get previewSong => 'Brano di Anteprima';

  @override
  String get noPreviewSongTitle => 'Nessuna canzone di anteprima';

  @override
  String get noPreviewSongMessage =>
      'Questo progetto non ha una canzone di anteprima impostata. Seleziona un file audio per caricarlo e riprodurlo.';

  @override
  String get noPreviewSongDragHint =>
      'Puoi anche trascinare e rilasciare un file audio direttamente sulla riga del progetto nella tabella.';

  @override
  String get previewSongRemoved => 'Brano di anteprima rimosso';

  @override
  String get previewSongAdded => 'Brano di anteprima aggiunto';

  @override
  String get previewSongFileNotFound =>
      'File del brano di anteprima non trovato';

  @override
  String get previewSongFileNotFoundMessage =>
      'Il file della canzone di anteprima non è stato trovato sul disco. Vuoi selezionare un nuovo file o rimuovere la voce?';

  @override
  String get selectNewFile => 'Seleziona nuovo file';

  @override
  String failedToPlayPreview(String error) {
    return 'Impossibile riprodurre l\'anteprima: $error';
  }

  @override
  String get removePreviewSong => 'Rimuovi brano di anteprima';

  @override
  String get removePreviewSongConfirm =>
      'Sei sicuro di voler rimuovere il brano di anteprima? Questa azione non può essere annullata.';

  @override
  String get noPreviewSongSelected => 'Nessun brano di anteprima selezionato';

  @override
  String get changePreviewSong => 'Cambia Brano di Anteprima';

  @override
  String get selectPreviewSong => 'Seleziona Brano di Anteprima';

  @override
  String get dropAudioFileHere => 'Rilascia il file audio qui';

  @override
  String projectAge(String age) {
    return 'Età del progetto: $age';
  }

  @override
  String createdDate(String date) {
    return 'creato $date';
  }

  @override
  String completedIn(String duration) {
    return 'Completato in: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'completato $date';
  }

  @override
  String get dateToday => 'oggi';

  @override
  String get dateYesterday => 'ieri';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settimane fa',
      one: '1 settimana fa',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesi fa',
      one: '1 mese fa',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anni fa',
      one: '1 anno fa',
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
    return '$years ann$yearPlural, $months mes$monthPlural';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years ann$plural';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months mes$monthPlural, $days giorn$dayPlural';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months mes$plural';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days giorn$plural';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours or$plural';
  }

  @override
  String get ageJustNow => 'Proprio adesso';

  @override
  String get ageLessThanHour => 'Meno di un\'ora';

  @override
  String get viewProfile => 'Visualizza Profilo';

  @override
  String get googleDriveSync => 'Sincronizzazione Google Drive';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Sincronizza i tuoi dati con Google Drive per eseguire backup e ripristinare tra i dispositivi.';

  @override
  String get manageGoogleDriveSync => 'Gestisci Sincronizzazione Google Drive';

  @override
  String get signInToGoogleDrive => 'Accedi a Google Drive';

  @override
  String get syncNow => 'Sincronizza Ora';

  @override
  String get uploadBackup => 'Carica Backup';

  @override
  String get downloadBackup => 'Scarica Backup';

  @override
  String get newerBackupAvailable => 'Nuovo backup disponibile nel cloud';

  @override
  String get restoreProjectFromDrive => 'Ripristina da Drive';

  @override
  String get restoringProjectFromDrive => 'Ripristino da Drive...';

  @override
  String get projectRestoredFromDrive => 'Progetto ripristinato da Drive';

  @override
  String get projectNotFoundInBackup =>
      'Questo progetto non è stato trovato nel backup di Drive';

  @override
  String get signInToGoogleDriveFirst =>
      'Accedi prima a Google Drive (apri le impostazioni di Drive Sync)';

  @override
  String get signOut => 'Esci';

  @override
  String get downloadPreviewSongs => 'Scarica canzoni di anteprima';

  @override
  String get downloadPreviewSongsExplanation =>
      'Se deselezionato, le canzoni di anteprima verranno saltate (risparmia tempo e spazio). Puoi scaricarle in seguito se necessario.';

  @override
  String get replaceLocalData => 'Sostituisci Dati Locali';

  @override
  String get downloadBackupConfirmation =>
      'Questo sostituirà i tuoi dati locali con il backup da Google Drive.\n\nSei sicuro di voler continuare?';

  @override
  String get enterAuthorizationCode => 'Inserisci Codice di Autorizzazione';

  @override
  String get authorizationCode => 'Codice di Autorizzazione';

  @override
  String get pasteCodeFromBrowser => 'Incolla il codice dal browser';

  @override
  String get sessionActive => 'Sessione attiva';

  @override
  String get signedIn => 'Connesso';

  @override
  String get creatingInitialBackup => 'Creazione backup iniziale...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Accesso riuscito e backup creato su Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Accesso riuscito e backup creato su Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Accesso riuscito a Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Accesso riuscito a Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Accesso annullato o fallito. Controlla la console per i dettagli.';

  @override
  String get failedToLaunchBrowser => 'Impossibile avviare il browser';

  @override
  String get signInCancelled => 'Accesso annullato';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Impossibile scambiare il codice di autorizzazione';

  @override
  String errorSigningIn(String error) {
    return 'Errore durante l\'accesso: $error';
  }

  @override
  String get unknownError => 'Errore sconosciuto';

  @override
  String get googleSignInError => 'Errore di Accesso Google';

  @override
  String get developerConsoleNotSetUp =>
      'La console sviluppatore non è configurata correttamente. Controlla la tua configurazione OAuth nella Google Cloud Console.';

  @override
  String get platformError => 'Errore di Piattaforma';

  @override
  String get signedOutFromGoogleDrive => 'Disconnesso da Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Errore durante la disconnessione: $error';
  }

  @override
  String get syncing => 'Sincronizzazione...';

  @override
  String get errorNoProfileSelected => 'Errore: Nessun profilo selezionato';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Sincronizzazione completata! Progetti: +$projectsAdded ~$projectsUpdated, Pubblicazioni: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Errore durante la sincronizzazione: $error';
  }

  @override
  String get uploadingBackup => 'Caricamento backup...';

  @override
  String get backupUploadedSuccessfully => 'Backup caricato con successo!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Backup caricato con successo su Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Errore durante il caricamento del backup: $error';
  }

  @override
  String get downloadingBackup => 'Download backup...';

  @override
  String get checkingForBackup => 'Controllo backup...';

  @override
  String get backupUpToDate => 'Il backup è aggiornato';

  @override
  String errorCheckingBackup(String error) {
    return 'Errore durante il controllo del backup: $error';
  }

  @override
  String get download => 'Scarica';

  @override
  String get remoteBackupIsNewer =>
      'Il backup remoto è più recente dei dati locali. Il caricamento lo sovrascriverà.';

  @override
  String get confirmUpload => 'Conferma caricamento';

  @override
  String get noBackupFileFound =>
      'Nessun file di backup trovato in Google Drive. Crea prima un backup sincronizzando i tuoi dati.';

  @override
  String get noBackupFileFoundStatus =>
      'Nessun file di backup trovato. Crea prima un backup.';

  @override
  String get downloadCancelled => 'Download annullato';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Backup scaricato! Progetti: +$projectsAdded ~$projectsUpdated, Pubblicazioni: +$releasesAdded ~$releasesUpdated';
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
    return 'Backup scaricato!\n\nProgetti:\n  • $projectsAdded aggiunti\n  • $projectsUpdated aggiornati\n\nPubblicazioni:\n  • $releasesAdded aggiunte\n  • $releasesUpdated aggiornate\n\nPreview Songs:\n  • $previewSongsDownloaded scaricate\n  • $previewSongsUpdated aggiornate';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Errore durante il download del backup: $error';
  }

  @override
  String get notSignedInYet => 'Non connesso';

  @override
  String get never => 'Mai';

  @override
  String signedInAs(String email) {
    return 'Connesso come: $email';
  }

  @override
  String lastSync(String date) {
    return 'Ultima sincronizzazione: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Backup remoto: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Ultimo caricamento: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Ultimo scaricamento: $date';
  }

  @override
  String get checkForBackup => 'Controlla Backup';

  @override
  String get notificationSettings => 'Impostazioni Notifiche';

  @override
  String get notificationsOnlyOnAndroid =>
      'Le notifiche di scadenza sono disponibili solo su dispositivi Android.';

  @override
  String get notificationPermissionRequired => 'Permesso di Notifica Richiesto';

  @override
  String get notificationPermissionDescription =>
      'Si prega di abilitare le notifiche per ricevere promemoria di scadenza.';

  @override
  String get notificationPermissionDenied =>
      'Permesso di notifica negato. Si prega di abilitarlo nelle impostazioni.';

  @override
  String get notificationSettingsSaved =>
      'Impostazioni di notifica salvate con successo';

  @override
  String get errorSavingSettings => 'Errore nel salvataggio delle impostazioni';

  @override
  String get enableDeadlineNotifications => 'Abilita Notifiche di Scadenza';

  @override
  String get receiveRemindersForDeadlines =>
      'Ricevi promemoria per le scadenze dei progetti';

  @override
  String get notificationTime => 'Ora di Notifica';

  @override
  String get timeToReceiveNotifications =>
      'Ora del giorno per ricevere le notifiche';

  @override
  String get reminderDays => 'Giorni di Promemoria';

  @override
  String get selectDaysBeforeDeadline =>
      'Seleziona quanti giorni prima della scadenza desideri essere notificato';

  @override
  String get notifyOnDeadlineDay => 'Notifica il Giorno della Scadenza';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Ricevi anche una notifica il giorno stesso della scadenza';

  @override
  String get howItWorks => 'Come Funziona';

  @override
  String get deadlineNotificationsHelp =>
      'Riceverai notifiche all\'ora specificata nei giorni selezionati prima di ogni scadenza del progetto. Tocca una notifica per aprire i dettagli del progetto.';

  @override
  String get oneDay => '1 giorno';

  @override
  String xDays(int count) {
    return '$count giorni';
  }

  @override
  String get settings => 'Impostazioni';

  @override
  String get searchSettings => 'Cerca nelle impostazioni';

  @override
  String noSettingsFoundFor(String query) {
    return 'Nessuna impostazione trovata per \"$query\"';
  }

  @override
  String get language => 'Lingua';

  @override
  String get theme => 'Tema';

  @override
  String get languageSettingDescription =>
      'La lingua utilizzata in tutta l\'app.';

  @override
  String get themeSettingDescription => 'Il tema colore dell\'app.';

  @override
  String get waveformStyle => 'Stile della forma d’onda';

  @override
  String get waveformStyleSettingDescription =>
      'Come viene disegnata la forma d’onda dell’anteprima audio.';

  @override
  String get waveformStyleDetailed => 'Dettagliato';

  @override
  String get waveformStyleDetailedDescription =>
      'Barre per pixel con corpo sfumato, come in una DAW.';

  @override
  String get waveformStyleClassic => 'Classico';

  @override
  String get waveformStyleClassicDescription => 'Un unico contorno pieno.';

  @override
  String get waveformChannels => 'Canali';

  @override
  String get waveformChannelsSettingDescription =>
      'Se la forma d’onda divide lo stereo in due tracce.';

  @override
  String get waveformChannelsSingle => 'Singolo';

  @override
  String get waveformChannelsDual => 'Doppio';

  @override
  String get waveformChannelsSingleDescription =>
      'Una traccia con il mix stereo.';

  @override
  String get waveformChannelsDualDescription =>
      'Sinistra e destra impilate come tracce separate.';

  @override
  String get waveformChannelsUnavailable => 'Questo file ha un solo canale';

  @override
  String get support => 'Supporta';

  @override
  String get shareDiagnosticLog => 'Condividi registro diagnostico';

  @override
  String get shareDiagnosticLogEmpty => 'Nessun registro diagnostico ancora';

  @override
  String get shareDiagnosticLogFolderOpened =>
      'La condivisione non è disponibile qui. È stata aperta la cartella dei log per allegare il file manualmente.';

  @override
  String get enableDiagnosticLogging => 'Attiva registrazione diagnostica';

  @override
  String get enableDiagnosticLoggingDescription =>
      'Mantiene un piccolo registro di arresti anomali ed errori su questo dispositivo, così puoi condividerlo in caso di problemi. Disattivato per impostazione predefinita.';

  @override
  String get clearDiagnosticLog => 'Cancella registro diagnostico';

  @override
  String get clearDiagnosticLogConfirmTitle =>
      'Cancellare il registro diagnostico?';

  @override
  String get clearDiagnosticLogConfirmMessage =>
      'Questa azione eliminerà definitivamente il file di registro diagnostico e non può essere annullata.';

  @override
  String get diagnosticLogCleared => 'Registro diagnostico cancellato';

  @override
  String get supportTheProject => 'Sostieni il progetto';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Impossibile aprire il browser. Si prega di visitare: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Errore durante l\'apertura del browser: $error';
  }

  @override
  String get generateTestingDatabase => 'Genera Database di Test';

  @override
  String get generateTestingDatabaseMessage =>
      'Questo creerà (o aggiornerà) un profilo dedicato \"Demo — Screenshots\" pieno di una vasta varietà di progetti, pubblicazioni e playlist di esempio per tutte le DAW supportate, e passerà a esso. I tuoi altri profili rimarranno invariati. Continuare?';

  @override
  String get testingDatabaseGenerated =>
      'Profilo demo pronto — passato ad esso!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Errore nella generazione del database di test: $error';
  }

  @override
  String get removeTestingDatabase => 'Rimuovi database di test';

  @override
  String get removeTestingDatabaseMessage =>
      'Questo eliminerà definitivamente il profilo \"Demo — Screenshots\" e tutti i suoi progetti, pubblicazioni, playlist e file audio di anteprima di esempio. Continuare?';

  @override
  String get testingDatabaseRemoved => 'Dati demo rimossi.';

  @override
  String get noTestingDatabaseFound => 'Nessun dato demo trovato da rimuovere.';

  @override
  String failedToRemoveTestingDatabase(String error) {
    return 'Errore nella rimozione del database di test: $error';
  }

  @override
  String get playlists => 'Playlist';

  @override
  String get playlistsDesktopOnly =>
      'Le playlist sono disponibili solo su Android.';

  @override
  String get noPlaylistsYet => 'Nessuna playlist ancora';

  @override
  String get createFirstPlaylist => 'Tocca + per creare la tua prima playlist';

  @override
  String playlistSongCount(int count) {
    return '$count brani';
  }

  @override
  String get createPlaylist => 'Crea Playlist';

  @override
  String get playlistName => 'Nome Playlist';

  @override
  String get playlistNameHint => 'La Mia Playlist';

  @override
  String get playlistNameRequired => 'Nome playlist richiesto';

  @override
  String get editPlaylist => 'Modifica Playlist';

  @override
  String get stopPlaybackBeforeEditing =>
      'Si prega di interrompere la riproduzione prima di modificare la playlist';

  @override
  String get selectPreviewSongs => 'Seleziona Anteprime';

  @override
  String get deletePlaylist => 'Elimina Playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?';
  }

  @override
  String get playlistDeleted => 'Playlist eliminata';

  @override
  String get errorDeletingPlaylist =>
      'Errore durante l\'eliminazione della playlist';

  @override
  String get playlistUpdated => 'Playlist aggiornata';

  @override
  String get changeSong => 'Cambia Canzone';

  @override
  String get changeSongConfirm =>
      'Una canzone è in riproduzione. Vuoi passare a questa canzone?';

  @override
  String get changeSongButton => 'Cambia';

  @override
  String playlistProgress(int current, int total) {
    return '$current di $total';
  }

  @override
  String get noPreviewSongsInPlaylist =>
      'Nessuna anteprima disponibile in questa playlist';

  @override
  String get tapEditToAddSongs =>
      'Tocca modifica per aggiungere canzoni a questa playlist';

  @override
  String get noProjectsAvailableForPlaylist =>
      'Nessun progetto con canzoni di anteprima disponibili da aggiungere';

  @override
  String get noProjectsInDatabase =>
      'Nessun progetto trovato nel database. Per favore sincronizza prima i tuoi progetti.';

  @override
  String get firstTimeSyncTitle => 'Sembra che sia la tua prima volta qui!';

  @override
  String get firstTimeSyncMessage =>
      'Sincronizziamo i tuoi dati da Google Drive per iniziare';

  @override
  String get syncWithGoogleDrive => 'Sincronizza con Google Drive';

  @override
  String get errorLoadingPlaylists => 'Errore caricamento playlist';

  @override
  String get playlistItems => 'Elementi Playlist';

  @override
  String get addSongs => 'Aggiungi Brani';

  @override
  String get addAudioFiles => 'Aggiungi File Audio';

  @override
  String get selectAudioFiles => 'Seleziona File Audio';

  @override
  String get selectFromProjects => 'Seleziona da Progetti';

  @override
  String get add => 'Aggiungi';

  @override
  String get addTaskAtTimestamp => 'Aggiungi attività al momento attuale';

  @override
  String get taskDescriptionHint => 'Descrizione dell\'attività';

  @override
  String get taskAdded => 'Attività aggiunta';

  @override
  String get fromProject => 'Dal Progetto';

  @override
  String get projectDeadline => 'Scadenza Progetto';

  @override
  String get noDeadlineSet => 'Nessuna scadenza';

  @override
  String get camelotCode => 'Codice Camelot';

  @override
  String get deadline => 'Scadenza';

  @override
  String get dueToday => 'Scade oggi';

  @override
  String daysLate(int days) {
    return '${days}g in ritardo';
  }

  @override
  String daysLeft(int days) {
    return '${days}g rimanenti';
  }

  @override
  String get hideFinished => 'Nascondi Finiti';

  @override
  String get showOnlyDeadlines => 'Mostra scadenza';

  @override
  String get filterByDeadline => 'Filtra per Scadenza';

  @override
  String get allDeadlines => 'Tutte le Scadenze';

  @override
  String get hasDeadline => 'Con Scadenza';

  @override
  String get overdue => 'Scaduto';

  @override
  String get dueSoon => 'Prossima Scadenza (7g)';

  @override
  String get today => 'Oggi';

  @override
  String get noPreviewSong => 'Nessuna anteprima';

  @override
  String get playPreview => 'Riproduci Anteprima';

  @override
  String get uploadCancelled => 'Caricamento annullato';

  @override
  String get backupUploadCancelledByUser =>
      'Caricamento backup annullato dall\'utente';

  @override
  String get collectingData => 'Raccolta dati...';

  @override
  String get uploadingPreviewSongs => 'Caricamento anteprime musicali...';

  @override
  String get uploadingProfilePhotos => 'Caricamento foto profilo...';

  @override
  String get uploadingReleaseArtwork => 'Caricamento artwork pubblicazioni...';

  @override
  String get uploadingDatabase => 'Caricamento database...';

  @override
  String get completed => 'Completato!';

  @override
  String get cancelling => 'Annullamento...';

  @override
  String get uploadingBackupTitle => 'Caricamento Backup';

  @override
  String get cancellingUpload => 'Annullamento caricamento...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Attendi mentre interrompiamo il caricamento...';

  @override
  String get downloadingDatabase => 'Scaricamento database...';

  @override
  String get downloadingPreviewSongs => 'Scaricamento canzoni di anteprima...';

  @override
  String get downloadingProfilePhotos => 'Scaricamento foto profilo...';

  @override
  String get downloadingReleaseArtwork =>
      'Scaricamento artwork pubblicazioni...';

  @override
  String get mergingData => 'Unione dati...';

  @override
  String get downloadingBackupTitle => 'Scaricamento Backup';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'File sorgente non trovato su questa macchina';

  @override
  String get metadataExtractionNotSupportedForDaw =>
      'L\'estrazione dei metadati non è supportata per questa DAW';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'File sorgente non trovato su questa macchina — modalità solo metadati. Puoi comunque modificare ed esportare i metadati.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Anteprima non disponibile. Scarica prima il backup.';

  @override
  String get sharePreviewSong => 'Condividi anteprima';

  @override
  String get shareAsZip => 'Condividi come ZIP';

  @override
  String get share => 'Condividi';

  @override
  String get convertingAudioForSharing =>
      'Preparazione dell\'audio per la condivisione…';

  @override
  String get shareSheetUnavailable =>
      'Il menu di condivisione di sistema non è disponibile qui — usa il pulsante \"Trascina per Condividere\" nell\'anteprima del brano per trascinare il file su un\'altra app.';

  @override
  String get dragToShare => 'Trascina per Condividere';

  @override
  String get dragToShareTooltip =>
      'Trascina questo sulla finestra di un\'altra app (es: WhatsApp) per condividere il file direttamente — utile quando il pulsante Condividi non apre un menu di condivisione.';

  @override
  String get mp3ConversionFailed =>
      'La conversione audio non è disponibile su questo sistema — verrà condiviso il file originale, che alcune app come WhatsApp potrebbero rifiutare.';

  @override
  String get shareZip => 'Condividi ZIP';

  @override
  String get saveCopy => 'Salva copia';

  @override
  String savedCopyTo(String path) {
    return 'Salvato in $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Impossibile condividere l\'anteprima: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Impossibile condividere l\'anteprima come ZIP: $error';
  }

  @override
  String get biographySaved => 'Biografia salvata';

  @override
  String failedToSaveBiography(String error) {
    return 'Impossibile salvare la biografia: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'File salvato in $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Impossibile scaricare il file: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'Tutti i file salvati in $filename';
  }

  @override
  String get artworkAdded => 'Artwork aggiunto';

  @override
  String failedToAddArtwork(String error) {
    return 'Impossibile aggiungere l\'artwork: $error';
  }

  @override
  String get artworkRemoved => 'Artwork rimosso';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Impossibile rimuovere l\'artwork: $error';
  }

  @override
  String get pressKitFileAdded => 'File press kit aggiunto';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Impossibile aggiungere il file press kit: $error';
  }

  @override
  String get pressKitFileRemoved => 'File press kit rimosso';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Impossibile rimuovere il file press kit: $error';
  }

  @override
  String get selectFilesToDownload => 'Seleziona file da scaricare';

  @override
  String get biography => 'Biografia';

  @override
  String get biographyWillBeSaved => 'Verrà salvata come biography.txt';

  @override
  String get artworkFiles => 'File artwork';

  @override
  String get pressKitFiles => 'File press kit';

  @override
  String get additionalAssets => 'Asset aggiuntivi';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Scarica $count file$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count file$plural salvati in $filename';
  }

  @override
  String get addAsset => 'Aggiungi asset';

  @override
  String get assetNameLabel => 'Nome asset';

  @override
  String get assetNameHint => 'es. Logo, Banner, Foto';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName aggiunto con successo';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Impossibile aggiungere l\'asset: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName rimosso';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Impossibile rimuovere l\'asset: $error';
  }

  @override
  String get profileNotFound => 'Profilo non trovato';

  @override
  String get downloadFilesSectionTitle => 'Scarica File';

  @override
  String get downloadFilesSectionDescription =>
      'Scarica tutti i file di questo profilo — biografia, copertina, press kit e asset aggiuntivi — come un unico file ZIP, oppure seleziona quali includere.';

  @override
  String get selectFiles => 'Seleziona file';

  @override
  String get downloadAll => 'Scarica tutto';

  @override
  String get saveBiographyTooltip => 'Salva biografia';

  @override
  String get enterBiographyHint => 'Inserisci la biografia del profilo...';

  @override
  String get addArtwork => 'Aggiungi artwork';

  @override
  String get addFile => 'Aggiungi file';

  @override
  String get openFile => 'Apri file';

  @override
  String get menuView => 'Visualizza';

  @override
  String get menuAbout => 'Informazioni su DAW Project Manager';

  @override
  String get menuDocumentation => 'Documentazione';

  @override
  String get menuLanguage => 'Lingua';

  @override
  String get menuWarnBeforeQuit => 'Avvisa prima di uscire (⌘+Q)';

  @override
  String get menuQuit => 'Esci da DAW Project Manager';

  @override
  String get quitConfirmTitle => 'Uscire da DAW Project Manager?';

  @override
  String get quitConfirmMessage => 'Vuoi davvero uscire?';

  @override
  String get quit => 'Esci';

  @override
  String get trayNoticeTitle => 'Ancora in esecuzione in background';

  @override
  String get trayNoticeBody =>
      'DAW Project Manager è stato ridotto nella barra di sistema. Usa l\'icona nella barra per riaprirlo o uscire.';

  @override
  String get trayShowWindow => 'Mostra DAW Project Manager';

  @override
  String trayLastBackup(String when) {
    return 'Ultimo backup: $when';
  }

  @override
  String get trayNeverBackedUp => 'Nessun backup eseguito';

  @override
  String get trayBackupNow => 'Esegui Backup Ora';

  @override
  String get trayPauseSession => 'Metti in Pausa la Sessione';

  @override
  String get trayResumeSession => 'Riprendi Sessione';

  @override
  String get closeToTray => 'Chiudi nella barra delle applicazioni';

  @override
  String get closeToTrayDescription =>
      'Continua a funzionare in background (icona nella barra) quando chiudi la finestra, così il backup automatico e le notifiche continuano a funzionare';

  @override
  String get autoStart => 'Avvia all\'accensione';

  @override
  String get autoStartDescription =>
      'Apri DAW Project Manager automaticamente all\'accesso al computer';

  @override
  String get startMinimized => 'Avvia ridotto nella barra';

  @override
  String get startMinimizedDescription =>
      'Quando l\'app si avvia con il computer, aprirla nascosta nella barra invece di mostrare la finestra';

  @override
  String get onboardingStartMinimized => 'Avvia ridotto';

  @override
  String get autoStartFailed =>
      'Impossibile modificare l\'impostazione di avvio. Il tuo sistema potrebbe non consentirlo.';

  @override
  String get onboardingStartupTitle => 'Avvia all\'Accensione';

  @override
  String get onboardingStartupBody =>
      'Fai aprire DAW Project Manager automaticamente all\'accesso, così i backup in background e i promemoria delle scadenze continuano a funzionare.';

  @override
  String get menuWindow => 'Finestra';

  @override
  String get donate => 'Dona';

  @override
  String get website => 'Sito web';

  @override
  String get license => 'Licenza';

  @override
  String get reportIssue => 'Segnala un problema';

  @override
  String get switchToClassicDark => 'Passa a Classic Dark';

  @override
  String get switchToNeonDark => 'Passa a Neon Dark';

  @override
  String get switchToClassicTheme => 'Passa al tema Classic';

  @override
  String get switchToNeonTheme => 'Passa al tema Neon';

  @override
  String get switchToStudioLight => 'Passa a Studio Light';

  @override
  String get menuTheme => 'Tema';

  @override
  String get appDescription =>
      'Un gestore di progetti per produttori musicali e sound designer.';

  @override
  String get neonDarkThemeName => 'Neon Scuro';

  @override
  String get classicDarkThemeName => 'Classico Scuro';

  @override
  String get studioLightThemeName => 'Studio Chiaro';

  @override
  String get statisticsTab => 'Statistiche';

  @override
  String get statsTotalProjects => 'Totale Progetti';

  @override
  String get statsInProgress => 'In corso';

  @override
  String get statsFinished => 'Completati';

  @override
  String get statsAvgCompletion => 'Completamento medio';

  @override
  String get statsPhaseDistribution => 'Progetti per Fase';

  @override
  String get statsAvgTimePerPhase => 'Giorni medi per Fase';

  @override
  String get statsProductivity => 'Produttività';

  @override
  String get statsCreatedSeries => 'Creati';

  @override
  String get statsProjectHealth => 'Età e Salute dei Progetti';

  @override
  String get statsCatalogInsights => 'Analisi del Catalogo';

  @override
  String get statsBpmDistribution => 'Distribuzione BPM';

  @override
  String get statsTopKeys => 'Tonalità principali';

  @override
  String get statsDawTypes => 'Tipi di DAW';

  @override
  String get statsProjectActivity => 'Attività dei Progetti';

  @override
  String get statsSingleProjectActivity => 'Attività del Progetto';

  @override
  String get statsNoData => 'Nessun dato';

  @override
  String get statsNoPhaseData =>
      'I dati sulle fasi appariranno dopo le transizioni di fase.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Ultima attività: $days giorni fa';
  }

  @override
  String get statsLastActivityToday => 'Attivo oggi';

  @override
  String get statsNoEvents => 'Nessun evento registrato';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Fase: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Aggiornato: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Completato: $text';
  }

  @override
  String get statsEventFileModified => 'File modificato su disco';

  @override
  String get statsClearHistory => 'Cancella cronologia';

  @override
  String get statsClearHistoryConfirm =>
      'Cancellare tutti gli eventi registrati per questo progetto?';

  @override
  String get statsSearchProjects => 'Cerca progetti…';

  @override
  String statsEventCount(int count) {
    return '$count eventi';
  }

  @override
  String get statsViewHistory => 'Statistiche Progetto';

  @override
  String get statsPhaseHistory => 'Cronologia Fasi';

  @override
  String get statsEventBreakdown => 'Riepilogo Eventi';

  @override
  String statsDaysSoFar(int days) {
    return '${days}g finora';
  }

  @override
  String get statsNoProjectsFound => 'Nessun progetto trovato';

  @override
  String statsNotTouchedDays(int days) {
    return 'Invariato da $days giorni';
  }

  @override
  String get sortByLastModified => 'Ultima modifica';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByPhase => 'Fase';

  @override
  String get sortByCreatedAt => 'Data aggiunta';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get sortNewestFirst => 'Più recenti prima';

  @override
  String get sortOldestFirst => 'Più vecchi prima';

  @override
  String get sortTitleAZ => 'Titolo A–Z';

  @override
  String get sortTitleZA => 'Titolo Z–A';

  @override
  String get musicPlayerTab => 'Lettore musicale';

  @override
  String get previewAudioChangedRefreshing =>
      'L\'audio di anteprima è cambiato su disco — aggiornamento della forma d\'onda…';

  @override
  String get audioFileChangedRefreshing =>
      'Il file audio è cambiato su disco — aggiornamento della forma d\'onda…';

  @override
  String get autoFitAllColumns => 'Adatta colonne';

  @override
  String get uploadAutoDetectedPreviewSongs =>
      'Carica brani di anteprima rilevati automaticamente';

  @override
  String get uploadAutoDetectedPreviewSongsSubtitle =>
      'Includi i brani trovati automaticamente dallo scanner, non solo quelli impostati manualmente.';

  @override
  String get monoGenerating => 'Mono…';

  @override
  String errorHandlingDroppedFiles(String error) {
    return 'Errore durante la gestione dei file trascinati: $error';
  }

  @override
  String get resetOnboardingConfirm =>
      'Questo riavvierà la procedura guidata di configurazione. Continuare?';

  @override
  String couldNotLaunchDaw(String daw, String error) {
    return 'Impossibile avviare $daw: $error';
  }

  @override
  String get couldNotOpenLink => 'Impossibile aprire il link.';

  @override
  String get githubButtonLabel => 'GitHub';

  @override
  String get monoLabel => 'Mono';

  @override
  String get monoToggleTooltip => 'Attiva/disattiva riproduzione mono';

  @override
  String get monoRequiresWav => 'Il mixaggio mono richiede un file WAV';

  @override
  String get monoUnsupportedFormat =>
      'Impossibile creare il mix mono — formato non supportato';

  @override
  String monoSwitchFailed(String error) {
    return 'Cambio mono fallito: $error';
  }

  @override
  String get analyzeLabel => 'Analizza';

  @override
  String get reAnalyzeLabel => 'Ri-analizza';

  @override
  String get analysisRequiresWav => 'L\'analisi richiede un file WAV';

  @override
  String get noResultsForFilter => 'Nessun risultato per il filtro corrente';

  @override
  String get noResultsForFilterHint =>
      'Prova a modificare la ricerca o i filtri.';

  @override
  String get noProjectsFound => 'Nessun progetto trovato';

  @override
  String get noProjectsFoundHint =>
      'Aggiungi una cartella radice nelle impostazioni per iniziare.';

  @override
  String get noProjectsFoundInFoldersHint =>
      'Prova ad aggiungere un\'altra cartella contenente progetti DAW.';

  @override
  String get queueTab => 'Attività';

  @override
  String get queueSearchHint => 'Cerca attività...';

  @override
  String get queueNoPendingTasks => 'Tutto in ordine!';

  @override
  String get queueNoPendingTasksHint =>
      'Nessuna attività in sospeso nei tuoi progetti.';

  @override
  String get queueNoMatchingTasks => 'Nessuna attività corrispondente';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks attività in sospeso in $projects progetti';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager $version';
  }

  @override
  String versionLabel(String version) {
    return 'Versione $version';
  }

  @override
  String get renameProjectFileTitle => 'Rinomina file di progetto';

  @override
  String get renameFileButtonLabel => 'Rinomina file';

  @override
  String get newFileNameLabel => 'Nuovo nome file (senza estensione)';

  @override
  String renameAlreadyExists(String name) {
    return 'Un file chiamato \"$name\" esiste già.';
  }

  @override
  String renameSuccess(String name) {
    return 'Rinominato in \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Rinomina fallita: $error';
  }

  @override
  String get nameCannotBeEmpty => 'Il nome non può essere vuoto';

  @override
  String get nameInvalidCharacters => 'Il nome non può contenere / \\ :';

  @override
  String get alsoRenameContainingFolder =>
      'Rinomina anche la cartella contenitore';

  @override
  String get renameButton => 'Rinomina';

  @override
  String get previewMixdownFolderTitle => 'Cartelle mixdown anteprima';

  @override
  String get previewMixdownFolderSubtitle =>
      'Nomi delle sottocartelle in ogni cartella di progetto da controllare per prime, in ordine, durante il rilevamento automatico dei brani di anteprima. Lascia vuoto per usare i valori predefiniti del DAW.';

  @override
  String get previewMixdownFolderHint => 'es. Mixdown';

  @override
  String get mixdownFoldersInfoTooltip => 'Come funziona';

  @override
  String get mixdownFoldersInfoDialogTitle =>
      'Come funziona il rilevamento dell\'anteprima';

  @override
  String get mixdownFoldersInfoDialogBody =>
      'Quando un progetto non ha una canzone di anteprima scelta manualmente, l\'app cerca il file audio modificato più di recente da usare come anteprima. Controlla prima le tue cartelle personalizzate qui sotto, in ordine, poi ricorre a un elenco di nomi di cartelle predefiniti in base al DAW del progetto.';

  @override
  String get mixdownFoldersDawDefaultsHeading => 'Cartelle predefinite per DAW';

  @override
  String get mixdownFoldersOtherDawLabel => 'Altro / DAW non riconosciuta';

  @override
  String get addMixdownFolder => 'Aggiungi';

  @override
  String get noCustomMixdownFolders =>
      'Nessuna cartella personalizzata aggiunta — verranno usati i valori predefiniti del DAW.';

  @override
  String get mixdownFoldersTabLabel => 'Cartelle di Mixdown';

  @override
  String get mixdownFoldersSectionDescription =>
      'Controlla in quale cartella l\'app cerca l\'audio esportato/bounced di un progetto, usato come anteprima quando nessuna è impostata manualmente. Espandi una DAW qui sotto per vedere i nomi delle cartelle già controllate di default, e aggiungi le tue se la tua configurazione usa un nome diverso.';

  @override
  String get mixdownFoldersDefaultsLabel => 'Cartelle controllate di default:';

  @override
  String get mixdownFoldersCustomLabel => 'Le tue aggiunte per questa DAW:';

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
    return 'Tonalità: $key';
  }

  @override
  String get audioFileNotFound => 'File audio non trovato';

  @override
  String errorPlayingAudio(String error) {
    return 'Errore durante la riproduzione audio: $error';
  }

  @override
  String get notificationTestTitle =>
      'Testa le notifiche per verificare fuso orario e pianificazione:';

  @override
  String get notificationSendNow => 'Invia ora';

  @override
  String get notificationSchedule30s => 'Pianifica +30s';

  @override
  String get notificationShowDebugInfo => 'Mostra informazioni di debug';

  @override
  String get notificationRescheduleAll => 'Ripianifica tutto';

  @override
  String get notificationTestSent => '✅ Notifica di test inviata!';

  @override
  String get notificationTestScheduled =>
      '✅ Notifica di test pianificata per 30 secondi! Controlla i log.';

  @override
  String notificationTestError(String error) {
    return '❌ Errore: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Informazioni di debug';

  @override
  String get autoDetected => 'Rilevato automaticamente';

  @override
  String get matchedInDescription => 'Trovato nella descrizione';

  @override
  String get matchedInProjectNotes => 'Trovato nelle note del progetto del DAW';

  @override
  String get relocateFolderDialogTitle => 'Riposiziona cartella';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count percorsi progetto aggiornati',
      one: '1 percorso progetto aggiornato',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Personalizza le schede';

  @override
  String get alwaysVisible => '(sempre visibile)';

  @override
  String get customizeTabsDescription =>
      'Scegli quali schede mostrare nella barra di navigazione. La scheda Progetti e sempre visibile.';

  @override
  String get keyboardShortcuts => 'Scorciatoie da tastiera';

  @override
  String get shortcutGroupGlobal => 'Globale';

  @override
  String get shortcutGroupProjectsTable =>
      'Tabella progetti (la tabella deve essere focalizzata)';

  @override
  String get shortcutGroupReleasesTable =>
      'Tabella release (la tabella deve essere focalizzata)';

  @override
  String get shortcutGroupNavigation => 'Navigazione';

  @override
  String get shortcutFocusSearch => 'Focalizza la barra di ricerca';

  @override
  String get shortcutRescan => 'Esegui nuova scansione delle cartelle';

  @override
  String get shortcutFocusTable => 'Focalizza la tabella dei progetti';

  @override
  String get shortcutPlayPause => 'Riproduci / metti in pausa l\'anteprima';

  @override
  String get shortcutOpenInDaw => 'Apri il progetto nel DAW';

  @override
  String get shortcutViewDetails => 'Visualizza dettagli del progetto';

  @override
  String get shortcutOpenFolder => 'Apri la cartella del progetto';

  @override
  String get shortcutNavigateRows => 'Naviga tra le righe';

  @override
  String get shortcutEditCell => 'Apri dettagli progetto';

  @override
  String get shortcutViewRelease => 'Visualizza dettagli della release';

  @override
  String get shortcutGoBack => 'Indietro';

  @override
  String get shortcutGroupProjectsTableStandardMode => 'Modalità standard';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'Modalità sessione';

  @override
  String get shortcutToggleSession => 'Avvia / Termina sessione';

  @override
  String get shortcutGroupPreviewPlayer => 'Lettore di anteprima';

  @override
  String get shortcutPlayerPlayPause => 'Riproduci / pausa';

  @override
  String get shortcutPlayerSeek5 => 'Cerca ±5 secondi';

  @override
  String get shortcutPlayerSeek30 => 'Cerca ±30 secondi';

  @override
  String get startupDialogTitle => 'Benvenuto in DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Inizia aggiungendo una cartella di progetti o ripristinando un backup da Google Drive.';

  @override
  String get startupAddFolderTitle => 'Aggiungi cartella di progetti';

  @override
  String get startupAddFolderSubtitle =>
      'Seleziona una cartella contenente i tuoi progetti DAW.';

  @override
  String get startupGoogleDriveTitle => 'Sincronizza backup Google Drive';

  @override
  String get startupGoogleDriveSubtitle =>
      'Ripristina i tuoi progetti da un backup su Google Drive.';

  @override
  String get startupDontShowAgain => 'Non mostrare all\'avvio';

  @override
  String get deleteAllData => 'Elimina tutti i dati';

  @override
  String get deleteAllDataSubtitle =>
      'Rimuovi tutti i profili, progetti, uscite, playlist e impostazioni da questo dispositivo.';

  @override
  String get deleteAllDataConfirm1Title => 'Eliminare tutti i dati?';

  @override
  String get deleteAllDataConfirm1Message =>
      'Questo cancellerà definitivamente tutti i profili, progetti, uscite, playlist e impostazioni da questo dispositivo. Il backup su Google Drive (se presente) non sarà influenzato.';

  @override
  String get deleteAllDataConfirm2Title => 'Sei assolutamente sicuro?';

  @override
  String get deleteAllDataConfirm2Message =>
      'Questa azione non può essere annullata. L\'app tornerà al suo stato iniziale.';

  @override
  String get deleteEverything => 'Elimina tutto';

  @override
  String get allDataDeleted => 'Tutti i dati sono stati eliminati.';

  @override
  String get newerExportFound => 'Export più recente trovato';

  @override
  String newerExportFoundMessage(String filename) {
    return 'È stato trovato un file più recente nella stessa cartella:\n$filename\n\nSostituire la canzone di anteprima?';
  }

  @override
  String get replaceAndPlay => 'Sostituisci e riproduci';

  @override
  String get keepCurrent => 'Mantieni attuale';

  @override
  String get autoBackup => 'Backup Automatico';

  @override
  String get autoBackupDescription =>
      'Carica automaticamente un backup su Google Drive all\'intervallo selezionato.';

  @override
  String get autoBackupInterval => 'Intervallo di backup';

  @override
  String get autoBackupOff => 'Disattivato';

  @override
  String get autoBackupEvery30Min => 'Ogni 30 minuti';

  @override
  String get autoBackupHourly => 'Ogni ora';

  @override
  String get autoBackupEvery6Hours => 'Ogni 6 ore';

  @override
  String get autoBackupDaily => 'Giornaliero';

  @override
  String autoBackupNextBackup(String time) {
    return 'Prossimo backup: $time';
  }

  @override
  String get autoBackupNextSoon => 'a breve';

  @override
  String autoBackupNextInMinutes(int count) {
    return 'tra $count min';
  }

  @override
  String get autoBackupNextInOneHour => 'tra 1 ora';

  @override
  String autoBackupNextInHours(int count) {
    return 'tra $count ore';
  }

  @override
  String get autoBackupNextInOneDay => 'tra 1 giorno';

  @override
  String autoBackupNextInDays(int count) {
    return 'tra $count giorni';
  }

  @override
  String get playerTitle => 'Lettore musicale';

  @override
  String get playerToggleQueue => 'Attiva/disattiva coda';

  @override
  String get playerSearchHint => 'Cerca tracce…';

  @override
  String playerTrackCount(int count) {
    return '$count tracce';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'Nessuna anteprima trovata.\nApri un progetto e imposta un\'anteprima.';

  @override
  String playerNoTracksMatch(String query) {
    return 'Nessuna traccia corrisponde a\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay =>
      'Doppio clic su una traccia per riprodurla';

  @override
  String get playerSingleClickToPreview =>
      'Clic singolo per l\'anteprima nella barra sottostante';

  @override
  String get playerQueueTitle => 'Coda';

  @override
  String get playerClearQueue => 'Svuota coda';

  @override
  String get playerQueueEmptyHint =>
      'Doppio clic per iniziare,\no trascina le tracce qui.';

  @override
  String get playerPrev => 'Precedente';

  @override
  String get playerNext => 'Successivo';

  @override
  String get playerGoToProject => 'Vai al progetto';

  @override
  String get playerAddToQueue => 'Aggiungi alla coda';

  @override
  String get playerRemoveFromQueue => 'Rimuovi dalla coda';

  @override
  String get playerDismissDetail => 'Chiudi dettaglio';

  @override
  String get playerNotes => 'NOTE';

  @override
  String get playerTasks => 'ATTIVITÀ';

  @override
  String get playerNoTasks => 'Nessuna attività ancora.';

  @override
  String get playerAddTaskHint => 'Aggiungi un\'attività…';

  @override
  String playerCompletedTasks(int count) {
    return '$count completata/e';
  }

  @override
  String get playerPreviousTrack => 'Traccia precedente';

  @override
  String get playerNextTrack => 'Traccia successiva';

  @override
  String get playerOpenProject => 'Apri progetto';

  @override
  String get playerRepeatAll => 'Ripeti tutto';

  @override
  String get playerShuffle => 'Casuale';

  @override
  String get volumeMute => 'Silenzia';

  @override
  String get volumeUnmute => 'Riattiva audio';

  @override
  String totalWorkTime(String time) {
    return 'Lavoro totale: $time';
  }

  @override
  String sessionTime(String time) {
    return 'Sessione: $time';
  }

  @override
  String headerAgeOld(String age) {
    return '$age di vita';
  }

  @override
  String headerEdited(String when) {
    return 'modificato $when';
  }

  @override
  String headerWorked(String time) {
    return '$time di lavoro';
  }

  @override
  String get sessionHistory => 'Cronologia sessioni';

  @override
  String get noSessionsYet => 'Nessuna sessione registrata';

  @override
  String get removeSessionTitle => 'Rimuovere la sessione?';

  @override
  String get editSessionTitle => 'Modifica durata sessione';

  @override
  String get editSessionHours => 'Ore';

  @override
  String get editSessionInvalid => 'La durata deve essere di almeno 1 minuto';

  @override
  String get sessionTableDate => 'Data';

  @override
  String get sessionTableTime => 'Ora';

  @override
  String get sessionTableDuration => 'Durata';

  @override
  String get sessionTableTotal => 'Totale';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessioni',
      one: '1 sessione',
    );
    return '$_temp0';
  }

  @override
  String get sessionByPhase => 'Lavoro per fase';

  @override
  String get tabPosition => 'Posizione schede';

  @override
  String get tabPositionTop => 'In alto';

  @override
  String get tabPositionLeft => 'A sinistra';

  @override
  String updateAvailableMessage(String version) {
    return 'Versione $version disponibile';
  }

  @override
  String get dismiss => 'Ignora';

  @override
  String get checkForUpdates => 'Cerca aggiornamenti';

  @override
  String get checkForUpdatesDescription =>
      'Ricevi notifiche quando è disponibile una nuova versione.';

  @override
  String get checkNow => 'Controlla ora';

  @override
  String updateAvailable(String version) {
    return 'Aggiornamento disponibile: v$version';
  }

  @override
  String get upToDate => 'L\'app è aggiornata';

  @override
  String get updateAvailableTitle => 'Aggiornamento disponibile';

  @override
  String updateAvailableVersion(String version) {
    return 'La versione $version è pronta.';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Stai usando v$version.';
  }

  @override
  String get viewUpdateDetails => 'Visualizza dettagli';

  @override
  String get getOnMicrosoftStore => 'Scarica da Microsoft Store';

  @override
  String get downloadFromGitHub => 'Scarica da GitHub';

  @override
  String get updateWindowsInstructions =>
      'Apri Microsoft Store e aggiorna DAW Project Manager, oppure clicca qui sotto.';

  @override
  String get updateMacInstructions =>
      'Scarica l\'ultima versione da GitHub e sostituisci l\'app.';

  @override
  String get updateAppImageSourceLabel => 'AppImage';

  @override
  String get updateAppImageInstructions => 'Aggiornamento sul posto e riavvio.';

  @override
  String get updateNowButtonLabel => 'Aggiorna ora';

  @override
  String get appImageUpdateFetching => 'Ricerca dell\'aggiornamento…';

  @override
  String get appImageUpdateDownloading => 'Download dell\'aggiornamento…';

  @override
  String appImageUpdateDownloadingProgress(int percent) {
    return 'Download dell\'aggiornamento… $percent%';
  }

  @override
  String get appImageUpdateVerifying => 'Verifica e installazione…';

  @override
  String get appImageUpdateReadyTitle => 'Aggiornamento pronto';

  @override
  String appImageUpdateReadyMessage(String version) {
    return 'Aggiornato alla versione $version. Riavvia ora per completare.';
  }

  @override
  String get appImageUpdateRestartNow => 'Riavvia ora';

  @override
  String get appImageUpdateFailedTitle => 'Aggiornamento non riuscito';

  @override
  String get appImageUpdateRetry => 'Riprova';

  @override
  String get appImageUpdateErrorMessage =>
      'Si è verificato un errore durante l\'aggiornamento. Puoi riprovare oppure controllare i dettagli dell\'errore qui sotto.';

  @override
  String get appImageUpdateErrorDetailsLabel => 'Dettagli errore';

  @override
  String get appImageUpdateCopyErrorDetails => 'Copia dettagli errore';

  @override
  String get appImageUpdateErrorDetailsCopied => 'Dettagli errore copiati';

  @override
  String get resetOnboarding => 'Reimposta configurazione iniziale';

  @override
  String get onboardingWelcomeTitle => 'Benvenuto in DAW Project Manager';

  @override
  String get onboardingWelcomeBody =>
      'Organizza tutti i tuoi progetti musicali in un unico posto.';

  @override
  String get onboardingFeatureScanFolders =>
      'Scansiona automaticamente le cartelle dei progetti DAW';

  @override
  String get onboardingFeatureTrackMetadata =>
      'Tiene traccia di BPM, tonalità, stato e scadenze';

  @override
  String get onboardingFeatureSyncDrive =>
      'Sincronizza i metadati con Google Drive';

  @override
  String get onboardingFeatureTrackTime =>
      'Tiene traccia del tempo dedicato a ogni progetto';

  @override
  String get onboardingLanguageTitle => 'Scegli la lingua';

  @override
  String get onboardingThemeTitle => 'Scegli un tema';

  @override
  String get onboardingFoldersTitle => 'Aggiungi cartelle di progetto';

  @override
  String get onboardingFoldersBody =>
      'Aggiungi la cartella radice in cui sono archiviati i tuoi progetti DAW.';

  @override
  String get onboardingDriveTitle => 'Sincronizzazione Google Drive';

  @override
  String get onboardingDriveBody =>
      'Esegui il backup e sincronizza i metadati del progetto con Google Drive.';

  @override
  String get onboardingUpdatesTitle => 'Controlli aggiornamenti';

  @override
  String get onboardingUpdatesBody =>
      'Ricevi notifiche quando è disponibile una nuova versione.';

  @override
  String get onboardingDoneTitle => 'Tutto pronto!';

  @override
  String get onboardingDoneBody => 'Inizia a esplorare i tuoi progetti.';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingBack => 'Indietro';

  @override
  String get onboardingGetStarted => 'Inizia';

  @override
  String get dawSession => 'Sessione DAW';

  @override
  String get clearDawSession => 'Chiudi sessione';

  @override
  String get stop => 'Ferma';

  @override
  String get pause => 'Pausa';

  @override
  String get playPauseTooltip => 'Riproduci / Pausa';

  @override
  String get resume => 'Riprendi';

  @override
  String get workTimerSection => 'Promemoria sessione di lavoro';

  @override
  String get workTimerSectionDesc =>
      'Ricevi notifiche periodiche mentre hai una sessione di lavoro attiva';

  @override
  String get workTimerRequiresSessionMode =>
      'Abilita la Modalità Sessione sopra per usare i promemoria sessione di lavoro';

  @override
  String get workTimerEnabled => 'Abilita promemoria sessione di lavoro';

  @override
  String get workTimerIntervalLabel => 'Notifica ogni';

  @override
  String get minutes => 'minuti';

  @override
  String workTimerNotifBody(String time) {
    return 'Stai lavorando da $time';
  }

  @override
  String get sendTestNotification => 'Invia notifica di prova';

  @override
  String get testNotificationTitle => 'Notifica di prova';

  @override
  String get testNotificationBody =>
      'Questa è una notifica di prova da DAW Project Manager.';

  @override
  String get general => 'Generale';

  @override
  String get expand => 'Espandi';

  @override
  String get collapse => 'Comprimi';

  @override
  String get lastModifiedColors => 'Colori della data di ultima modifica';

  @override
  String get lastModifiedColorsDescription =>
      'Colora la data di ultima modifica in base all’età e allo stato. Verde = Finito. Le date più vecchie sfumano dal giallo al rosso — un rosso più intenso significa che il progetto non è stato modificato da più tempo.';

  @override
  String get sessionMode => 'Modalità sessione';

  @override
  String get sessionModeDescription =>
      'Avvia una sessione su un progetto per monitorare il tempo di lavoro e gestirlo dalla barra degli strumenti';

  @override
  String get workSessionsTabLabel => 'Sessioni di Lavoro';

  @override
  String get normalMode => 'Modalità Normale';

  @override
  String get normalModeDescription =>
      'I progetti si aprono direttamente nella loro DAW all\'avvio.';

  @override
  String get sessionModeCardDescription =>
      'Avvia una sessione per monitorare la tua attività e il tempo sul progetto.';

  @override
  String get startSession => 'Avvia sessione';

  @override
  String get endSession => 'Termina sessione';

  @override
  String get switchSession => 'Cambia sessione';

  @override
  String get switchSessionBody =>
      'Terminare la sessione corrente e avviarne una nuova?';

  @override
  String switchSessionCurrent(String project) {
    return 'Corrente: $project';
  }

  @override
  String switchSessionNew(String project) {
    return 'Nuova: $project';
  }

  @override
  String get sessionDuration => 'Durata sessione';

  @override
  String get scanModeLabel => 'Modalità scansione:';

  @override
  String get scanModeSectionTitle => 'Modalità di scansione';

  @override
  String get scanModeSectionDescription =>
      'Controlla come i progetti in ogni cartella vengono visualizzati nella tabella — come un elenco semplice o raggruppati per sottocartella.';

  @override
  String get smartFolderOptionsSectionTitle => 'Opzioni cartelle intelligenti';

  @override
  String get smartFolderOptionsSectionDescription =>
      'Regola il comportamento dei gruppi di cartelle intelligenti nella tabella dei progetti.';

  @override
  String get excludeSmartFoldersFromSort =>
      'Escludi le cartelle smart dall\'ordinamento';

  @override
  String get excludeSmartFoldersFromSortDescription =>
      'Quando ordini la tabella dei progetti per colonna, i gruppi di cartelle smart restano al loro posto invece di spostarsi con l\'ordinamento — vengono riordinati solo i progetti al loro interno (e quelli non raggruppati). Sperimentale: disattivato per impostazione predefinita.';

  @override
  String get mergeSmartFoldersByName =>
      'Unisci le cartelle smart con lo stesso nome';

  @override
  String get mergeSmartFoldersByNameDescription =>
      'Quando due cartelle radice di scansione (ad esempio DAW diversi) hanno una cartella di primo livello con lo stesso nome, vengono trattate come un unico gruppo unito nella tabella dei progetti invece che come due gruppi separati.';

  @override
  String get alwaysShowSmartFolders => 'Mostra sempre le cartelle smart';

  @override
  String get alwaysShowSmartFoldersDescription =>
      'Mostra una cartella smart come una propria riga di gruppo anche quando è visibile solo uno dei suoi progetti (ad esempio dopo una ricerca o un filtro), invece di ridurla a una semplice riga non raggruppata.';

  @override
  String get scanModeFlat => 'Piatto';

  @override
  String get scanModeSmartFolder => 'Cartella intelligente';

  @override
  String get scanModeFlatDescription =>
      'Mostra ogni progetto come lista semplice. Semplice e veloce.';

  @override
  String get scanModeSmartFolderDescription =>
      'Raggruppa i progetti per cartella quando una cartella contiene più di un progetto.';

  @override
  String get skip => 'Salta';

  @override
  String get suggestionsLabel => 'Suggerimenti';

  @override
  String get suggestionsRefresh => 'Aggiorna';

  @override
  String get suggestionsEmptyState =>
      'Nessun suggerimento al momento. Tocca Aggiorna per ripristinare gli elementi ignorati.';

  @override
  String get suggestionNewProject => 'Nuovo';

  @override
  String get showSuggestions => 'Mostra suggerimenti';

  @override
  String get showSuggestionsDescription =>
      'Mostra suggerimenti intelligenti nella barra degli strumenti quando non c\'è una sessione in corso';

  @override
  String get onboardingSuggestionsTitle => 'Suggerimenti intelligenti';

  @override
  String get onboardingSuggestionsBody =>
      'Ricevi raccomandazioni di progetti personalizzate nella barra degli strumenti mentre lavori';

  @override
  String get onboardingSessionModeTitle => 'Modalità sessione';

  @override
  String get onboardingSessionModeBody =>
      'Avvia sessioni di lavoro mirate e tieni traccia automaticamente del tempo dedicato a ogni progetto';

  @override
  String get suggestionsFeatureDeadlines =>
      'Promemoria delle scadenze per i prossimi progetti';

  @override
  String get suggestionsFeatureResume =>
      'Riprendi l\'ultimo progetto su cui hai lavorato';

  @override
  String get suggestionsFeatureRecentlyModified =>
      'Continua le tracce modificate di recente';

  @override
  String get suggestionsEnableToggle => 'Abilita suggerimenti intelligenti';

  @override
  String get canBeChangedInSettings =>
      'Può essere modificato in seguito nelle Impostazioni';

  @override
  String get next => 'Avanti';

  @override
  String get createProject => 'Crea';

  @override
  String get createProjectTooltip => 'Crea una nuova cartella di progetto';

  @override
  String get createProjectSelectFolder => 'Scegli posizione';

  @override
  String get createProjectSelectFolderHint =>
      'Seleziona in quale cartella creare il nuovo progetto';

  @override
  String get createProjectNameTitle => 'Nomina il progetto';

  @override
  String get createProjectNameHint =>
      'Scegli uno schema di denominazione per la nuova cartella';

  @override
  String get createProjectSchemeArtistTrack => 'Artista — Traccia';

  @override
  String get createProjectSchemeCollab => 'Collaborazione';

  @override
  String get createProjectSchemeDate => 'Data — Traccia';

  @override
  String get createProjectSchemeCustom => 'Personalizzato';

  @override
  String get createProjectSchemeRemix => 'Remix';

  @override
  String get createProjectArtistName => 'Nome artista';

  @override
  String get createProjectTrackName => 'Nome traccia';

  @override
  String get createProjectCustomName => 'Nome cartella';

  @override
  String get createProjectAddArtist => 'Aggiungi artista';

  @override
  String get createProjectOriginalArtist => 'Artista originale';

  @override
  String get createProjectRemixerName => 'Remixer';

  @override
  String get createProjectAddRemixer => 'Aggiungi remixer';

  @override
  String get createProjectSelectDaw => 'Apri nel DAW';

  @override
  String get createProjectSelectDawHint =>
      'Scegli quale DAW aprire per questo progetto';

  @override
  String get createProjectDetectDaws => 'Rileva DAW installati';

  @override
  String get createProjectSkipDaw => 'Crea solo la cartella';

  @override
  String get createProjectNoDawsFound =>
      'Nessun DAW trovato. La cartella verrà comunque creata.';

  @override
  String get createProjectCreateOnly => 'Crea cartella';

  @override
  String get createProjectCreateAndOpen => 'Crea e apri';

  @override
  String get createProjectFolderExists =>
      'Esiste già una cartella con questo nome';

  @override
  String get createProjectInvalidChars =>
      'Il nome contiene caratteri non validi';

  @override
  String get createProjectError => 'Impossibile creare la cartella';

  @override
  String get createProjectIncludeDate => 'Includi prefisso data';

  @override
  String get createProjectCreatedTitle => 'Cartella creata';

  @override
  String get createProjectCreatedMessage =>
      'La tua cartella di progetto è stata creata:';

  @override
  String get createProjectCopyName => 'Copia nome cartella';

  @override
  String get createProjectNameCopied => 'Nome cartella copiato';

  @override
  String get createProjectTrackSession => 'Tieni traccia della sessione da ora';

  @override
  String get pendingFolderSessionTitle => 'Sessione di lavoro rilevata';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return 'Hai lavorato su \"$projectName\" per $duration.';
  }

  @override
  String get pendingFolderSessionContinue => 'Continua sessione';

  @override
  String get pendingFolderSessionEndRecord => 'Termina e registra';

  @override
  String get activeSessionSwitchTitle => 'Sessione già attiva';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return 'Una sessione è in corso per \"$current\". Passare a \"$next\" e salvare la sessione corrente?';
  }

  @override
  String get activeSessionSwitch => 'Cambia';

  @override
  String get pendingProjectWaiting => 'In attesa del file di progetto…';

  @override
  String get pendingProjectDelete => 'Elimina cartella vuota';

  @override
  String get pendingProjectDeleteTitle => 'Eliminare la cartella?';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return 'Eliminare \"$folderName\" e il suo contenuto?';
  }

  @override
  String get pendingProjectDismiss => 'Smetti di tracciare questa cartella';

  @override
  String get pendingProjectDismissTitle => 'Interrompere il tracciamento?';

  @override
  String get pendingProjectDismissKeep => 'Mantieni cartella';

  @override
  String get pendingProjectDismissDelete => 'Elimina e chiudi';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'La cartella non è vuota';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '\"$folderName\" contiene file. Eliminare tutto definitivamente?';
  }

  @override
  String get pendingProjectRefresh => 'Cerca il file di progetto';

  @override
  String get pendingProjectNotFound => 'Nessun file di progetto trovato ancora';

  @override
  String get phases => 'Fasi';

  @override
  String get phasesSubtitle =>
      'Aggiungi, rimuovi e riordina le fasi del progetto';

  @override
  String get phasesDescription =>
      'Le fasi tracciano lo stadio di ogni progetto nel tuo flusso di lavoro (es. Idea → Mixaggio → Mastering). Trascina per riordinare, tocca un pallino colorato per ricolorare e contrassegna una fase come completata per trattarla come tale in tutta l\'app.';

  @override
  String get resetToDefaults => 'Ripristina predefiniti';

  @override
  String get addPhase => 'Aggiungi fase';

  @override
  String get phaseNameHint => 'Nome della fase';

  @override
  String get phaseDuplicateError => 'Esiste già una fase con quel nome';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count progetti usano questa fase',
      one: '1 progetto usa questa fase',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => 'Seleziona colore';

  @override
  String get markAsFinished => 'Segna come fase completata';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count progetti usano fasi che non esisteranno più.',
      one: '1 progetto usa una fase che non esisterà più.',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      'Quei progetti manterranno il loro stato attuale ma non appariranno nei filtri di fase. Puoi sempre aggiungere nuovamente quelle fasi in seguito.';

  @override
  String get resetPhasesConfirm =>
      'Ripristinare tutte le fasi personalizzate, i colori e i contrassegni di fase completata ai valori predefiniti?';

  @override
  String get camelotGenerateButton => 'Genera mix';

  @override
  String get camelotDialogTitle => 'Mix Camelot';

  @override
  String get camelotDialogDescription =>
      'Ordina le tracce per compatibilità armonica usando la ruota Camelot. La prossimità BPM viene usata come criterio di selezione.';

  @override
  String camelotEligibleTracks(int count) {
    return '$count tracce idonee (tonalità impostata)';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$count verranno saltate (nessuna tonalità)';
  }

  @override
  String get camelotNoEligibleTracks =>
      'Nessuna traccia ha una tonalità impostata. Apri un progetto e imposta la tonalità.';

  @override
  String get camelotGenerate => 'Genera';

  @override
  String camelotQueueGenerated(int count) {
    return 'Coda riempita con $count tracce in ordine armonico';
  }

  @override
  String get camelotWheelGuideTooltip => 'Guida alla ruota Camelot';

  @override
  String get camelotWheelGuideTitle => 'Guida alla Ruota Camelot';

  @override
  String get camelotGuideRingsTitle => 'Gli Anelli';

  @override
  String get camelotGuideRingsBody =>
      'Anello interno (A)  →  tonalità minori\nAnello esterno (B)  →  tonalità maggiori';

  @override
  String get camelotGuideNumbersTitle => 'Numeri 1–12';

  @override
  String get camelotGuideNumbersBody =>
      'Posizioni disposte in senso orario. Ogni numero rappresenta un vicinato armonico — i vicini condividono forti relazioni tonali.';

  @override
  String get camelotGuideColoursTitle => 'Guida ai Colori';

  @override
  String get camelotGuideColoursBody =>
      '● Luminoso  →  la tonalità del tuo brano\n● Tenue  →  compatibile per il mix\n● Attenuato  →  da evitare per un mix fluido';

  @override
  String get camelotGuideTransitionsTitle => 'Transizioni Compatibili';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  (stesso numero, cambio anello)\n  Maggiore/minore relativo — praticamente senza soluzione di continuità.\n\n8A → 7A o 9A  (±1, stesso anello)\n  Tonalità adiacente — cambio morbido e sottile.\n\n8A → 1A o 3A  (±7, stesso anello)\n  Aumento o calo di energia — cambiamento più drammatico.';

  @override
  String get playerMixSuggestions => 'SUGGERIMENTI MIX';

  @override
  String get nowPlaying => 'In riproduzione';

  @override
  String get noPreviewSongsAvailable => 'Nessuna anteprima audio disponibile';

  @override
  String get upNext => 'Prossimo';

  @override
  String get playbackModeNormal => 'Normale';

  @override
  String get playbackModeRepeat => 'Ripeti';

  @override
  String get playbackModeShuffle => 'Casuale';

  @override
  String get hideDatesInNames => 'Nascondi le date nei nomi dei progetti';

  @override
  String get hideDatesInNamesDescription =>
      'Alcune DAW antepongono ai file di progetto la data di creazione (ad esempio \"2026-08-02 - Il Mio Brano\"). Nascondila per mostrare solo il titolo. I file non vengono mai rinominati.';

  @override
  String get findPreviewAutomatically => 'Trova automaticamente';

  @override
  String get noPreviewSongFoundAutomatically =>
      'Nessun brano di anteprima trovato nelle cartelle di mixdown di questo progetto.';

  @override
  String get selectProjects => 'Seleziona';

  @override
  String sharePreviewSongText(String name) {
    return 'Brano di anteprima: $name';
  }

  @override
  String sharePreviewSongZipText(String name) {
    return 'Brano di anteprima (ZIP): $name';
  }

  @override
  String get songParts => 'Strumenti e parti';

  @override
  String partsProgress(int done, int total) {
    return '$done di $total take definitivi';
  }

  @override
  String get noPartsYet => 'Nessuna parte registrata';

  @override
  String get noPartsYetHint =>
      'Elenca gli strumenti che il brano richiede, chi li suona e a che punto è ogni take.';

  @override
  String get addPart => 'Aggiungi parte';

  @override
  String get addPartHint => 'es. Batteria, Voce principale, Basso';

  @override
  String get partNameLabel => 'Parte';

  @override
  String get partNameRequired => 'Il nome della parte è obbligatorio';

  @override
  String get partPerformerLabel => 'Esecutore';

  @override
  String get partPerformerHint => 'Chi la suona';

  @override
  String get partNotesLabel => 'Note della parte';

  @override
  String get partStatusLabel => 'Stato del take';

  @override
  String get partStatusNeeded => 'Da fare';

  @override
  String get partStatusRecording => 'In registrazione';

  @override
  String get partStatusEarlyTake => 'Take provvisorio';

  @override
  String get partStatusFinalTake => 'Take definitivo';

  @override
  String get editPart => 'Modifica parte';

  @override
  String get deletePart => 'Elimina parte';

  @override
  String get partsUnassignedPerformer => 'Non assegnata';

  @override
  String get partTemplates => 'Modelli di parti';

  @override
  String get importPartsFromTemplate => 'Importa parti da un modello';

  @override
  String get managePartTemplates => 'Gestisci modelli di parti';

  @override
  String get selectPartTemplate => 'Seleziona un modello di parti';

  @override
  String get noPartTemplatesAvailable => 'Nessun modello di parti disponibile';

  @override
  String get noPartTemplatesYet => 'Nessun modello di parti';

  @override
  String get createFirstPartTemplate =>
      'Creane uno per riutilizzare la stessa formazione in più brani';

  @override
  String get createPartTemplate => 'Crea modello di parti';

  @override
  String get editPartTemplate => 'Modifica modello di parti';

  @override
  String get deletePartTemplate => 'Elimina modello di parti';

  @override
  String deletePartTemplateConfirm(String name) {
    return 'Vuoi davvero eliminare il modello di parti \"$name\"?';
  }

  @override
  String get partTemplateCreated => 'Modello di parti creato';

  @override
  String get partTemplateUpdated => 'Modello di parti aggiornato';

  @override
  String get partTemplateDeleted => 'Modello di parti eliminato';

  @override
  String get partTemplateItems => 'Parti (una per riga)';

  @override
  String get partTemplateItemsHint =>
      'Batteria — Alex\nBasso — Sam\nVoce principale';

  @override
  String get partTemplateItemsHelp =>
      'Una parte per riga. Indica l\'esecutore dopo un trattino: Batteria — Alex';

  @override
  String get partTemplateItemsRequired => 'Aggiungi almeno una parte';

  @override
  String get partTemplateNameAndItemsRequired =>
      'Sono richiesti un nome e almeno una parte';

  @override
  String partTemplateItemCount(int count) {
    return '$count parte/i';
  }

  @override
  String partTemplateImported(String name, int count) {
    return 'Modello di parti \"$name\" importato ($count parti)';
  }

  @override
  String get errorLoadingPartTemplates =>
      'Errore nel caricamento dei modelli di parti';

  @override
  String get exportPartsCsv => 'Esporta le parti in CSV';

  @override
  String get exportAllPartsCsv => 'Esporta le parti di tutti i brani in CSV';

  @override
  String get exportAllPartsCsvSubtitle =>
      'Una riga di foglio di calcolo per ogni parte, per tutti i progetti — per condividere i progressi con i collaboratori';

  @override
  String get noPartsToExport => 'Nessuna parte da esportare';

  @override
  String partsCsvExported(int count) {
    return '$count parti esportate';
  }

  @override
  String get projectExportPartsLabel => 'Parti:';

  @override
  String get csvHeaderProject => 'Progetto';

  @override
  String get csvHeaderPart => 'Parte';

  @override
  String get csvHeaderPerformer => 'Esecutore';

  @override
  String get csvHeaderStatus => 'Stato';

  @override
  String get csvHeaderNotes => 'Note';

  @override
  String get exportPartsXlsx => 'Esporta le parti in Excel (.xlsx)';

  @override
  String get exportAllPartsXlsx =>
      'Esporta le parti di tutti i brani in Excel (.xlsx)';

  @override
  String get exportAllPartsXlsxSubtitle =>
      'Lo stesso foglio del CSV, con intestazione bloccata, filtri sulle colonne e stati dei take a colori';

  @override
  String get importPartsFromSpreadsheet =>
      'Importa parti da un foglio di calcolo';

  @override
  String get partsImportPickerTitle => 'Seleziona un file CSV o Excel';

  @override
  String partsImported(int added, int updated) {
    return '$added parti aggiunte, $updated aggiornate';
  }

  @override
  String get partsImportNothingFound => 'Nessuna parte trovata in quel file';

  @override
  String partsImportFailed(String error) {
    return 'Impossibile leggere quel foglio di calcolo: $error';
  }

  @override
  String get partsMoreActions => 'Altre azioni sulle parti';

  @override
  String partsPageTitle(String name) {
    return '$name — Parti';
  }

  @override
  String get manageParts => 'Gestisci le parti';

  @override
  String partsMoreCount(int count) {
    return '+$count altre';
  }

  @override
  String get searchParts => 'Cerca parti';

  @override
  String get allStatuses => 'Tutti gli stati';

  @override
  String get allPerformers => 'Tutti gli esecutori';

  @override
  String partsSelectedCount(int count) {
    return '$count selezionate';
  }

  @override
  String get setPartStatus => 'Imposta stato';

  @override
  String get assignPartPerformer => 'Assegna esecutore';

  @override
  String get deleteSelectedParts => 'Elimina selezionate';

  @override
  String deleteSelectedPartsConfirm(int count) {
    return 'Eliminare $count parti da questo brano?';
  }

  @override
  String partsDeleted(int count) {
    return '$count parti eliminate';
  }

  @override
  String get noPartsMatchFilters => 'Nessuna parte corrisponde a questi filtri';

  @override
  String get reorderNeedsUnfilteredList =>
      'Azzera ricerca, filtri e ordinamento per trascinare le parti';

  @override
  String get projectMarkers => 'Marcatori';

  @override
  String projectMarkerUnnamed(int index) {
    return 'Marcatore $index';
  }

  @override
  String projectRegionUnnamed(int index) {
    return 'Regione $index';
  }

  @override
  String get projectMarkerJumpTooltip =>
      'Vai a questo punto del brano di anteprima';

  @override
  String get projectMarkerNoPreviewSong =>
      'Aggiungi un brano di anteprima per saltare ai marcatori';

  @override
  String get projectDetailLayout => 'Layout dei Dettagli Progetto';

  @override
  String get projectDetailLayoutSettingDescription =>
      'Come è organizzata la pagina dei dettagli del progetto.';

  @override
  String get projectDetailLayoutClassic => 'Classico';

  @override
  String get projectDetailLayoutClassicDescription =>
      'Tutto in un unico scorrimento.';

  @override
  String get projectDetailLayoutSectioned => 'Sezioni';

  @override
  String get projectDetailLayoutSectionedDescription =>
      'Una barra a sinistra sceglie una sezione alla volta.';

  @override
  String get stackAsVersions => 'Impila come versioni';

  @override
  String get stackNeedsTwoVersions =>
      'Seleziona almeno due progetti per impilarli come versioni di un progetto principale.';

  @override
  String stackCreatedMessage(int count) {
    return '$count versioni impilate in un progetto principale.';
  }

  @override
  String get stackVersionsTitle => 'Versioni';

  @override
  String stackVersionCount(int count) {
    return '$count versioni';
  }

  @override
  String get stackAddVersion => 'Aggiungi versione';

  @override
  String get stackAddVersionTitle => 'Aggiungi una versione';

  @override
  String get stackAddVersionEmpty =>
      'Nessun progetto non impilato disponibile da aggiungere.';

  @override
  String get stackRemoveVersion => 'Rimuovi dalla pila';

  @override
  String get stackRemoveVersionMessage =>
      'Il file del progetto resta su disco e torna nell\'elenco come progetto a sé.';

  @override
  String get stackUnstack => 'Separa';

  @override
  String get stackUnstackTitle => 'Separare questo progetto principale?';

  @override
  String get stackUnstackMessage =>
      'Ogni versione torna a essere un progetto a sé con i metadati che aveva prima dell\'impilamento. Le note, le attività e la scadenza condivise sul progetto principale vengono eliminate.';

  @override
  String get stackDefaultVersion => 'Si apre per impostazione predefinita';

  @override
  String get stackSetDefaultVersion =>
      'Apri questa versione per impostazione predefinita';

  @override
  String get stackChooseVersionToOpen => 'Quale versione vuoi aprire?';

  @override
  String get stackMemberOf => 'Versione di';

  @override
  String get stackMemberNotice =>
      'Questo file è una versione di un progetto impilato. Metadati, attività e tempo di lavoro condivisi si trovano sul progetto principale, non qui.';

  @override
  String get stackOpenMainProject => 'Apri progetto principale';

  @override
  String get stackWorkTimeAcrossVersions => 'Totale su tutte le versioni';

  @override
  String get scanModeVersionStack => 'Pila di versioni';

  @override
  String get scanModeVersionStackDescription =>
      'Tutti i file di progetto in una cartella diventano un progetto principale che condivide metadati, attività e tempo di lavoro. I nuovi file si uniscono automaticamente.';

  @override
  String stackTooltipStacked(int count) {
    return '$count versioni impilate in un progetto principale';
  }

  @override
  String get stackMetadataSourceTitle =>
      'Quale progetto deve diventare il progetto principale?';

  @override
  String get stackMetadataSourceBody =>
      'Più di uno ha già dettagli propri. Quello che scegli diventa il progetto principale: nome, BPM, tonalità, note, attività e scadenza saranno quelli usati dalla pila. Nulla viene unito o perso: gli altri mantengono i propri dettagli e separandoli li riavrai.';

  @override
  String get stackMetadataSourceOldestHint => 'La più vecchia — suggerita';

  @override
  String get stackMetadataNoneLabel => 'Ancora nessun dettaglio';

  @override
  String stackMetadataTodosLabel(int count) {
    return '$count attività';
  }

  @override
  String get stackMetadataNotesLabel => 'note';

  @override
  String get stackNotStackedYet => 'Non ancora impilato';

  @override
  String get stackStartFromHere =>
      'Aggiungi altri file di progetto e diventeranno versioni di un progetto principale, condividendo metadati, attività e tempo di lavoro.';

  @override
  String get stackSearchProjects => 'Cerca progetti';

  @override
  String get stackSearchNoMatches =>
      'Nessun progetto corrisponde alla tua ricerca.';

  @override
  String get stackStartedMessage => 'Impilato in un progetto principale.';

  @override
  String get stackDefaultVersionTooltip =>
      'Questa versione si apre per impostazione predefinita all\'avvio della DAW.';

  @override
  String stackAddVersionsConfirm(int count) {
    return 'Aggiungi $count';
  }

  @override
  String get stackAddVersionMultiTitle => 'Aggiungi versioni';

  @override
  String get stackSelectAll => 'Seleziona tutto';

  @override
  String get stackClearSelection => 'Cancella';
}
