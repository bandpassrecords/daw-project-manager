// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Gestionnaire de Projets DAW';

  @override
  String get projectDetails => 'Détails du Projet';

  @override
  String get back => 'Retour';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get launch => 'Ouvrir';

  @override
  String get view => 'Voir';

  @override
  String get openFolder => 'Ouvrir le Dossier';

  @override
  String get openInDaw => 'Lancer dans le DAW';

  @override
  String get extract => 'Extraire';

  @override
  String get extracting => 'Extraction…';

  @override
  String get extractingMetadata => 'Extraction des métadonnées...';

  @override
  String get deepScan => 'Scan Approfondi';

  @override
  String get rescan => 'Rescanner';

  @override
  String get scanning => 'Scan en cours…';

  @override
  String get projectName => 'Nom du Projet';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tonalité (ex: C#m, F majeur)';

  @override
  String get notes => 'Notes';

  @override
  String get projectPhase => 'Phase du Projet';

  @override
  String get failedToLoad => 'Échec du chargement';

  @override
  String get fileMissing => 'Fichier manquant.';

  @override
  String launchingProject(String projectName) {
    return 'Ouverture de $projectName…';
  }

  @override
  String get clearLibrary => 'Vider la Bibliothèque';

  @override
  String get clearLibraryMessage =>
      'Cela supprimera tous les projets enregistrés et dossiers sources. Continuer?';

  @override
  String get clear => 'Vider';

  @override
  String get roots => 'Racines';

  @override
  String get projects => 'Projets';

  @override
  String get hidden => 'masqués';

  @override
  String get profileManager => 'Gestionnaire de Profils';

  @override
  String get createNewProfile => 'Créer un Nouveau Profil';

  @override
  String get profileName => 'Nom du Profil';

  @override
  String get create => 'Créer';

  @override
  String get profiles => 'Profils';

  @override
  String get active => 'Actif';

  @override
  String get switchProfile => 'Changer';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get addFolder => 'Ajouter un Dossier';

  @override
  String get searchProjects => 'Rechercher des projets...';

  @override
  String get deepScanTooltip =>
      'Le Scan Approfondi extrait les métadonnées complètes des fichiers de projet:\n• BPM (Battements Par Minute)\n• Tonalité Musicale\n• Version du DAW\nC\'est plus lent mais fournit des informations complètes.';

  @override
  String get deepScanConfirm =>
      'Cela scannera tous les projets et extraira les métadonnées complètes (BPM, Tonalité, Version du DAW). Cela peut prendre un certain temps. Continuer?';

  @override
  String get metadataExtractedSuccessfully =>
      'Métadonnées extraites avec succès';

  @override
  String failedToExtractMetadata(String error) {
    return 'Échec de l\'extraction des métadonnées: $error';
  }

  @override
  String get saved => 'Enregistré';

  @override
  String get failedToLaunchDaw => 'Échec de l\'ouverture du DAW';

  @override
  String get releaseDetails => 'Détails de la Sortie';

  @override
  String get releaseNotFound => 'Sortie Non Trouvée';

  @override
  String get error => 'Erreur';

  @override
  String get loading => 'Chargement...';

  @override
  String get deleteProfile => 'Supprimer le Profil';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$profileName\"? Cela supprimera tous les projets, racines et sorties de ce profil.';
  }

  @override
  String get editProfile => 'Modifier le Profil';

  @override
  String get changePhoto => 'Changer la Photo';

  @override
  String get remove => 'Supprimer';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$trackName\" de cette sortie ?';
  }

  @override
  String get saveName => 'Enregistrer le Nom';

  @override
  String get profilePhotoUpdated => 'Photo de profil mise à jour.';

  @override
  String get profilePhotoRemoved => 'Photo de profil supprimée.';

  @override
  String profileRenamed(String newName) {
    return 'Profil renommé en \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Profil \"$name\" créé avec succès';
  }

  @override
  String profileDeleted(String name) {
    return 'Profil \"$name\" supprimé';
  }

  @override
  String get pleaseEnterProfileName => 'Veuillez entrer un nom de profil';

  @override
  String failedToCreateProfile(String error) {
    return 'Échec de la création du profil: $error';
  }

  @override
  String get noProfilesFound => 'Aucun profil trouvé. Créez-en un ci-dessus.';

  @override
  String created(String date) {
    return 'Créé';
  }

  @override
  String get toggleSort => 'Basculer le tri';

  @override
  String get clearLibraryTooltip =>
      'Vider la Bibliothèque (projets et racines)';

  @override
  String lastModified(String date) {
    return 'Dernière modification: $date';
  }

  @override
  String get name => 'Nom';

  @override
  String get status => 'Statut';

  @override
  String get phase => 'Phase';

  @override
  String get filterByPhase => 'Filtrer par Phase';

  @override
  String get allPhases => 'Toutes les Phases';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Dernière Modification';

  @override
  String get actions => 'Actions';

  @override
  String get hide => 'Masquer';

  @override
  String get unhide => 'Afficher';

  @override
  String get extractMetadata => 'Extraire les Métadonnées';

  @override
  String get createRelease => 'Créer une Sortie';

  @override
  String get clearSelection => 'Effacer la Sélection';

  @override
  String get selectAllProjects => 'Sélectionner tous les projets';

  @override
  String get switchingProfiles => 'Changement de profils...';

  @override
  String get scanningProjects => 'Scan des projets...';

  @override
  String get projectsTab => 'Projets';

  @override
  String get releasesTab => 'Sorties';

  @override
  String get showHidden => 'Afficher les Masqués';

  @override
  String get showAll => 'Afficher Tout';

  @override
  String get showOnlyHidden => 'Afficher Seulement les Masqués';

  @override
  String get deleteRootPath => 'Supprimer le Chemin Racine';

  @override
  String deleteRootPathMessage(String path) {
    return 'Êtes-vous sûr de vouloir supprimer \"$path\"? Cela supprimera également tous les projets de ce dossier qui ne sont pas dans les sorties.';
  }

  @override
  String rootsCount(int count) {
    return 'Racines: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Projets: $count';
  }

  @override
  String get hiddenOnly => '(masqués uniquement)';

  @override
  String hiddenCount(int count) {
    return '($count masqués)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count projet$plural masqué$plural.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count projet$plural affiché$plural.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Échec du masquage des projets: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Échec de l\'affichage des projets: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Êtes-vous sûr de vouloir masquer \"$projectName\" ?';
  }

  @override
  String releaseCreated(String title) {
    return 'Sortie \"$title\" créée avec succès.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Échec de la création de la sortie: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Erreur lors de l\'ajout du dossier: $error';
  }

  @override
  String get noProjectsFoundInRoots =>
      'Aucun projet trouvé dans les racines sélectionnées.';

  @override
  String get selectProjectsFolder => 'Sélectionnez un dossier de projets';

  @override
  String get enterReleaseTitle => 'Entrez le Titre de la Sortie';

  @override
  String get releaseTitle => 'Titre de la Sortie';

  @override
  String get enterReleaseTitleHint => 'Entrez le titre de la sortie';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Métadonnées extraites pour $count projet$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count échoué$plural.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Échec de l\'écriture du fichier BPM: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Échec de l\'écriture du fichier de tonalité: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Échec de l\'ouverture: $error';
  }

  @override
  String get libraryCleared => 'Bibliothèque vidée.';

  @override
  String scanType(String type) {
    return 'Scan $type';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type terminé: $count projet$plural ajouté$plural/mis à jour$plural.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count projet$plural sélectionné$plural';
  }

  @override
  String openingFolder(String projectName) {
    return 'Ouverture du dossier pour $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Échec de l\'ouverture du dossier: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Système d\'exploitation non pris en charge pour ouvrir le dossier.';

  @override
  String get noProjectsAvailable =>
      'Aucun projet disponible. Veuillez d\'abord ajouter des projets.';

  @override
  String get createNewRelease => 'Créer une Nouvelle Sortie';

  @override
  String get deleteRelease => 'Supprimer la Sortie';

  @override
  String deleteReleaseMessage(String title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Sortie \"$title\" supprimée.';
  }

  @override
  String get selectTracks => 'Sélectionner les Pistes';

  @override
  String get continueButton => 'Continuer';

  @override
  String get noReleasesYet => 'Aucune sortie pour le moment';

  @override
  String get createFirstRelease =>
      'Créez votre première sortie en sélectionnant des pistes de vos projets';

  @override
  String releasesCount(int count) {
    return 'Sorties ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Erreur lors du chargement des sorties: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Pistes ($count)';
  }

  @override
  String get addTracks => 'Ajouter des Pistes';

  @override
  String get allProjectsAlreadyInRelease =>
      'Tous les projets sont déjà dans cette sortie.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Ajouté$plural $count piste$plural à la sortie.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Fichiers de la Sortie ($count)';
  }

  @override
  String get addFiles => 'Ajouter des Fichiers';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Ajouté$plural $count fichier$plural à la sortie.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Échec de l\'ajout des fichiers: $error';
  }

  @override
  String get noFilesToDownload => 'Aucun fichier à télécharger.';

  @override
  String zipFileSaved(String path) {
    return 'Fichier ZIP enregistré dans: $path';
  }

  @override
  String failedToCreateZip(String error) {
    return 'Échec de la création du ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist =>
      'Le fichier sélectionné n\'existe pas.';

  @override
  String get imageSavedSuccessfully => 'Image enregistrée avec succès!';

  @override
  String failedToSaveImage(String error) {
    return 'Échec de l\'enregistrement de l\'image: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Erreur lors du chargement de la sortie: $error';
  }

  @override
  String errorLoadingProjects(String error) {
    return 'Erreur lors du chargement des projets: $error';
  }

  @override
  String get releaseSaved => 'Sortie enregistrée.';

  @override
  String get releaseDate => 'Date de Sortie';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Échec de l\'enregistrement de la date de sortie: $error';
  }

  @override
  String get releaseDateSaved => 'Date de sortie enregistrée.';

  @override
  String get releaseDateCleared => 'Date de sortie effacée.';

  @override
  String get saveReleaseFilesZip => 'Enregistrer les fichiers ZIP de la sortie';

  @override
  String failedToOpenFile(String error) {
    return 'Échec de l\'ouverture du fichier: $error';
  }

  @override
  String failedToPlayAudio(String error) {
    return 'Échec de la lecture audio: $error';
  }

  @override
  String get renameFile => 'Renommer le Fichier';

  @override
  String get selectTracksToAdd => 'Sélectionner les Pistes à Ajouter';

  @override
  String get fileNameUpdated => 'Nom du fichier mis à jour.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Erreur lors de la mise à jour du nom du fichier: $error';
  }

  @override
  String get deleteFile => 'Supprimer le Fichier';

  @override
  String deleteFileMessage(String fileName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'Fichier \"$fileName\" supprimé.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Échec de la suppression du fichier: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Impossible d\'ouvrir le dossier: $error';
  }

  @override
  String get artwork => 'Artwork';

  @override
  String get title => 'Titre';

  @override
  String get tracks => 'Pistes';

  @override
  String get description => 'Description';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Sélectionner les pistes à inclure dans la sortie ($count sélectionnée$plural)';
  }

  @override
  String get searchTracks => 'Rechercher des pistes';

  @override
  String get searchTracksHint => 'Rechercher par nom ou type de DAW';

  @override
  String get noTracksFound => 'Aucune piste trouvée';

  @override
  String get unknown => 'Inconnu';

  @override
  String get fileNotFound => 'Fichier non trouvé';

  @override
  String get fileName => 'Nom du Fichier';

  @override
  String get editTodo => 'Modifier la Tâche';

  @override
  String get todoText => 'Texte de la tâche';

  @override
  String get enterTodoText => 'Entrez le texte de la tâche';

  @override
  String get addNewTodo => 'Ajouter une nouvelle tâche';

  @override
  String get enterTodoItem => 'Entrez l\'élément de la tâche';

  @override
  String get todoList => 'Liste de Tâches';

  @override
  String get addToRelease => 'Ajouter à la Sortie';

  @override
  String get createNew => 'Créer Nouveau';

  @override
  String get addToExisting => 'Ajouter à l\'Existant';

  @override
  String get createAndAdd => 'Créer et Ajouter';

  @override
  String get selectRelease => 'Sélectionnez une sortie';

  @override
  String get noExistingReleasesFound => 'Aucune sortie existante trouvée.';

  @override
  String get addToSelectedRelease => 'Ajouter à la Sortie Sélectionnée';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Échec de l\'enregistrement de la photo de profil: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Échec de la suppression de la photo de profil: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Échec du renommage du profil: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Échec de la suppression du profil: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Erreur lors du chargement des profils: $error';
  }

  @override
  String get projectPhaseIdea => 'Idée';

  @override
  String get projectPhaseArranging => 'Arrangement';

  @override
  String get projectPhaseMixing => 'Mixage';

  @override
  String get projectPhaseMastering => 'Masterisation';

  @override
  String get projectPhaseFinished => 'Terminé';

  @override
  String get changeStatus => 'Changer la Phase';

  @override
  String get selectNewStatus => 'Sélectionnez la nouvelle phase:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Phase changée en \"$status\" pour $count projet$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Phase changée en \"$status\" pour $successCount projet$successPlural, $failCount a échoué$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Échec du changement de phase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Modifier le nom du profil';

  @override
  String get tooltipAddTodo => 'Ajouter une tâche';

  @override
  String get tooltipClearDate => 'Effacer la date';

  @override
  String get tooltipPickDate => 'Choisir la date';

  @override
  String get tooltipViewDetails => 'Voir les Détails';

  @override
  String get tooltipLaunchInDaw => 'Ouvrir dans le DAW';

  @override
  String get tooltipRemoveFromRelease => 'Retirer de la Sortie';

  @override
  String get profile => 'Profil';

  @override
  String get noDateSet => 'Aucune date définie';

  @override
  String get imageNotFound => 'Image introuvable';

  @override
  String get clickToBrowseArtwork => 'Cliquez pour parcourir l\'artwork';

  @override
  String get noFilesAddedYet =>
      'Aucun fichier ajouté pour le moment.\nCliquez sur \"Ajouter des Fichiers\" pour télécharger les fichiers de la sortie.';

  @override
  String get noTodosYet =>
      'Aucune tâche pour le moment. Ajoutez-en une ci-dessus.';

  @override
  String get done => 'Terminé';

  @override
  String get backupAndRestore => 'Sauvegarde et Restauration';

  @override
  String get exportBackup => 'Exporter la Sauvegarde';

  @override
  String get importBackup => 'Importer la Sauvegarde';

  @override
  String get backupExportedSuccessfully => 'Sauvegarde exportée avec succès';

  @override
  String failedToExportBackup(String error) {
    return 'Échec de l\'exportation de la sauvegarde : $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Sauvegarde importée avec succès : $projectsCount projets, $rootsCount racines, $releasesCount sorties';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Échec de l\'importation de la sauvegarde : $error';
  }

  @override
  String get importBackupMessage =>
      'Choisissez comment importer la sauvegarde :';

  @override
  String get mergeWithCurrentProfile => 'Fusionner avec le profil actif actuel';

  @override
  String get replaceCurrentProfile =>
      'Remplacer entièrement le profil actuel (ATTENTION : Cela supprimera toutes les données du profil actuel)';

  @override
  String get createNewProfileForImport =>
      'Créer un nouveau profil pour ces données';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Sauvegarde importée dans le nouveau profil \"$profileName\" : $projectsCount projets, $rootsCount racines, $releasesCount sorties';
  }

  @override
  String get noProfileSelected => 'Aucun profil sélectionné';

  @override
  String get exportBackupDialogTitle => 'Exporter la Sauvegarde';

  @override
  String get importBackupDialogTitle => 'Importer la Sauvegarde';

  @override
  String get invalidBackupFileFormat =>
      'Format de fichier de sauvegarde invalide : version manquante';

  @override
  String get profileNameRequiredForNewProfile =>
      'Le nom du profil est requis lors de la création d\'un nouveau profil';

  @override
  String get currentProfileRequired =>
      'Le profil actuel est requis pour le mode fusionner ou remplacer';
}
