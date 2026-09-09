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
  String get enable => 'Activer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get undo => 'Annuler';

  @override
  String get customInterval => 'Personnalisé';

  @override
  String get close => 'Fermer';

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
  String get refreshProject => 'Actualiser';

  @override
  String get scanning => 'Scan en cours…';

  @override
  String get newProjectBadge => 'NOUVEAU';

  @override
  String get projectName => 'Nom du Projet';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tonalité (ex: C#m, F majeur)';

  @override
  String get notes => 'Notes';

  @override
  String get expandNotes => 'Agrandir';

  @override
  String get collapseNotes => 'Réduire';

  @override
  String get projectNotesFromDaw => 'Notes du Projet (depuis le fichier DAW)';

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
  String failedToLaunchProject(String projectName) {
    return 'Échec de l\'ouverture de $projectName';
  }

  @override
  String get clearLibrary => 'Vider la Bibliothèque';

  @override
  String get clearLibraryMessage =>
      'Cela supprimera tous les projets enregistrés et dossiers sources. Continuer?';

  @override
  String get clear => 'Vider';

  @override
  String get roots => 'Dossiers de Projets';

  @override
  String get pathsSettingsDangerZoneTitle => 'Bibliothèque';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Effacez tous les projets et dossiers de projets du profil actuel.';

  @override
  String get projectFoldersSectionTitle => 'Dossiers de projets';

  @override
  String get projectFoldersSectionSubtitle =>
      'Dossiers qui seront scannés pour trouver des projets DAW.';

  @override
  String get projectFoldersEmptyTitle =>
      'Aucun dossier de projets pour le moment';

  @override
  String get projectFoldersEmptySubtitle =>
      'Ajoutez au moins un dossier pour commencer à scanner les projets.';

  @override
  String get notScannedYet => 'Pas encore scanné';

  @override
  String lastScan(String date) {
    return 'Dernier scan : $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Dossiers exclus';

  @override
  String get excludedFoldersSectionSubtitle =>
      'Ces dossiers seront ignorés pendant le scan, même s\'ils se trouvent dans un dossier de projets.';

  @override
  String get addExcludedFolder => 'Ajouter exclu';

  @override
  String get selectExcludedFolder => 'Sélectionnez un dossier à exclure';

  @override
  String get excludedFoldersEmptyTitle => 'Aucun dossier exclu';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Optionnel : ajoutez des dossiers que vous ne voulez jamais scanner.';

  @override
  String get removeExcludedFolderTitle => 'Supprimer le dossier exclu ?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'Ce dossier ne sera plus exclu :\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'Ce dossier ne sera plus exclu.';

  @override
  String get desktopOnlyPathsSettings =>
      'Cette page est disponible uniquement dans l’application de bureau.';

  @override
  String get renameProjectFolderTitle => 'Nom d\'Affichage';

  @override
  String get flatpakPortalPathExplanation =>
      'Ce chemin est un emplacement en bac à sable (sandbox), pas l\'emplacement réel du dossier — Flatpak ne partage pas cette information avec l\'application. Utilisez le nom ci-dessus pour l\'identifier à la place.';

  @override
  String get removeProjectFolderTitle => 'Supprimer le dossier de projets ?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Êtes-vous sûr de vouloir supprimer \"$path\" ? Cela supprimera aussi tous les projets de ce dossier qui ne sont pas dans des sorties.';
  }

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
  String get searchReleases => 'Rechercher des sorties...';

  @override
  String get searchPlaylists => 'Rechercher des playlists...';

  @override
  String get noReleasesFound => 'Aucune sortie trouvée';

  @override
  String get noPlaylistsFound => 'Aucune playlist trouvée';

  @override
  String get tryDifferentSearch => 'Essayez un terme de recherche différent';

  @override
  String get deepScanConfirm =>
      'Le Scan Approfondi extrait les métadonnées complètes des fichiers de projet:\n• BPM (Battements Par Minute)\n• Tonalité Musicale\n• Version du DAW\n• Notes de Projet (si pris en charge)\n\nC\'est plus lent qu\'un scan régulier et peut prendre un certain temps. Continuer?';

  @override
  String get deepScanViewSupportedDaws =>
      'Voir les DAW et champs pris en charge';

  @override
  String get deepScanOnlyUnscanned =>
      'Scanner uniquement les projets sans métadonnées';

  @override
  String get metadataExtractionTitle => 'Extraction des Métadonnées';

  @override
  String get metadataExtractionSubtitle =>
      'Découvrez quelles données chaque DAW prend en charge';

  @override
  String get metadataExtractionIntro =>
      'Le Scan Approfondi peut lire automatiquement certains de ces champs directement depuis un fichier de projet — le reste doit être saisi manuellement. Ce tableau indique ce qui est automatique aujourd\'hui pour chaque DAW prise en charge.';

  @override
  String get metadataFieldKey => 'Tonalité';

  @override
  String get metadataFieldVersion => 'Version du DAW';

  @override
  String get metadataExtractionManualNote =>
      'Tout champ sans prise en charge automatique peut toujours être saisi manuellement dans le Détail du Projet. Pour le BPM et la Tonalité en particulier, déposer un fichier bpm.txt ou key.txt à côté du projet est également détecté lors du prochain scan.';

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
    return 'Êtes-vous sûr de vouloir supprimer \"$profileName\"? Cela supprimera tous les projets, dossiers de projets et sorties de ce profil.';
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
  String get clearLibraryTooltip =>
      'Vider la Bibliothèque (projets et dossiers de projets)';

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
  String get filters => 'Filtres';

  @override
  String get allPhases => 'Toutes les Phases';

  @override
  String get filterByDaw => 'Filtrer par DAW';

  @override
  String get allDaws => 'Tous les DAW';

  @override
  String get daw => 'DAW';

  @override
  String get clearDaw => 'Effacer le DAW';

  @override
  String get filterByKey => 'Filtrer par Tonalité';

  @override
  String get allKeys => 'Toutes les Tonalités';

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
  String scanProgressLabel(int current, int total) {
    return 'Chargement du projet $current sur $total…';
  }

  @override
  String get search => 'Rechercher';

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
  String get deleteRootPath => 'Supprimer le dossier de projets';

  @override
  String deleteRootPathMessage(String path) {
    return 'Êtes-vous sûr de vouloir supprimer \"$path\"? Cela supprimera également tous les projets de ce dossier qui ne sont pas dans les sorties.';
  }

  @override
  String rootsCount(int count) {
    return 'Dossiers de Projets: $count';
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
  String get deleteMissingProjects => 'Supprimer les manquants';

  @override
  String get deleteMissingProjectsTitle => 'Supprimer les projets manquants ?';

  @override
  String deleteMissingProjectsConfirm(int count, String plural) {
    return '$count projet$plural dont le fichier est introuvable sur cette machine seront définitivement supprimés, ainsi que toutes les notes, échéances et l\'historique des sessions. Cette action est irréversible.';
  }

  @override
  String get deleteMissingProjectsConfirmButton => 'Supprimer définitivement';

  @override
  String missingProjectsDeleted(int count, String plural) {
    return '$count projet$plural manquant supprimé.';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(
    int count,
    String plural,
  ) {
    return 'Supprimer également $count projet$plural faisant partie d\'une sortie (les retire aussi de cette sortie)';
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
  String get folderAlreadyAdded => 'Ce dossier a déjà été ajouté.';

  @override
  String get noProjectsFoundInRoots =>
      'Aucun projet trouvé dans les dossiers de projets sélectionnés.';

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
  String get scanCancelled => 'Scan annulé.';

  @override
  String scanFailuresSnackbar(int count, String plural) {
    return '$count projet$plural n\'a/n\'ont pas pu être chargé$plural.';
  }

  @override
  String get scanFailuresSnackbarAction => 'Détails';

  @override
  String get scanFailuresDialogTitle => 'Erreurs de Scan';

  @override
  String get scanFailuresDialogIntro =>
      'Ces fichiers n\'ont pas pu être lus pendant le scan (ils ont peut-être été supprimés, déplacés ou verrouillés par un autre programme) :';

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
  String releasesSelected(int count, String plural) {
    return '$count sortie$plural sélectionnée$plural';
  }

  @override
  String get deleteSelectedReleases => 'Supprimer la sélection';

  @override
  String deleteSelectedReleasesConfirm(int count, String plural) {
    return 'Voulez-vous vraiment supprimer $count sortie$plural ?';
  }

  @override
  String releasesDeleted(int count, String plural) {
    return '$count sortie$plural supprimée$plural';
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
  String get creatingZipFile => 'Création du fichier ZIP...';

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
  String get errorLoadingProjects =>
      'Erreur lors du chargement des projets: null';

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
  String get failedToOpenFile => 'Échec de l\'ouverture du fichier';

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
  String addTodoAtTimestamp(String timestamp) {
    return 'Ajouter une tâche à $timestamp';
  }

  @override
  String todoAddedAtTimestamp(String timestamp) {
    return 'Tâche ajoutée à $timestamp';
  }

  @override
  String get todoList => 'Liste de Tâches';

  @override
  String get todoTemplates => 'Modèles de TODO';

  @override
  String get createTemplate => 'Créer un Modèle';

  @override
  String get editTemplate => 'Modifier le Modèle';

  @override
  String get deleteTemplate => 'Supprimer le Modèle';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer le modèle \"$name\" ?';
  }

  @override
  String get templateName => 'Nom du Modèle';

  @override
  String get templateNameHint => 'ex. Liste de Mixage';

  @override
  String get templateItems => 'Éléments du Modèle';

  @override
  String get templateItemsHint => 'Un élément par ligne';

  @override
  String get templateNameAndItemsRequired =>
      'Le nom et les éléments sont requis';

  @override
  String get templateItemsRequired => 'Au moins un élément est requis';

  @override
  String get templateCreated => 'Modèle créé';

  @override
  String get templateUpdated => 'Modèle mis à jour';

  @override
  String get templateDeleted => 'Modèle supprimé';

  @override
  String get noTemplatesYet => 'Pas encore de modèles';

  @override
  String get createFirstTemplate => 'Créez votre premier modèle TODO';

  @override
  String templateItemCount(int count) {
    return '$count élément(s)';
  }

  @override
  String get selectTemplate => 'Sélectionner un Modèle';

  @override
  String get importFromTemplate => 'Importer depuis un Modèle';

  @override
  String get manageTemplates => 'Gérer les Modèles';

  @override
  String get noTemplatesAvailable =>
      'Aucun modèle disponible. Créez-en un d\'abord.';

  @override
  String templateImported(String name, int count) {
    return 'Modèle \"$name\" importé ($count éléments)';
  }

  @override
  String get errorLoadingTemplates => 'Erreur de chargement des modèles';

  @override
  String get createProjectStartFrom => 'Comment souhaitez-vous commencer ?';

  @override
  String get createProjectStartFromHint =>
      'Partez d\'un dossier vide ou copiez un modèle enregistré.';

  @override
  String get createProjectEmptyFolder => 'Dossier Vide';

  @override
  String get createProjectFromTemplate => 'Depuis un Modèle';

  @override
  String get selectTemplateMainFile =>
      'Sélectionner le Fichier Principal du Modèle';

  @override
  String get registerTemplate => 'Enregistrer le Modèle';

  @override
  String get projectTemplates => 'Modèles de Projet';

  @override
  String get searchTemplates => 'Rechercher des modèles...';

  @override
  String get createFirstProjectTemplate =>
      'Enregistrez un dossier modèle à réutiliser pour de nouveaux projets';

  @override
  String get noMatchingTemplates => 'Aucun modèle correspondant';

  @override
  String get templateSourceMissing => 'Dossier source du modèle introuvable';

  @override
  String get useTemplate => 'Utiliser';

  @override
  String get selectTemplatesParentFolder =>
      'Sélectionner le Dossier Parent des Modèles';

  @override
  String get templateSourceFolder => 'Dossier Source';

  @override
  String get dateCreatedColumn => 'Créé';

  @override
  String get dateModifiedColumn => 'Modifié';

  @override
  String get manageTemplateFolders => 'Gérer les Dossiers';

  @override
  String get addTemplateFolder => 'Ajouter un Dossier';

  @override
  String get removeTemplateFolder => 'Supprimer le Dossier de Modèles';

  @override
  String removeTemplateFolderConfirm(String path) {
    return 'Supprimer \"$path\" de vos dossiers de modèles enregistrés ? Les modèles déjà importés ne seront pas supprimés.';
  }

  @override
  String get noTemplateFoldersRegistered =>
      'Aucun dossier de modèles enregistré';

  @override
  String get refreshTemplateFolders =>
      'Actualiser les modèles depuis les dossiers enregistrés';

  @override
  String lastRefreshed(String date) {
    return 'Dernière actualisation $date';
  }

  @override
  String templatesRefreshedSummary(int count) {
    return '$count nouveau(x) modèle(s) ajouté(s)';
  }

  @override
  String templatesSelected(int count, String plural) {
    return '$count modèle$plural sélectionné$plural';
  }

  @override
  String get deleteSelectedTemplates => 'Supprimer la sélection';

  @override
  String deleteSelectedTemplatesConfirm(int count, String plural) {
    return 'Voulez-vous vraiment supprimer $count modèle$plural ?';
  }

  @override
  String templatesDeleted(int count, String plural) {
    return '$count modèle$plural supprimé$plural';
  }

  @override
  String get templateDetailTitle => 'Template';

  @override
  String get templateNotFound => 'Modèle introuvable';

  @override
  String get saveAsTemplate => 'Enregistrer comme Modèle';

  @override
  String get newTemplateNameLabel => 'Nom du modèle';

  @override
  String get savedAsTemplate => 'Enregistré comme modèle';

  @override
  String get duplicateTemplate => 'Dupliquer';

  @override
  String get templateDuplicated => 'Modèle dupliqué';

  @override
  String get fileInfo => 'Informations sur le Fichier';

  @override
  String get fileSize => 'Taille du Fichier';

  @override
  String get filePath => 'Chemin';

  @override
  String get fileModified => 'Dernière Modification';

  @override
  String projectsFromThisTemplate(int count) {
    return 'Projets Créés à partir de ce Modèle ($count)';
  }

  @override
  String get noProjectsFromThisTemplate =>
      'Aucun projet créé à partir de ce modèle pour l\'instant';

  @override
  String get importTodos => 'Importer des Tâches depuis un Fichier';

  @override
  String get noTodosInFile => 'Aucune tâche trouvée dans le fichier';

  @override
  String todosImported(int count) {
    return '$count tâche(s) importée(s) avec succès';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Erreur lors de l\'importation: $error';
  }

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
  String get dropImageHere => 'Déposez l\'image ici';

  @override
  String get removeArtwork => 'Supprimer l\'artwork';

  @override
  String get removeArtworkConfirm =>
      'Supprimer cet artwork ? Le fichier image sera supprimé.';

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
  String get backupTabLabel => 'Sauvegarde';

  @override
  String get aboutTabLabel => 'À propos';

  @override
  String get localBackup => 'Sauvegarde Locale';

  @override
  String get appearanceTabLabel => 'Apparence';

  @override
  String get exportBackup => 'Exporter la Sauvegarde';

  @override
  String get importBackup => 'Importer la Sauvegarde';

  @override
  String get exportProjectInfo => 'Exporter les infos';

  @override
  String get exportProjectInfoTooltip =>
      'Enregistrer les informations de ce projet dans un fichier texte';

  @override
  String get exportAllProjectsInfo => 'Exporter tous les projets en TXT';

  @override
  String get exportAllProjectsInfoSubtitle =>
      'Enregistre un fichier texte avec les informations de tous les projets, conservé même après la suppression du fichier DAW';

  @override
  String get projectInfoExported => 'Informations du projet exportées';

  @override
  String allProjectsInfoExported(int count) {
    return 'Informations exportées pour $count projets';
  }

  @override
  String failedToExportProjectInfo(String error) {
    return 'Échec de l\'exportation des informations du projet : $error';
  }

  @override
  String get projectExportHeaderTitle => 'DAW PROJECT MANAGER — PROJECT EXPORT';

  @override
  String projectExportExportedLabel(String dateTime) {
    return 'Exporté : $dateTime';
  }

  @override
  String projectExportTotalProjectsLabel(int count) {
    return 'Total des projets : $count';
  }

  @override
  String projectExportProjectLabel(String name) {
    return 'Projet : $name';
  }

  @override
  String projectExportDawLabel(String dawType) {
    return 'DAW : $dawType';
  }

  @override
  String projectExportDawWithVersionLabel(String dawType, String version) {
    return 'DAW : $dawType $version';
  }

  @override
  String projectExportStatusLabel(String status) {
    return 'Statut : $status';
  }

  @override
  String projectExportBpmLabel(String bpm) {
    return 'BPM : $bpm';
  }

  @override
  String projectExportKeyLabel(String key) {
    return 'Tonalité : $key';
  }

  @override
  String projectExportKeyWithCamelotLabel(String key, String code) {
    return 'Tonalité : $key (Camelot $code)';
  }

  @override
  String projectExportFilePathLabel(String path) {
    return 'Chemin du fichier : $path';
  }

  @override
  String projectExportFileSizeLabel(String size) {
    return 'Taille du fichier : $size';
  }

  @override
  String projectExportFileCreatedLabel(String date) {
    return 'Fichier créé : $date';
  }

  @override
  String projectExportAddedToLibraryLabel(String date) {
    return 'Ajouté à la bibliothèque : $date';
  }

  @override
  String projectExportLastModifiedLabel(String date) {
    return 'Dernière modification : $date';
  }

  @override
  String projectExportDeadlineLabel(String date) {
    return 'Échéance : $date';
  }

  @override
  String projectExportDeadlineWithStatusLabel(String date, String status) {
    return 'Échéance : $date ($status)';
  }

  @override
  String projectExportTotalTimeWorkedLabel(String duration) {
    return 'Temps total travaillé : $duration';
  }

  @override
  String get projectExportNotesLabel => 'Notes :';

  @override
  String get projectExportTodosLabel => 'Tâches :';

  @override
  String projectExportWorkSessionsLabel(int count) {
    return 'Sessions de travail ($count) :';
  }

  @override
  String get noProjectsToExport => 'Aucun projet à exporter';

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
    return 'Sauvegarde importée avec succès : $projectsCount projets, $rootsCount dossiers de projets, $releasesCount sorties';
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
    return 'Sauvegarde importée dans le nouveau profil \"$profileName\" : $projectsCount projets, $rootsCount dossiers de projets, $releasesCount sorties';
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

  @override
  String get previewSong => 'Chanson d\'Aperçu';

  @override
  String get noPreviewSongTitle => 'Pas de chanson d\'aperçu';

  @override
  String get noPreviewSongMessage =>
      'Ce projet n\'a pas de chanson d\'aperçu définie. Sélectionnez un fichier audio pour le charger et le lire.';

  @override
  String get noPreviewSongDragHint =>
      'Vous pouvez également glisser-déposer un fichier audio directement sur la ligne du projet dans le tableau.';

  @override
  String get previewSongRemoved => 'Chanson d\'aperçu supprimée';

  @override
  String get previewSongAdded => 'Chanson d\'aperçu ajoutée';

  @override
  String get previewSongFileNotFound =>
      'Fichier de chanson d\'aperçu introuvable';

  @override
  String get previewSongFileNotFoundMessage =>
      'Le fichier de chanson d\'aperçu est introuvable sur le disque. Voulez-vous sélectionner un nouveau fichier ou supprimer l\'entrée ?';

  @override
  String get selectNewFile => 'Sélectionner un nouveau fichier';

  @override
  String failedToPlayPreview(String error) {
    return 'Échec de la lecture de l\'aperçu : $error';
  }

  @override
  String get removePreviewSong => 'Supprimer la chanson d\'aperçu';

  @override
  String get removePreviewSongConfirm =>
      'Êtes-vous sûr de vouloir supprimer la chanson d\'aperçu ? Cette action ne peut pas être annulée.';

  @override
  String get noPreviewSongSelected => 'Aucune chanson d\'aperçu sélectionnée';

  @override
  String get changePreviewSong => 'Changer la Chanson d\'Aperçu';

  @override
  String get selectPreviewSong => 'Sélectionner une Chanson d\'Aperçu';

  @override
  String get dropAudioFileHere => 'Déposez le fichier audio ici';

  @override
  String projectAge(String age) {
    return 'Âge du projet: $age';
  }

  @override
  String createdDate(String date) {
    return 'créé $date';
  }

  @override
  String completedIn(String duration) {
    return 'Terminé en: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'terminé $date';
  }

  @override
  String get dateToday => 'aujourd\'hui';

  @override
  String get dateYesterday => 'hier';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count semaines',
      one: 'il y a 1 semaine',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count mois',
      one: 'il y a 1 mois',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count ans',
      one: 'il y a 1 an',
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
    return '$years an$yearPlural, $months mois';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years an$plural';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months mois, $days jour$dayPlural';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months mois';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days jour$plural';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours heure$plural';
  }

  @override
  String get ageJustNow => 'À l\'instant';

  @override
  String get ageLessThanHour => 'Moins d\'une heure';

  @override
  String get viewProfile => 'Voir le Profil';

  @override
  String get googleDriveSync => 'Synchronisation Google Drive';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Synchronisez vos données avec Google Drive pour sauvegarder et restaurer entre les appareils.';

  @override
  String get manageGoogleDriveSync => 'Gérer la Synchronisation Google Drive';

  @override
  String get signInToGoogleDrive => 'Se connecter à Google Drive';

  @override
  String get syncNow => 'Synchroniser Maintenant';

  @override
  String get uploadBackup => 'Téléverser la Sauvegarde';

  @override
  String get downloadBackup => 'Télécharger la Sauvegarde';

  @override
  String get newerBackupAvailable =>
      'Nouvelle sauvegarde disponible dans le cloud';

  @override
  String get restoreProjectFromDrive => 'Restaurer depuis Drive';

  @override
  String get restoringProjectFromDrive => 'Restauration depuis Drive...';

  @override
  String get projectRestoredFromDrive => 'Projet restauré depuis Drive';

  @override
  String get projectNotFoundInBackup =>
      'Ce projet n\'a pas été trouvé dans la sauvegarde Drive';

  @override
  String get signInToGoogleDriveFirst =>
      'Veuillez d\'abord vous connecter à Google Drive (ouvrez les paramètres Drive Sync)';

  @override
  String get signOut => 'Se Déconnecter';

  @override
  String get downloadPreviewSongs => 'Télécharger les chansons d\'aperçu';

  @override
  String get downloadPreviewSongsExplanation =>
      'Si décoché, les chansons d\'aperçu seront ignorées (économise du temps et de l\'espace). Vous pouvez les télécharger plus tard si nécessaire.';

  @override
  String get replaceLocalData => 'Remplacer les Données Locales';

  @override
  String get downloadBackupConfirmation =>
      'Cela remplacera vos données locales par la sauvegarde de Google Drive.\n\nÊtes-vous sûr de vouloir continuer?';

  @override
  String get enterAuthorizationCode => 'Entrer le Code d\'Autorisation';

  @override
  String get authorizationCode => 'Code d\'Autorisation';

  @override
  String get pasteCodeFromBrowser => 'Collez le code du navigateur';

  @override
  String get sessionActive => 'Session active';

  @override
  String get signedIn => 'Connecté';

  @override
  String get creatingInitialBackup => 'Création de la sauvegarde initiale...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Connexion réussie et sauvegarde créée sur Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Connexion réussie et sauvegarde créée sur Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Connexion réussie à Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Connexion réussie à Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Connexion annulée ou échouée. Vérifiez la console pour plus de détails.';

  @override
  String get failedToLaunchBrowser => 'Échec du lancement du navigateur';

  @override
  String get signInCancelled => 'Connexion annulée';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Échec de l\'échange du code d\'autorisation';

  @override
  String errorSigningIn(String error) {
    return 'Erreur lors de la connexion: $error';
  }

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get googleSignInError => 'Erreur de Connexion Google';

  @override
  String get developerConsoleNotSetUp =>
      'La console développeur n\'est pas correctement configurée. Veuillez vérifier votre configuration OAuth dans Google Cloud Console.';

  @override
  String get platformError => 'Erreur de Plateforme';

  @override
  String get signedOutFromGoogleDrive => 'Déconnecté de Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Erreur lors de la déconnexion: $error';
  }

  @override
  String get syncing => 'Synchronisation...';

  @override
  String get errorNoProfileSelected => 'Erreur: Aucun profil sélectionné';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Synchronisation terminée! Projets: +$projectsAdded ~$projectsUpdated, Sorties: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Erreur lors de la synchronisation: $error';
  }

  @override
  String get uploadingBackup => 'Téléversement de la sauvegarde...';

  @override
  String get backupUploadedSuccessfully => 'Sauvegarde téléversée avec succès!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Sauvegarde téléversée avec succès sur Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Erreur lors du téléversement de la sauvegarde: $error';
  }

  @override
  String get downloadingBackup => 'Téléchargement de la sauvegarde...';

  @override
  String get checkingForBackup => 'Vérification de la sauvegarde...';

  @override
  String get backupUpToDate => 'La sauvegarde est à jour';

  @override
  String errorCheckingBackup(String error) {
    return 'Erreur lors de la vérification de la sauvegarde: $error';
  }

  @override
  String get download => 'Télécharger';

  @override
  String get remoteBackupIsNewer =>
      'La sauvegarde distante est plus récente que les données locales. Le téléversement l\'écrasera.';

  @override
  String get confirmUpload => 'Confirmer le téléversement';

  @override
  String get noBackupFileFound =>
      'Aucun fichier de sauvegarde trouvé dans Google Drive. Créez d\'abord une sauvegarde en synchronisant vos données.';

  @override
  String get noBackupFileFoundStatus =>
      'Aucun fichier de sauvegarde trouvé. Créez d\'abord une sauvegarde.';

  @override
  String get downloadCancelled => 'Téléchargement annulé';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Sauvegarde téléchargée! Projets: +$projectsAdded ~$projectsUpdated, Sorties: +$releasesAdded ~$releasesUpdated';
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
    return 'Sauvegarde téléchargée!\n\nProjets:\n  • $projectsAdded ajoutés\n  • $projectsUpdated mis à jour\n\nSorties:\n  • $releasesAdded ajoutées\n  • $releasesUpdated mises à jour\n\nPreview Songs:\n  • $previewSongsDownloaded téléchargées\n  • $previewSongsUpdated mises à jour';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Erreur lors du téléchargement de la sauvegarde: $error';
  }

  @override
  String get notSignedInYet => 'Non connecté';

  @override
  String get never => 'Jamais';

  @override
  String signedInAs(String email) {
    return 'Connecté en tant que: $email';
  }

  @override
  String lastSync(String date) {
    return 'Dernière synchronisation: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Sauvegarde distante: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Dernier envoi: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Dernier téléchargement: $date';
  }

  @override
  String get checkForBackup => 'Vérifier la sauvegarde';

  @override
  String get notificationSettings => 'Paramètres de Notification';

  @override
  String get notificationsOnlyOnAndroid =>
      'Les notifications de délai ne sont disponibles que sur les appareils Android.';

  @override
  String get notificationPermissionRequired =>
      'Permission de Notification Requise';

  @override
  String get notificationPermissionDescription =>
      'Veuillez activer les notifications pour recevoir des rappels de délai.';

  @override
  String get notificationPermissionDenied =>
      'Permission de notification refusée. Veuillez l\'activer dans les paramètres.';

  @override
  String get notificationSettingsSaved =>
      'Paramètres de notification enregistrés avec succès';

  @override
  String get errorSavingSettings =>
      'Erreur lors de l\'enregistrement des paramètres';

  @override
  String get enableDeadlineNotifications =>
      'Activer les Notifications de Délai';

  @override
  String get receiveRemindersForDeadlines =>
      'Recevoir des rappels pour les délais de projet';

  @override
  String get notificationTime => 'Heure de Notification';

  @override
  String get timeToReceiveNotifications =>
      'Heure de la journée pour recevoir les notifications';

  @override
  String get reminderDays => 'Jours de Rappel';

  @override
  String get selectDaysBeforeDeadline =>
      'Sélectionnez combien de jours avant le délai vous souhaitez être notifié';

  @override
  String get notifyOnDeadlineDay => 'Notifier le Jour du Délai';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Recevoir également une notification le jour même du délai';

  @override
  String get howItWorks => 'Comment Ça Marche';

  @override
  String get deadlineNotificationsHelp =>
      'Vous recevrez des notifications à l\'heure spécifiée les jours sélectionnés avant chaque délai de projet. Appuyez sur une notification pour ouvrir les détails du projet.';

  @override
  String get oneDay => '1 jour';

  @override
  String xDays(int count) {
    return '$count jours';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get searchSettings => 'Rechercher dans les paramètres';

  @override
  String noSettingsFoundFor(String query) {
    return 'Aucun paramètre trouvé pour « $query »';
  }

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get languageSettingDescription =>
      'La langue utilisée dans toute l\'application.';

  @override
  String get themeSettingDescription =>
      'Le thème de couleur de l\'application.';

  @override
  String get waveformStyle => 'Style de forme d\'onde';

  @override
  String get waveformStyleSettingDescription =>
      'Comment la forme d\'onde de l\'aperçu audio est dessinée.';

  @override
  String get waveformStyleDetailed => 'Détaillé';

  @override
  String get waveformStyleDetailedDescription =>
      'Barres par pixel avec un corps ombré, comme dans une STAN.';

  @override
  String get waveformStyleClassic => 'Classique';

  @override
  String get waveformStyleClassicDescription => 'Un seul contour rempli.';

  @override
  String get waveformChannels => 'Canaux';

  @override
  String get waveformChannelsSettingDescription =>
      'Si la forme d\'onde sépare la stéréo en deux pistes.';

  @override
  String get waveformChannelsSingle => 'Unique';

  @override
  String get waveformChannelsDual => 'Double';

  @override
  String get waveformChannelsSingleDescription =>
      'Une piste affichant le mixage stéréo.';

  @override
  String get waveformChannelsDualDescription =>
      'Gauche et droite empilées en pistes distinctes.';

  @override
  String get waveformChannelsUnavailable => 'Ce fichier n\'a qu\'un seul canal';

  @override
  String get support => 'Soutenir';

  @override
  String get shareDiagnosticLog => 'Partager le journal de diagnostic';

  @override
  String get shareDiagnosticLogEmpty =>
      'Aucun journal de diagnostic pour l\'instant';

  @override
  String get shareDiagnosticLogFolderOpened =>
      'Le partage n\'est pas disponible ici. Le dossier des journaux a été ouvert pour que vous puissiez joindre le fichier manuellement.';

  @override
  String get enableDiagnosticLogging =>
      'Activer la journalisation de diagnostic';

  @override
  String get enableDiagnosticLoggingDescription =>
      'Conserve un petit journal des plantages et des erreurs sur cet appareil, afin que vous puissiez le partager en cas de problème. Désactivé par défaut.';

  @override
  String get clearDiagnosticLog => 'Effacer le journal de diagnostic';

  @override
  String get clearDiagnosticLogConfirmTitle =>
      'Effacer le journal de diagnostic ?';

  @override
  String get clearDiagnosticLogConfirmMessage =>
      'Cela supprimera définitivement le fichier journal de diagnostic. Cette action est irréversible.';

  @override
  String get diagnosticLogCleared => 'Journal de diagnostic effacé';

  @override
  String get supportTheProject => 'Soutenez le projet';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Impossible d\'ouvrir le navigateur. Veuillez visiter: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Erreur lors de l\'ouverture du navigateur: $error';
  }

  @override
  String get generateTestingDatabase => 'Générer Base de Données de Test';

  @override
  String get generateTestingDatabaseMessage =>
      'Cela va créer (ou actualiser) un profil dédié \"Demo — Screenshots\" rempli d\'une grande variété de projets, sorties et playlists d\'exemple pour tous les DAW pris en charge, puis basculer dessus. Vos autres profils restent inchangés. Continuer ?';

  @override
  String get testingDatabaseGenerated =>
      'Profil de démonstration prêt — basculé dessus !';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Échec de la génération de la base de données de test: $error';
  }

  @override
  String get removeTestingDatabase => 'Supprimer la base de données de test';

  @override
  String get removeTestingDatabaseMessage =>
      'Cela supprimera définitivement le profil \"Demo — Screenshots\" ainsi que tous ses projets, sorties, playlists et fichiers audio d\'aperçu d\'exemple. Continuer ?';

  @override
  String get testingDatabaseRemoved => 'Données de démonstration supprimées.';

  @override
  String get noTestingDatabaseFound =>
      'Aucune donnée de démonstration trouvée à supprimer.';

  @override
  String failedToRemoveTestingDatabase(String error) {
    return 'Échec de la suppression de la base de données de test : $error';
  }

  @override
  String get playlists => 'Listes de Lecture';

  @override
  String get playlistsDesktopOnly =>
      'Les listes de lecture ne sont disponibles que sur Android.';

  @override
  String get noPlaylistsYet => 'Pas encore de listes';

  @override
  String get createFirstPlaylist =>
      'Appuyez sur + pour créer votre première liste';

  @override
  String playlistSongCount(int count) {
    return '$count morceaux';
  }

  @override
  String get createPlaylist => 'Créer une Liste';

  @override
  String get playlistName => 'Nom de la Liste';

  @override
  String get playlistNameHint => 'Ma Liste';

  @override
  String get playlistNameRequired => 'Nom de liste requis';

  @override
  String get editPlaylist => 'Modifier la Liste';

  @override
  String get stopPlaybackBeforeEditing =>
      'Veuillez arrêter la lecture avant de modifier la liste de lecture';

  @override
  String get selectPreviewSongs => 'Sélectionner les Aperçus';

  @override
  String get deletePlaylist => 'Supprimer la Liste';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ?';
  }

  @override
  String get playlistDeleted => 'Liste supprimée';

  @override
  String get errorDeletingPlaylist =>
      'Erreur lors de la suppression de la liste';

  @override
  String get playlistUpdated => 'Liste mise à jour';

  @override
  String get changeSong => 'Changer de Chanson';

  @override
  String get changeSongConfirm =>
      'Une chanson est en cours de lecture. Voulez-vous passer à cette chanson ?';

  @override
  String get changeSongButton => 'Changer';

  @override
  String playlistProgress(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get noPreviewSongsInPlaylist =>
      'Aucun aperçu disponible dans cette liste';

  @override
  String get tapEditToAddSongs =>
      'Appuyez sur modifier pour ajouter des chansons à cette playlist';

  @override
  String get noProjectsAvailableForPlaylist =>
      'Aucun projet avec des chansons de prévisualisation disponibles à ajouter';

  @override
  String get noProjectsInDatabase =>
      'Aucun projet trouvé dans la base de données. Veuillez d\'abord synchroniser vos projets.';

  @override
  String get firstTimeSyncTitle =>
      'Il semble que ce soit votre première fois ici !';

  @override
  String get firstTimeSyncMessage =>
      'Synchronisons vos données depuis Google Drive pour commencer';

  @override
  String get syncWithGoogleDrive => 'Synchroniser avec Google Drive';

  @override
  String get errorLoadingPlaylists => 'Erreur de chargement des listes';

  @override
  String get playlistItems => 'Éléments de la Liste';

  @override
  String get addSongs => 'Ajouter des Morceaux';

  @override
  String get addAudioFiles => 'Ajouter des Fichiers Audio';

  @override
  String get selectAudioFiles => 'Sélectionner des Fichiers Audio';

  @override
  String get selectFromProjects => 'Sélectionner des Projets';

  @override
  String get add => 'Ajouter';

  @override
  String get addTaskAtTimestamp => 'Ajouter une tâche à l\'instant actuel';

  @override
  String get taskDescriptionHint => 'Description de la tâche';

  @override
  String get taskAdded => 'Tâche ajoutée';

  @override
  String get fromProject => 'Du Projet';

  @override
  String get projectDeadline => 'Date Limite du Projet';

  @override
  String get noDeadlineSet => 'Aucune date limite';

  @override
  String get camelotCode => 'Code Camelot';

  @override
  String get deadline => 'Date Limite';

  @override
  String get dueToday => 'Échéance aujourd\'hui';

  @override
  String daysLate(int days) {
    return '${days}j en retard';
  }

  @override
  String daysLeft(int days) {
    return '${days}j restants';
  }

  @override
  String get hideFinished => 'Masquer Terminés';

  @override
  String get showOnlyDeadlines => 'Afficher échéance';

  @override
  String get filterByDeadline => 'Filtrer par Date Limite';

  @override
  String get allDeadlines => 'Toutes les Dates';

  @override
  String get hasDeadline => 'Avec Date Limite';

  @override
  String get overdue => 'En Retard';

  @override
  String get dueSoon => 'Bientôt Échu (7j)';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get noPreviewSong => 'Pas d\'aperçu';

  @override
  String get playPreview => 'Lire l\'Aperçu';

  @override
  String get uploadCancelled => 'Téléchargement annulé';

  @override
  String get backupUploadCancelledByUser =>
      'Téléchargement de sauvegarde annulé par l\'utilisateur';

  @override
  String get collectingData => 'Collecte des données...';

  @override
  String get uploadingPreviewSongs => 'Téléchargement des aperçus musicaux...';

  @override
  String get uploadingProfilePhotos => 'Téléchargement des photos de profil...';

  @override
  String get uploadingReleaseArtwork =>
      'Téléchargement des artwork de sortie...';

  @override
  String get uploadingDatabase => 'Téléchargement de la base de données...';

  @override
  String get completed => 'Terminé !';

  @override
  String get cancelling => 'Annulation...';

  @override
  String get uploadingBackupTitle => 'Téléchargement de la Sauvegarde';

  @override
  String get cancellingUpload => 'Annulation du téléchargement...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Veuillez patienter pendant l\'arrêt du téléchargement...';

  @override
  String get downloadingDatabase => 'Téléchargement de la base de données...';

  @override
  String get downloadingPreviewSongs =>
      'Téléchargement des chansons d\'aperçu...';

  @override
  String get downloadingProfilePhotos =>
      'Téléchargement des photos de profil...';

  @override
  String get downloadingReleaseArtwork =>
      'Téléchargement des artwork de sortie...';

  @override
  String get mergingData => 'Fusion des données...';

  @override
  String get downloadingBackupTitle => 'Téléchargement de la Sauvegarde';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Fichier source introuvable sur cette machine';

  @override
  String get metadataExtractionNotSupportedForDaw =>
      'L\'extraction des métadonnées n\'est pas prise en charge pour ce DAW';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Fichier source introuvable sur cette machine — mode métadonnées uniquement. Vous pouvez toujours modifier et exporter les métadonnées.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Chanson d\'aperçu non disponible. Veuillez d\'abord télécharger la sauvegarde.';

  @override
  String get sharePreviewSong => 'Partager la chanson d\'aperçu';

  @override
  String get shareAsZip => 'Partager en ZIP';

  @override
  String get share => 'Partager';

  @override
  String get convertingAudioForSharing =>
      'Préparation de l\'audio pour le partage…';

  @override
  String get shareSheetUnavailable =>
      'Le menu de partage du système n\'est pas disponible ici — utilisez la puce « Glisser pour Partager » sur l\'aperçu du morceau pour glisser le fichier vers une autre application.';

  @override
  String get dragToShare => 'Glisser pour Partager';

  @override
  String get dragToShareTooltip =>
      'Glissez ceci sur la fenêtre d\'une autre application (ex : WhatsApp) pour partager le fichier directement — utile quand le bouton Partager n\'ouvre pas de menu de partage.';

  @override
  String get mp3ConversionFailed =>
      'La conversion audio n\'est pas disponible sur ce système — partage du fichier original, que certaines applications comme WhatsApp peuvent refuser.';

  @override
  String get shareZip => 'Partager ZIP';

  @override
  String get saveCopy => 'Enregistrer une copie';

  @override
  String savedCopyTo(String path) {
    return 'Enregistré dans $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Échec du partage de la chanson d\'aperçu : $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Échec du partage de la chanson d\'aperçu en ZIP : $error';
  }

  @override
  String get biographySaved => 'Biographie enregistrée';

  @override
  String failedToSaveBiography(String error) {
    return 'Échec de l\'enregistrement de la biographie : $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'Fichier enregistré dans $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Échec du téléchargement du fichier : $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'Tous les fichiers enregistrés dans $filename';
  }

  @override
  String get artworkAdded => 'Artwork ajouté';

  @override
  String failedToAddArtwork(String error) {
    return 'Échec de l\'ajout de l\'artwork : $error';
  }

  @override
  String get artworkRemoved => 'Artwork supprimé';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Échec de la suppression de l\'artwork : $error';
  }

  @override
  String get pressKitFileAdded => 'Fichier de presse ajouté';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Échec de l\'ajout du fichier de presse : $error';
  }

  @override
  String get pressKitFileRemoved => 'Fichier de presse supprimé';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Échec de la suppression du fichier de presse : $error';
  }

  @override
  String get selectFilesToDownload => 'Sélectionner les Fichiers à Télécharger';

  @override
  String get biography => 'Biographie';

  @override
  String get biographyWillBeSaved => 'Sera enregistré sous biography.txt';

  @override
  String get artworkFiles => 'Fichiers Artwork';

  @override
  String get pressKitFiles => 'Fichiers de Presse';

  @override
  String get additionalAssets => 'Ressources Supplémentaires';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Télécharger $count fichier$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count fichier$plural enregistré dans $filename';
  }

  @override
  String get addAsset => 'Ajouter une Ressource';

  @override
  String get assetNameLabel => 'Nom de la Ressource';

  @override
  String get assetNameHint => 'ex., Logo, Bannière, Photo';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName ajouté avec succès';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Échec de l\'ajout de la ressource : $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName supprimé';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Échec de la suppression de la ressource : $error';
  }

  @override
  String get profileNotFound => 'Profil introuvable';

  @override
  String get downloadFilesSectionTitle => 'Télécharger les Fichiers';

  @override
  String get downloadFilesSectionDescription =>
      'Téléchargez tous les fichiers de ce profil — biographie, artwork, dossier de presse et ressources supplémentaires — sous forme d\'un seul ZIP, ou sélectionnez ceux à inclure.';

  @override
  String get selectFiles => 'Sélectionner des Fichiers';

  @override
  String get downloadAll => 'Tout Télécharger';

  @override
  String get saveBiographyTooltip => 'Enregistrer la Biographie';

  @override
  String get enterBiographyHint => 'Entrez la biographie du profil...';

  @override
  String get addArtwork => 'Ajouter un Artwork';

  @override
  String get addFile => 'Ajouter un Fichier';

  @override
  String get openFile => 'Ouvrir le Fichier';

  @override
  String get menuView => 'Affichage';

  @override
  String get menuAbout => 'À propos de DAW Project Manager';

  @override
  String get menuDocumentation => 'Documentation';

  @override
  String get menuLanguage => 'Langue';

  @override
  String get menuWarnBeforeQuit => 'Avertir Avant de Quitter (⌘+Q)';

  @override
  String get menuQuit => 'Quitter DAW Project Manager';

  @override
  String get quitConfirmTitle => 'Quitter DAW Project Manager ?';

  @override
  String get quitConfirmMessage => 'Voulez-vous vraiment quitter ?';

  @override
  String get quit => 'Quitter';

  @override
  String get trayNoticeTitle =>
      'Toujours en cours d\'exécution en arrière-plan';

  @override
  String get trayNoticeBody =>
      'DAW Project Manager a été réduit dans la barre système. Utilisez l\'icône de la barre système pour le rouvrir ou le quitter.';

  @override
  String get trayShowWindow => 'Afficher DAW Project Manager';

  @override
  String trayLastBackup(String when) {
    return 'Dernière sauvegarde : $when';
  }

  @override
  String get trayNeverBackedUp => 'Aucune sauvegarde effectuée';

  @override
  String get trayBackupNow => 'Sauvegarder maintenant';

  @override
  String get trayPauseSession => 'Mettre en pause la session';

  @override
  String get trayResumeSession => 'Reprendre la session';

  @override
  String get closeToTray => 'Fermer dans la barre système';

  @override
  String get closeToTrayDescription =>
      'Continuer à s\'exécuter en arrière-plan (icône dans la barre système) à la fermeture de la fenêtre, afin que la sauvegarde automatique et les notifications continuent de fonctionner';

  @override
  String get autoStart => 'Lancer au démarrage';

  @override
  String get autoStartDescription =>
      'Ouvrir DAW Project Manager automatiquement à l\'ouverture de votre session';

  @override
  String get startMinimized => 'Démarrer réduit dans la barre d\'état';

  @override
  String get startMinimizedDescription =>
      'Quand l\'app démarre avec votre ordinateur, l\'ouvrir masquée dans la barre d\'état au lieu d\'afficher la fenêtre';

  @override
  String get onboardingStartMinimized => 'Démarrer réduit';

  @override
  String get autoStartFailed =>
      'Impossible de modifier le réglage de démarrage. Votre système ne l\'autorise peut-être pas.';

  @override
  String get onboardingStartupTitle => 'Lancer au Démarrage';

  @override
  String get onboardingStartupBody =>
      'Ouvrez DAW Project Manager automatiquement à l\'ouverture de session, pour que les sauvegardes en arrière-plan et les rappels d\'échéance continuent de fonctionner.';

  @override
  String get menuWindow => 'Fenêtre';

  @override
  String get donate => 'Faire un Don';

  @override
  String get website => 'Site Web';

  @override
  String get license => 'Licence';

  @override
  String get reportIssue => 'Signaler un problème';

  @override
  String get switchToClassicDark => 'Passer à Classic Dark';

  @override
  String get switchToNeonDark => 'Passer à Neon Dark';

  @override
  String get switchToClassicTheme => 'Passer au Thème Classique';

  @override
  String get switchToNeonTheme => 'Passer au Thème Néon';

  @override
  String get switchToStudioLight => 'Passer à Studio Light';

  @override
  String get menuTheme => 'Thème';

  @override
  String get appDescription =>
      'Un gestionnaire de projets pour les producteurs de musique et les concepteurs sonores.';

  @override
  String get neonDarkThemeName => 'Néon Sombre';

  @override
  String get classicDarkThemeName => 'Classique Sombre';

  @override
  String get studioLightThemeName => 'Studio Clair';

  @override
  String get statisticsTab => 'Statistiques';

  @override
  String get statsTotalProjects => 'Total des Projets';

  @override
  String get statsInProgress => 'En cours';

  @override
  String get statsFinished => 'Terminés';

  @override
  String get statsAvgCompletion => 'Achèvement moy.';

  @override
  String get statsPhaseDistribution => 'Projets par Phase';

  @override
  String get statsAvgTimePerPhase => 'Jours moy. par Phase';

  @override
  String get statsProductivity => 'Productivité';

  @override
  String get statsCreatedSeries => 'Créés';

  @override
  String get statsProjectHealth => 'Âge et Santé des Projets';

  @override
  String get statsCatalogInsights => 'Analyse du Catalogue';

  @override
  String get statsBpmDistribution => 'Distribution BPM';

  @override
  String get statsTopKeys => 'Tonalités principales';

  @override
  String get statsDawTypes => 'Types de DAW';

  @override
  String get statsProjectActivity => 'Activité des Projets';

  @override
  String get statsSingleProjectActivity => 'Activité du Projet';

  @override
  String get statsNoData => 'Pas encore de données';

  @override
  String get statsNoPhaseData =>
      'Les données de phases apparaîtront après des transitions de phase.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Dernière activité: il y a $days j';
  }

  @override
  String get statsLastActivityToday => 'Actif aujourd\'hui';

  @override
  String get statsNoEvents => 'Aucun événement enregistré';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Phase: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Mis à jour: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Terminé: $text';
  }

  @override
  String get statsEventFileModified => 'Fichier modifié sur disque';

  @override
  String get statsClearHistory => 'Effacer l\'historique';

  @override
  String get statsClearHistoryConfirm =>
      'Effacer tous les événements enregistrés pour ce projet?';

  @override
  String get statsSearchProjects => 'Rechercher des projets…';

  @override
  String statsEventCount(int count) {
    return '$count événements';
  }

  @override
  String get statsViewHistory => 'Statistiques du Projet';

  @override
  String get statsPhaseHistory => 'Historique des Phases';

  @override
  String get statsEventBreakdown => 'Détail des Événements';

  @override
  String statsDaysSoFar(int days) {
    return '${days}j jusqu\'ici';
  }

  @override
  String get statsNoProjectsFound => 'Aucun projet trouvé';

  @override
  String statsNotTouchedDays(int days) {
    return 'Inchangé depuis $days jours';
  }

  @override
  String get sortByLastModified => 'Dernière modification';

  @override
  String get sortByName => 'Nom';

  @override
  String get sortByPhase => 'Phase';

  @override
  String get sortByCreatedAt => 'Date d\'ajout';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get sortNewestFirst => 'Plus récent d\'abord';

  @override
  String get sortOldestFirst => 'Plus ancien d\'abord';

  @override
  String get sortTitleAZ => 'Titre A–Z';

  @override
  String get sortTitleZA => 'Titre Z–A';

  @override
  String get musicPlayerTab => 'Lecteur de musique';

  @override
  String get previewAudioChangedRefreshing =>
      'L\'audio d\'aperçu a changé sur le disque — actualisation de la forme d\'onde…';

  @override
  String get audioFileChangedRefreshing =>
      'Le fichier audio a changé sur le disque — actualisation de la forme d\'onde…';

  @override
  String get autoFitAllColumns => 'Ajuster les colonnes';

  @override
  String get uploadAutoDetectedPreviewSongs =>
      'Envoyer les morceaux d\'aperçu détectés automatiquement';

  @override
  String get uploadAutoDetectedPreviewSongsSubtitle =>
      'Inclure les morceaux trouvés automatiquement par le scanner, pas seulement ceux définis manuellement.';

  @override
  String get monoGenerating => 'Mono…';

  @override
  String errorHandlingDroppedFiles(String error) {
    return 'Erreur lors du traitement des fichiers déposés : $error';
  }

  @override
  String get resetOnboardingConfirm =>
      'Cela relancera l\'assistant de configuration. Continuer ?';

  @override
  String couldNotLaunchDaw(String daw, String error) {
    return 'Impossible de lancer $daw : $error';
  }

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien.';

  @override
  String get githubButtonLabel => 'GitHub';

  @override
  String get monoLabel => 'Mono';

  @override
  String get monoToggleTooltip => 'Basculer en lecture mono';

  @override
  String get monoRequiresWav => 'Le mixage mono nécessite un fichier WAV';

  @override
  String get monoUnsupportedFormat =>
      'Impossible de créer le mixage mono — format non pris en charge';

  @override
  String monoSwitchFailed(String error) {
    return 'Échec du passage en mono : $error';
  }

  @override
  String get analyzeLabel => 'Analyser';

  @override
  String get reAnalyzeLabel => 'Ré-analyser';

  @override
  String get analysisRequiresWav => 'L\'analyse nécessite un fichier WAV';

  @override
  String get noResultsForFilter => 'Aucun résultat pour le filtre actuel';

  @override
  String get noResultsForFilterHint =>
      'Essayez d\'ajuster votre recherche ou vos filtres.';

  @override
  String get noProjectsFound => 'Aucun projet trouvé';

  @override
  String get noProjectsFoundHint =>
      'Ajoutez un dossier racine dans les paramètres pour commencer.';

  @override
  String get noProjectsFoundInFoldersHint =>
      'Essayez d\'ajouter un autre dossier contenant des projets DAW.';

  @override
  String get queueTab => 'Tâches';

  @override
  String get queueSearchHint => 'Rechercher des tâches...';

  @override
  String get queueNoPendingTasks => 'Tout est à jour !';

  @override
  String get queueNoPendingTasksHint =>
      'Aucune tâche en attente dans vos projets.';

  @override
  String get queueNoMatchingTasks => 'Aucune tâche correspondante';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks tâches en attente dans $projects projets';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager $version';
  }

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get renameProjectFileTitle => 'Renommer le fichier de projet';

  @override
  String get renameFileButtonLabel => 'Renommer le fichier';

  @override
  String get newFileNameLabel => 'Nouveau nom de fichier (sans extension)';

  @override
  String renameAlreadyExists(String name) {
    return 'Un fichier nommé \"$name\" existe déjà.';
  }

  @override
  String renameSuccess(String name) {
    return 'Renommé en \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Échec du renommage : $error';
  }

  @override
  String get nameCannotBeEmpty => 'Le nom ne peut pas être vide';

  @override
  String get nameInvalidCharacters => 'Le nom ne peut pas contenir / \\ :';

  @override
  String get alsoRenameContainingFolder => 'Renommer aussi le dossier parent';

  @override
  String get renameButton => 'Renommer';

  @override
  String get previewMixdownFolderTitle =>
      'Dossiers de mixage de prévisualisation';

  @override
  String get previewMixdownFolderSubtitle =>
      'Noms des sous-dossiers dans chaque dossier de projet à vérifier en premier, dans l\'ordre, lors de la détection automatique des morceaux de prévisualisation. Laisser vide pour utiliser les valeurs par défaut du DAW.';

  @override
  String get previewMixdownFolderHint => 'ex. Mixages';

  @override
  String get mixdownFoldersInfoTooltip => 'Comment ça marche';

  @override
  String get mixdownFoldersInfoDialogTitle =>
      'Comment fonctionne la détection de prévisualisation';

  @override
  String get mixdownFoldersInfoDialogBody =>
      'Lorsqu\'un projet n\'a pas de morceau de prévisualisation choisi manuellement, l\'application recherche le fichier audio le plus récemment modifié à utiliser comme aperçu. Elle vérifie d\'abord vos dossiers personnalisés ci-dessous, dans l\'ordre, puis se rabat sur une liste de noms de dossiers par défaut selon le DAW du projet.';

  @override
  String get mixdownFoldersDawDefaultsHeading =>
      'Dossiers par défaut selon le DAW';

  @override
  String get mixdownFoldersOtherDawLabel => 'Autre / DAW non reconnu';

  @override
  String get addMixdownFolder => 'Ajouter';

  @override
  String get noCustomMixdownFolders =>
      'Aucun dossier personnalisé ajouté — les valeurs par défaut du DAW seront utilisées.';

  @override
  String get mixdownFoldersTabLabel => 'Dossiers de Mixdown';

  @override
  String get mixdownFoldersSectionDescription =>
      'Détermine dans quel dossier l\'application recherche l\'audio exporté/mixé d\'un projet, utilisé comme aperçu musical lorsqu\'aucun n\'est défini manuellement. Développez un DAW ci-dessous pour voir les noms de dossiers déjà vérifiés par défaut, et ajoutez les vôtres si votre configuration utilise un nom différent.';

  @override
  String get mixdownFoldersDefaultsLabel => 'Dossiers vérifiés par défaut :';

  @override
  String get mixdownFoldersCustomLabel => 'Vos ajouts pour ce DAW :';

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
    return 'DAW : $daw';
  }

  @override
  String bpmInfoLabel(String bpm) {
    return 'BPM : $bpm';
  }

  @override
  String keyInfoLabel(String key) {
    return 'Tonalité : $key';
  }

  @override
  String get audioFileNotFound => 'Fichier audio introuvable';

  @override
  String errorPlayingAudio(String error) {
    return 'Erreur de lecture audio : $error';
  }

  @override
  String get notificationTestTitle =>
      'Tester les notifications pour vérifier le fuseau horaire et la planification :';

  @override
  String get notificationSendNow => 'Envoyer maintenant';

  @override
  String get notificationSchedule30s => 'Planifier +30s';

  @override
  String get notificationShowDebugInfo => 'Afficher les infos de débogage';

  @override
  String get notificationRescheduleAll => 'Replanifier tout';

  @override
  String get notificationTestSent => '✅ Notification de test envoyée !';

  @override
  String get notificationTestScheduled =>
      '✅ Notification de test planifiée dans 30 secondes ! Vérifiez les journaux.';

  @override
  String notificationTestError(String error) {
    return '❌ Erreur : $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Informations de débogage';

  @override
  String get autoDetected => 'Détecté automatiquement';

  @override
  String get matchedInDescription => 'Correspondance dans la description';

  @override
  String get matchedInProjectNotes =>
      'Correspondance dans les notes de projet du DAW';

  @override
  String get relocateFolderDialogTitle => 'Déplacer le dossier';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chemins de projet mis à jour',
      one: '1 chemin de projet mis à jour',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Personnaliser les onglets';

  @override
  String get alwaysVisible => '(toujours visible)';

  @override
  String get customizeTabsDescription =>
      'Choisissez les onglets a afficher dans la barre de navigation. L\'onglet Projets est toujours visible.';

  @override
  String get keyboardShortcuts => 'Raccourcis clavier';

  @override
  String get shortcutGroupGlobal => 'Global';

  @override
  String get shortcutGroupProjectsTable =>
      'Tableau des projets (le tableau doit être focalisé)';

  @override
  String get shortcutGroupReleasesTable =>
      'Tableau des sorties (le tableau doit être focalisé)';

  @override
  String get shortcutGroupNavigation => 'Navigation';

  @override
  String get shortcutFocusSearch => 'Focaliser la barre de recherche';

  @override
  String get shortcutRescan => 'Rescanner les dossiers de projets';

  @override
  String get shortcutFocusTable => 'Focaliser le tableau des projets';

  @override
  String get shortcutPlayPause => 'Lire / mettre en pause la chanson d\'aperçu';

  @override
  String get shortcutOpenInDaw => 'Ouvrir le projet dans le DAW';

  @override
  String get shortcutViewDetails => 'Voir les détails du projet';

  @override
  String get shortcutOpenFolder => 'Ouvrir le dossier du projet';

  @override
  String get shortcutNavigateRows => 'Naviguer dans les lignes';

  @override
  String get shortcutEditCell => 'Ouvrir les détails du projet';

  @override
  String get shortcutViewRelease => 'Voir les détails de la sortie';

  @override
  String get shortcutGoBack => 'Retour';

  @override
  String get shortcutGroupProjectsTableStandardMode => 'Mode standard';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'Mode session';

  @override
  String get shortcutToggleSession => 'Démarrer / Terminer la session';

  @override
  String get shortcutGroupPreviewPlayer => 'Lecteur de prévisualisation';

  @override
  String get shortcutPlayerPlayPause => 'Lecture / pause';

  @override
  String get shortcutPlayerSeek5 => 'Avancer/Reculer de ±5 secondes';

  @override
  String get shortcutPlayerSeek30 => 'Avancer/Reculer de ±30 secondes';

  @override
  String get startupDialogTitle => 'Bienvenue dans DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Commencez en ajoutant un dossier de projets ou en restaurant une sauvegarde Google Drive.';

  @override
  String get startupAddFolderTitle => 'Ajouter un dossier de projets';

  @override
  String get startupAddFolderSubtitle =>
      'Sélectionnez un dossier contenant vos projets DAW.';

  @override
  String get startupGoogleDriveTitle =>
      'Synchroniser la sauvegarde Google Drive';

  @override
  String get startupGoogleDriveSubtitle =>
      'Restaurez vos projets depuis une sauvegarde Google Drive.';

  @override
  String get startupDontShowAgain => 'Ne plus afficher au démarrage';

  @override
  String get pinnedLibraryWarningTitle =>
      'Bibliothèque de test en cours d\'utilisation';

  @override
  String get pinnedLibraryWarningBody =>
      'Cette version stocke ses données dans une bibliothèque de test distincte : elle ne peut donc pas modifier la bibliothèque utilisée par la copie installée de l\'application. Les projets, profils et réglages que vous modifiez ici n\'y apparaîtront pas.';

  @override
  String get pinnedLibraryWarningLibraryLabel => 'Bibliothèque';

  @override
  String get pinnedLibraryWarningLocationLabel => 'Emplacement';

  @override
  String get pinnedLibraryWarningDontShowAgain =>
      'Ne plus m\'avertir pour cette bibliothèque';

  @override
  String get deleteAllData => 'Supprimer toutes les données';

  @override
  String get deleteAllDataSubtitle =>
      'Supprimer tous les profils, projets, sorties, playlists et paramètres de cet appareil.';

  @override
  String get deleteAllDataConfirm1Title => 'Supprimer toutes les données ?';

  @override
  String get deleteAllDataConfirm1Message =>
      'Cela supprimera définitivement tous les profils, projets, sorties, playlists et paramètres de cet appareil. Votre sauvegarde Google Drive (le cas échéant) ne sera pas affectée.';

  @override
  String get deleteAllDataConfirm2Title => 'Êtes-vous absolument sûr ?';

  @override
  String get deleteAllDataConfirm2Message =>
      'Cette action est irréversible. L\'application reviendra à son état initial.';

  @override
  String get deleteEverything => 'Tout supprimer';

  @override
  String get allDataDeleted => 'Toutes les données ont été supprimées.';

  @override
  String get newerExportFound => 'Export plus récent trouvé';

  @override
  String newerExportFoundMessage(String filename) {
    return 'Un fichier plus récent a été trouvé dans le même dossier :\n$filename\n\nRemplacer la chanson de prévisualisation ?';
  }

  @override
  String get replaceAndPlay => 'Remplacer et lire';

  @override
  String get keepCurrent => 'Garder l\'actuel';

  @override
  String get autoBackup => 'Sauvegarde Automatique';

  @override
  String get autoBackupDescription =>
      'Téléverse automatiquement une sauvegarde sur Google Drive selon l\'intervalle sélectionné.';

  @override
  String get autoBackupInterval => 'Intervalle de sauvegarde';

  @override
  String get autoBackupOff => 'Désactivé';

  @override
  String get autoBackupEvery30Min => 'Toutes les 30 minutes';

  @override
  String get autoBackupHourly => 'Toutes les heures';

  @override
  String get autoBackupEvery6Hours => 'Toutes les 6 heures';

  @override
  String get autoBackupDaily => 'Quotidien';

  @override
  String autoBackupNextBackup(String time) {
    return 'Prochain backup : $time';
  }

  @override
  String get autoBackupNextSoon => 'bientôt';

  @override
  String autoBackupNextInMinutes(int count) {
    return 'dans $count min';
  }

  @override
  String get autoBackupNextInOneHour => 'dans 1 heure';

  @override
  String autoBackupNextInHours(int count) {
    return 'dans $count heures';
  }

  @override
  String get autoBackupNextInOneDay => 'dans 1 jour';

  @override
  String autoBackupNextInDays(int count) {
    return 'dans $count jours';
  }

  @override
  String get playerTitle => 'Lecteur de musique';

  @override
  String get playerToggleQueue => 'Basculer la file d\'attente';

  @override
  String get playerSearchHint => 'Rechercher des pistes…';

  @override
  String playerTrackCount(int count) {
    return '$count pistes';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'Aucun aperçu trouvé.\nOuvrez un projet et définissez un aperçu.';

  @override
  String playerNoTracksMatch(String query) {
    return 'Aucune piste ne correspond à\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay =>
      'Double-cliquez sur une piste pour la lire';

  @override
  String get playerSingleClickToPreview =>
      'Clic simple pour l\'aperçu dans la barre ci-dessous';

  @override
  String get playerQueueTitle => 'File d\'attente';

  @override
  String get playerClearQueue => 'Vider la file d\'attente';

  @override
  String get playerQueueEmptyHint =>
      'Double-cliquez pour démarrer,\nou faites glisser des pistes ici.';

  @override
  String get playerPrev => 'Précédent';

  @override
  String get playerNext => 'Suivant';

  @override
  String get playerGoToProject => 'Aller au projet';

  @override
  String get playerAddToQueue => 'Ajouter à la file';

  @override
  String get playerRemoveFromQueue => 'Retirer de la file';

  @override
  String get playerDismissDetail => 'Fermer le détail';

  @override
  String get playerNotes => 'NOTES';

  @override
  String get playerTasks => 'TÂCHES';

  @override
  String get playerNoTasks => 'Aucune tâche pour l\'instant.';

  @override
  String get playerAddTaskHint => 'Ajouter une tâche…';

  @override
  String playerCompletedTasks(int count) {
    return '$count terminée(s)';
  }

  @override
  String get playerPreviousTrack => 'Piste précédente';

  @override
  String get playerNextTrack => 'Piste suivante';

  @override
  String get playerOpenProject => 'Ouvrir le projet';

  @override
  String get playerRepeatAll => 'Tout répéter';

  @override
  String get playerShuffle => 'Aléatoire';

  @override
  String get volumeMute => 'Muet';

  @override
  String get volumeUnmute => 'Réactiver le son';

  @override
  String totalWorkTime(String time) {
    return 'Travail total : $time';
  }

  @override
  String sessionTime(String time) {
    return 'Session : $time';
  }

  @override
  String headerAgeOld(String age) {
    return '$age d\'existence';
  }

  @override
  String headerEdited(String when) {
    return 'modifié $when';
  }

  @override
  String headerWorked(String time) {
    return '$time de travail';
  }

  @override
  String get sessionHistory => 'Historique des sessions';

  @override
  String get noSessionsYet => 'Aucune session enregistrée';

  @override
  String get removeSessionTitle => 'Supprimer la session ?';

  @override
  String get editSessionTitle => 'Modifier la duree de la session';

  @override
  String get editSessionHours => 'Heures';

  @override
  String get editSessionInvalid => 'La duree doit etre d\'au moins 1 minute';

  @override
  String get sessionTableDate => 'Date';

  @override
  String get sessionTableTime => 'Heure';

  @override
  String get sessionTableDuration => 'Durée';

  @override
  String get sessionTableTotal => 'Total';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get sessionByPhase => 'Travail par phase';

  @override
  String get tabPosition => 'Position des onglets';

  @override
  String get tabPositionTop => 'Haut';

  @override
  String get tabPositionLeft => 'Gauche';

  @override
  String updateAvailableMessage(String version) {
    return 'Version $version disponible';
  }

  @override
  String get dismiss => 'Ignorer';

  @override
  String get checkForUpdates => 'Vérifier les mises à jour';

  @override
  String get checkForUpdatesDescription =>
      'Soyez notifié lorsqu\'une nouvelle version est disponible.';

  @override
  String get checkNow => 'Vérifier maintenant';

  @override
  String updateAvailable(String version) {
    return 'Mise à jour disponible : v$version';
  }

  @override
  String get upToDate => 'L\'application est à jour';

  @override
  String get updateAvailableTitle => 'Mise à jour disponible';

  @override
  String updateAvailableVersion(String version) {
    return 'La version $version est prête.';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Vous utilisez v$version.';
  }

  @override
  String get viewUpdateDetails => 'Voir les détails';

  @override
  String get getOnMicrosoftStore => 'Obtenir sur Microsoft Store';

  @override
  String get downloadFromGitHub => 'Télécharger depuis GitHub';

  @override
  String get updateWindowsInstructions =>
      'Ouvrez Microsoft Store et mettez à jour DAW Project Manager, ou cliquez ci-dessous.';

  @override
  String get updateMacInstructions =>
      'Téléchargez la dernière version depuis GitHub et remplacez l\'application.';

  @override
  String get updateAppImageSourceLabel => 'AppImage';

  @override
  String get updateAppImageInstructions =>
      'Mise à jour sur place, puis redémarrage.';

  @override
  String get updateNowButtonLabel => 'Mettre à jour maintenant';

  @override
  String get appImageUpdateFetching => 'Recherche de la mise à jour…';

  @override
  String get appImageUpdateDownloading => 'Téléchargement de la mise à jour…';

  @override
  String appImageUpdateDownloadingProgress(int percent) {
    return 'Téléchargement de la mise à jour… $percent %';
  }

  @override
  String get appImageUpdateVerifying => 'Vérification et installation…';

  @override
  String get appImageUpdateReadyTitle => 'Mise à jour prête';

  @override
  String appImageUpdateReadyMessage(String version) {
    return 'Mis à jour vers la version $version. Redémarrez maintenant pour terminer.';
  }

  @override
  String get appImageUpdateRestartNow => 'Redémarrer maintenant';

  @override
  String get appImageUpdateFailedTitle => 'Échec de la mise à jour';

  @override
  String get appImageUpdateRetry => 'Réessayer';

  @override
  String get appImageUpdateErrorMessage =>
      'Une erreur s\'est produite pendant la mise à jour. Vous pouvez réessayer ou consulter les détails de l\'erreur ci-dessous.';

  @override
  String get appImageUpdateErrorDetailsLabel => 'Détails de l\'erreur';

  @override
  String get appImageUpdateCopyErrorDetails =>
      'Copier les détails de l\'erreur';

  @override
  String get appImageUpdateErrorDetailsCopied => 'Détails de l\'erreur copiés';

  @override
  String get resetOnboarding => 'Réinitialiser l\'intégration';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue dans DAW Project Manager';

  @override
  String get onboardingWelcomeBody =>
      'Organisez tous vos projets musicaux en un seul endroit.';

  @override
  String get onboardingFeatureScanFolders =>
      'Scanne automatiquement les dossiers de projets DAW';

  @override
  String get onboardingFeatureTrackMetadata =>
      'Suit le BPM, la tonalité, le statut et les échéances';

  @override
  String get onboardingFeatureSyncDrive =>
      'Synchronise les métadonnées avec Google Drive';

  @override
  String get onboardingFeatureTrackTime =>
      'Suit le temps passé sur chaque projet';

  @override
  String get onboardingLanguageTitle => 'Choisissez votre langue';

  @override
  String get onboardingThemeTitle => 'Choisissez un thème';

  @override
  String get onboardingFoldersTitle => 'Ajouter des dossiers de projets';

  @override
  String get onboardingFoldersBody =>
      'Ajoutez le dossier racine où sont stockés vos projets DAW.';

  @override
  String get onboardingDriveTitle => 'Synchronisation Google Drive';

  @override
  String get onboardingDriveBody =>
      'Sauvegardez et synchronisez les métadonnées du projet avec Google Drive.';

  @override
  String get onboardingUpdatesTitle => 'Vérifications des mises à jour';

  @override
  String get onboardingUpdatesBody =>
      'Soyez notifié lorsqu\'une nouvelle version est disponible.';

  @override
  String get onboardingDoneTitle => 'Tout est prêt !';

  @override
  String get onboardingDoneBody => 'Commencez à explorer vos projets.';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingBack => 'Retour';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get dawSession => 'Session DAW';

  @override
  String get clearDawSession => 'Fermer la session';

  @override
  String get stop => 'Arrêter';

  @override
  String get pause => 'Pause';

  @override
  String get playPauseTooltip => 'Lecture / Pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get workTimerSection => 'Rappels de session de travail';

  @override
  String get workTimerSectionDesc =>
      'Recevez des notifications périodiques pendant qu\'une session de travail est active';

  @override
  String get workTimerRequiresSessionMode =>
      'Activez le Mode Session ci-dessus pour utiliser les rappels de session de travail';

  @override
  String get workTimerEnabled => 'Activer les rappels de session de travail';

  @override
  String get workTimerIntervalLabel => 'Notifier toutes les';

  @override
  String get minutes => 'minutes';

  @override
  String workTimerNotifBody(String time) {
    return 'Vous travaillez depuis $time';
  }

  @override
  String get sendTestNotification => 'Envoyer une notification de test';

  @override
  String get testNotificationTitle => 'Notification de test';

  @override
  String get testNotificationBody =>
      'Ceci est une notification de test de DAW Project Manager.';

  @override
  String get general => 'Général';

  @override
  String get expand => 'Développer';

  @override
  String get collapse => 'Réduire';

  @override
  String get lastModifiedColors =>
      'Couleurs de la date de dernière modification';

  @override
  String get lastModifiedColorsDescription =>
      'Colore la date de dernière modification en fonction de l’ancienneté et du statut. Vert = Terminé. Les dates plus anciennes passent progressivement du jaune au rouge — un rouge plus intense signifie que le projet n’a pas été touché depuis plus longtemps.';

  @override
  String get sessionMode => 'Mode session';

  @override
  String get sessionModeDescription =>
      'Démarrez une session sur un projet pour suivre votre temps de travail et le gérer depuis la barre d\'outils';

  @override
  String get workSessionsTabLabel => 'Sessions de Travail';

  @override
  String get normalMode => 'Mode Normal';

  @override
  String get normalModeDescription =>
      'Les projets s\'ouvrent directement dans leur DAW au lancement.';

  @override
  String get sessionModeCardDescription =>
      'Démarrez une session pour suivre votre activité et votre temps sur le projet.';

  @override
  String get startSession => 'Démarrer la session';

  @override
  String get endSession => 'Terminer la session';

  @override
  String get switchSession => 'Changer de session';

  @override
  String get switchSessionBody =>
      'Arrêter la session en cours et en démarrer une nouvelle ?';

  @override
  String switchSessionCurrent(String project) {
    return 'Actuelle : $project';
  }

  @override
  String switchSessionNew(String project) {
    return 'Nouvelle : $project';
  }

  @override
  String get sessionDuration => 'Durée de la session';

  @override
  String get scanModeLabel => 'Mode de scan :';

  @override
  String get scanModeSectionTitle => 'Mode de scan';

  @override
  String get scanModeSectionDescription =>
      'Contrôle comment les projets de chaque dossier sont affichés dans le tableau — sous forme de liste simple ou regroupés par sous-dossier.';

  @override
  String get smartFolderOptionsSectionTitle =>
      'Options des dossiers intelligents';

  @override
  String get smartFolderOptionsSectionDescription =>
      'Ajustez le comportement des groupes de dossiers intelligents dans le tableau des projets.';

  @override
  String get excludeSmartFoldersFromSort =>
      'Exclure les dossiers intelligents du tri';

  @override
  String get excludeSmartFoldersFromSortDescription =>
      'Lorsque vous triez le tableau des projets par colonne, les groupes de dossiers intelligents restent à leur place au lieu de se déplacer avec le tri — seuls les projets qu\'ils contiennent (et les projets non groupés) sont réordonnés. Expérimental : désactivé par défaut.';

  @override
  String get mergeSmartFoldersByName =>
      'Fusionner les dossiers intelligents portant le même nom';

  @override
  String get mergeSmartFoldersByNameDescription =>
      'Lorsque deux dossiers racines de numérisation (par exemple différents DAW) ont un dossier de premier niveau portant le même nom, ils sont traités comme un seul groupe fusionné dans le tableau des projets plutôt que comme deux groupes distincts.';

  @override
  String get alwaysShowSmartFolders =>
      'Toujours afficher les dossiers intelligents';

  @override
  String get alwaysShowSmartFoldersDescription =>
      'Affiche un dossier intelligent comme sa propre ligne de groupe même lorsqu\'un seul de ses projets est actuellement visible (par exemple après une recherche ou un filtre), au lieu de le réduire à une simple ligne non groupée.';

  @override
  String get scanModeFlat => 'Plat';

  @override
  String get scanModeSmartFolder => 'Dossier intelligent';

  @override
  String get scanModeFlatDescription =>
      'Affiche tous les projets sous forme de liste simple. Simple et rapide.';

  @override
  String get scanModeSmartFolderDescription =>
      'Regroupe les projets par dossier quand un dossier contient plus d\'un projet.';

  @override
  String get skip => 'Passer';

  @override
  String get suggestionsLabel => 'Suggestions';

  @override
  String get suggestionsRefresh => 'Actualiser';

  @override
  String get suggestionsEmptyState =>
      'Aucune suggestion pour le moment. Appuyez sur Actualiser pour réinitialiser les éléments ignorés.';

  @override
  String get suggestionNewProject => 'Nouveau';

  @override
  String get showSuggestions => 'Afficher les suggestions';

  @override
  String get showSuggestionsDescription =>
      'Affiche des suggestions intelligentes dans la barre d\'outils quand aucune session n\'est en cours';

  @override
  String get onboardingSuggestionsTitle => 'Suggestions intelligentes';

  @override
  String get onboardingSuggestionsBody =>
      'Obtenez des recommandations de projets personnalisées dans la barre d\'outils pendant votre travail';

  @override
  String get onboardingSessionModeTitle => 'Mode session';

  @override
  String get onboardingSessionModeBody =>
      'Démarrez des sessions de travail ciblées et suivez automatiquement le temps passé sur chaque projet';

  @override
  String get suggestionsFeatureDeadlines =>
      'Rappels d\'échéances pour les projets à venir';

  @override
  String get suggestionsFeatureResume =>
      'Reprendre le dernier projet sur lequel vous avez travaillé';

  @override
  String get suggestionsFeatureRecentlyModified =>
      'Continuer les pistes récemment modifiées';

  @override
  String get suggestionsEnableToggle => 'Activer les suggestions intelligentes';

  @override
  String get canBeChangedInSettings =>
      'Peut être modifié plus tard dans les Paramètres';

  @override
  String get next => 'Suivant';

  @override
  String get createProject => 'Créer';

  @override
  String get createProjectTooltip => 'Créer un nouveau dossier de projet';

  @override
  String get createProjectSelectFolder => 'Choisir l\'emplacement';

  @override
  String get createProjectSelectFolderHint =>
      'Sélectionnez dans quel dossier créer le nouveau projet';

  @override
  String get createProjectNameTitle => 'Nommez votre projet';

  @override
  String get createProjectNameHint =>
      'Choisissez un schéma de nommage pour le nouveau dossier';

  @override
  String get createProjectSchemeArtistTrack => 'Artiste — Piste';

  @override
  String get createProjectSchemeCollab => 'Collaboration';

  @override
  String get createProjectSchemeDate => 'Date — Piste';

  @override
  String get createProjectSchemeCustom => 'Personnalisé';

  @override
  String get createProjectSchemeRemix => 'Remix';

  @override
  String get createProjectArtistName => 'Nom de l\'artiste';

  @override
  String get createProjectTrackName => 'Nom de la piste';

  @override
  String get createProjectCustomName => 'Nom du dossier';

  @override
  String get createProjectAddArtist => 'Ajouter un artiste';

  @override
  String get createProjectOriginalArtist => 'Artiste original';

  @override
  String get createProjectRemixerName => 'Remixeur';

  @override
  String get createProjectAddRemixer => 'Ajouter un remixeur';

  @override
  String get createProjectSelectDaw => 'Ouvrir dans le DAW';

  @override
  String get createProjectSelectDawHint =>
      'Choisissez quel DAW ouvrir pour ce projet';

  @override
  String get createProjectDetectDaws => 'Détecter les DAWs installés';

  @override
  String get createProjectSkipDaw => 'Créer le dossier uniquement';

  @override
  String get createProjectNoDawsFound =>
      'Aucun DAW trouvé. Le dossier sera quand même créé.';

  @override
  String get createProjectCreateOnly => 'Créer le dossier';

  @override
  String get createProjectCreateAndOpen => 'Créer et ouvrir';

  @override
  String get createProjectFolderExists => 'Un dossier avec ce nom existe déjà';

  @override
  String get createProjectInvalidChars =>
      'Le nom contient des caractères invalides';

  @override
  String get createProjectError => 'Impossible de créer le dossier';

  @override
  String get createProjectIncludeDate => 'Inclure le préfixe de date';

  @override
  String get createProjectCreatedTitle => 'Dossier créé';

  @override
  String get createProjectCreatedMessage =>
      'Votre dossier de projet a été créé :';

  @override
  String get createProjectCopyName => 'Copier le nom du dossier';

  @override
  String get createProjectNameCopied => 'Nom du dossier copié';

  @override
  String get createProjectTrackSession => 'Suivre la session dès maintenant';

  @override
  String get pendingFolderSessionTitle => 'Session de travail détectée';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return 'Vous avez travaillé sur \"$projectName\" pendant $duration.';
  }

  @override
  String get pendingFolderSessionContinue => 'Continuer la session';

  @override
  String get pendingFolderSessionEndRecord => 'Terminer et enregistrer';

  @override
  String get activeSessionSwitchTitle => 'Session déjà active';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return 'Une session est en cours pour \"$current\". Passer à \"$next\" et enregistrer la session actuelle ?';
  }

  @override
  String get activeSessionSwitch => 'Changer';

  @override
  String get pendingProjectWaiting => 'En attente du fichier de projet…';

  @override
  String get pendingProjectDelete => 'Supprimer le dossier vide';

  @override
  String get pendingProjectDeleteTitle => 'Supprimer le dossier ?';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return 'Supprimer \"$folderName\" et son contenu ?';
  }

  @override
  String get pendingProjectDismiss => 'Ne plus suivre ce dossier';

  @override
  String get pendingProjectDismissTitle => 'Arrêter le suivi ?';

  @override
  String get pendingProjectDismissKeep => 'Conserver le dossier';

  @override
  String get pendingProjectDismissDelete => 'Supprimer et fermer';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'Le dossier n\'est pas vide';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '\"$folderName\" contient des fichiers. Tout supprimer définitivement ?';
  }

  @override
  String get pendingProjectRefresh => 'Rechercher le fichier de projet';

  @override
  String get pendingProjectNotFound =>
      'Aucun fichier de projet trouvé pour l\'instant';

  @override
  String get phases => 'Phases';

  @override
  String get phasesSubtitle =>
      'Ajouter, supprimer et réorganiser les phases du projet';

  @override
  String get phasesDescription =>
      'Les phases suivent l\'étape de chaque projet dans votre flux de travail (par ex. Idée → Mixage → Mastering). Faites glisser pour réorganiser, touchez un point de couleur pour recolorer, et marquez une phase comme terminée pour la traiter comme complète dans toute l\'application.';

  @override
  String get resetToDefaults => 'Réinitialiser par défaut';

  @override
  String get addPhase => 'Ajouter une phase';

  @override
  String get phaseNameHint => 'Nom de la phase';

  @override
  String get phaseDuplicateError => 'Une phase avec ce nom existe déjà';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets utilisent cette phase',
      one: '1 projet utilise cette phase',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => 'Sélectionner une couleur';

  @override
  String get markAsFinished => 'Marquer comme phase terminée';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets utilisent des phases qui n\'existeront plus.',
      one: '1 projet utilise une phase qui n\'existera plus.',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      'Ces projets conserveront leur statut actuel mais n\'apparaîtront pas dans les filtres de phase. Vous pouvez toujours rajouter ces phases plus tard.';

  @override
  String get resetPhasesConfirm =>
      'Réinitialiser toutes les phases personnalisées, couleurs et indicateurs de phase terminée aux valeurs par défaut ?';

  @override
  String get camelotGenerateButton => 'Générer le mix';

  @override
  String get camelotDialogTitle => 'Mix Camelot';

  @override
  String get camelotDialogDescription =>
      'Trie vos pistes par compatibilité harmonique en utilisant la roue Camelot. La proximité BPM est utilisée comme critère de départage.';

  @override
  String camelotEligibleTracks(int count) {
    return '$count pistes éligibles (tonalité définie)';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$count seront ignorées (sans tonalité)';
  }

  @override
  String get camelotNoEligibleTracks =>
      'Aucune piste n\'a de tonalité définie. Ouvrez un projet et définissez sa tonalité.';

  @override
  String get camelotGenerate => 'Générer';

  @override
  String camelotQueueGenerated(int count) {
    return 'File remplie avec $count pistes en ordre harmonique';
  }

  @override
  String get camelotWheelGuideTooltip => 'Guide de la roue Camelot';

  @override
  String get camelotWheelGuideTitle => 'Guide de la Roue Camelot';

  @override
  String get camelotGuideRingsTitle => 'Les Anneaux';

  @override
  String get camelotGuideRingsBody =>
      'Anneau intérieur (A)  →  tonalités mineures\nAnneau extérieur (B)  →  tonalités majeures';

  @override
  String get camelotGuideNumbersTitle => 'Chiffres 1–12';

  @override
  String get camelotGuideNumbersBody =>
      'Positions arrangées dans le sens des aiguilles d’une montre. Chaque chiffre représente un voisinage harmonique — les voisins partagent de fortes relations tonales.';

  @override
  String get camelotGuideColoursTitle => 'Guide des Couleurs';

  @override
  String get camelotGuideColoursBody =>
      '● Lumineux  →  la tonalité de votre chanson\n● Doucement éclairé  →  compatible pour le mix\n● Atténué  →  à éviter pour un mix fluide';

  @override
  String get camelotGuideTransitionsTitle => 'Transitions Compatibles';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  (même chiffre, changer d’anneau)\n  Majeur/mineur relatif — pratiquement sans couture.\n\n8A → 7A ou 9A  (±1, même anneau)\n  Ton adjacent — changement doux et subtil.\n\n8A → 1A ou 3A  (±7, même anneau)\n  Boost ou chute d’énergie — changement plus dramatique.';

  @override
  String get playerMixSuggestions => 'SUGGESTIONS DE MIX';

  @override
  String get nowPlaying => 'Lecture en cours';

  @override
  String get noPreviewSongsAvailable => 'Aucun aperçu musical disponible';

  @override
  String get upNext => 'Suivant';

  @override
  String get playbackModeNormal => 'Normal';

  @override
  String get playbackModeRepeat => 'Répéter';

  @override
  String get playbackModeShuffle => 'Aléatoire';

  @override
  String get hideDatesInNames => 'Masquer les dates dans les noms de projet';

  @override
  String get hideDatesInNamesDescription =>
      'Certaines STAN préfixent les fichiers de projet avec leur date de création (par exemple « 2026-08-02 - Mon Morceau »). Masquez-la pour n\'afficher que le titre. Les fichiers ne sont jamais renommés.';

  @override
  String get findPreviewAutomatically => 'Rechercher automatiquement';

  @override
  String get noPreviewSongFoundAutomatically =>
      'Aucune chanson d\'aperçu trouvée dans les dossiers de mixage de ce projet.';

  @override
  String get selectProjects => 'Sélectionner';

  @override
  String sharePreviewSongText(String name) {
    return 'Chanson d\'aperçu : $name';
  }

  @override
  String sharePreviewSongZipText(String name) {
    return 'Chanson d\'aperçu (ZIP) : $name';
  }

  @override
  String get songParts => 'Instruments et parties';

  @override
  String partsProgress(int done, int total) {
    return '$done sur $total prises finales';
  }

  @override
  String get noPartsYet => 'Aucune partie enregistrée pour l\'instant';

  @override
  String get noPartsYetHint =>
      'Listez les instruments dont le morceau a besoin, qui les joue et où en est chaque prise.';

  @override
  String get addPart => 'Ajouter une partie';

  @override
  String get addPartHint => 'ex. Batterie, Voix principale, Basse';

  @override
  String get partNameLabel => 'Partie';

  @override
  String get partNameRequired => 'Le nom de la partie est obligatoire';

  @override
  String get partPerformerLabel => 'Interprète';

  @override
  String get partPerformerHint => 'Qui la joue';

  @override
  String get partNotesLabel => 'Notes de la partie';

  @override
  String get partStatusLabel => 'État de la prise';

  @override
  String get partStatusNeeded => 'À faire';

  @override
  String get partStatusRecording => 'En cours d\'enregistrement';

  @override
  String get partStatusEarlyTake => 'Prise provisoire';

  @override
  String get partStatusFinalTake => 'Prise finale';

  @override
  String get editPart => 'Modifier la partie';

  @override
  String get deletePart => 'Supprimer la partie';

  @override
  String get partsUnassignedPerformer => 'Non attribuée';

  @override
  String get partTemplates => 'Modèles de parties';

  @override
  String get importPartsFromTemplate => 'Importer des parties depuis un modèle';

  @override
  String get managePartTemplates => 'Gérer les modèles de parties';

  @override
  String get selectPartTemplate => 'Sélectionnez un modèle de parties';

  @override
  String get noPartTemplatesAvailable => 'Aucun modèle de parties disponible';

  @override
  String get noPartTemplatesYet => 'Aucun modèle de parties pour l\'instant';

  @override
  String get createFirstPartTemplate =>
      'Créez-en un pour réutiliser la même formation d\'un morceau à l\'autre';

  @override
  String get createPartTemplate => 'Créer un modèle de parties';

  @override
  String get editPartTemplate => 'Modifier le modèle de parties';

  @override
  String get deletePartTemplate => 'Supprimer le modèle de parties';

  @override
  String deletePartTemplateConfirm(String name) {
    return 'Voulez-vous vraiment supprimer le modèle de parties « $name » ?';
  }

  @override
  String get partTemplateCreated => 'Modèle de parties créé';

  @override
  String get partTemplateUpdated => 'Modèle de parties mis à jour';

  @override
  String get partTemplateDeleted => 'Modèle de parties supprimé';

  @override
  String get partTemplateItems => 'Parties (une par ligne)';

  @override
  String get partTemplateItemsHint =>
      'Batterie — Alex\nBasse — Sam\nVoix principale';

  @override
  String get partTemplateItemsHelp =>
      'Une partie par ligne. Indiquez l\'interprète après un tiret : Batterie — Alex';

  @override
  String get partTemplateItemsRequired => 'Ajoutez au moins une partie';

  @override
  String get partTemplateNameAndItemsRequired =>
      'Un nom et au moins une partie sont requis';

  @override
  String partTemplateItemCount(int count) {
    return '$count partie(s)';
  }

  @override
  String partTemplateImported(String name, int count) {
    return 'Modèle de parties « $name » importé ($count parties)';
  }

  @override
  String get errorLoadingPartTemplates =>
      'Erreur lors du chargement des modèles de parties';

  @override
  String get exportPartsCsv => 'Exporter les parties en CSV';

  @override
  String get exportAllPartsCsv =>
      'Exporter les parties de tous les morceaux en CSV';

  @override
  String get exportAllPartsCsvSubtitle =>
      'Une ligne de tableur par partie, pour tous les projets — pour partager l\'avancement avec vos collaborateurs';

  @override
  String get noPartsToExport => 'Aucune partie à exporter';

  @override
  String partsCsvExported(int count) {
    return '$count parties exportées';
  }

  @override
  String get projectExportPartsLabel => 'Parties :';

  @override
  String get csvHeaderProject => 'Projet';

  @override
  String get csvHeaderPart => 'Partie';

  @override
  String get csvHeaderPerformer => 'Interprète';

  @override
  String get csvHeaderStatus => 'État';

  @override
  String get csvHeaderNotes => 'Notes';

  @override
  String get exportPartsXlsx => 'Exporter les parties en Excel (.xlsx)';

  @override
  String get exportAllPartsXlsx =>
      'Exporter les parties de tous les morceaux en Excel (.xlsx)';

  @override
  String get exportAllPartsXlsxSubtitle =>
      'La même feuille que le CSV, avec en-tête figé, filtres de colonne et états de prise en couleur';

  @override
  String get importPartsFromSpreadsheet =>
      'Importer des parties depuis un tableur';

  @override
  String get partsImportPickerTitle => 'Sélectionnez un fichier CSV ou Excel';

  @override
  String partsImported(int added, int updated) {
    return '$added parties ajoutées, $updated mises à jour';
  }

  @override
  String get partsImportNothingFound => 'Aucune partie trouvée dans ce fichier';

  @override
  String partsImportFailed(String error) {
    return 'Impossible de lire ce tableur : $error';
  }

  @override
  String get partsMoreActions => 'Autres actions sur les parties';

  @override
  String partsPageTitle(String name) {
    return '$name — Parties';
  }

  @override
  String get manageParts => 'Gérer les parties';

  @override
  String partsMoreCount(int count) {
    return '+$count de plus';
  }

  @override
  String get searchParts => 'Rechercher des parties';

  @override
  String get allStatuses => 'Tous les états';

  @override
  String get allPerformers => 'Tous les interprètes';

  @override
  String partsSelectedCount(int count) {
    return '$count sélectionnées';
  }

  @override
  String get setPartStatus => 'Définir l\'état';

  @override
  String get assignPartPerformer => 'Attribuer un interprète';

  @override
  String get deleteSelectedParts => 'Supprimer la sélection';

  @override
  String deleteSelectedPartsConfirm(int count) {
    return 'Supprimer $count parties de ce morceau ?';
  }

  @override
  String partsDeleted(int count) {
    return '$count parties supprimées';
  }

  @override
  String get noPartsMatchFilters => 'Aucune partie ne correspond à ces filtres';

  @override
  String get reorderNeedsUnfilteredList =>
      'Effacez la recherche, les filtres et le tri pour réorganiser les parties';

  @override
  String get projectMarkers => 'Marqueurs';

  @override
  String projectMarkerUnnamed(int index) {
    return 'Marqueur $index';
  }

  @override
  String projectRegionUnnamed(int index) {
    return 'Région $index';
  }

  @override
  String get projectMarkerJumpTooltip =>
      'Aller à ce point de la chanson d\'aperçu';

  @override
  String get projectMarkerNoPreviewSong =>
      'Ajoutez une chanson d\'aperçu pour accéder aux marqueurs';

  @override
  String get projectDetailLayout => 'Disposition des Détails du Projet';

  @override
  String get projectDetailLayoutSettingDescription =>
      'Comment la page de détails du projet est organisée.';

  @override
  String get projectDetailLayoutClassic => 'Classique';

  @override
  String get projectDetailLayoutClassicDescription =>
      'Tout dans un seul défilement.';

  @override
  String get projectDetailLayoutSectioned => 'Sections';

  @override
  String get projectDetailLayoutSectionedDescription =>
      'Une barre à gauche choisit une section à la fois.';

  @override
  String get stackAsVersions => 'Empiler comme versions';

  @override
  String get stackNeedsTwoVersions =>
      'Sélectionnez au moins deux projets pour les empiler comme versions d\'un projet principal.';

  @override
  String stackCreatedMessage(int count) {
    return '$count versions empilées en un projet principal.';
  }

  @override
  String get stackVersionsTitle => 'Versions';

  @override
  String stackVersionCount(int count) {
    return '$count versions';
  }

  @override
  String get stackAddVersion => 'Ajouter une version';

  @override
  String get stackAddVersionTitle => 'Ajouter une version';

  @override
  String get stackAddVersionEmpty =>
      'Aucun projet non empilé disponible à ajouter.';

  @override
  String get stackRemoveVersion => 'Retirer de la pile';

  @override
  String get stackRemoveVersionMessage =>
      'Le fichier du projet reste sur le disque et revient dans la liste comme projet à part entière.';

  @override
  String get stackUnstack => 'Désempiler';

  @override
  String get stackUnstackTitle => 'Désempiler ce projet principal ?';

  @override
  String get stackUnstackMessage =>
      'Chaque version redevient un projet distinct avec les métadonnées qu\'elle avait avant l\'empilement. Les notes, tâches et l\'échéance partagées sur le projet principal sont supprimées.';

  @override
  String get stackDefaultVersion => 'Ouvert par défaut';

  @override
  String get stackSetDefaultVersion => 'Ouvrir cette version par défaut';

  @override
  String get stackChooseVersionToOpen => 'Quelle version voulez-vous ouvrir ?';

  @override
  String get stackMemberOf => 'Version de';

  @override
  String get stackMemberNotice =>
      'Ce fichier est une version d\'un projet empilé. Les métadonnées, tâches et temps de travail partagés sont sur le projet principal, pas ici.';

  @override
  String get stackOpenMainProject => 'Ouvrir le projet principal';

  @override
  String get stackWorkTimeAcrossVersions => 'Total sur toutes les versions';

  @override
  String get scanModeVersionStack => 'Pile de versions';

  @override
  String get scanModeVersionStackDescription =>
      'Tous les fichiers de projet d\'un dossier deviennent un projet principal partageant métadonnées, tâches et temps de travail. Les nouveaux fichiers le rejoignent automatiquement.';

  @override
  String stackTooltipStacked(int count) {
    return '$count versions empilées en un projet principal';
  }

  @override
  String get stackMetadataSourceTitle =>
      'Quel projet doit devenir le projet principal ?';

  @override
  String get stackMetadataSourceBody =>
      'Plusieurs d\'entre eux ont déjà leurs propres détails. Celui que vous choisissez devient le projet principal : son nom, BPM, tonalité, notes, tâches et échéance seront ceux de la pile. Rien n\'est fusionné ni perdu : les autres conservent leurs détails, et le désempilement les restitue.';

  @override
  String get stackMetadataSourceOldestHint => 'La plus ancienne — suggérée';

  @override
  String get stackMetadataNoneLabel => 'Aucun détail';

  @override
  String stackMetadataTodosLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches',
      one: '1 tâche',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataNotesLabel => 'notes';

  @override
  String get stackNotStackedYet => 'Pas encore empilé';

  @override
  String get stackStartFromHere =>
      'Ajoutez d\'autres fichiers de projet et ils deviendront des versions d\'un projet principal, partageant métadonnées, tâches et temps de travail.';

  @override
  String get stackSearchProjects => 'Rechercher des projets';

  @override
  String get stackSearchNoMatches =>
      'Aucun projet ne correspond à votre recherche.';

  @override
  String get stackStartedMessage => 'Empilé en un projet principal.';

  @override
  String get stackDefaultVersionTooltip =>
      'Cette version s\'ouvre par défaut au lancement du DAW.';

  @override
  String stackAddVersionsConfirm(int count) {
    return 'Ajouter $count';
  }

  @override
  String get stackAddVersionMultiTitle => 'Ajouter des versions';

  @override
  String get stackSelectAll => 'Tout sélectionner';

  @override
  String get stackClearSelection => 'Effacer';

  @override
  String stackMetadataPartsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parties',
      one: '1 partie',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataDeadlineLabel => 'échéance';

  @override
  String get stackMetadataRenamedLabel => 'nom personnalisé';

  @override
  String stackMetadataWorkHours(String hours) {
    return '$hours h enregistrées';
  }

  @override
  String get stackUnstackReleaseTitle => 'Quelle version reste sur la sortie ?';

  @override
  String stackUnstackReleaseBody(String releases) {
    return 'Ce projet est un titre de $releases. Le désempilement supprime l\'entrée empilée, donc une de ses versions doit prendre cette place — choisissez celle vers laquelle la sortie doit pointer.';
  }

  @override
  String get stackAutoConfirmTitle => 'Empiler ces versions ?';

  @override
  String stackAutoConfirmBody(int projects, int folders) {
    return 'La Pile de versions va regrouper $projects projets dans $folders dossiers. Chaque dossier devient un projet principal partageant métadonnées, tâches et temps de travail. Rien n\'est supprimé, et vous pourrez les désempiler ensuite.';
  }

  @override
  String get stackAutoConfirmApply => 'Empiler';

  @override
  String stackAutoFolderEntry(String folder, int count) {
    return '$folder — $count versions';
  }

  @override
  String get stackAutoJoinsExisting => 'rejoint le projet principal existant';

  @override
  String get untitledTheme => 'Thème sans nom';

  @override
  String switchToTheme(String themeName) {
    return 'Passer à $themeName';
  }

  @override
  String get newTheme => 'Nouveau thème';

  @override
  String get editTheme => 'Modifier le thème';

  @override
  String get duplicateTheme => 'Dupliquer';

  @override
  String get deleteThemeTitle => 'Supprimer le thème ?';

  @override
  String deleteThemeMessage(String name) {
    return '\"$name\" sera supprimé. Cette action est irréversible.';
  }

  @override
  String get themeNameLabel => 'Nom du thème';

  @override
  String get themeNameHint => 'ex. Studio Ambre';

  @override
  String get themeNameRequired => 'Donnez un nom au thème.';

  @override
  String get themeColorAccent => 'Accent';

  @override
  String get themeColorSecondaryAccent => 'Accent secondaire';

  @override
  String get themeColorBackground => 'Arrière-plan';

  @override
  String get themeColorCards => 'Cartes et panneaux';

  @override
  String get themeCardRoundness => 'Arrondi des cartes';

  @override
  String get themeButtonRoundness => 'Arrondi des boutons';

  @override
  String themeLowContrastWarning(String ratio) {
    return 'Contraste faible ($ratio:1). Le texte peut être difficile à lire.';
  }

  @override
  String get exportTheme => 'Exporter le thème';

  @override
  String get importTheme => 'Importer un thème';

  @override
  String themeExported(String path) {
    return 'Thème exporté vers $path';
  }

  @override
  String themeImported(String name) {
    return '« $name » importé';
  }

  @override
  String get themeImportFailed => 'Ce fichier n\'est pas un thème valide.';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexInvalid => 'Utilisez #RRGGBB';

  @override
  String get apply => 'Appliquer';

  @override
  String themeCopyName(String name) {
    return '$name copie';
  }

  @override
  String get suggestedColorsLabel => 'Couleurs Suggérées';
}
