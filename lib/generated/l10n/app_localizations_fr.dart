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
      'Le Scan Approfondi extrait les métadonnées complètes des fichiers de projet:\n• BPM (Battements Par Minute)\n• Tonalité Musicale\n• Version du DAW\n• Notes de Projet (si pris en charge)\n• Pistes, plug-ins et clips MIDI (si pris en charge)\n\nC\'est plus lent qu\'un scan régulier et peut prendre un certain temps. Continuer?';

  @override
  String get deepScanViewSupportedDaws =>
      'Voir les DAW et champs pris en charge';

  @override
  String get deepScanOnlyUnscanned =>
      'Scanner uniquement les projets pas encore lus entièrement';

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
  String get metadataFieldMidiEvents => 'Contrôleurs et pitch bend MIDI';

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
  String get viewModeTable => 'Vue tableau';

  @override
  String get viewModeCards => 'Vue cartes';

  @override
  String get selectProject => 'Sélectionner le projet';

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
  String projectsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets masqués.',
      one: '$count projet masqué.',
    );
    return '$_temp0';
  }

  @override
  String projectsUnhidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets affichés.',
      one: '$count projet affiché.',
    );
    return '$_temp0';
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
  String deleteMissingProjectsConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count projets dont les fichiers sont introuvables sur cette machine passeront dans Supprimés récemment (Réglages > Dossiers de projets), où vous pourrez les restaurer avec leurs notes, échéances et historique des sessions pendant 30 jours.',
      one:
          '$count projet dont le fichier est introuvable sur cette machine passera dans Supprimés récemment (Réglages > Dossiers de projets), où vous pourrez le restaurer avec ses notes, échéances et historique des sessions pendant 30 jours.',
    );
    return '$_temp0';
  }

  @override
  String get deleteMissingProjectsConfirmButton => 'Supprimer';

  @override
  String missingProjectsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets manquants supprimés.',
      one: '$count projet manquant supprimé.',
    );
    return '$_temp0';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Supprimer également $count projets faisant partie d\'une sortie (les retire aussi de cette sortie)',
      one:
          'Supprimer également $count projet faisant partie d\'une sortie (le retire aussi de cette sortie)',
    );
    return '$_temp0';
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
  String metadataExtractedForProjects(int count, String failures) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Métadonnées extraites pour $count projets.',
      one: 'Métadonnées extraites pour $count projet.',
    );
    return '$_temp0 $failures';
  }

  @override
  String extractionFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ont échoué.',
      one: '$count a échoué.',
    );
    return '$_temp0';
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
  String scanComplete(String type, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$type terminé: $count projets ajoutés/mis à jour.',
      one: '$type terminé: $count projet ajouté/mis à jour.',
    );
    return '$_temp0';
  }

  @override
  String get scanCancelled => 'Scan annulé.';

  @override
  String scanFailuresSnackbar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets n\'ont pas pu être chargés.',
      one: '$count projet n\'a pas pu être chargé.',
    );
    return '$_temp0';
  }

  @override
  String get scanFailuresSnackbarAction => 'Détails';

  @override
  String get scanFailuresDialogTitle => 'Erreurs de Scan';

  @override
  String get scanFailuresDialogIntro =>
      'Ces fichiers n\'ont pas pu être lus pendant le scan (ils ont peut-être été supprimés, déplacés ou verrouillés par un autre programme) :';

  @override
  String projectsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets sélectionnés',
      one: '$count projet sélectionné',
    );
    return '$_temp0';
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
  String releasesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sorties sélectionnées',
      one: '$count sortie sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedReleases => 'Supprimer la sélection';

  @override
  String deleteSelectedReleasesConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voulez-vous vraiment supprimer $count sorties ?',
      one: 'Voulez-vous vraiment supprimer $count sortie ?',
    );
    return '$_temp0';
  }

  @override
  String releasesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sorties supprimées',
      one: '$count sortie supprimée',
    );
    return '$_temp0';
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
  String addedTracksToRelease(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistes ajoutées à la sortie.',
      one: '$count piste ajoutée à la sortie.',
    );
    return '$_temp0';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Fichiers de la Sortie ($count)';
  }

  @override
  String get addFiles => 'Ajouter des Fichiers';

  @override
  String addedFilesToRelease(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers ajoutés à la sortie.',
      one: '$count fichier ajouté à la sortie.',
    );
    return '$_temp0';
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
  String selectTracksToInclude(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '$count sélectionnée',
    );
    return 'Sélectionner les pistes à inclure dans la sortie ($_temp0)';
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
  String templatesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modèles sélectionnés',
      one: '$count modèle sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedTemplates => 'Supprimer la sélection';

  @override
  String deleteSelectedTemplatesConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voulez-vous vraiment supprimer $count modèles ?',
      one: 'Voulez-vous vraiment supprimer $count modèle ?',
    );
    return '$_temp0';
  }

  @override
  String templatesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modèles supprimés',
      one: '$count modèle supprimé',
    );
    return '$_temp0';
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
  String statusChangedForProjects(int count, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Phase changée en \"$status\" pour $count projets',
      one: 'Phase changée en \"$status\" pour $count projet',
    );
    return '$_temp0';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    int failCount,
    String status,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      successCount,
      locale: localeName,
      other: '$successCount projets',
      one: '$successCount projet',
    );
    String _temp1 = intl.Intl.pluralLogic(
      failCount,
      locale: localeName,
      other: '$failCount ont échoué',
      one: '$failCount a échoué',
    );
    return 'Phase changée en \"$status\" pour $_temp0, $_temp1';
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
  String get importLaunchCommandsTitle =>
      'Importer les programmes de « Lancer dans le DAW » ?';

  @override
  String get importLaunchCommandsMessage =>
      'Cette sauvegarde désigne des programmes que « Lancer dans le DAW » exécuterait sur cet ordinateur. Ne les importez que si vous avez créé la sauvegarde vous-même.';

  @override
  String get importLaunchCommandsSkip => 'Ne pas importer';

  @override
  String get importLaunchCommandsImport => 'Les importer';

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
  String dateYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count ans',
      one: 'il y a 1 an',
    );
    return '$_temp0';
  }

  @override
  String ageYearsMonths(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years ans',
      one: '$years an',
    );
    return '$_temp0, $months mois';
  }

  @override
  String ageYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years ans',
      one: '$years an',
    );
    return '$_temp0';
  }

  @override
  String ageMonthsDays(int months, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
    );
    return '$months mois, $_temp0';
  }

  @override
  String ageMonths(int months) {
    return '$months mois';
  }

  @override
  String ageDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
    );
    return '$_temp0';
  }

  @override
  String ageHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '$hours heure',
    );
    return '$_temp0';
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
  String get pressKitFile => 'Fichier du dossier de presse';

  @override
  String get saveFileDialogTitle => 'Enregistrer le fichier';

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
  String downloadNFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Télécharger $count fichiers',
      one: 'Télécharger $count fichier',
    );
    return '$_temp0';
  }

  @override
  String nFilesSavedTo(int count, String filename) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers enregistrés dans $filename',
      one: '$count fichier enregistré dans $filename',
    );
    return '$_temp0';
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
  String get trayBackupNow => 'Synchroniser maintenant';

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
  String get sortByDeadline => 'Échéance';

  @override
  String get sortByLabel => 'Trier par';

  @override
  String get cardInitialsTitle => 'Initiales de la carte';

  @override
  String get cardInitialsDescription =>
      'Les lettres affichées sur la carte de ce projet lorsqu\'il n\'a pas de pochette.';

  @override
  String get cardInitialsEmptyHint =>
      'Laisser vide pour utiliser les initiales du nom.';

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
  String byLabel(String label) {
    return 'par $label';
  }

  @override
  String get latestCaptureTitle => 'Dernière capture';

  @override
  String get latestCaptureExplanation =>
      'Le dernier passage enregistré par le plugin de la DAW';

  @override
  String latestCaptureDetails(String when, String length) {
    return '$when · $length';
  }

  @override
  String get latestCaptureUseAsPreview => 'Utiliser comme chanson d\'aperçu';

  @override
  String get latestCaptureNotOnThisDevice => 'Pas encore sur cet appareil';

  @override
  String get latestCapturePlay => 'Lire la dernière capture';

  @override
  String get latestCaptureMenuHint =>
      'Clic droit pour lire la dernière capture';

  @override
  String get latestCaptureNowPreview =>
      'La dernière capture est maintenant la chanson d\'aperçu';

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
  String get relocateFolderAction => 'Déplacer';

  @override
  String get relocateFolderConfirmBody =>
      'Les projets de ce dossier seront cherchés dans le nouveau, avec leurs notes, tâches, temps de travail et tout le reste. Rien n\'est copié ni déplacé sur le disque.';

  @override
  String get relocateFolderFrom => 'De';

  @override
  String get relocateFolderTo => 'Vers';

  @override
  String relocateFolderFound(int found, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$found projets sur $total sont déjà dans le nouveau dossier.',
      one: '$found projet sur 1 est déjà dans le nouveau dossier.',
    );
    return '$_temp0';
  }

  @override
  String get relocateFolderSomeMissing =>
      'Les autres apparaîtront comme manquants jusqu\'à ce que leurs fichiers soient là. N\'utilisez pas « Supprimer les manquants » d\'ici là.';

  @override
  String get relocateFolderNoneFound =>
      'Aucun n\'y est encore. Si les fichiers sont encore en cours de téléchargement, c\'est normal. Sinon, vérifiez que vous avez choisi le dossier lui-même, pas celui du dessus ou du dessous.';

  @override
  String relocateFolderOverlapsOwn(String path) {
    return '$path est déjà un dossier de projets de ce profil, ou en chevauche un. Choisissez un autre dossier, ou retirez d\'abord celui-là.';
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
  String get updateWindowsInstallerSourceLabel =>
      'Programme d’installation Windows';

  @override
  String get updateWindowsInstallerInstructions =>
      'Téléchargez le nouveau programme d’installation et lancez-le. Il met à jour cette installation et conserve votre bibliothèque.';

  @override
  String get updateDownloadInstaller =>
      'Télécharger le programme d’installation';

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
      'Chaque projet, chaque DAW, un seul endroit.';

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
  String get onboardingDetailLayoutTitle => 'Pages de projet';

  @override
  String get onboardingDetailLayoutBody =>
      'La façon dont la page d\'un projet est organisée. Modifiable à tout moment avec les boutons en haut de la page.';

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

  @override
  String get todoDueDate => 'Échéance';

  @override
  String get todoSetDueDate => 'Définir l\'échéance';

  @override
  String get todoClearDueDate => 'Supprimer l\'échéance';

  @override
  String get todoNoDueDate => 'Sans échéance';

  @override
  String get todoDueToday => 'Échéance aujourd’hui';

  @override
  String get todoDueTomorrow => 'Échéance demain';

  @override
  String todoDueOn(String date) {
    return 'Échéance le $date';
  }

  @override
  String todoOverdueByDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours de retard',
      one: '1 jour de retard',
    );
    return '$_temp0';
  }

  @override
  String get queueDueFilterLabel => 'Échéance';

  @override
  String get queueDueFilterAll => 'Toutes les tâches';

  @override
  String get queueDueFilterOverdue => 'En retard';

  @override
  String get queueDueFilterToday => 'Échéance aujourd’hui';

  @override
  String get queueDueFilterThisWeek => 'Échéance cette semaine';

  @override
  String get queueDueFilterNoDate => 'Sans échéance';

  @override
  String get queueNoTasksForDueFilter =>
      'Aucune tâche ne correspond à ce filtre d’échéance';

  @override
  String get projectAttachments => 'Pièces jointes';

  @override
  String get attachmentAddFile => 'Ajouter un fichier';

  @override
  String get attachmentAddLink => 'Ajouter un lien';

  @override
  String get attachmentsEmptyTitle => 'Rien de joint pour l\'instant';

  @override
  String get attachmentsEmptyDescription =>
      'Gardez la piste de référence, le lien de livraison des stems, le texte et le contrat avec le morceau plutôt que dans une conversation.';

  @override
  String get attachmentEditDialogTitle => 'Modifier la pièce jointe';

  @override
  String get attachmentUrlLabel => 'URL';

  @override
  String get attachmentPathLabel => 'Chemin du fichier';

  @override
  String get attachmentLabelLabel => 'Libellé (facultatif)';

  @override
  String get attachmentNoteLabel => 'Note (facultative)';

  @override
  String get attachmentUrlInvalid =>
      'Saisissez un lien valide, p. ex. https://exemple.com';

  @override
  String get attachmentPathRequired => 'Saisissez le chemin du fichier';

  @override
  String get attachmentOpenTooltip => 'Ouvrir';

  @override
  String get attachmentRemoveTitle => 'Retirer la pièce jointe';

  @override
  String attachmentRemoveMessage(String label) {
    return 'Retirer \"$label\" de ce projet ? Le fichier lui-même n\'est pas supprimé.';
  }

  @override
  String get attachmentRemoved => 'Pièce jointe retirée';

  @override
  String get attachmentAdded => 'Pièce jointe ajoutée';

  @override
  String get attachmentOpenFailed => 'Impossible d\'ouvrir cette pièce jointe';

  @override
  String get attachmentPickFileTitle => 'Choisissez un fichier à joindre';

  @override
  String get attachmentAlreadyAdded => 'C\'est déjà joint à ce projet';

  @override
  String get attachmentExport => 'Exporter';

  @override
  String get attachmentExportTooltip =>
      'Enregistrer les fichiers et liens joints';

  @override
  String get attachmentExportNothing => 'Rien à exporter';

  @override
  String get attachmentExporting => 'Exportation des pièces jointes...';

  @override
  String attachmentExportSaved(String path) {
    return 'Enregistré dans : $path';
  }

  @override
  String attachmentExportSkippedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers introuvables ignorés',
      one: '$count fichier introuvable ignoré',
    );
    return '$_temp0';
  }

  @override
  String attachmentExportFailed(String error) {
    return 'Échec de l\'exportation des pièces jointes : $error';
  }

  @override
  String get projectAppearance => 'Apparence';

  @override
  String get projectAppearanceTooltip =>
      'Modifier la pochette, la couleur et l\'icône';

  @override
  String get projectCoverArt => 'Pochette';

  @override
  String get chooseCoverArt => 'Choisir une image…';

  @override
  String get replaceCoverArt => 'Remplacer l\'image…';

  @override
  String get removeCoverArt => 'Supprimer la pochette';

  @override
  String get removeCoverArtConfirm =>
      'Supprimer la pochette de ce projet ? L\'image enregistrée sera supprimée.';

  @override
  String get coverArtRemoved => 'Pochette supprimée';

  @override
  String failedToRemoveCoverArt(String error) {
    return 'Échec de la suppression de la pochette : $error';
  }

  @override
  String get projectAccentColor => 'Couleur d\'accent';

  @override
  String get projectIcon => 'Icône';

  @override
  String get appearanceNone => 'Aucun';

  @override
  String get appearanceNoneHint =>
      'Les projets n\'affichent ni couleur ni icône tant que vous n\'en choisissez pas. Touchez à nouveau l\'icône sélectionnée pour la retirer.';

  @override
  String get clearColorAndIcon => 'Effacer la couleur et l\'icône';

  @override
  String get dropCoverArtHere => 'Déposez une image pour définir la pochette';

  @override
  String get uploadingProjectCoverArt => 'Envoi des pochettes de projets...';

  @override
  String get downloadingProjectCoverArt =>
      'Téléchargement des pochettes de projets...';

  @override
  String get moveProjectButtonLabel => 'Déplacer…';

  @override
  String get moveProjectDialogTitle => 'Déplacer le projet';

  @override
  String get moveProjectDestinationLabel => 'Destination';

  @override
  String get moveProjectChooseDestination => 'Choisir…';

  @override
  String get moveProjectNoDestinationChosen =>
      'Aucun dossier choisi pour l\'instant';

  @override
  String moveProjectIncludeFolder(String folder) {
    return 'Déplacer tout le dossier « $folder »';
  }

  @override
  String get moveProjectIncludeFolderDescription =>
      'Ce dossier ne contient que ce projet : ses samples et mixages sont déplacés avec lui.';

  @override
  String get moveProjectFileOnlyDescription =>
      'Seul le fichier du projet est déplacé. Les samples et mixages à côté restent en place.';

  @override
  String get moveProjectConfirm => 'Déplacer';

  @override
  String get moveProjectInProgress => 'Déplacement…';

  @override
  String moveProjectSuccess(String name, String path) {
    return '« $name » déplacé vers $path';
  }

  @override
  String moveProjectFailed(String error) {
    return 'Échec du déplacement : $error';
  }

  @override
  String get moveProjectErrorSourceMissing =>
      'Le fichier de ce projet n\'est pas sur cette machine.';

  @override
  String moveProjectErrorDestinationOccupied(String name) {
    return '« $name » existe déjà dans ce dossier.';
  }

  @override
  String get moveProjectErrorDestinationInsideSource =>
      'Vous ne pouvez pas déplacer un dossier dans lui-même.';

  @override
  String get moveProjectErrorSameLocation =>
      'Le projet est déjà dans ce dossier.';

  @override
  String get moveProjectStackUnsupported =>
      'Une pile de versions n\'a pas de fichier propre — déplacez ses versions individuellement.';

  @override
  String get selectMoveDestinationTitle =>
      'Sélectionner le dossier de destination';

  @override
  String get archiveProjectButtonLabel => 'Archiver…';

  @override
  String get archiveProjectDialogTitle => 'Archiver le projet';

  @override
  String get archiveProjectWhatToArchive => 'Que faut-il archiver';

  @override
  String archiveProjectScopeFolder(String folder) {
    return 'Tout le dossier « $folder »';
  }

  @override
  String get archiveProjectScopeFileOnly => 'Le fichier du projet seulement';

  @override
  String archiveScopeSummary(String size, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files fichiers',
      one: '1 fichier',
    );
    return '$size · $_temp0';
  }

  @override
  String get archiveProjectDeleteOriginals =>
      'Supprimer les originaux après vérification de l\'archive';

  @override
  String get archiveProjectDeleteOriginalsDescription =>
      'L\'archive est d\'abord rouverte et contrôlée entrée par entrée. Rien n\'est supprimé si ce contrôle échoue.';

  @override
  String get archiveProjectConfirm => 'Archiver';

  @override
  String get archiveStageScanning => 'Lecture du dossier du projet…';

  @override
  String get archiveStageCompressing => 'Compression…';

  @override
  String get archiveStageVerifying => 'Vérification de l\'archive…';

  @override
  String get archiveStageDeleting => 'Suppression des originaux…';

  @override
  String archiveProjectSuccess(String name) {
    return '« $name » archivé';
  }

  @override
  String archiveProjectFailed(String error) {
    return 'Échec de l\'archivage : $error';
  }

  @override
  String get archiveErrorSourceMissing =>
      'Les fichiers de ce projet ne sont pas sur cette machine.';

  @override
  String archiveErrorDestinationInScanRoot(String root) {
    return 'Les archives ne peuvent pas être dans un dossier analysé — « $root » les réindexerait aussitôt.';
  }

  @override
  String archiveErrorDestinationOccupied(String name) {
    return 'Une archive nommée « $name » s\'y trouve déjà.';
  }

  @override
  String archiveErrorVerificationFailed(String entries) {
    return 'Il manque des fichiers dans l\'archive : rien n\'a été supprimé ($entries)';
  }

  @override
  String get archiveErrorNotArchived => 'Ce projet n\'est pas archivé.';

  @override
  String archiveWarningsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers illisibles ont été ignorés',
      one: '1 fichier illisible a été ignoré',
    );
    return '$_temp0';
  }

  @override
  String get archiveLocationTitle => 'Emplacement des archives';

  @override
  String get archiveLocationSubtitle =>
      'Où « Archiver le projet » écrit ses fichiers zip. Conservé sur cet appareil.';

  @override
  String get archiveLocationNotSet =>
      'Non défini — la question vous sera posée au premier archivage';

  @override
  String get selectArchiveLocationTitle =>
      'Sélectionner le dossier d\'archives';

  @override
  String get restoreProjectButtonLabel => 'Restaurer…';

  @override
  String get restoreProjectDialogTitle => 'Restaurer le projet';

  @override
  String get restoreProjectDescription =>
      'Extrait l\'archive dans un dossier de votre choix et fait pointer le projet vers les fichiers restaurés.';

  @override
  String get restoreProjectConfirm => 'Restaurer';

  @override
  String get restoreProjectInProgress => 'Restauration…';

  @override
  String restoreProjectSuccess(String name) {
    return '« $name » restauré';
  }

  @override
  String restoreProjectFailed(String error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String get selectRestoreDestinationTitle =>
      'Sélectionner un dossier de restauration';

  @override
  String get archivedLabel => 'Archivé';

  @override
  String archivedOnLabel(String date) {
    return 'Archivé le $date';
  }

  @override
  String get showArchivedProjects => 'Afficher les archivés';

  @override
  String get showOnlyArchivedProjects => 'Archivés uniquement';

  @override
  String get hideArchivedProjects => 'Masquer les archivés';

  @override
  String get archivedFilterLabel => 'Archivés';

  @override
  String get archiveProjectStackUnsupported =>
      'Une pile de versions n\'a pas de fichiers propres — archivez ses versions individuellement.';

  @override
  String get archiveBulkButtonLabel => 'Archiver la sélection';

  @override
  String archiveBulkConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Archiver $count projets ?',
      one: 'Archiver 1 projet ?',
    );
    return '$_temp0';
  }

  @override
  String archiveBulkSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets archivés',
      one: '1 projet archivé',
    );
    return '$_temp0';
  }

  @override
  String get openArchiveFolder => 'Ouvrir le dossier d\'archives';

  @override
  String archiveBulkProgress(int current, int total) {
    return '$current sur $total';
  }

  @override
  String archiveBulkFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets n\'ont pas pu être archivés',
      one: '1 projet n\'a pas pu être archivé',
    );
    return '$_temp0';
  }

  @override
  String get archiveBulkScopeNote =>
      'Chaque projet est archivé avec la portée qui lui convient : le dossier entier s\'il en a un à lui, le fichier du projet seul s\'il partage son dossier.';

  @override
  String get archivedWithLocalCopy =>
      'Archivé — les originaux sont toujours là';

  @override
  String get archivedAwayTooltip =>
      'Archivé — les fichiers ne sont plus que dans l\'archive';

  @override
  String get archiveUndone => 'Archivage annulé';

  @override
  String archiveUndoFailed(String error) {
    return 'Impossible d\'annuler l\'archivage : $error';
  }

  @override
  String get moveUndone => 'Déplacement annulé';

  @override
  String moveUndoFailed(String error) {
    return 'Impossible d\'annuler le déplacement : $error';
  }

  @override
  String get restoreToOriginalLocation => 'Vers son emplacement d\'origine';

  @override
  String get restoreToChosenFolder => 'Vers un autre dossier…';

  @override
  String get restoreWhereTo => 'Où doit-il aller ?';

  @override
  String get restoreOriginalLocationOccupied =>
      'Il y a déjà quelque chose à l\'emplacement d\'origine';

  @override
  String get discardArchiveButtonLabel => 'Supprimer l\'archive';

  @override
  String get discardArchiveConfirmTitle => 'Supprimer l\'archive ?';

  @override
  String get discardArchiveConfirmMessage =>
      'Supprime le zip et retire l\'indicateur d\'archivage. Les fichiers du projet restent en place.';

  @override
  String get discardArchiveDone => 'Archive supprimée';

  @override
  String get whatsNewTitle => 'Nouveautés';

  @override
  String whatsNewTitleWithVersion(String version) {
    return 'Nouveautés de la version $version';
  }

  @override
  String get whatsNewIntro =>
      'Voici ce qui a changé depuis votre version précédente.';

  @override
  String get whatsNewGotIt => 'J\'ai compris';

  @override
  String get changelogFullButton => 'Journal complet';

  @override
  String get changelogPageTitle => 'Journal des modifications';

  @override
  String get changelogEmpty =>
      'Aucun journal des modifications disponible pour cette version.';

  @override
  String get changelogCurrentVersionBadge => 'Installée';

  @override
  String get disableProjectFolderTooltip =>
      'Désactiver ce dossier (conserve ses projets)';

  @override
  String get enableProjectFolderTooltip => 'Activer ce dossier';

  @override
  String get projectFolderDisabledBadge => 'Désactivé';

  @override
  String get projectFolderDisabledExplanation =>
      'Non analysé, et ses projets sont masqués. Rien n’a été supprimé — réactivez-le pour les retrouver.';

  @override
  String projectFolderEnabled(String name) {
    return '« $name » est de nouveau analysé';
  }

  @override
  String projectFolderDisabled(String name) {
    return '« $name » est désactivé — ses projets sont masqués, pas supprimés';
  }

  @override
  String get releaseArtworkCarryOverTitle =>
      'Utiliser la pochette d’une piste ?';

  @override
  String releaseArtworkCarryOverBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count des pistes sélectionnées ont une pochette. Choisissez-en une comme pochette de cette sortie.',
      one:
          'Une des pistes sélectionnées a une pochette. L’utiliser comme pochette de cette sortie ?',
    );
    return '$_temp0';
  }

  @override
  String get releaseArtworkCarryOverUse => 'Utiliser comme pochette';

  @override
  String get releaseArtworkCarryOverSkip => 'Aucune pochette';

  @override
  String get tracksViewList => 'Vue liste';

  @override
  String get tracksViewTable => 'Vue tableau';

  @override
  String get partsColumn => 'Parties';

  @override
  String partsNeededCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parties encore nécessaires',
      one: '1 partie encore nécessaire',
    );
    return '$_temp0';
  }

  @override
  String get songLength => 'Durée';

  @override
  String get songLengthColumn => 'Durée';

  @override
  String get songLengthHint => '3:45';

  @override
  String get songLengthManual =>
      'Saisie à la main — videz le champ pour utiliser la durée de l’aperçu';

  @override
  String get songLengthFromPreview => 'Mesurée depuis l’aperçu';

  @override
  String releaseLengthAtLeast(String total) {
    return '$total+';
  }

  @override
  String get releaseLengthComplete => 'Durée totale';

  @override
  String releaseLengthPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Total partiel — $count pistes n’ont pas encore de durée',
      one: 'Total partiel — 1 piste n’a pas encore de durée',
    );
    return '$_temp0';
  }

  @override
  String get breadcrumbHome => 'Accueil';

  @override
  String breadcrumbGoTo(String label) {
    return 'Aller à $label';
  }

  @override
  String get scrollForMore => 'Faites défiler pour en voir plus';

  @override
  String get shortcutPlayerMono => 'Activer/désactiver la lecture en mono';

  @override
  String get shortcutPlayerVolume => 'Régler le volume';

  @override
  String get shortcutMouseWheel => 'Molette';

  @override
  String get releaseTotalLengthLabel => 'Durée totale';

  @override
  String get releaseLengthNone =>
      'Aucune piste n’a encore de durée — lisez une piste ou saisissez sa durée sur la page du projet';

  @override
  String get songLengthHowItWorks =>
      'Renseignée automatiquement depuis l’aperçu — lorsqu’il est lu, ou à l’ouverture d’une sortie contenant cette piste. Vous pouvez aussi la saisir : 3:45, 1:02:03 ou en secondes.';

  @override
  String get changelogSectionSubtitle =>
      'Tout ce qui a changé dans chaque version, de la plus récente à la plus ancienne.';

  @override
  String get changelogSearchHint => 'Rechercher dans le journal';

  @override
  String changelogNoMatches(String query) {
    return 'Aucune modification ne correspond à « $query »';
  }

  @override
  String get projectFileMenu => 'Fichier';

  @override
  String get moreActions => 'Plus d\'actions';

  @override
  String get sectionRailResizeHint =>
      'Faites glisser pour redimensionner · double-cliquez pour réinitialiser';

  @override
  String get stackMetadataCoverArtLabel => 'pochette';

  @override
  String get stackMetadataColorLabel => 'couleur d\'accent';

  @override
  String get stackMetadataIconLabel => 'icône';

  @override
  String get projectTags => 'Étiquettes';

  @override
  String get filterByTag => 'Filtrer par étiquette';

  @override
  String get allTags => 'Toutes les étiquettes';

  @override
  String get addTagHint => 'Ajouter une étiquette…';

  @override
  String get tagsHelper =>
      'Appuyez sur Entrée pour ajouter. Genre, ambiance, client, emoji : tout ce qui vous sert à filtrer.';

  @override
  String removeTagTooltip(String tag) {
    return 'Retirer l\'étiquette « $tag »';
  }

  @override
  String filterByThisTagTooltip(String tag) {
    return 'Afficher uniquement les projets avec l\'étiquette « $tag »';
  }

  @override
  String get sortByTags => 'Étiquettes';

  @override
  String get bulkTagsButton => 'Étiquettes';

  @override
  String bulkTagsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Étiqueter $count projets',
      one: 'Étiqueter 1 projet',
    );
    return '$_temp0';
  }

  @override
  String get bulkTagsAddLabel =>
      'Ajouter une étiquette à tous les projets sélectionnés';

  @override
  String get bulkTagsRemoveLabel => 'Retirer une étiquette de la sélection';

  @override
  String get bulkTagsNoneToRemove =>
      'Aucun des projets sélectionnés n\'a encore d\'étiquette.';

  @override
  String bulkTagsUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets mis à jour',
      one: '1 projet mis à jour',
      zero: 'Rien à modifier',
    );
    return '$_temp0';
  }

  @override
  String stackMetadataTagsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étiquettes',
      one: '1 étiquette',
    );
    return '$_temp0';
  }

  @override
  String projectExportTagsLabel(String tags) {
    return 'Étiquettes : $tags';
  }

  @override
  String get enableTags => 'Activer les étiquettes';

  @override
  String get tagsSettingDescription =>
      'Ajoutez vos propres étiquettes aux projets, puis filtrez, recherchez et triez par étiquette. Désactiver l\'option les masque seulement : les étiquettes ajoutées sont conservées.';

  @override
  String get projectContentsTitle => 'Contenu du projet';

  @override
  String get projectStatsTracks => 'Pistes';

  @override
  String get projectStatsAudio => 'Audio';

  @override
  String get projectStatsMidi => 'MIDI';

  @override
  String get projectStatsInstrument => 'Instrument';

  @override
  String get projectStatsSampler => 'Sampler';

  @override
  String get projectStatsBus => 'Groupes et FX';

  @override
  String get projectStatsFolder => 'Dossiers';

  @override
  String get projectStatsPlugins => 'Plug-ins';

  @override
  String get midiClipsTitle => 'Clips MIDI';

  @override
  String get midiClipsLoad => 'Charger les clips MIDI';

  @override
  String get midiClipsLoadHint =>
      'Lus depuis le fichier du projet et conservés avec lui, pour être synchronisés sur vos autres appareils.';

  @override
  String get midiClipsLoading => 'Lecture du fichier du projet…';

  @override
  String get midiClipsNone => 'Aucun clip MIDI avec des notes dans ce projet.';

  @override
  String midiClipsError(String error) {
    return 'Impossible de lire les clips MIDI : $error';
  }

  @override
  String get midiClipPlay => 'Écouter avec un synthé simple';

  @override
  String get midiClipStop => 'Arrêter l’écoute';

  @override
  String get midiClipSave => 'Enregistrer en fichier MIDI';

  @override
  String get midiClipsExportAll => 'Tout exporter en MIDI…';

  @override
  String midiClipsExported(int count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers MIDI enregistrés dans $folder',
      one: '1 fichier MIDI enregistré dans $folder',
    );
    return '$_temp0';
  }

  @override
  String midiClipSaved(String fileName) {
    return '$fileName enregistré';
  }

  @override
  String get midiClipDragTooltip => 'Glisser dans votre DAW ou un dossier';

  @override
  String midiClipBars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesures',
      one: '1 mesure',
    );
    return '$_temp0';
  }

  @override
  String midiClipNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String midiClipUsedTimes(int count) {
    return 'Utilisé $count×';
  }

  @override
  String midiClipPreviewFailed(String error) {
    return 'Impossible de lire l’aperçu : $error';
  }

  @override
  String midiClipSaveFailed(String error) {
    return 'Impossible d’enregistrer le fichier MIDI : $error';
  }

  @override
  String get midiClipsExportFolderTitle =>
      'Choisissez un dossier pour les fichiers MIDI';

  @override
  String midiClipAlsoAs(String names) {
    return 'Aussi : $names';
  }

  @override
  String get midiClipsNoTrack => 'Autres clips';

  @override
  String get midiClipsExpandTrack => 'Afficher les clips de cette piste';

  @override
  String get midiClipsCollapseTrack => 'Masquer les clips de cette piste';

  @override
  String get midiTempoTooltip =>
      'Tempo de l’écoute et des fichiers MIDI enregistrés';

  @override
  String get midiTempoSlower => 'Plus lent';

  @override
  String get midiTempoFaster => 'Plus rapide';

  @override
  String midiTempoReset(String bpm) {
    return 'Revenir au tempo du projet ($bpm BPM)';
  }

  @override
  String get midiClipShare => 'Partager';

  @override
  String get midiClipsShareAll => 'Tout partager';

  @override
  String midiClipShareText(String clip, String project) {
    return 'Clip MIDI « $clip » de $project';
  }

  @override
  String midiClipsShareAllText(String project) {
    return 'Clips MIDI de $project';
  }

  @override
  String get midiClipsShareFallback =>
      'Le partage n’est pas disponible ici : les fichiers sont dans le dossier qui vient de s’ouvrir. Glissez-les dans votre messagerie.';

  @override
  String midiClipShareFailed(String error) {
    return 'Partage impossible : $error';
  }

  @override
  String get midiClipsRefresh => 'Relire depuis le fichier du projet';

  @override
  String get midiClipsStale =>
      'Le fichier du projet a changé depuis la lecture de ces clips.';

  @override
  String get midiClipsNoneStored =>
      'Aucun clip MIDI enregistré pour ce projet. Extrayez ses métadonnées sur l’ordinateur qui a le fichier du projet.';

  @override
  String midiClipInstrumentTooltip(String name) {
    return 'Instrument : $name';
  }

  @override
  String get synthVoiceLead => 'Lead';

  @override
  String get synthVoiceBass => 'Basse';

  @override
  String get synthVoicePad => 'Nappe';

  @override
  String get synthVoicePluck => 'Pluck';

  @override
  String get synthVoiceKeys => 'Clavier';

  @override
  String get synthVoiceOrgan => 'Orgue';

  @override
  String get synthVoiceStrings => 'Cordes';

  @override
  String get synthVoiceBrass => 'Cuivres';

  @override
  String get synthVoiceBell => 'Cloche';

  @override
  String get synthVoiceDrumKit => 'Batterie';

  @override
  String get synthVoiceKick => 'Grosse caisse';

  @override
  String get synthVoiceSnare => 'Caisse claire';

  @override
  String get synthVoiceClap => 'Clap';

  @override
  String get synthVoiceHiHat => 'Charleston';

  @override
  String get synthVoicePercussion => 'Percussions';

  @override
  String get midiLibraryTab => 'MIDI';

  @override
  String get midiLibrarySearchHint => 'Rechercher des clips MIDI';

  @override
  String get midiLibraryAllClips => 'Tous les clips';

  @override
  String get midiCollectionsTitle => 'Collections';

  @override
  String get midiCollectionNew => 'Nouvelle collection';

  @override
  String get midiCollectionNameHint => 'Nom de la collection';

  @override
  String get midiCollectionCreate => 'Créer';

  @override
  String get midiCollectionRename => 'Renommer';

  @override
  String get midiCollectionDelete => 'Supprimer la collection';

  @override
  String midiCollectionDeleteConfirm(String name) {
    return 'Supprimer « $name » ? Ses clips sont des copies : les projets d’origine ne sont pas touchés.';
  }

  @override
  String get midiCollectionAddTo => 'Ajouter à une collection';

  @override
  String get midiCollectionRemoveFrom => 'Retirer de la collection';

  @override
  String midiCollectionAdded(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clips ajoutés à $name',
      one: 'Ajouté à $name',
    );
    return '$_temp0';
  }

  @override
  String midiCollectionAlreadyIn(String name) {
    return 'Déjà dans $name';
  }

  @override
  String midiCollectionRemoved(String clip, String name) {
    return '$clip retiré de $name';
  }

  @override
  String get midiCollectionEmpty =>
      'Cette collection est vide. Ajoutez des clips depuis Tous les clips ou depuis la page d’un projet.';

  @override
  String midiCollectionShareText(String name) {
    return 'Collection MIDI « $name »';
  }

  @override
  String get midiLibraryEmpty =>
      'Pas encore de clips MIDI. Extrayez les métadonnées d’un projet pour lire ses clips.';

  @override
  String get midiLibraryNoMatches => 'Aucun clip ne correspond.';

  @override
  String get midiLibraryAllInstruments => 'Tous les instruments';

  @override
  String get midiClipMoreActions => 'Plus';

  @override
  String get midiTempoAuto => 'Auto';

  @override
  String get midiTempoResetAuto => 'Revenir au tempo propre de chaque clip';

  @override
  String get releaseTracksResizeHint =>
      'Faites glisser pour redimensionner · double-cliquez pour réinitialiser';

  @override
  String get releaseTracksMaximize => 'Afficher toute la liste des pistes';

  @override
  String get releaseTracksRestoreFiles => 'Réafficher le panneau des fichiers';

  @override
  String get columnsAndFieldsTabLabel => 'Colonnes et champs';

  @override
  String get projectsTableColumnsTitle => 'Colonnes des tableaux';

  @override
  String get projectsTableColumnsDescription =>
      'Choisissez les colonnes affichées dans le tableau des projets et dans les listes de pistes des sorties, et faites-les glisser dans l\'ordre voulu, commun aux deux. Le nom et les actions sont toujours affichés. S\'applique à cet appareil uniquement.';

  @override
  String get customFieldsTitle => 'Champs personnalisés';

  @override
  String get customFieldsDescription =>
      'Ajoutez vos propres champs à chaque projet : sonie (LUFS), ingénieur de mastering, ISRC, tout ce que vous voulez. Un champ se remplit toujours sur la page du projet ; choisissez s\'il a aussi une colonne dans le tableau des projets ou dans les listes de pistes des sorties.';

  @override
  String get addCustomField => 'Ajouter un champ';

  @override
  String get editCustomField => 'Modifier le champ';

  @override
  String get customFieldName => 'Nom du champ';

  @override
  String get customFieldNameHint => 'ex. : LUFS';

  @override
  String get customFieldNameRequired => 'Saisissez un nom';

  @override
  String get customFieldNameDuplicate => 'Un champ porte déjà ce nom';

  @override
  String get customFieldType => 'Type';

  @override
  String get customFieldTypeText => 'Texte';

  @override
  String get customFieldTypeNumber => 'Nombre';

  @override
  String get customFieldTypeNumberHelp =>
      'Les nombres sont triés par valeur : -9,8 vient après -14,2.';

  @override
  String get customFieldShowInProjectsTable =>
      'Colonne dans le tableau des projets';

  @override
  String get customFieldShowInReleaseTracks =>
      'Colonne dans les listes de pistes des sorties';

  @override
  String get customFieldProjectPageOnly => 'Page du projet uniquement';

  @override
  String get noCustomFieldsYet => 'Aucun champ personnalisé pour le moment.';

  @override
  String get deleteCustomFieldTitle => 'Supprimer le champ ?';

  @override
  String deleteCustomFieldMessage(String name) {
    return '« $name » et les valeurs saisies n’apparaîtront plus dans aucun projet, tableau ni recherche.';
  }

  @override
  String get customFieldInvalidNumber => 'Saisissez un nombre';

  @override
  String get customFieldsProjectPageHint =>
      'Vos propres champs — ajoutez-les ou modifiez-les dans Paramètres > Colonnes et champs.';

  @override
  String get midiPianoRollOpen => 'Ouvrir le piano roll';

  @override
  String get midiPianoRollZoomIn => 'Zoom avant';

  @override
  String get midiPianoRollZoomOut => 'Zoom arrière';

  @override
  String get midiPianoRollFit => 'Ajuster à la fenêtre';

  @override
  String get midiPianoRollFollow => 'Suivre la lecture';

  @override
  String get midiClipsShareOfferFolder =>
      'Si aucune fenêtre de partage n’est apparue, les fichiers sont prêts dans un dossier.';

  @override
  String get midiClipsShowInFolder => 'Afficher dans le dossier';

  @override
  String get midiPianoRollPause => 'Pause';

  @override
  String get midiProjectDetails => 'Détails du projet';

  @override
  String get midiSourceProjectGone =>
      'Le projet d’origine de ce clip n’est plus dans votre bibliothèque.';

  @override
  String get midiCollectionShareZip => 'Partager en ZIP';

  @override
  String get midiCollectionOpen => 'Ouvrir';

  @override
  String get midiPreviewVolume => 'Volume de l’aperçu';

  @override
  String get midiLanePicker => 'Paramètre affiché sous les notes';

  @override
  String get midiLaneNone => 'Aucun';

  @override
  String get midiLaneVelocity => 'Vélocité';

  @override
  String get midiLanePitchBend => 'Pitch bend';

  @override
  String get midiLaneChannelPressure => 'Aftertouch';

  @override
  String get midiLanePolyPressure => 'Aftertouch polyphonique';

  @override
  String get midiLaneProgram => 'Changement de programme';

  @override
  String midiLaneController(int number) {
    return 'CC $number';
  }

  @override
  String midiLaneControllerNamed(int number, String name) {
    return 'CC $number · $name';
  }

  @override
  String get midiCcModulation => 'Modulation';

  @override
  String get midiCcBreath => 'Souffle';

  @override
  String get midiCcFoot => 'Pédale';

  @override
  String get midiCcPortamentoTime => 'Temps de portamento';

  @override
  String get midiCcVolume => 'Volume';

  @override
  String get midiCcBalance => 'Balance';

  @override
  String get midiCcPan => 'Panoramique';

  @override
  String get midiCcExpression => 'Expression';

  @override
  String get midiCcSustain => 'Pédale de sustain';

  @override
  String get midiCcPortamento => 'Portamento';

  @override
  String get midiCcSostenuto => 'Sostenuto';

  @override
  String get midiCcSoftPedal => 'Pédale douce';

  @override
  String get midiCcResonance => 'Résonance';

  @override
  String get midiCcRelease => 'Release';

  @override
  String get midiCcAttack => 'Attaque';

  @override
  String get midiCcCutoff => 'Fréquence de coupure';

  @override
  String get midiCcReverb => 'Réverbération';

  @override
  String get midiCcChorus => 'Chorus';

  @override
  String get filterHasMidi => 'Seulement les projets avec MIDI';

  @override
  String midiClipsMissingFiles(int count, String files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fichiers MIDI référencés sont introuvables ou illisibles : $files',
      one: 'Un fichier MIDI référencé est introuvable ou illisible : $files',
    );
    return '$_temp0';
  }

  @override
  String get midiLibraryArrangeProject => 'Par projet';

  @override
  String get midiLibraryArrangeAdded => 'Ordre d’ajout';

  @override
  String get midiLibraryArrangeTempo => 'Par tempo (BPM)';

  @override
  String midiLibraryTempoGroup(String bpm) {
    return '$bpm BPM';
  }

  @override
  String get midiLibraryTempoUnknown => 'Tempo inconnu';

  @override
  String get midiImportFiles => 'Importer des fichiers MIDI';

  @override
  String get midiImportDialogTitle => 'Choisir les fichiers MIDI à importer';

  @override
  String midiImportSkipped(String files) {
    return 'Non importé (pas un fichier MIDI, ou aucune note) : $files';
  }

  @override
  String get midiPreviewLoop => 'Lecture en boucle';

  @override
  String get columnsInProjectsTable => 'Projets';

  @override
  String get columnsInReleaseTracks => 'Pistes des sorties';

  @override
  String get projectContentsRead => 'Lire le contenu du projet';

  @override
  String get projectContentsReadHint =>
      'Lit les pistes, les plug-ins et les clips MIDI du fichier du projet. Ils sont conservés avec le projet et synchronisés sur vos autres appareils.';

  @override
  String get projectContentsNoneRead =>
      'Rien n’a encore été lu dans ce projet. Lancez un scan approfondi, ou extrayez ses métadonnées, sur l’ordinateur qui a le fichier du projet.';

  @override
  String get midiScale => 'Gamme';

  @override
  String get midiScaleNone => 'Aucune gamme';

  @override
  String get midiScaleRoot => 'Tonique';

  @override
  String get midiScaleType => 'Type de gamme';

  @override
  String get scaleMajor => 'Majeur';

  @override
  String get scaleMinor => 'Mineur';

  @override
  String get scaleHarmonicMinor => 'Mineur harmonique';

  @override
  String get scaleMelodicMinor => 'Mineur mélodique';

  @override
  String get scaleDorian => 'Dorien';

  @override
  String get scalePhrygian => 'Phrygien';

  @override
  String get scaleLydian => 'Lydien';

  @override
  String get scaleMixolydian => 'Mixolydien';

  @override
  String get scaleLocrian => 'Locrien';

  @override
  String get scaleMajorPentatonic => 'Pentatonique majeure';

  @override
  String get scaleMinorPentatonic => 'Pentatonique mineure';

  @override
  String get scaleBlues => 'Blues';

  @override
  String get midiEditNotes => 'Modifier les notes';

  @override
  String get midiUndo => 'Annuler';

  @override
  String get midiRedo => 'Rétablir';

  @override
  String get midiSnap => 'Aligner sur la grille';

  @override
  String get midiSnapOff => 'Désactivé';

  @override
  String get midiSaveAsNewClip => 'Enregistrer comme nouveau clip';

  @override
  String midiClipEditedName(String name) {
    return '$name (modifié)';
  }

  @override
  String get midiDiscardEditsTitle => 'Abandonner les modifications ?';

  @override
  String get midiDiscardEditsBody =>
      'Le clip modifié n’a pas été enregistré. Enregistrez-le comme nouveau clip pour le garder.';

  @override
  String get midiKeepEditing => 'Continuer à modifier';

  @override
  String get midiDiscardEdits => 'Abandonner';

  @override
  String get midiToolSelect => 'Sélection (1)';

  @override
  String get midiToolPencil => 'Crayon (8)';

  @override
  String get midiAcousticFeedback => 'Entendre les notes pendant l’édition';

  @override
  String get midiShortcuts => 'Raccourcis clavier (?)';

  @override
  String get midiShortcutsTitle => 'Raccourcis du piano roll';

  @override
  String get midiShortcutsTools => 'Outils';

  @override
  String get midiShortcutsNotes => 'Notes';

  @override
  String get midiShortcutsSelecting => 'Sélection';

  @override
  String get midiShortcutsLanes => 'Pistes de vélocité et de contrôleurs';

  @override
  String get midiShortcutsEditing => 'Édition';

  @override
  String get midiShortcutsPlayback => 'Lecture et affichage';

  @override
  String get midiKeyCtrl => 'Ctrl';

  @override
  String get midiKeyShift => 'Maj';

  @override
  String get midiKeyAlt => 'Alt';

  @override
  String get midiKeyDelete => 'Suppr';

  @override
  String get midiKeySpace => 'Espace';

  @override
  String get midiKeyEsc => 'Échap';

  @override
  String get midiGestureClick => 'Clic';

  @override
  String get midiGestureDoubleClick => 'Double-clic';

  @override
  String get midiGestureDrag => 'Glisser';

  @override
  String get midiGesturePen => 'Stylet';

  @override
  String get midiGestureWheel => 'Molette';

  @override
  String get midiShortcutSelectTool => 'Outil de sélection';

  @override
  String get midiShortcutPencilTool =>
      'Crayon : cliquez pour ajouter une note — glissez de côté pour l’allonger, vers le haut ou le bas pour sa vélocité ; un clic sur une note la sélectionne';

  @override
  String get midiShortcutPenPressure =>
      'Dessiner au stylet : plus vous appuyez, plus la note est forte';

  @override
  String get midiShortcutDoubleClick =>
      'Dans le vide : ajouter une note (maintenez et glissez : de côté pour la durée, haut ou bas pour la vélocité ; Ctrl : hors grille). Sur une note : la supprimer';

  @override
  String get midiShortcutMove =>
      'Une note : la déplacer, avec toutes les notes sélectionnées';

  @override
  String get midiShortcutResize =>
      'Le bord d’une note : la raccourcir ou l’allonger';

  @override
  String get midiShortcutCopy => 'Une note : copier les notes sélectionnées';

  @override
  String get midiShortcutOffGrid =>
      'Déplacer ou redimensionner sans s’aligner sur la grille';

  @override
  String get midiShortcutSemitone =>
      'Déplacer les notes sélectionnées d’un demi-ton';

  @override
  String get midiShortcutOctave =>
      'Déplacer les notes sélectionnées d’une octave';

  @override
  String get midiShortcutDelete => 'Supprimer les notes sélectionnées';

  @override
  String get midiShortcutBox =>
      'Dans le vide : sélectionner les notes dans le cadre';

  @override
  String get midiShortcutToggle =>
      'Ajouter une note à la sélection, ou l’en retirer';

  @override
  String get midiShortcutSelectAll => 'Sélectionner toutes les notes';

  @override
  String get midiShortcutVelocity =>
      'Sur les barres de vélocité : régler la vélocité de chaque note survolée';

  @override
  String get midiShortcutLane =>
      'Dans une piste de contrôleur ou de pitch bend : dessiner la courbe (le bend revient au centre)';

  @override
  String get midiShortcutPlay => 'Lire ou mettre en pause';

  @override
  String get midiShortcutStop => 'Arrêter ; à l’arrêt, fermer la fenêtre';

  @override
  String get midiShortcutKeyboard =>
      'Sur le clavier : jouer la touche (glissez pour jouer les touches survolées)';

  @override
  String get midiShortcutRuler => 'Sur la règle : y aller';

  @override
  String get midiShortcutZoom => 'Zoomer ou dézoomer autour de la souris';

  @override
  String get midiShortcutScroll => 'Défiler horizontalement';

  @override
  String get midiShortcutShowSheet => 'Afficher ces raccourcis';

  @override
  String get midiFullScreen => 'Plein écran';

  @override
  String get midiExitFullScreen => 'Quitter le plein écran';

  @override
  String get midiToolRange => 'Plage (2)';

  @override
  String get midiToolEraser => 'Gomme (5)';

  @override
  String get midiDuplicate => 'Dupliquer';

  @override
  String get midiTranspose => 'Transposer';

  @override
  String get midiTransposeUpSemitone => 'Monter d’un demi-ton';

  @override
  String get midiTransposeDownSemitone => 'Descendre d’un demi-ton';

  @override
  String get midiTransposeUpOctave => 'Monter d’une octave';

  @override
  String get midiTransposeDownOctave => 'Descendre d’une octave';

  @override
  String get midiShortcutRangeTool =>
      'Plage : glissez pour sélectionner un intervalle de temps et toutes ses notes';

  @override
  String get midiShortcutEraserTool =>
      'Gomme : cliquez ou glissez sur les notes pour les supprimer';

  @override
  String get midiShortcutDuplicate =>
      'Dupliquer : une plage juste après elle-même, ou les notes sélectionnées juste après la dernière';

  @override
  String get midiNewClip => 'Nouveau clip';

  @override
  String midiNewClipName(int number) {
    return 'Idée $number';
  }

  @override
  String get midiQuantize => 'Quantifier (Q)';

  @override
  String get midiShortcutQuantize =>
      'Quantifier : caler sur la grille les notes sélectionnées (ou toutes)';

  @override
  String get midiTimeSignature => 'Signature rythmique';

  @override
  String get midiShortcutLoopStart =>
      'Sur la règle : placer le début de la boucle';

  @override
  String get midiShortcutLoopEnd => 'Sur la règle : placer la fin de la boucle';

  @override
  String get midiShortcutLoopDrag =>
      'La barre violette de la boucle : glissez ses extrémités pour la redimensionner, son milieu pour la déplacer (boucle activée, seule elle est jouée)';

  @override
  String get midiShortcutLoopToggle =>
      'Moitié haute de la barre de boucle : activer ou désactiver la boucle (grise quand elle est coupée)';

  @override
  String get midiRoleMelody => 'Mélodie';

  @override
  String get midiRoleBass => 'Basse';

  @override
  String get midiRoleChords => 'Accords';

  @override
  String get midiRoleArp => 'Arpège';

  @override
  String get midiRoleLead => 'Lead';

  @override
  String get midiRolePad => 'Pad';

  @override
  String get midiRoleDrums => 'Batterie';

  @override
  String get midiRoleFx => 'FX';

  @override
  String get midiRoleOther => 'Autre';

  @override
  String get midiRoleLabel => 'Rôle';

  @override
  String midiRoleAutomatic(String role) {
    return 'Automatique ($role)';
  }

  @override
  String midiItemRoleMenu(String role) {
    return 'Rôle : $role';
  }

  @override
  String get midiNameFree => 'libre';

  @override
  String get midiNamingTitle => 'Noms de fichiers';

  @override
  String get midiNamingNumbered => 'Numéroter les fichiers';

  @override
  String get midiNamingNumberedHint =>
      '01, 02… dans l\'ordre de chaque dossier, pour qu\'un explorateur de fichiers les affiche ainsi';

  @override
  String get midiNamingSeparator => 'Séparateur';

  @override
  String get midiNamingFields => 'Dans le nom';

  @override
  String get midiNamingFieldsHint => 'Faites glisser pour changer l\'ordre';

  @override
  String get midiNameFieldName => 'Nom';

  @override
  String get midiNameFieldBpm => 'Tempo (BPM)';

  @override
  String get midiNameFieldKey => 'Tonalité';

  @override
  String get midiNameFieldBars => 'Longueur en mesures';

  @override
  String get midiNameFieldTimeSignature =>
      'Signature rythmique (si autre que 4/4)';

  @override
  String get midiNameFieldGrid => 'Quantification (1-16, libre…)';

  @override
  String get midiNameFieldInstrument => 'Instrument';

  @override
  String get midiNamingPreview => 'Exemple';

  @override
  String get midiNamingReset => 'Par défaut';

  @override
  String get midiFolderNew => 'Nouveau dossier';

  @override
  String get midiFolderRename => 'Renommer le dossier';

  @override
  String get midiFolderDelete => 'Supprimer le dossier';

  @override
  String midiFolderDeleteConfirm(String name) {
    return 'Supprimer le dossier « $name » ? Ses clips et dossiers remontent d\'un niveau.';
  }

  @override
  String get midiFolderName => 'Nom du dossier';

  @override
  String get midiFolderLabel => 'Dossier';

  @override
  String get midiFolderTopLevel => 'Niveau supérieur';

  @override
  String get midiMoveTo => 'Déplacer vers…';

  @override
  String get midiMoveUp => 'Monter';

  @override
  String get midiMoveDown => 'Descendre';

  @override
  String get midiItemRename => 'Renommer';

  @override
  String get midiItemNameHint => 'Vide : le nom du clip';

  @override
  String get midiSaveClipTitle => 'Enregistrer le clip';

  @override
  String get midiSaveFileName => 'Nom du fichier';

  @override
  String get midiBulkRenameMenu => 'Renommer selon le schéma…';

  @override
  String get midiBulkRenameTitle => 'Renommer selon le schéma de noms';

  @override
  String get midiBulkRenameHint =>
      'Chaque nom est proposé à partir du schéma de noms de la collection. Modifiez-les avant si besoin et décochez les clips à laisser tels quels.';

  @override
  String midiBulkRenameApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Renommer $count clips',
      one: 'Renommer 1 clip',
    );
    return '$_temp0';
  }

  @override
  String midiBulkRenameDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clips renommés',
      one: '1 clip renommé',
    );
    return '$_temp0';
  }

  @override
  String get midiBulkRenameSelectAll => 'Tous';

  @override
  String get midiNameFromScheme => 'Selon le schéma de noms';

  @override
  String midiCollectionMoved(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clips déplacés vers $name',
      one: 'Déplacé vers $name',
    );
    return '$_temp0';
  }

  @override
  String get midiExpandAll => 'Tout développer';

  @override
  String get midiCollapseAll => 'Tout réduire';

  @override
  String get templateExportTitle => 'Exporter les données du modèle Cubase';

  @override
  String get templateExportSubtitle =>
      'Lit la structure des pistes de vos projets Cubase et génère template.md, template-spec.md, patterns.json et corpus.json pour que Claude construise un modèle';

  @override
  String get templateExportAnonymize =>
      'Masquer les noms de projets dans corpus.json';

  @override
  String get templateExportButton => 'Exporter';

  @override
  String get templateExportDialogTitle =>
      'Choisissez un dossier pour l\'export du modèle';

  @override
  String templateExportDone(int analysed, int skipped) {
    return '$analysed projets exportés ($skipped illisibles)';
  }

  @override
  String get templateExportNothing => 'Aucun projet Cubase lisible trouvé';

  @override
  String get melodicExportTitle => 'Exporter le catalogue MIDI mélodique';

  @override
  String get melodicExportSubtitle =>
      'Enregistre les leads, arps et mélodies de vos projets en fichiers .mid, un dossier par projet, avec un catalogue (CSV, JSON, Markdown) du tempo, de la tonalité, de l\'étendue et plus. Batteries et fragments courts sont exclus.';

  @override
  String get melodicExportIncludeChords => 'Inclure accords et pads';

  @override
  String get melodicExportIncludeBass => 'Inclure les lignes de basse';

  @override
  String get melodicExportDialogTitle =>
      'Choisissez un dossier pour l\'export MIDI';

  @override
  String melodicExportDone(int clips, int projects) {
    return '$clips clips exportés depuis $projects projets';
  }

  @override
  String melodicExportDoneUnread(int clips, int projects, int unread) {
    return '$clips clips exportés depuis $projects projets. $unread projets n\'ont pas encore leur MIDI lu : analysez-les d\'abord en entier.';
  }

  @override
  String get melodicExportNothing =>
      'Aucun MIDI mélodique trouvé. Les projets doivent d\'abord subir une analyse complète des métadonnées.';

  @override
  String get melodicReadConfirmTitle => 'Lire le MIDI d\'abord ?';

  @override
  String melodicReadConfirmBody(int count, String size) {
    return '$count projets ($size) n\'ont pas encore leur MIDI lu. La lecture ouvre chaque fichier de projet ; les fichiers sur un cloud sont d\'abord téléchargés.';
  }

  @override
  String get melodicReadAndExport => 'Lire et exporter';

  @override
  String get melodicExportReadOnly => 'Exporter ce qui est déjà lu';

  @override
  String get melodicReadingTitle => 'Lecture du MIDI';

  @override
  String melodicReadingProgress(int done, int total, String name) {
    return '$done sur $total : $name';
  }

  @override
  String get melodicReadStop => 'Arrêter et exporter ce qui est lu';

  @override
  String get referenceTitle => 'Page de référence des inserts';

  @override
  String get referenceSubtitle =>
      'Génère une page web à partir de vos projets Cubase : les chaînes de plugins par rôle de piste, la chaîne du master et tous les inserts que vous avez utilisés. S\'ouvre dans le navigateur.';

  @override
  String get referenceButton => 'Générer';

  @override
  String get referenceDialogTitle => 'Choisissez un dossier pour la page';

  @override
  String get referenceReadTitle => 'Lire les projets Cubase ?';

  @override
  String referenceReadBody(int count, String size) {
    return '$count projets Cubase ($size) sont nouveaux ou ont changé depuis la dernière page. La lecture ouvre chaque fichier ; les fichiers sur un cloud sont d\'abord téléchargés.';
  }

  @override
  String get referenceReadAndGenerate => 'Lire et générer';

  @override
  String get referenceUseRead => 'Utiliser ce qui est déjà lu';

  @override
  String get referenceReadingTitle => 'Lecture des projets Cubase';

  @override
  String get referenceReadStop => 'Arrêter et générer avec ce qui est lu';

  @override
  String referenceDone(int count) {
    return 'Page générée à partir de $count projets';
  }

  @override
  String get referenceNothing => 'Aucun projet Cubase lisible trouvé';

  @override
  String get experimentalTabLabel => 'Expérimental';

  @override
  String get experimentalSectionIntro =>
      'Nouveaux outils qui fonctionnent, mais sont encore à l\'essai. Ils peuvent changer ou disparaître dans une prochaine version.';

  @override
  String get samplePackTitle => 'Pack de samples tiré de vos projets';

  @override
  String get samplePackSubtitle =>
      'Copie les samples utilisés par vos projets dans un dossier, classés par type (Kick, Snare, Bass, FX…), avec un rapport du nombre de morceaux qui utilisent chacun. Réexporter dans le même dossier n\'ajoute que les nouveautés.';

  @override
  String get samplePackDialogTitle => 'Exporter un pack de samples';

  @override
  String get samplePackProfiles => 'Profils';

  @override
  String get samplePackSelectAll => 'Tout sélectionner';

  @override
  String get samplePackSelectNone => 'Tout désélectionner';

  @override
  String samplePackProjectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets',
      one: '1 projet',
    );
    return '$_temp0';
  }

  @override
  String get samplePackLibraryFolders => 'Dossiers de bibliothèques de samples';

  @override
  String get samplePackLibraryFoldersHelp =>
      'Où chercher un sample qu\'un projet ne trouve plus à l\'endroit où il l\'a enregistré — après le déplacement d\'une bibliothèque ou un changement de lettre de lecteur. Le dossier du projet lui-même est toujours exploré.';

  @override
  String get samplePackNoLibraryFolders => 'Aucun dossier ajouté.';

  @override
  String get samplePackIncludeOwnAudio =>
      'Inclure mes enregistrements, bounces et stems';

  @override
  String samplePackIncludeOwnAudioHelp(String folder) {
    return 'Dans un dossier à part, « $folder ».';
  }

  @override
  String get samplePackIncludeMidi => 'Ajouter mes collections MIDI';

  @override
  String get samplePackChooseDestination => 'Choisir le dossier et exporter';

  @override
  String get samplePackDestinationTitle => 'Où écrire le pack de samples';

  @override
  String get samplePackProgressTitle => 'Création du pack de samples';

  @override
  String samplePackReading(int current, int total, String name) {
    return 'Lecture du projet $current sur $total : $name';
  }

  @override
  String samplePackLocating(int current, int total, String name) {
    return 'Recherche du sample $current sur $total : $name';
  }

  @override
  String samplePackMeasuring(int current, int total, String name) {
    return 'Vérification du sample $current sur $total : $name';
  }

  @override
  String samplePackCopying(int current, int total, String name) {
    return 'Copie $current sur $total : $name';
  }

  @override
  String samplePackWritingMidi(int current, int total, String name) {
    return 'Écriture de la collection MIDI $current sur $total : $name';
  }

  @override
  String get samplePackFinishing => 'Écriture du rapport…';

  @override
  String get samplePackDoneTitle => 'Pack de samples prêt';

  @override
  String get samplePackStoppedTitle => 'Pack de samples interrompu';

  @override
  String samplePackAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux samples ajoutés',
      one: '1 nouveau sample ajouté',
      zero: 'Aucun nouveau sample ajouté',
    );
    return '$_temp0';
  }

  @override
  String samplePackAlreadyThere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étaient déjà dans le dossier',
      one: '1 était déjà dans le dossier',
    );
    return '$_temp0';
  }

  @override
  String samplePackLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements, bounces ou stems laissés de côté',
      one: '1 enregistrement, bounce ou stem laissé de côté',
    );
    return '$_temp0';
  }

  @override
  String samplePackMidiWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers MIDI écrits',
      one: '1 fichier MIDI écrit',
    );
    return '$_temp0';
  }

  @override
  String samplePackMissing(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples introuvables — voir $file',
      one: '1 sample introuvable — voir $file',
    );
    return '$_temp0';
  }

  @override
  String samplePackNotRead(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets illisibles — voir $file',
      one: '1 projet illisible — voir $file',
    );
    return '$_temp0';
  }

  @override
  String samplePackReportHint(String file) {
    return 'Le nombre de morceaux qui utilisent chaque sample, et sa provenance, sont dans $file.';
  }

  @override
  String get samplePackExcludeMasters => 'Ignorer les projets de master';

  @override
  String get samplePackExcludeMastersHelp =>
      'Projets nommés « (Master) » ou « (M) », ou rangés dans un dossier « Master Project » : ils contiennent les stems et mixages d\'un morceau, pas des samples.';

  @override
  String samplePackMastersLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets de master ignorés',
      one: '1 projet de master ignoré',
    );
    return '$_temp0';
  }

  @override
  String get samplePackProjects => 'Projets';

  @override
  String get samplePackAllProjects => 'Tous les projets';

  @override
  String get samplePackPickedProjects => 'Choisir des projets';

  @override
  String get samplePackSearchProjects => 'Rechercher des projets';

  @override
  String samplePackPickedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets choisis',
      one: '1 projet choisi',
      zero: 'Aucun projet choisi',
    );
    return '$_temp0';
  }

  @override
  String get samplePackNoProjectsMatch => 'Aucun projet ne correspond.';

  @override
  String get samplePackRename => 'Renommer les samples';

  @override
  String get samplePackRenameHelp =>
      'Catégorie et numéro, puis ce que vous choisissez. Seuls les samples ajoutés par cet export sont renommés ; le rapport garde le nom d\'origine de chacun.';

  @override
  String get samplePackRenameName => 'Nom d\'origine';

  @override
  String get samplePackRenameBpm => 'Tempo (BPM)';

  @override
  String get samplePackRenameKey => 'Tonalité';

  @override
  String get samplePackRenamePrefix => 'Préfixe';

  @override
  String get samplePackRenamePrefixHint => 'ex. AC';

  @override
  String samplePackRenameExample(String name) {
    return 'Exemple : $name';
  }

  @override
  String get driveAgoJustNow => 'à l\'instant';

  @override
  String driveAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String driveAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String get driveSyncIntro =>
      'Gardez vos projets, notes et sorties identiques sur tous vos appareils. Tout est enregistré dans un dossier de votre propre Google Drive.';

  @override
  String get driveWaitingForBrowser =>
      'Terminez la connexion dans votre navigateur…';

  @override
  String get driveThisDevice => 'cet appareil';

  @override
  String driveThisDeviceSynced(String when) {
    return 'Cet appareil a été synchronisé $when';
  }

  @override
  String get driveThisDeviceNeverSynced =>
      'Cet appareil n\'a pas encore été synchronisé';

  @override
  String driveUpdatedFrom(String when, String device) {
    return 'Drive mis à jour $when depuis $device';
  }

  @override
  String driveUpdatedAt(String when) {
    return 'Drive mis à jour $when';
  }

  @override
  String get driveNoBackupYet => 'Rien sur Google Drive pour le moment';

  @override
  String driveNewerBanner(String device) {
    return '$device a des modifications sur Drive qui ne sont pas encore sur cet appareil. Synchronisez pour les récupérer.';
  }

  @override
  String get driveNewerBannerNoDevice =>
      'Drive contient des modifications qui ne sont pas encore sur cet appareil. Synchronisez pour les récupérer.';

  @override
  String get driveSyncNow => 'Synchroniser';

  @override
  String get driveSyncNowHint =>
      'La synchronisation récupère ce qui est sur Drive, puis envoie les modifications de cet appareil. Rien n\'est supprimé, sauf ce qui a été supprimé volontairement sur l\'un de vos appareils.';

  @override
  String get driveSyncing => 'Synchronisation…';

  @override
  String get driveSyncingTitle => 'Synchronisation avec Google Drive';

  @override
  String driveSyncedSummary(int added, int updated, int removed) {
    return 'Synchronisé : $added nouveaux, $updated mis à jour, $removed supprimés.';
  }

  @override
  String get driveSyncedNothingNew => 'Synchronisé. Tout était déjà à jour.';

  @override
  String get driveOperationCancelled => 'Annulé.';

  @override
  String driveFilesFailedToUpload(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers n\'ont pas pu être envoyés :',
      one: '1 fichier n\'a pas pu être envoyé :',
    );
    return '$_temp0';
  }

  @override
  String driveLastSyncFailed(String when) {
    return 'La dernière synchronisation a échoué ($when)';
  }

  @override
  String get driveErrorOffline =>
      'Impossible de joindre Google Drive. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get driveErrorSignInExpired =>
      'Google Drive vous demande de vous reconnecter.';

  @override
  String get driveErrorDriveFull =>
      'Votre Google Drive est plein. Libérez de l’espace pour continuer à synchroniser.';

  @override
  String get driveErrorNoBackup =>
      'Il n\'y a pas encore de sauvegarde sur Google Drive.';

  @override
  String get driveErrorOther => 'La synchronisation n\'a pas abouti.';

  @override
  String driveSignInPortInUse(String port) {
    return 'Impossible de lancer la connexion : un autre programme utilise le port $port. Fermez toute autre instance de DAW Project Manager et réessayez.';
  }

  @override
  String get driveSignInTimedOut =>
      'La connexion a pris trop de temps. Réessayez.';

  @override
  String get driveSignInNoBrowser =>
      'Impossible d\'ouvrir votre navigateur pour vous connecter.';

  @override
  String get driveBrowserSignedInTitle => 'Connecté';

  @override
  String get driveBrowserSignedInBody =>
      'Vous pouvez fermer cet onglet et revenir à DAW Project Manager.';

  @override
  String get driveBrowserCancelledTitle => 'Connexion annulée';

  @override
  String get driveBrowserCancelledBody =>
      'Vous pouvez fermer cet onglet et réessayer depuis DAW Project Manager.';

  @override
  String get driveBrowserErrorTitle => 'Une erreur s\'est produite';

  @override
  String get driveBrowserErrorBody =>
      'Fermez cet onglet et reconnectez-vous depuis DAW Project Manager.';

  @override
  String get driveAutoSyncTitle => 'Synchronisation automatique';

  @override
  String get driveAutoSyncDescription =>
      'Tant que l\'app est ouverte, synchronise avec Google Drive à l\'intervalle choisi.';

  @override
  String get driveAutoSyncIntervalLabel => 'Synchroniser automatiquement';

  @override
  String driveNextSync(String when) {
    return 'Prochaine synchronisation $when';
  }

  @override
  String get driveMoreOptions => 'Restauration et autres options';

  @override
  String get driveRestoreFromDrive =>
      'Récupérer seulement les modifications de Drive';

  @override
  String get driveRestoreFromDriveHint =>
      'Met cet appareil à jour sans rien envoyer.';

  @override
  String get driveRecoverEarlier =>
      'Récupérer depuis une sauvegarde antérieure';

  @override
  String driveRecoverEarlierHint(int count) {
    return 'Drive conserve les $count dernières sauvegardes. En récupérer une ajoute ce qui manque ; cela n\'annule pas les modifications plus récentes.';
  }

  @override
  String get driveOverwrite => 'Remplacer la copie de Drive par cet appareil';

  @override
  String get driveOverwriteHint =>
      'Drive contiendra exactement ce qu\'a cet appareil. La copie remplacée est conservée comme sauvegarde antérieure.';

  @override
  String get driveDeleteData => 'Supprimer mes données de Google Drive';

  @override
  String get driveDeleteDataHint =>
      'Supprime de Drive la sauvegarde, les morceaux d’aperçu, les images et les sauvegardes antérieures. Cet appareil conserve tout.';

  @override
  String get driveMergeTitle => 'Récupérer les modifications de Drive ?';

  @override
  String get driveMergeConfirm => 'Récupérer';

  @override
  String get driveMergeNothing =>
      'Rien sur Drive n\'est nouveau pour cet appareil.';

  @override
  String get driveMergeKeepsLocal =>
      'Rien d’autre ne change sur cet appareil, et les modifications plus récentes que celles de Drive sont conservées.';

  @override
  String driveMergeAdds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux projets',
      one: '1 nouveau projet',
    );
    return '$_temp0';
  }

  @override
  String driveMergeUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets mis à jour',
      one: '1 projet mis à jour',
    );
    return '$_temp0';
  }

  @override
  String driveMergeRemoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets retirés (supprimés sur un autre appareil)',
      one: '1 projet retiré (supprimé sur un autre appareil)',
    );
    return '$_temp0';
  }

  @override
  String driveMergeReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles sorties',
      one: '1 nouvelle sortie',
    );
    return '$_temp0';
  }

  @override
  String driveMergeReleasesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sorties retirées (supprimées sur un autre appareil)',
      one: '1 sortie retirée (supprimée sur un autre appareil)',
    );
    return '$_temp0';
  }

  @override
  String get driveRecoverTitle => 'Sauvegardes antérieures';

  @override
  String get driveNoSnapshots =>
      'Pas encore de sauvegarde antérieure. Une est conservée chaque fois qu\'une synchronisation remplace la sauvegarde sur Drive.';

  @override
  String driveSnapshotItem(String when, String device) {
    return '$when · $device';
  }

  @override
  String get driveRecoverConfirmTitle => 'Récupérer cette sauvegarde ?';

  @override
  String get driveRecoverConfirm => 'Récupérer';

  @override
  String get driveOverwriteTitle => 'Remplacer la copie de Drive ?';

  @override
  String get driveOverwriteBody =>
      'Tout ce qui est sur Drive mais pas sur cet appareil, comme des projets ajoutés sur un autre appareil, disparaîtra de Drive. La copie actuelle est conservée comme sauvegarde antérieure : vous pourrez la récupérer.';

  @override
  String get driveOverwriteConfirm => 'Remplacer la copie';

  @override
  String get driveDeleteTitle => 'Supprimer vos données de Google Drive ?';

  @override
  String get driveDeleteBody =>
      'Cela supprime définitivement le dossier DAW Project Manager de votre Google Drive, y compris la sauvegarde, les morceaux d’aperçu, les images et les sauvegardes antérieures. Cet appareil conserve ses propres données. La synchronisation automatique sera désactivée.';

  @override
  String get driveDeleteConfirm => 'Supprimer de Drive';

  @override
  String get driveDeleted =>
      'Vos données ont été supprimées de Google Drive. La synchronisation automatique est désactivée.';

  @override
  String get driveSignOutTitle => 'Se déconnecter de Google Drive ?';

  @override
  String get driveSignOutBody =>
      'Vos données restent sur Google Drive et sur cet appareil. La synchronisation automatique s’arrête jusqu’à votre prochaine connexion.';

  @override
  String get driveFoundBackupTitle => 'Sauvegarde trouvée sur Google Drive';

  @override
  String get driveFoundBackupBody =>
      'Synchronisez maintenant pour la récupérer sur cet appareil et y ajouter ce qui s\'y trouve.';

  @override
  String get driveFirstUploadTitle => 'Rien sur Google Drive pour le moment';

  @override
  String get driveFirstUploadBody =>
      'Synchronisez maintenant pour envoyer la bibliothèque de cet appareil et garder vos appareils alignés.';

  @override
  String driveUploadEstimate(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Environ $count fichiers ($size) seront envoyés.',
      one: 'Environ 1 fichier ($size) sera envoyé.',
    );
    return '$_temp0';
  }

  @override
  String get driveKeepInSyncAutomatically =>
      'Garder cet appareil synchronisé automatiquement (toutes les heures)';

  @override
  String get driveLater => 'Plus tard';

  @override
  String get driveStatusSyncing => 'Synchronisation avec Google Drive…';

  @override
  String get driveStatusFailed =>
      'La dernière synchronisation Google Drive a échoué';

  @override
  String get driveStatusNewer => 'Nouvelles modifications sur Google Drive';

  @override
  String get driveStatusUpToDate => 'Google Drive : à jour';

  @override
  String trayLastSyncFailed(String when) {
    return 'Échec de la dernière synchronisation : $when';
  }

  @override
  String get driveSyncOnStartup => 'Synchroniser au démarrage de l\'app';

  @override
  String get driveSyncOnStartupHint =>
      'Récupère ce que vos autres appareils ont modifié à chaque ouverture de l\'app.';

  @override
  String get driveAlreadyInSync =>
      'Cet appareil et Google Drive sont déjà identiques. Il n’y a rien à synchroniser.';

  @override
  String get driveFromDrive => 'Depuis Google Drive';

  @override
  String get driveFromThisDevice => 'Depuis cet appareil';

  @override
  String driveUploadProjects(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets ajoutés ou modifiés ici',
      one: '1 projet ajouté ou modifié ici',
    );
    return '$_temp0';
  }

  @override
  String driveUploadReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sorties ajoutées ici',
      one: '1 sortie ajoutée ici',
    );
    return '$_temp0';
  }

  @override
  String drivePreviewLineWithNames(String line, String names) {
    return '$line : $names';
  }

  @override
  String driveNamesAndMore(String names, int count) {
    return '$names et $count autres';
  }

  @override
  String get deleteProjectMenu => 'Supprimer…';

  @override
  String deleteProjectTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get deleteProjectBody =>
      'Il passe dans Supprimés récemment (Réglages > Dossiers de projets), où vous pouvez le restaurer avec ses notes, tâches et temps de travail pendant 30 jours. Ses fichiers sur le disque ne sont pas touchés.';

  @override
  String get deleteProjectStillScanned =>
      'Son fichier se trouve dans l\'un des dossiers de projets de ce profil : la prochaine analyse le rajouterait comme un nouveau projet vide.';

  @override
  String get deleteProjectStopScanningFolder =>
      'Ne plus analyser son dossier non plus';

  @override
  String get deleteProjectStopScanningFile =>
      'Ne plus analyser ce fichier non plus';

  @override
  String projectMovedToRecentlyDeleted(String name) {
    return '« $name » déplacé dans Supprimés récemment.';
  }

  @override
  String get recentlyDeletedTitle => 'Supprimés récemment';

  @override
  String get recentlyDeletedSubtitle =>
      'Les projets supprimés de ce profil restent ici 30 jours, avec leurs notes, tâches et temps de travail. Leurs fichiers sur le disque ne sont jamais touchés.';

  @override
  String get recentlyDeletedNothing => 'Rien ici.';

  @override
  String recentlyDeletedWhen(String when) {
    return 'Supprimé $when';
  }

  @override
  String recentlyDeletedExpires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'supprimé définitivement dans $count jours',
      one: 'supprimé définitivement dans 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get recentlyDeletedRestore => 'Restaurer';

  @override
  String get recentlyDeletedDeleteForever => 'Supprimer définitivement';

  @override
  String get recentlyDeletedEmptyAll => 'Vider';

  @override
  String get emptyRecentlyDeletedTitle => 'Vider Supprimés récemment ?';

  @override
  String emptyRecentlyDeletedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count projets seront supprimés définitivement, avec leurs notes, tâches et temps de travail. Leurs fichiers sur le disque ne sont pas touchés.',
      one:
          '1 projet sera supprimé définitivement, avec ses notes, tâches et temps de travail. Ses fichiers sur le disque ne sont pas touchés.',
    );
    return '$_temp0';
  }

  @override
  String deleteForeverTitle(String name) {
    return 'Supprimer « $name » définitivement ?';
  }

  @override
  String get deleteForeverBody =>
      'Ses notes, tâches et temps de travail disparaîtront. Ses fichiers sur le disque ne sont pas touchés.';

  @override
  String projectRestored(String name) {
    return '« $name » restauré.';
  }

  @override
  String projectRestoredReplacingRescan(String name) {
    return '« $name » restauré, à la place de la copie vide qu’une analyse avait ajoutée entre-temps.';
  }

  @override
  String get scanFolderOverlapTitle => 'Un autre profil analyse déjà ceci';

  @override
  String scanFolderOverlapSame(String profile) {
    return '$profile analyse ce même dossier.';
  }

  @override
  String scanFolderOverlapInside(String profile, String path) {
    return '$profile analyse $path, qui contient ce dossier.';
  }

  @override
  String scanFolderOverlapContains(String profile, String path) {
    return '$profile analyse $path, qui se trouve dans ce dossier.';
  }

  @override
  String get scanFolderOverlapBody =>
      'Chaque profil garde sa propre copie de chaque projet qu’il trouve : ceux-ci apparaîtraient dans les deux, avec des notes, tâches et temps de travail séparés. Pour donner un morceau à un autre profil, utilisez plutôt « Déplacer vers un profil… ».';

  @override
  String get scanFolderOverlapAddAnyway => 'Ajouter quand même';

  @override
  String get moveToProfileMenu => 'Déplacer vers un profil…';

  @override
  String get projectMenuFiles => 'Fichiers';

  @override
  String get projectMenuUpdate => 'Mettre à jour les infos';

  @override
  String moveToProfileTitle(String name) {
    return 'Déplacer « $name » vers un autre profil';
  }

  @override
  String moveToProfileVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les $count versions partent ensemble, comme un seul morceau.',
      one: 'Sa version part avec lui, comme un seul morceau.',
    );
    return '$_temp0';
  }

  @override
  String get moveToProfileTarget => 'Profil';

  @override
  String get moveToProfileKeepFiles => 'Laisser ses fichiers où ils sont';

  @override
  String moveToProfileKeepFilesHint(String profile, String path) {
    return '$profile n’analyse plus $path, pour qu’il n’y revienne pas.';
  }

  @override
  String get moveToProfileKeepFilesHintUnscanned =>
      'Rien ne change sur le disque.';

  @override
  String get moveToProfileMoveFiles => 'Déplacer aussi ses fichiers';

  @override
  String get moveToProfileInto => 'Vers :';

  @override
  String get moveToProfileOtherFolder => 'Autre dossier…';

  @override
  String get moveToProfileNoFolder =>
      'Ce profil n’a pas encore de dossier de projets : choisissez un dossier.';

  @override
  String moveToProfileSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Environ $count fichiers ($size) sont copiés, vérifiés, puis retirés de leur emplacement actuel.',
      one:
          'Environ 1 fichier ($size) est copié, vérifié, puis retiré de son emplacement actuel.',
    );
    return '$_temp0';
  }

  @override
  String get moveToProfileCantMoveFiles =>
      'Ses versions sont dans plusieurs dossiers : leurs fichiers ne peuvent pas être déplacés ensemble.';

  @override
  String moveToProfileReleases(String profile, String releases) {
    return 'Il est retiré de $releases dans $profile.';
  }

  @override
  String get moveToProfileConfirm => 'Déplacer';

  @override
  String get moveToProfileNoOtherProfiles =>
      'Il n’y a pas d’autre profil vers lequel le déplacer.';

  @override
  String get moveToProfileInSession =>
      'Terminez d’abord la session de travail en cours dessus.';

  @override
  String get moveToProfileMoving => 'Déplacement des fichiers…';

  @override
  String moveToProfileDone(String name, String profile) {
    return '« $name » déplacé vers $profile.';
  }

  @override
  String get moveToProfileBlockedArchived =>
      'Il est archivé : restaurez-le d’abord depuis son archive.';

  @override
  String moveToProfileBlockedTargetCopy(String profile) {
    return '$profile a déjà ce morceau, avec ses propres notes ou tâches. Rien n’a été déplacé.';
  }

  @override
  String get moveToProfileBlockedSourceMissing =>
      'Ses fichiers ne sont pas sur cet ordinateur.';

  @override
  String moveToProfileBlockedOccupied(String path) {
    return 'Il y a déjà quelque chose de ce nom dans $path. Rien n’a été déplacé.';
  }

  @override
  String get moveToProfileBlockedInsideSource =>
      'Ce dossier se trouve dans le propre dossier du morceau.';

  @override
  String get moveToProfileBlockedSameLocation => 'Ses fichiers y sont déjà.';

  @override
  String get moveToProfileCopyFailed =>
      'La copie ne correspondait pas à l’original : rien n’a été retiré ni déplacé :';

  @override
  String get foldersProfilePickerLabel => 'Profil';

  @override
  String foldersProfileActive(String name) {
    return '$name (actif)';
  }

  @override
  String foldersEditingOtherProfile(String name) {
    return 'Vous modifiez les dossiers de $name, pas ceux du profil actif. Les nouveaux fichiers qu’ils contiennent apparaîtront la prochaine fois que vous passerez à $name.';
  }

  @override
  String get midiInput => 'Entrée MIDI';

  @override
  String get midiInputOff => 'Aucune entrée MIDI';

  @override
  String get midiInputAll => 'Toutes les entrées MIDI';

  @override
  String get midiInputNoDevices => 'Aucune entrée MIDI trouvée';

  @override
  String midiInputListening(String names) {
    return 'Entrée MIDI : $names';
  }

  @override
  String midiInputBusy(String names) {
    return 'Impossible d’ouvrir $names. Une autre application l’utilise peut-être.';
  }

  @override
  String get midiShortcutsMidiInput => 'Clavier MIDI';

  @override
  String get midiGesturePlayKey => 'Jouer une touche';

  @override
  String get midiShortcutPlayKey =>
      'Fait entendre la note avec l’instrument du clip';

  @override
  String get midiRecord =>
      'Enregistrer depuis le clavier MIDI : joue la boucle et enregistre ce que vous jouez';

  @override
  String get midiStopRecording => 'Arrêter l’enregistrement';

  @override
  String get midiShortcutRecord =>
      'Enregistrer depuis le clavier MIDI (joue la boucle ; chaque passage garde ce que vous jouez)';

  @override
  String get midiShortcutRulerDoubleClick =>
      'Sur la règle : lire à partir de là';

  @override
  String get midiMetronome => 'Métronome';

  @override
  String get midiShortcutMetronome => 'Activer ou désactiver le métronome';

  @override
  String midiRecordLatency(int ms) {
    return 'Latence d’enregistrement : $ms ms';
  }

  @override
  String get midiRecordLatencyTitle => 'Latence d’enregistrement';

  @override
  String get midiRecordLatencyBody =>
      'Les notes enregistrées sont placées d’autant plus tôt, pour compenser le temps que met le son à vous parvenir et vos touches à atteindre l’application. Calibrez pour la mesurer sur cet ordinateur.';

  @override
  String get midiCalibrate => 'Calibrer';

  @override
  String midiCalibrating(int done, int total) {
    return 'Jouez une touche à chaque clic ($done sur $total)';
  }

  @override
  String midiCalibrated(int ms) {
    return 'Latence d’enregistrement réglée à $ms ms';
  }

  @override
  String get dpmPluginSessionsDescription =>
      'Avec le plugin DAW Project Manager dans un projet, l\'application sait quand votre DAW l\'ouvre et le ferme.';

  @override
  String get dpmPluginEndSessionWhenDawCloses =>
      'Terminer la session quand la DAW ferme le projet';

  @override
  String get dpmPluginEndSessionWhenDawClosesDescription =>
      'Même après un plantage : la session se termine au moment où la DAW a lâché le projet.';

  @override
  String get dpmPluginStartSessionWhenDawOpens =>
      'Démarrer une session quand un projet s\'ouvre dans la DAW';

  @override
  String get dpmPluginStartSessionWhenDawOpensDescription =>
      'Seulement si aucune session n\'est en cours, et seulement pour les projets du profil actif.';

  @override
  String get dpmPluginSessionEndedTitle => 'Session terminée';

  @override
  String dpmPluginSessionEndedClosed(String daw, String project) {
    return '$daw a fermé $project, la session de travail est donc terminée.';
  }

  @override
  String dpmPluginSessionEndedNoResponse(String daw, String project) {
    return 'Le plugin DAW Project Manager a cessé de répondre dans $daw, la session de $project s\'est donc terminée au dernier signe de vie. La DAW a peut-être planté ou été fermée brutalement.';
  }

  @override
  String get dpmPluginUnknownDaw => 'Votre DAW';

  @override
  String dpmPluginSessionEndedSummary(
    String start,
    String end,
    String duration,
  ) {
    return '$start–$end · $duration';
  }

  @override
  String get dpmPluginTabLabel => 'Plugin pour la DAW';

  @override
  String get dpmPluginTitle => 'Plugin DAW Project Manager';

  @override
  String get dpmPluginDescription =>
      'Un plugin VST3/AU pour votre DAW. Placez-le sur le bus master : il affiche les tâches du projet, enregistre chaque lecture comme dernière capture du projet et peut terminer votre session de travail quand la DAW ferme le projet.';

  @override
  String dpmPluginLastSeen(String daw, String version, String date) {
    return 'Vu pour la dernière fois dans $daw (version $version) le $date.';
  }

  @override
  String get dpmPluginNotSeen =>
      'Pas encore vu sur cet ordinateur. Installez-le, puis placez-le sur le bus master de votre DAW.';

  @override
  String dpmPluginUpdateAvailable(String version) {
    return 'La version $version est disponible.';
  }

  @override
  String get dpmPluginDownload => 'Télécharger le plugin pour la DAW';

  @override
  String get dpmPluginDownloadUpdate => 'Télécharger la mise à jour';

  @override
  String get dpmPluginInstalledTitle => 'Installé';

  @override
  String dpmPluginInstalledVersion(String version) {
    return 'Version $version';
  }

  @override
  String get dpmPluginInstalledNone =>
      'Introuvable dans les dossiers de plugins standard.';

  @override
  String get dpmPluginInstalledDuplicates =>
      'Plusieurs copies sont installées : votre DAW peut charger l\'une ou l\'autre. N\'en gardez qu\'une.';

  @override
  String get dpmPluginSearchAgain => 'Rechercher à nouveau';

  @override
  String get dpmPluginSearching => 'Recherche…';

  @override
  String get dpmPluginCustomFoldersHint =>
      'Installé ailleurs ? Ajoutez ce dossier : l\'application y cherchera quand les dossiers standard n\'en contiennent aucune copie.';

  @override
  String get dpmPluginCustomFolderTag => 'votre dossier';

  @override
  String get dpmPluginScanUnavailable =>
      'Le Flatpak ne peut pas regarder dans vos dossiers de plugins. Le plugin apparaîtra ici dès qu\'une DAW l\'aura chargé.';

  @override
  String get legacyInstallTitle => 'Supprimer l’ancienne installation ?';

  @override
  String get legacyInstallMessage =>
      'Une ancienne copie de DAW Project Manager, issue du précédent programme d’installation, est encore installée. Celle-ci la remplace et se met désormais à jour toute seule. Supprimer l’ancienne copie ne touche pas à votre bibliothèque.';

  @override
  String get legacyInstallRemove => 'La supprimer';

  @override
  String get legacyInstallKeep => 'La garder';

  @override
  String get legacyInstallRemoveFailed =>
      'Impossible de lancer le programme de désinstallation de l’ancienne copie.';

  @override
  String get missingPreviewSongsTitle => 'Chansons d\'aperçu manquantes';

  @override
  String get missingPreviewSongsSubtitle =>
      'Les chansons d\'aperçu du profil actuel que cet ordinateur ne trouve pas. Vérifiez-les, puis téléchargez, recherchez ou retirez chacune : rien ne change tant que vous n\'avez pas choisi.';

  @override
  String get missingPreviewSongsCheck => 'Vérifier';

  @override
  String get missingPreviewSongsChecking => 'Vérification…';

  @override
  String get missingPreviewSongsNone =>
      'Toutes les chansons d\'aperçu sont à leur place.';

  @override
  String get missingPreviewSongsSignInHint =>
      'Connectez-vous à Google Drive pour les y chercher aussi.';

  @override
  String missingPreviewOnDriveTitle(int count) {
    return 'Sur Google Drive ($count)';
  }

  @override
  String get missingPreviewOnDriveDescription =>
      'Une sauvegarde contient ces chansons. Les télécharger en place une copie sur cet ordinateur.';

  @override
  String missingPreviewOtherComputerTitle(int count) {
    return 'D\'un autre ordinateur ($count)';
  }

  @override
  String get missingPreviewOtherComputerDescription =>
      'Leurs chemins appartiennent à un autre ordinateur, où elles se lisent peut-être très bien. Choisissez un fichier ici pour les lire aussi sur cet ordinateur.';

  @override
  String missingPreviewFolderMissingTitle(int count) {
    return 'Dossier introuvable ($count)';
  }

  @override
  String get missingPreviewFolderMissingDescription =>
      'Leur dossier n\'est pas là non plus : un disque non connecté, ou un dossier déplacé ou supprimé. Connectez le disque et vérifiez à nouveau avant de retirer quoi que ce soit.';

  @override
  String missingPreviewFileMissingTitle(int count) {
    return 'Fichier introuvable ($count)';
  }

  @override
  String get missingPreviewFileMissingDescription =>
      'Le dossier est là, mais pas le fichier.';

  @override
  String get missingPreviewDownload => 'Télécharger';

  @override
  String get missingPreviewDownloadAll => 'Tout télécharger';

  @override
  String get missingPreviewFindAll => 'Tout rechercher';

  @override
  String get missingPreviewRemoveAll => 'Tout retirer';

  @override
  String missingPreviewRemoveAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retirer $count chansons d\'aperçu ?',
      one: 'Retirer $count chanson d\'aperçu ?',
    );
    return '$_temp0';
  }

  @override
  String get missingPreviewRemoveBody =>
      'Elles ne sont retirées que sur cet ordinateur, et aucun fichier n\'est supprimé. Si un autre appareil a encore l\'une de ces chansons, la prochaine synchronisation la ramène ici.';

  @override
  String missingPreviewDownloadedResult(int done, int total) {
    return '$done sur $total téléchargées.';
  }

  @override
  String missingPreviewFoundResult(int found, int total) {
    return 'Mixdown trouvé pour $found sur $total.';
  }

  @override
  String missingPreviewDownloadFailed(String name) {
    return 'Impossible de télécharger la chanson de $name.';
  }

  @override
  String get missingPreviewAutoDetected => 'Détectée automatiquement';

  @override
  String missingPreviewRemoveEverything(int count) {
    return 'Retirer toutes les introuvables ($count)';
  }

  @override
  String missingPreviewRemoveIncludesDrive(int count) {
    return 'Parmi elles, $count peuvent encore être téléchargées depuis Google Drive.';
  }

  @override
  String missingPreviewRemoveIncludesOtherComputer(int count) {
    return 'Parmi elles, $count se lisent peut-être encore sur un autre ordinateur.';
  }

  @override
  String get inspectorTab => 'Inspecteur';

  @override
  String get inspectorSearchHint => 'Rechercher des pistes et des plug-ins';

  @override
  String get inspectorEmptyTitle =>
      'Voir l\'intérieur d\'un projet sans ouvrir la DAW';

  @override
  String get inspectorEmptyBody =>
      'Déposez un fichier de projet ici, ouvrez-en un ou choisissez Inspecter dans le menu d\'un projet. Le projet est seulement lu, jamais modifié.';

  @override
  String get inspectorOpenProject => 'Ouvrir un projet…';

  @override
  String get inspectorChooseProjectTitle => 'Choisir un projet à inspecter';

  @override
  String get inspectorReading => 'Lecture du projet…';

  @override
  String get inspectorReadFailed => 'Ce projet n\'a pas pu être lu.';

  @override
  String inspectorUnsupported(String extension) {
    return 'L\'Inspecteur ne peut pas lire les fichiers $extension.';
  }

  @override
  String get inspectorReload => 'Relire';

  @override
  String get inspectorClose => 'Fermer';

  @override
  String inspectorSavedWith(String daw, String version) {
    return 'Enregistré avec $daw $version';
  }

  @override
  String get inspectorTileTempo => 'Tempo';

  @override
  String get inspectorTileTimeSignature => 'Signature rythmique';

  @override
  String get inspectorTileSampleRate => 'Fréquence d\'échantillonnage';

  @override
  String inspectorBitDepth(int bits) {
    return '$bits bits';
  }

  @override
  String get inspectorNotInFile => 'Absent du projet';

  @override
  String inspectorTileTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pistes',
      one: 'piste',
    );
    return '$_temp0';
  }

  @override
  String inspectorTileEffects(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'effets',
      one: 'effet',
    );
    return '$_temp0';
  }

  @override
  String inspectorTileInstruments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'instruments',
      one: 'instrument',
    );
    return '$_temp0';
  }

  @override
  String inspectorEffectsBreakdown(int stock, int thirdParty) {
    return '$stock fournis · $thirdParty tiers';
  }

  @override
  String get inspectorFilterAll => 'Toutes';

  @override
  String get inspectorKindAudio => 'Audio';

  @override
  String get inspectorKindInstrument => 'Instrument';

  @override
  String get inspectorKindMidi => 'MIDI';

  @override
  String get inspectorKindSampler => 'Sampler';

  @override
  String get inspectorKindGroup => 'Groupe';

  @override
  String get inspectorKindFx => 'FX';

  @override
  String get inspectorKindFolder => 'Dossier';

  @override
  String get inspectorTabTracks => 'Pistes';

  @override
  String get inspectorTabPlugins => 'Plug-ins';

  @override
  String get inspectorTabRouting => 'Routage';

  @override
  String get inspectorTabMedia => 'Fichiers audio';

  @override
  String get inspectorTabStatistics => 'Statistiques';

  @override
  String inspectorNotAvailable(String daw) {
    return 'Pas encore lu pour les projets $daw.';
  }

  @override
  String get inspectorOutput => 'Sortie';

  @override
  String get inspectorInserts => 'Inserts';

  @override
  String get inspectorSends => 'Départs';

  @override
  String get inspectorInstrument => 'Instrument';

  @override
  String get inspectorFader => 'Fader';

  @override
  String get inspectorNoInserts => 'Aucun insert';

  @override
  String get inspectorNoSends => 'Aucun départ';

  @override
  String get inspectorNotConnected => 'Non connectée';

  @override
  String get inspectorDeactivated => 'désactivé';

  @override
  String get inspectorSoloed => 'Solo';

  @override
  String get inspectorPreFader => 'Pré-fader';

  @override
  String get inspectorSendSwitchedOff => 'Désactivé';

  @override
  String inspectorSideChainInto(String plugin) {
    return 'Sidechain vers $plugin';
  }

  @override
  String inspectorEqBandsOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'EQ : $count bandes actives',
      one: 'EQ : 1 bande active',
      zero: 'EQ désactivé',
    );
    return '$_temp0';
  }

  @override
  String get inspectorFaderPositionOnly =>
      'Position du fader ; sa valeur en dB n’est pas encore lue';

  @override
  String get inspectorSelectChannel =>
      'Sélectionnez une voie pour voir son routage et ses plug-ins.';

  @override
  String get inspectorGroupStock => 'Effets fournis';

  @override
  String get inspectorGroupThirdParty => 'Effets tiers';

  @override
  String get inspectorGroupInstruments => 'Instruments';

  @override
  String inspectorPluginSummary(int unique, int instances) {
    return '$unique différents · $instances instances';
  }

  @override
  String inspectorPluginsNamesOnly(String daw) {
    return 'Les voies qui utilisent chaque plug-in ne sont pas encore lues pour les projets $daw.';
  }

  @override
  String get inspectorSignalFlow => 'Flux du signal';

  @override
  String get inspectorByDestination => 'Par destination';

  @override
  String get inspectorFeedsIn => 'Arrive de';

  @override
  String get inspectorGoesTo => 'Va vers';

  @override
  String get inspectorSignalPath => 'Chemin du signal';

  @override
  String get inspectorViaSend => 'Départ';

  @override
  String get inspectorViaSideChain => 'Sidechain';

  @override
  String get inspectorNothingFeeds => 'Rien n\'arrive à cette voie.';

  @override
  String inspectorHintNowhere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voies ne vont nulle part',
      one: '1 voie ne va nulle part',
    );
    return '$_temp0';
  }

  @override
  String inspectorHintSkipBuses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistes vont directement à une sortie',
      one: '1 piste va directement à une sortie',
    );
    return '$_temp0';
  }

  @override
  String inspectorSourcesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources',
      one: '1 source',
    );
    return '$_temp0';
  }

  @override
  String get inspectorMediaFound => 'Trouvé';

  @override
  String get inspectorMediaElsewhere => 'Trouvé dans le dossier du projet';

  @override
  String get inspectorMediaMissing => 'Manquant';

  @override
  String inspectorMediaSummary(int missing, int total) {
    return '$missing sur $total manquants';
  }

  @override
  String inspectorMediaAllFound(int total) {
    return 'Les $total sont trouvés';
  }

  @override
  String get inspectorMediaChecking => 'Recherche des fichiers…';

  @override
  String get inspectorMediaNone => 'Ce projet n\'utilise aucun fichier audio.';

  @override
  String inspectorMediaStoredAt(String path) {
    return 'Selon le projet : $path';
  }

  @override
  String inspectorMediaFoundAt(String path) {
    return 'Trouvé ici : $path';
  }

  @override
  String get inspectorStatTrackTypes => 'Types de pistes';

  @override
  String get inspectorStatPluginInstances => 'Instances de plug-ins';

  @override
  String get inspectorStatUnknown => 'Inconnu';

  @override
  String get inspectorStatMostUsed => 'Plug-ins les plus utilisés';

  @override
  String get inspectorStatUsualChains => 'Chaînes habituelles';

  @override
  String get inspectorStatNoChains =>
      'Aucune chaîne de plug-ins ne se répète entre les voies.';

  @override
  String get inspectorStatInsertsPerChannel => 'Inserts par voie';

  @override
  String get inspectorStatBusiest => 'Destinations les plus chargées';

  @override
  String inspectorInsertsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inserts',
      one: '1 insert',
    );
    return '$_temp0';
  }

  @override
  String inspectorChannelsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voies',
      one: '1 voie',
    );
    return '$_temp0';
  }

  @override
  String get projectMenuInspect => 'Inspecter';

  @override
  String get sampleRateColumn => 'Fréquence d\'échantillonnage';

  @override
  String get inspectorCloudTitle => 'Télécharger ce projet ?';

  @override
  String inspectorCloudBody(String size) {
    return 'Ce projet est dans le cloud, pas sur cet ordinateur. Le lire télécharge tout le fichier ($size).';
  }

  @override
  String get inspectorCloudRead => 'Télécharger et lire';

  @override
  String get inspectorTabAudioIo => 'E/S audio';

  @override
  String get inspectorAudioDriver => 'Pilote audio';

  @override
  String get inspectorUnnamedDriver => 'Non nommé dans le projet';

  @override
  String inspectorSavedOn(String platform) {
    return 'Enregistré sous $platform';
  }

  @override
  String get inspectorInputBuses => 'Bus d’entrée';

  @override
  String get inspectorOutputBuses => 'Bus de sortie';

  @override
  String get inspectorInterfaceInputs => 'Entrées de l’interface';

  @override
  String get inspectorInterfaceOutputs => 'Sorties de l’interface';

  @override
  String get inspectorMidiInputs => 'Entrées MIDI';

  @override
  String get inspectorMidiOutputs => 'Sorties MIDI';

  @override
  String get inspectorNone => 'Aucun';

  @override
  String get inspectorPan => 'Panoramique';

  @override
  String get inspectorMuted => 'Coupé';

  @override
  String get inspectorChannelStrip => 'Channel strip';

  @override
  String get inspectorStripBypassed => 'Strip contourné';

  @override
  String get inspectorStripBeforeInserts => 'Avant les inserts';

  @override
  String get inspectorStripGate => 'Gate';

  @override
  String get inspectorStripCompressor => 'Compresseur';

  @override
  String get inspectorStripEq => 'EQ';

  @override
  String get inspectorStripTools => 'Outils';

  @override
  String get inspectorStripSaturation => 'Saturation';

  @override
  String get inspectorStripLimiter => 'Limiteur';

  @override
  String get inspectorStripModule => 'Module';

  @override
  String get relinkFixButton => 'Réparer les fichiers manquants…';

  @override
  String get relinkTitle => 'Réparer les fichiers manquants';

  @override
  String get relinkIntro =>
      'Une copie du projet est écrite à côté de lui, pointant vers l\'emplacement actuel des fichiers. Le projet lui-même n\'est jamais modifié.';

  @override
  String get relinkSearchFolder => 'Chercher dans un dossier…';

  @override
  String get relinkSearchFolderTitle => 'Où sont les fichiers manquants ?';

  @override
  String get relinkSearching => 'Recherche des fichiers…';

  @override
  String relinkSearchedIn(String folders) {
    return 'Recherché dans : $folders';
  }

  @override
  String relinkWillFix(int count, int total) {
    return '$count fichiers sur $total seront reliés';
  }

  @override
  String relinkChooseOne(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trouvé $count fois — choisissez',
    );
    return '$_temp0';
  }

  @override
  String get relinkNotFound => 'Introuvable';

  @override
  String get relinkBrowse => 'Parcourir…';

  @override
  String relinkBrowseTitle(String name) {
    return 'Où est $name ?';
  }

  @override
  String get relinkLeave => 'Laisser tel quel';

  @override
  String get relinkChange => 'Choisir la cible';

  @override
  String relinkRuleOffer(int count, String from, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Le même déplacement trouve $count fichiers de plus : $from → $to',
      one: 'Le même déplacement trouve 1 fichier de plus : $from → $to',
    );
    return '$_temp0';
  }

  @override
  String get relinkApplyRule => 'Appliquer';

  @override
  String get relinkWrite => 'Écrire la copie reliée';

  @override
  String get relinkWriting => 'Écriture et vérification de la copie…';

  @override
  String relinkWrote(String name) {
    return '$name écrit';
  }

  @override
  String relinkRelinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers reliés',
      one: '1 fichier relié',
    );
    return '$_temp0';
  }

  @override
  String relinkRefusedTooLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count non reliés : leur nouveau chemin est plus long que la place dans le projet. Déplacez-les vers un chemin plus court ou cherchez-les dans Cubase.',
      one:
          '1 non relié : son nouveau chemin est plus long que la place dans le projet. Déplacez-le vers un chemin plus court ou cherchez-le dans Cubase.',
    );
    return '$_temp0';
  }

  @override
  String relinkRefusedEncoding(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count non reliés : ce projet ancien ne peut pas stocker les accents de leur nouveau chemin.',
      one:
          '1 non relié : ce projet ancien ne peut pas stocker les accents de son nouveau chemin.',
    );
    return '$_temp0';
  }

  @override
  String relinkRefusedNotFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count non reliés : le projet ne les nomme qu\'à des endroits qu\'une copie ne peut pas modifier.',
      one:
          '1 non relié : le projet ne le nomme qu\'à un endroit qu\'une copie ne peut pas modifier.',
    );
    return '$_temp0';
  }

  @override
  String get relinkNothingWritten =>
      'Rien n\'a pu être relié : aucune copie n\'a été écrite.';

  @override
  String relinkFailed(String reason) {
    return 'La copie n\'a pas passé la vérification et n\'a pas été conservée : $reason';
  }

  @override
  String get relinkInspectCopy => 'Inspecter la copie';

  @override
  String get inspectorTileKey => 'Tonalité';

  @override
  String inspectorTileMidiClips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'clips MIDI',
      one: 'clip MIDI',
    );
    return '$_temp0';
  }

  @override
  String inspectorTileMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'marqueurs',
      one: 'marqueur',
    );
    return '$_temp0';
  }

  @override
  String inspectorMarkerRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count régions',
      one: '1 région',
      zero: 'Aucune région',
    );
    return '$_temp0';
  }

  @override
  String inspectorTilePlugins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'plug-ins',
      one: 'plug-in',
    );
    return '$_temp0';
  }

  @override
  String get inspectorPluginNamesOnly => 'Par nom uniquement';

  @override
  String inspectorMidiFilesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers .mid manquants',
      one: '1 fichier .mid manquant',
    );
    return '$_temp0';
  }

  @override
  String get inspectorKindBuses => 'Groupe et FX';

  @override
  String get inspectorNotesTitle => 'Notes dans le projet';

  @override
  String get inspectorMissingMidiTitle => 'Fichiers MIDI introuvables';
}
