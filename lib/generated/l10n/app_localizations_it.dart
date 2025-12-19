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
  String get cancel => 'Annulla';

  @override
  String get launch => 'Apri';

  @override
  String get view => 'Visualizza';

  @override
  String get openFolder => 'Apri Cartella';

  @override
  String get openInDaw => 'Apri nel DAW';

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
  String get scanning => 'Scansione in corso…';

  @override
  String get projectName => 'Nome del Progetto';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tonalità (es: C#m, F maggiore)';

  @override
  String get notes => 'Note';

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
  String get clearLibrary => 'Svuota Libreria';

  @override
  String get clearLibraryMessage =>
      'Questo rimuoverà tutti i progetti salvati e le cartelle sorgente. Continuare?';

  @override
  String get clear => 'Svuota';

  @override
  String get roots => 'Radici';

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
  String get deepScanTooltip =>
      'La Scansione Approfondita estrae metadati completi dai file di progetto:\n• BPM (Battiti Per Minuto)\n• Tonalità Musicale\n• Versione del DAW\nÈ più lenta ma fornisce informazioni complete.';

  @override
  String get deepScanConfirm =>
      'Questo scannerà tutti i progetti ed estrarrà metadati completi (BPM, Tonalità, Versione del DAW). Questo potrebbe richiedere del tempo. Continuare?';

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
    return 'Sei sicuro di voler eliminare \"$profileName\"? Questo eliminerà tutti i progetti, radici e pubblicazioni di questo profilo.';
  }

  @override
  String get editProfile => 'Modifica Profilo';

  @override
  String get changePhoto => 'Cambia Foto';

  @override
  String get remove => 'Rimuovi';

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
  String created(String date) {
    return 'Creato: $date';
  }

  @override
  String get toggleSort => 'Inverti ordinamento';

  @override
  String get clearLibraryTooltip => 'Svuota Libreria (progetti e radici)';

  @override
  String lastModified(String date) {
    return 'Ultima modifica: $date';
  }

  @override
  String get name => 'Nome';

  @override
  String get status => 'Stato';

  @override
  String get daw => 'DAW';

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
  String get deleteRootPath => 'Elimina Percorso Radice';

  @override
  String deleteRootPathMessage(String path) {
    return 'Sei sicuro di voler rimuovere \"$path\"? Questo rimuoverà anche tutti i progetti da questa cartella che non sono nelle pubblicazioni.';
  }

  @override
  String rootsCount(int count) {
    return 'Radici: $count';
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
  String get noProjectsFoundInRoots =>
      'Nessun progetto trovato nelle radici selezionate.';

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
  String errorLoadingProjects(String error) {
    return 'Errore nel caricamento dei progetti: $error';
  }

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
  String failedToOpenFile(String error) {
    return 'Errore nell\'apertura del file: $error';
  }

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
  String get todoList => 'Lista Attività';

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
  String get noFilesAddedYet =>
      'Nessun file aggiunto ancora.\nClicca su \"Aggiungi File\" per caricare i file della pubblicazione.';

  @override
  String get noTodosYet => 'Nessuna attività ancora. Aggiungine una sopra.';

  @override
  String get done => 'Fatto';
}
