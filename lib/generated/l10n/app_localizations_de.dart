// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'DAW Projektmanager';

  @override
  String get projectDetails => 'Projektdetails';

  @override
  String get back => 'Zurück';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get launch => 'Öffnen';

  @override
  String get view => 'Anzeigen';

  @override
  String get openFolder => 'Ordner öffnen';

  @override
  String get openInDaw => 'Im DAW starten';

  @override
  String get extract => 'Extrahieren';

  @override
  String get extracting => 'Extrahieren…';

  @override
  String get extractingMetadata => 'Metadaten werden extrahiert...';

  @override
  String get deepScan => 'Tiefenscan';

  @override
  String get rescan => 'Erneut scannen';

  @override
  String get scanning => 'Scannen…';

  @override
  String get projectName => 'Projektname';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tonart (z.B. C#m, F-Dur)';

  @override
  String get notes => 'Notizen';

  @override
  String get projectPhase => 'Projektphase';

  @override
  String get failedToLoad => 'Laden fehlgeschlagen';

  @override
  String get fileMissing => 'Datei fehlt.';

  @override
  String launchingProject(String projectName) {
    return 'Öffne $projectName…';
  }

  @override
  String get clearLibrary => 'Bibliothek leeren';

  @override
  String get clearLibraryMessage =>
      'Dies entfernt alle gespeicherten Projekte und Quellordner. Fortfahren?';

  @override
  String get clear => 'Leeren';

  @override
  String get roots => 'Wurzeln';

  @override
  String get projects => 'Projekte';

  @override
  String get hidden => 'versteckt';

  @override
  String get profileManager => 'Profilverwaltung';

  @override
  String get createNewProfile => 'Neues Profil erstellen';

  @override
  String get profileName => 'Profilname';

  @override
  String get create => 'Erstellen';

  @override
  String get profiles => 'Profile';

  @override
  String get active => 'Aktiv';

  @override
  String get switchProfile => 'Wechseln';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get addFolder => 'Ordner hinzufügen';

  @override
  String get searchProjects => 'Projekte suchen...';

  @override
  String get deepScanTooltip =>
      'Der Tiefenscan extrahiert vollständige Metadaten aus Projektdateien:\n• BPM (Schläge Pro Minute)\n• Tonart\n• DAW-Version\nDies ist langsamer, liefert aber vollständige Informationen.';

  @override
  String get deepScanConfirm =>
      'Dies scannt alle Projekte und extrahiert vollständige Metadaten (BPM, Tonart, DAW-Version). Dies kann eine Weile dauern. Fortfahren?';

  @override
  String get metadataExtractedSuccessfully =>
      'Metadaten erfolgreich extrahiert';

  @override
  String failedToExtractMetadata(String error) {
    return 'Metadatenextraktion fehlgeschlagen: $error';
  }

  @override
  String get saved => 'Gespeichert';

  @override
  String get failedToLaunchDaw => 'DAW konnte nicht geöffnet werden';

  @override
  String get releaseDetails => 'Veröffentlichungsdetails';

  @override
  String get releaseNotFound => 'Veröffentlichung nicht gefunden';

  @override
  String get error => 'Fehler';

  @override
  String get loading => 'Laden...';

  @override
  String get deleteProfile => 'Profil löschen';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Möchten Sie \"$profileName\" wirklich löschen? Dies löscht alle Projekte, Wurzeln und Veröffentlichungen dieses Profils.';
  }

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get changePhoto => 'Foto ändern';

  @override
  String get remove => 'Entfernen';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Sind Sie sicher, dass Sie \"$trackName\" aus dieser Veröffentlichung entfernen möchten?';
  }

  @override
  String get saveName => 'Namen speichern';

  @override
  String get profilePhotoUpdated => 'Profilfoto aktualisiert.';

  @override
  String get profilePhotoRemoved => 'Profilfoto entfernt.';

  @override
  String profileRenamed(String newName) {
    return 'Profil umbenannt in \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Profil \"$name\" erfolgreich erstellt';
  }

  @override
  String profileDeleted(String name) {
    return 'Profil \"$name\" gelöscht';
  }

  @override
  String get pleaseEnterProfileName => 'Bitte geben Sie einen Profilnamen ein';

  @override
  String failedToCreateProfile(String error) {
    return 'Profil konnte nicht erstellt werden: $error';
  }

  @override
  String get noProfilesFound =>
      'Keine Profile gefunden. Erstellen Sie eines oben.';

  @override
  String created(String date) {
    return 'Erstellt';
  }

  @override
  String get toggleSort => 'Sortierung umschalten';

  @override
  String get clearLibraryTooltip => 'Bibliothek leeren (Projekte und Wurzeln)';

  @override
  String lastModified(String date) {
    return 'Zuletzt geändert: $date';
  }

  @override
  String get name => 'Name';

  @override
  String get status => 'Status';

  @override
  String get phase => 'Phase';

  @override
  String get filterByPhase => 'Nach Phase filtern';

  @override
  String get allPhases => 'Alle Phasen';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Zuletzt Geändert';

  @override
  String get actions => 'Aktionen';

  @override
  String get hide => 'Verstecken';

  @override
  String get unhide => 'Anzeigen';

  @override
  String get extractMetadata => 'Metadaten Extrahieren';

  @override
  String get createRelease => 'Veröffentlichung Erstellen';

  @override
  String get clearSelection => 'Auswahl Löschen';

  @override
  String get selectAllProjects => 'Alle Projekte auswählen';

  @override
  String get switchingProfiles => 'Profile wechseln...';

  @override
  String get scanningProjects => 'Projekte scannen...';

  @override
  String get projectsTab => 'Projekte';

  @override
  String get releasesTab => 'Veröffentlichungen';

  @override
  String get showHidden => 'Versteckte Anzeigen';

  @override
  String get showAll => 'Alle Anzeigen';

  @override
  String get showOnlyHidden => 'Nur Versteckte Anzeigen';

  @override
  String get deleteRootPath => 'Stammpfad Löschen';

  @override
  String deleteRootPathMessage(String path) {
    return 'Möchten Sie \"$path\" wirklich entfernen? Dies entfernt auch alle Projekte aus diesem Ordner, die nicht in Veröffentlichungen sind.';
  }

  @override
  String rootsCount(int count) {
    return 'Wurzeln: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Projekte: $count';
  }

  @override
  String get hiddenOnly => '(nur versteckt)';

  @override
  String hiddenCount(int count) {
    return '($count versteckt)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count Projekt$plural versteckt.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count Projekt$plural angezeigt.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Projekte konnten nicht versteckt werden: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Projekte konnten nicht angezeigt werden: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Sind Sie sicher, dass Sie \"$projectName\" ausblenden möchten?';
  }

  @override
  String releaseCreated(String title) {
    return 'Veröffentlichung \"$title\" erfolgreich erstellt.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Veröffentlichung konnte nicht erstellt werden: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Fehler beim Hinzufügen des Ordners: $error';
  }

  @override
  String get noProjectsFoundInRoots =>
      'Keine Projekte in den ausgewählten Wurzeln gefunden.';

  @override
  String get selectProjectsFolder => 'Wählen Sie einen Projektordner';

  @override
  String get enterReleaseTitle => 'Veröffentlichungstitel Eingeben';

  @override
  String get releaseTitle => 'Veröffentlichungstitel';

  @override
  String get enterReleaseTitleHint => 'Veröffentlichungstitel eingeben';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Metadaten für $count Projekt$plural extrahiert. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count fehlgeschlagen.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'BPM-Datei konnte nicht geschrieben werden: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Tonart-Datei konnte nicht geschrieben werden: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Öffnen fehlgeschlagen: $error';
  }

  @override
  String get libraryCleared => 'Bibliothek geleert.';

  @override
  String scanType(String type) {
    return '$type Scan';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type abgeschlossen: $count Projekt$plural hinzugefügt/aktualisiert.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count Projekt$plural ausgewählt';
  }

  @override
  String openingFolder(String projectName) {
    return 'Öffne Ordner für $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Ordner konnte nicht geöffnet werden: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Betriebssystem wird zum Öffnen von Ordnern nicht unterstützt.';

  @override
  String get noProjectsAvailable =>
      'Keine Projekte verfügbar. Bitte fügen Sie zuerst Projekte hinzu.';

  @override
  String get createNewRelease => 'Neue Veröffentlichung Erstellen';

  @override
  String get deleteRelease => 'Veröffentlichung Löschen';

  @override
  String deleteReleaseMessage(String title) {
    return 'Möchten Sie \"$title\" wirklich löschen?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Veröffentlichung \"$title\" gelöscht.';
  }

  @override
  String get selectTracks => 'Titel Auswählen';

  @override
  String get continueButton => 'Fortfahren';

  @override
  String get noReleasesYet => 'Noch keine Veröffentlichungen';

  @override
  String get createFirstRelease =>
      'Erstellen Sie Ihre erste Veröffentlichung, indem Sie Titel aus Ihren Projekten auswählen';

  @override
  String releasesCount(int count) {
    return 'Veröffentlichungen ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Fehler beim Laden der Veröffentlichungen: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Titel ($count)';
  }

  @override
  String get addTracks => 'Titel Hinzufügen';

  @override
  String get allProjectsAlreadyInRelease =>
      'Alle Projekte sind bereits in dieser Veröffentlichung.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return '$count Titel$plural zur Veröffentlichung hinzugefügt.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Veröffentlichungsdateien ($count)';
  }

  @override
  String get addFiles => 'Dateien Hinzufügen';

  @override
  String addedFilesToRelease(int count, String plural) {
    return '$count Datei$plural zur Veröffentlichung hinzugefügt.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Dateien konnten nicht hinzugefügt werden: $error';
  }

  @override
  String get noFilesToDownload => 'Keine Dateien zum Herunterladen.';

  @override
  String zipFileSaved(String path) {
    return 'ZIP-Datei gespeichert in: $path';
  }

  @override
  String failedToCreateZip(String error) {
    return 'ZIP konnte nicht erstellt werden: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'Ausgewählte Datei existiert nicht.';

  @override
  String get imageSavedSuccessfully => 'Bild erfolgreich gespeichert!';

  @override
  String failedToSaveImage(String error) {
    return 'Bild konnte nicht gespeichert werden: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Fehler beim Laden der Veröffentlichung: $error';
  }

  @override
  String errorLoadingProjects(String error) {
    return 'Fehler beim Laden der Projekte: $error';
  }

  @override
  String get releaseSaved => 'Veröffentlichung gespeichert.';

  @override
  String get releaseDate => 'Veröffentlichungsdatum';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Veröffentlichungsdatum konnte nicht gespeichert werden: $error';
  }

  @override
  String get releaseDateSaved => 'Veröffentlichungsdatum gespeichert.';

  @override
  String get releaseDateCleared => 'Veröffentlichungsdatum gelöscht.';

  @override
  String get saveReleaseFilesZip => 'Veröffentlichungsdateien ZIP speichern';

  @override
  String failedToOpenFile(String error) {
    return 'Datei konnte nicht geöffnet werden: $error';
  }

  @override
  String failedToPlayAudio(String error) {
    return 'Audio konnte nicht abgespielt werden: $error';
  }

  @override
  String get renameFile => 'Datei Umbenennen';

  @override
  String get selectTracksToAdd => 'Titel zum Hinzufügen Auswählen';

  @override
  String get fileNameUpdated => 'Dateiname aktualisiert.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Fehler beim Aktualisieren des Dateinamens: $error';
  }

  @override
  String get deleteFile => 'Datei Löschen';

  @override
  String deleteFileMessage(String fileName) {
    return 'Möchten Sie \"$fileName\" wirklich löschen?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'Datei \"$fileName\" gelöscht.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Datei konnte nicht gelöscht werden: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Ordner konnte nicht geöffnet werden: $error';
  }

  @override
  String get artwork => 'Cover';

  @override
  String get title => 'Titel';

  @override
  String get tracks => 'Titel';

  @override
  String get description => 'Beschreibung';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Titel zum Einbeziehen in die Veröffentlichung auswählen ($count ausgewählt)';
  }

  @override
  String get searchTracks => 'Titel suchen';

  @override
  String get searchTracksHint => 'Suche nach Name oder DAW-Typ';

  @override
  String get noTracksFound => 'Keine Titel gefunden';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get fileNotFound => 'Datei nicht gefunden';

  @override
  String get fileName => 'Dateiname';

  @override
  String get editTodo => 'Aufgabe Bearbeiten';

  @override
  String get todoText => 'Aufgabentext';

  @override
  String get enterTodoText => 'Aufgabentext eingeben';

  @override
  String get addNewTodo => 'Neue Aufgabe hinzufügen';

  @override
  String get enterTodoItem => 'Aufgabenelement eingeben';

  @override
  String get todoList => 'Aufgabenliste';

  @override
  String get addToRelease => 'Zur Veröffentlichung Hinzufügen';

  @override
  String get createNew => 'Neu Erstellen';

  @override
  String get addToExisting => 'Zu Existierender Hinzufügen';

  @override
  String get createAndAdd => 'Erstellen und Hinzufügen';

  @override
  String get selectRelease => 'Wählen Sie eine Veröffentlichung';

  @override
  String get noExistingReleasesFound =>
      'Keine bestehenden Veröffentlichungen gefunden.';

  @override
  String get addToSelectedRelease =>
      'Zur Ausgewählten Veröffentlichung Hinzufügen';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Profilfoto konnte nicht gespeichert werden: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Profilfoto konnte nicht entfernt werden: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Profil konnte nicht umbenannt werden: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Profil konnte nicht gelöscht werden: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Fehler beim Laden der Profile: $error';
  }

  @override
  String get projectPhaseIdea => 'Idee';

  @override
  String get projectPhaseArranging => 'Arrangement';

  @override
  String get projectPhaseMixing => 'Mischen';

  @override
  String get projectPhaseMastering => 'Mastering';

  @override
  String get projectPhaseFinished => 'Fertig';

  @override
  String get changeStatus => 'Phase Ändern';

  @override
  String get selectNewStatus => 'Neue Phase auswählen:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Phase für $count Projekt$plural auf \"$status\" geändert';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Phase für $successCount Projekt$successPlural auf \"$status\" geändert, $failCount fehlgeschlagen$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Fehler beim Ändern der Phase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Profilname bearbeiten';

  @override
  String get tooltipAddTodo => 'Aufgabe hinzufügen';

  @override
  String get tooltipClearDate => 'Datum löschen';

  @override
  String get tooltipPickDate => 'Datum auswählen';

  @override
  String get tooltipViewDetails => 'Details Anzeigen';

  @override
  String get tooltipLaunchInDaw => 'Im DAW öffnen';

  @override
  String get tooltipRemoveFromRelease => 'Aus Veröffentlichung Entfernen';

  @override
  String get profile => 'Profil';

  @override
  String get noDateSet => 'Kein Datum festgelegt';

  @override
  String get imageNotFound => 'Bild nicht gefunden';

  @override
  String get clickToBrowseArtwork => 'Klicken Sie, um Artwork zu durchsuchen';

  @override
  String get noFilesAddedYet =>
      'Noch keine Dateien hinzugefügt.\nKlicken Sie auf \"Dateien Hinzufügen\", um Veröffentlichungsdateien hochzuladen.';

  @override
  String get noTodosYet => 'Noch keine Aufgaben. Fügen Sie oben eine hinzu.';

  @override
  String get done => 'Erledigt';

  @override
  String get backupAndRestore => 'Sicherung und Wiederherstellung';

  @override
  String get exportBackup => 'Sicherung Exportieren';

  @override
  String get importBackup => 'Sicherung Importieren';

  @override
  String get backupExportedSuccessfully => 'Sicherung erfolgreich exportiert';

  @override
  String failedToExportBackup(String error) {
    return 'Fehler beim Exportieren der Sicherung: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Sicherung erfolgreich importiert: $projectsCount Projekte, $rootsCount Wurzeln, $releasesCount Veröffentlichungen';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Fehler beim Importieren der Sicherung: $error';
  }

  @override
  String get importBackupMessage =>
      'Wählen Sie, wie die Sicherung importiert werden soll:';

  @override
  String get mergeWithCurrentProfile =>
      'Mit dem aktuellen aktiven Profil zusammenführen';

  @override
  String get replaceCurrentProfile =>
      'Das aktuelle Profil vollständig ersetzen (WARNUNG: Dies löscht alle Daten des aktuellen Profils)';

  @override
  String get createNewProfileForImport =>
      'Ein neues Profil für diese Daten erstellen';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Sicherung in neues Profil \"$profileName\" importiert: $projectsCount Projekte, $rootsCount Wurzeln, $releasesCount Veröffentlichungen';
  }

  @override
  String get noProfileSelected => 'Kein Profil ausgewählt';

  @override
  String get exportBackupDialogTitle => 'Sicherung Exportieren';

  @override
  String get importBackupDialogTitle => 'Sicherung Importieren';

  @override
  String get invalidBackupFileFormat =>
      'Ungültiges Sicherungsdateiformat: Version fehlt';

  @override
  String get profileNameRequiredForNewProfile =>
      'Der Profilname ist beim Erstellen eines neuen Profils erforderlich';

  @override
  String get currentProfileRequired =>
      'Das aktuelle Profil ist für den Modus Zusammenführen oder Ersetzen erforderlich';
}
