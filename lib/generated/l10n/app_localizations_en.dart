// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DAW Project Manager';

  @override
  String get projectDetails => 'Project Details';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get enable => 'Enable';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get undo => 'Undo';

  @override
  String get customInterval => 'Custom';

  @override
  String get close => 'Close';

  @override
  String get launch => 'Launch';

  @override
  String get view => 'View';

  @override
  String get openFolder => 'Open Folder';

  @override
  String get openInDaw => 'Launch in DAW';

  @override
  String get extract => 'Extract';

  @override
  String get extracting => 'Extracting…';

  @override
  String get extractingMetadata => 'Extracting metadata...';

  @override
  String get deepScan => 'Deep Scan';

  @override
  String get rescan => 'Rescan';

  @override
  String get refreshProject => 'Refresh';

  @override
  String get scanning => 'Scanning…';

  @override
  String get newProjectBadge => 'NEW';

  @override
  String get projectName => 'Project Name';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Key (e.g., C#m, F major)';

  @override
  String get notes => 'Notes';

  @override
  String get expandNotes => 'Expand';

  @override
  String get collapseNotes => 'Collapse';

  @override
  String get projectNotesFromDaw => 'Project Notes (from DAW file)';

  @override
  String get projectPhase => 'Project Phase';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get fileMissing => 'File missing.';

  @override
  String launchingProject(String projectName) {
    return 'Launching $projectName…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return 'Failed to launch $projectName';
  }

  @override
  String get clearLibrary => 'Clear Library';

  @override
  String get clearLibraryMessage =>
      'This will remove all saved projects and source folders. Continue?';

  @override
  String get clear => 'Clear';

  @override
  String get roots => 'Project Folders';

  @override
  String get pathsSettingsDangerZoneTitle => 'Library';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Clear all projects and project folders for the current profile.';

  @override
  String get projectFoldersSectionTitle => 'Project folders';

  @override
  String get projectFoldersSectionSubtitle =>
      'Folders that will be scanned for DAW projects.';

  @override
  String get projectFoldersEmptyTitle => 'No project folders yet';

  @override
  String get projectFoldersEmptySubtitle =>
      'Add at least one folder to start scanning for projects.';

  @override
  String get notScannedYet => 'Not scanned yet';

  @override
  String lastScan(String date) {
    return 'Last scan: $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Excluded folders';

  @override
  String get excludedFoldersSectionSubtitle =>
      'These folders will be skipped during scanning, even if they are inside a project folder.';

  @override
  String get addExcludedFolder => 'Add excluded';

  @override
  String get selectExcludedFolder => 'Select a folder to exclude';

  @override
  String get excludedFoldersEmptyTitle => 'No excluded folders';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Optional: add folders you never want to scan.';

  @override
  String get removeExcludedFolderTitle => 'Remove excluded folder?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'This folder will no longer be excluded:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'This folder will no longer be excluded.';

  @override
  String get desktopOnlyPathsSettings =>
      'This page is available only on the desktop app.';

  @override
  String get renameProjectFolderTitle => 'Display Name';

  @override
  String get flatpakPortalPathExplanation =>
      'This path is a sandboxed location, not the real folder location — Flatpak doesn\'t share that with the app. Use the name above to identify it instead.';

  @override
  String get removeProjectFolderTitle => 'Remove project folder?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Are you sure you want to remove \"$path\"? This will also remove all projects from this folder that are not in releases.';
  }

  @override
  String get projects => 'Projects';

  @override
  String get hidden => 'hidden';

  @override
  String get profileManager => 'Profile Manager';

  @override
  String get createNewProfile => 'Create New Profile';

  @override
  String get profileName => 'Profile Name';

  @override
  String get create => 'Create';

  @override
  String get profiles => 'Profiles';

  @override
  String get active => 'Active';

  @override
  String get switchProfile => 'Activate Profile';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get addFolder => 'Add Folder';

  @override
  String get searchProjects => 'Search projects...';

  @override
  String get searchReleases => 'Search releases...';

  @override
  String get searchPlaylists => 'Search playlists...';

  @override
  String get noReleasesFound => 'No releases found';

  @override
  String get noPlaylistsFound => 'No playlists found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get deepScanConfirm =>
      'Deep Scan extracts full metadata from project files:\n• BPM (Beats Per Minute)\n• Musical Key\n• DAW Version\n• Project Notes (where supported)\n\nThis is slower than a regular scan and may take a while. Continue?';

  @override
  String get deepScanViewSupportedDaws => 'View supported DAWs & fields';

  @override
  String get deepScanOnlyUnscanned => 'Only scan projects without metadata';

  @override
  String get metadataExtractionTitle => 'Metadata Extraction';

  @override
  String get metadataExtractionSubtitle => 'See which data each DAW supports';

  @override
  String get metadataExtractionIntro =>
      'Deep Scan can automatically read some of these fields straight from a project file — the rest have to be entered by hand. This table shows what\'s automatic for each supported DAW today.';

  @override
  String get metadataFieldKey => 'Key';

  @override
  String get metadataFieldVersion => 'DAW Version';

  @override
  String get metadataExtractionManualNote =>
      'Any field without automatic support can still be entered manually in Project Detail. For BPM and Key specifically, dropping a bpm.txt or key.txt file next to the project is also picked up on the next scan.';

  @override
  String get metadataExtractedSuccessfully => 'Metadata extracted successfully';

  @override
  String failedToExtractMetadata(String error) {
    return 'Failed to extract metadata: $error';
  }

  @override
  String get saved => 'Saved';

  @override
  String get failedToLaunchDaw => 'Failed to launch DAW';

  @override
  String get releaseDetails => 'Release Details';

  @override
  String get releaseNotFound => 'Release Not Found';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get deleteProfile => 'Delete Profile';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Are you sure you want to delete \"$profileName\"? This will delete all projects, project folders, and releases for this profile.';
  }

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get remove => 'Remove';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Are you sure you want to remove \"$trackName\" from this release?';
  }

  @override
  String get saveName => 'Save Name';

  @override
  String get profilePhotoUpdated => 'Profile photo updated.';

  @override
  String get profilePhotoRemoved => 'Profile photo removed.';

  @override
  String profileRenamed(String newName) {
    return 'Profile renamed to \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Profile \"$name\" created successfully';
  }

  @override
  String profileDeleted(String name) {
    return 'Profile \"$name\" deleted';
  }

  @override
  String get pleaseEnterProfileName => 'Please enter a profile name';

  @override
  String failedToCreateProfile(String error) {
    return 'Failed to create profile: $error';
  }

  @override
  String get noProfilesFound => 'No profiles found. Create one above.';

  @override
  String get clearLibraryTooltip =>
      'Clear Library (projects & project folders)';

  @override
  String lastModified(String date) {
    return 'Last modified: $date';
  }

  @override
  String get name => 'Name';

  @override
  String get status => 'Status';

  @override
  String get phase => 'Phase';

  @override
  String get filterByPhase => 'Filter by Phase';

  @override
  String get filters => 'Filters';

  @override
  String get allPhases => 'All Phases';

  @override
  String get filterByDaw => 'Filter by DAW';

  @override
  String get allDaws => 'All DAWs';

  @override
  String get daw => 'DAW';

  @override
  String get clearDaw => 'Clear DAW';

  @override
  String get filterByKey => 'Filter by Key';

  @override
  String get allKeys => 'All Keys';

  @override
  String get lastModifiedColumn => 'Last Modified';

  @override
  String get actions => 'Actions';

  @override
  String get hide => 'Hide';

  @override
  String get unhide => 'Unhide';

  @override
  String get extractMetadata => 'Extract Metadata';

  @override
  String get createRelease => 'Create Release';

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get selectAllProjects => 'Select all projects';

  @override
  String get switchingProfiles => 'Switching Profiles...';

  @override
  String get scanningProjects => 'Scanning projects...';

  @override
  String scanProgressLabel(int current, int total) {
    return 'Loading project $current of $total…';
  }

  @override
  String get search => 'Search';

  @override
  String get projectsTab => 'Projects';

  @override
  String get releasesTab => 'Releases';

  @override
  String get showHidden => 'Show Hidden';

  @override
  String get showAll => 'Show All';

  @override
  String get showOnlyHidden => 'Show Only Hidden';

  @override
  String get deleteRootPath => 'Remove project folder';

  @override
  String deleteRootPathMessage(String path) {
    return 'Are you sure you want to remove \"$path\"? This will also remove all projects from this folder that are not in releases.';
  }

  @override
  String rootsCount(int count) {
    return 'Project Folders: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Projects: $count';
  }

  @override
  String get hiddenOnly => '(hidden only)';

  @override
  String hiddenCount(int count) {
    return '($count hidden)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count project$plural hidden.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count project$plural unhidden.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Failed to hide projects: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Failed to unhide projects: $error';
  }

  @override
  String get deleteMissingProjects => 'Delete Missing';

  @override
  String get deleteMissingProjectsTitle => 'Delete missing projects?';

  @override
  String deleteMissingProjectsConfirm(int count, String plural) {
    return '$count project$plural whose file could not be found on this machine will be permanently deleted, along with all notes, deadlines, and session history. This can\'t be undone.';
  }

  @override
  String get deleteMissingProjectsConfirmButton => 'Delete Permanently';

  @override
  String missingProjectsDeleted(int count, String plural) {
    return '$count missing project$plural deleted.';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(
    int count,
    String plural,
  ) {
    return 'Also delete $count project$plural that are part of a release (removes them from that release too)';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Are you sure you want to hide \"$projectName\"?';
  }

  @override
  String releaseCreated(String title) {
    return 'Release \"$title\" created successfully.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Failed to create release: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Error adding folder: $error';
  }

  @override
  String get folderAlreadyAdded => 'This folder has already been added.';

  @override
  String get noProjectsFoundInRoots =>
      'No projects found in selected project folders.';

  @override
  String get selectProjectsFolder => 'Select a projects folder';

  @override
  String get enterReleaseTitle => 'Enter Release Title';

  @override
  String get releaseTitle => 'Release Title';

  @override
  String get enterReleaseTitleHint => 'Enter release title';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Extracted metadata for $count project$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count failed.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Failed to write BPM file: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Failed to write key file: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Failed to launch: $error';
  }

  @override
  String get libraryCleared => 'Library cleared.';

  @override
  String scanType(String type) {
    return '$type scan';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type complete: $count project$plural added/updated.';
  }

  @override
  String get scanCancelled => 'Scan cancelled.';

  @override
  String scanFailuresSnackbar(int count, String plural) {
    return '$count project$plural failed to load.';
  }

  @override
  String get scanFailuresSnackbarAction => 'Details';

  @override
  String get scanFailuresDialogTitle => 'Scan Errors';

  @override
  String get scanFailuresDialogIntro =>
      'These files could not be read during the scan (they may have been deleted, moved, or locked by another program):';

  @override
  String projectsSelected(int count, String plural) {
    return '$count project$plural selected';
  }

  @override
  String openingFolder(String projectName) {
    return 'Opening folder for $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Failed to open folder: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'OS not supported for opening folder.';

  @override
  String get noProjectsAvailable =>
      'No projects available. Please add projects first.';

  @override
  String get createNewRelease => 'Create New Release';

  @override
  String get deleteRelease => 'Delete Release';

  @override
  String deleteReleaseMessage(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Release \"$title\" deleted.';
  }

  @override
  String releasesSelected(int count, String plural) {
    return '$count release$plural selected';
  }

  @override
  String get deleteSelectedReleases => 'Delete Selected';

  @override
  String deleteSelectedReleasesConfirm(int count, String plural) {
    return 'Are you sure you want to delete $count release$plural?';
  }

  @override
  String releasesDeleted(int count, String plural) {
    return '$count release$plural deleted';
  }

  @override
  String get selectTracks => 'Select Tracks';

  @override
  String get continueButton => 'Continue';

  @override
  String get noReleasesYet => 'No releases yet';

  @override
  String get createFirstRelease =>
      'Create your first release by selecting tracks from your projects';

  @override
  String releasesCount(int count) {
    return 'Releases ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Error loading releases: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Tracks ($count)';
  }

  @override
  String get addTracks => 'Add Tracks';

  @override
  String get allProjectsAlreadyInRelease =>
      'All projects are already in this release.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Added $count track$plural to release.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Release Files ($count)';
  }

  @override
  String get addFiles => 'Add Files';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Added $count file$plural to release.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Failed to add files: $error';
  }

  @override
  String get noFilesToDownload => 'No files to download.';

  @override
  String zipFileSaved(String path) {
    return 'ZIP file saved to: $path';
  }

  @override
  String get creatingZipFile => 'Creating ZIP file...';

  @override
  String failedToCreateZip(String error) {
    return 'Failed to create ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'Selected file does not exist.';

  @override
  String get imageSavedSuccessfully => 'Image saved successfully!';

  @override
  String failedToSaveImage(String error) {
    return 'Failed to save image: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Error loading release: $error';
  }

  @override
  String get errorLoadingProjects => 'Error loading projects';

  @override
  String get releaseSaved => 'Release saved.';

  @override
  String get releaseDate => 'Release Date';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Failed to save release date: $error';
  }

  @override
  String get releaseDateSaved => 'Release date saved.';

  @override
  String get releaseDateCleared => 'Release date cleared.';

  @override
  String get saveReleaseFilesZip => 'Save release files ZIP';

  @override
  String get failedToOpenFile => 'Failed to open file';

  @override
  String failedToPlayAudio(String error) {
    return 'Failed to play audio: $error';
  }

  @override
  String get renameFile => 'Rename File';

  @override
  String get selectTracksToAdd => 'Select Tracks to Add';

  @override
  String get fileNameUpdated => 'File name updated.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Error updating file name: $error';
  }

  @override
  String get deleteFile => 'Delete File';

  @override
  String deleteFileMessage(String fileName) {
    return 'Are you sure you want to delete \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'File \"$fileName\" deleted.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Failed to delete file: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Could not open folder: $error';
  }

  @override
  String get artwork => 'Artwork';

  @override
  String get title => 'Title';

  @override
  String get tracks => 'Tracks';

  @override
  String get description => 'Description';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Select tracks to include in the release ($count selected)';
  }

  @override
  String get searchTracks => 'Search tracks';

  @override
  String get searchTracksHint => 'Search by name or DAW type';

  @override
  String get noTracksFound => 'No tracks found';

  @override
  String get unknown => 'Unknown';

  @override
  String get fileNotFound => 'File not found';

  @override
  String get fileName => 'File Name';

  @override
  String get editTodo => 'Edit Todo';

  @override
  String get todoText => 'Todo text';

  @override
  String get enterTodoText => 'Enter todo text';

  @override
  String get addNewTodo => 'Add new todo';

  @override
  String get enterTodoItem => 'Enter todo item';

  @override
  String addTodoAtTimestamp(String timestamp) {
    return 'Add todo at $timestamp';
  }

  @override
  String todoAddedAtTimestamp(String timestamp) {
    return 'Added todo at $timestamp';
  }

  @override
  String get todoList => 'TODO List';

  @override
  String get todoTemplates => 'TODO Templates';

  @override
  String get createTemplate => 'Create Template';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Are you sure you want to delete template \"$name\"?';
  }

  @override
  String get templateName => 'Template Name';

  @override
  String get templateNameHint => 'e.g., Mixing Checklist';

  @override
  String get templateItems => 'Template Items';

  @override
  String get templateItemsHint => 'One item per line';

  @override
  String get templateNameAndItemsRequired =>
      'Template name and items are required';

  @override
  String get templateItemsRequired => 'At least one item is required';

  @override
  String get templateCreated => 'Template created';

  @override
  String get templateUpdated => 'Template updated';

  @override
  String get templateDeleted => 'Template deleted';

  @override
  String get noTemplatesYet => 'No templates yet';

  @override
  String get createFirstTemplate => 'Create your first TODO template';

  @override
  String templateItemCount(int count) {
    return '$count item(s)';
  }

  @override
  String get selectTemplate => 'Select Template';

  @override
  String get importFromTemplate => 'Import from Template';

  @override
  String get manageTemplates => 'Manage Templates';

  @override
  String get noTemplatesAvailable =>
      'No templates available. Create one first.';

  @override
  String templateImported(String name, int count) {
    return 'Template \"$name\" imported ($count items)';
  }

  @override
  String get errorLoadingTemplates => 'Error loading templates';

  @override
  String get createProjectStartFrom => 'How do you want to start?';

  @override
  String get createProjectStartFromHint =>
      'Start from an empty folder or copy a registered template.';

  @override
  String get createProjectEmptyFolder => 'Empty Folder';

  @override
  String get createProjectFromTemplate => 'From Template';

  @override
  String get selectTemplateMainFile =>
      'Select the Template\'s Main Project File';

  @override
  String get registerTemplate => 'Register Template';

  @override
  String get projectTemplates => 'Project Templates';

  @override
  String get searchTemplates => 'Search templates...';

  @override
  String get createFirstProjectTemplate =>
      'Register a template folder to reuse for new projects';

  @override
  String get noMatchingTemplates => 'No matching templates';

  @override
  String get templateSourceMissing => 'Template source folder not found';

  @override
  String get useTemplate => 'Use';

  @override
  String get selectTemplatesParentFolder => 'Select Parent Folder of Templates';

  @override
  String get templateSourceFolder => 'Source Folder';

  @override
  String get dateCreatedColumn => 'Created';

  @override
  String get dateModifiedColumn => 'Modified';

  @override
  String get manageTemplateFolders => 'Manage Folders';

  @override
  String get addTemplateFolder => 'Add Folder';

  @override
  String get removeTemplateFolder => 'Remove Template Folder';

  @override
  String removeTemplateFolderConfirm(String path) {
    return 'Remove \"$path\" from your registered template folders? Templates already imported from it will not be deleted.';
  }

  @override
  String get noTemplateFoldersRegistered => 'No template folders registered';

  @override
  String get refreshTemplateFolders =>
      'Refresh templates from registered folders';

  @override
  String lastRefreshed(String date) {
    return 'Last refreshed $date';
  }

  @override
  String templatesRefreshedSummary(int count) {
    return '$count new template(s) added';
  }

  @override
  String templatesSelected(int count, String plural) {
    return '$count template$plural selected';
  }

  @override
  String get deleteSelectedTemplates => 'Delete Selected';

  @override
  String deleteSelectedTemplatesConfirm(int count, String plural) {
    return 'Are you sure you want to delete $count template$plural?';
  }

  @override
  String templatesDeleted(int count, String plural) {
    return '$count template$plural deleted';
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
  String get importTodos => 'Import Todos from File';

  @override
  String get noTodosInFile => 'No todos found in file';

  @override
  String todosImported(int count) {
    return '$count todo(s) imported successfully';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Error importing todos: $error';
  }

  @override
  String get addToRelease => 'Add to Release';

  @override
  String get createNew => 'Create New';

  @override
  String get addToExisting => 'Add to Existing';

  @override
  String get createAndAdd => 'Create and Add';

  @override
  String get selectRelease => 'Select a release';

  @override
  String get noExistingReleasesFound => 'No existing releases found.';

  @override
  String get addToSelectedRelease => 'Add to Selected Release';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Failed to save profile photo: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Failed to remove profile photo: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Failed to rename profile: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Failed to delete profile: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Error loading profiles: $error';
  }

  @override
  String get projectPhaseIdea => 'Idea';

  @override
  String get projectPhaseArranging => 'Arranging';

  @override
  String get projectPhaseMixing => 'Mixing';

  @override
  String get projectPhaseMastering => 'Mastering';

  @override
  String get projectPhaseFinished => 'Finished';

  @override
  String get changeStatus => 'Change Phase';

  @override
  String get selectNewStatus => 'Select new phase:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Phase changed to \"$status\" for $count project$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Phase changed to \"$status\" for $successCount project$successPlural, $failCount failed$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Failed to change phase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Edit profile name';

  @override
  String get tooltipAddTodo => 'Add todo';

  @override
  String get tooltipClearDate => 'Clear date';

  @override
  String get tooltipPickDate => 'Pick date';

  @override
  String get tooltipViewDetails => 'View Details';

  @override
  String get tooltipLaunchInDaw => 'Launch in DAW';

  @override
  String get tooltipRemoveFromRelease => 'Remove from Release';

  @override
  String get profile => 'Profile';

  @override
  String get noDateSet => 'No date set';

  @override
  String get imageNotFound => 'Image not found';

  @override
  String get clickToBrowseArtwork => 'Click to browse or drop an image';

  @override
  String get dropImageHere => 'Drop image here';

  @override
  String get removeArtwork => 'Remove Artwork';

  @override
  String get removeArtworkConfirm =>
      'Remove this artwork? The image file will be deleted.';

  @override
  String get noFilesAddedYet =>
      'No files added yet.\nClick \"Add Files\" to upload release files.';

  @override
  String get noTodosYet => 'No todos yet. Add one above.';

  @override
  String get done => 'Done';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get backupTabLabel => 'Backup';

  @override
  String get aboutTabLabel => 'About';

  @override
  String get localBackup => 'Local Backup';

  @override
  String get appearanceTabLabel => 'Appearance';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get exportProjectInfo => 'Export Info';

  @override
  String get exportProjectInfoTooltip =>
      'Save this project\'s info to a text file';

  @override
  String get exportAllProjectsInfo => 'Export All Projects to TXT';

  @override
  String get exportAllProjectsInfoSubtitle =>
      'Save a plain text record of every project\'s info, so it\'s kept even if you delete the DAW file later';

  @override
  String get projectInfoExported => 'Project info exported';

  @override
  String allProjectsInfoExported(int count) {
    return 'Exported info for $count projects';
  }

  @override
  String failedToExportProjectInfo(String error) {
    return 'Failed to export project info: $error';
  }

  @override
  String get projectExportHeaderTitle => 'DAW PROJECT MANAGER — PROJECT EXPORT';

  @override
  String projectExportExportedLabel(String dateTime) {
    return 'Exported: $dateTime';
  }

  @override
  String projectExportTotalProjectsLabel(int count) {
    return 'Total projects: $count';
  }

  @override
  String projectExportProjectLabel(String name) {
    return 'Project: $name';
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
    return 'Status: $status';
  }

  @override
  String projectExportBpmLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String projectExportKeyLabel(String key) {
    return 'Key: $key';
  }

  @override
  String projectExportKeyWithCamelotLabel(String key, String code) {
    return 'Key: $key (Camelot $code)';
  }

  @override
  String projectExportFilePathLabel(String path) {
    return 'File path: $path';
  }

  @override
  String projectExportFileSizeLabel(String size) {
    return 'File size: $size';
  }

  @override
  String projectExportFileCreatedLabel(String date) {
    return 'File created: $date';
  }

  @override
  String projectExportAddedToLibraryLabel(String date) {
    return 'Added to library: $date';
  }

  @override
  String projectExportLastModifiedLabel(String date) {
    return 'Last modified: $date';
  }

  @override
  String projectExportDeadlineLabel(String date) {
    return 'Deadline: $date';
  }

  @override
  String projectExportDeadlineWithStatusLabel(String date, String status) {
    return 'Deadline: $date ($status)';
  }

  @override
  String projectExportTotalTimeWorkedLabel(String duration) {
    return 'Total time worked: $duration';
  }

  @override
  String get projectExportNotesLabel => 'Notes:';

  @override
  String get projectExportTodosLabel => 'To-dos:';

  @override
  String projectExportWorkSessionsLabel(int count) {
    return 'Work sessions ($count):';
  }

  @override
  String get noProjectsToExport => 'No projects to export';

  @override
  String get backupExportedSuccessfully => 'Backup exported successfully';

  @override
  String failedToExportBackup(String error) {
    return 'Failed to export backup: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup imported successfully: $projectsCount projects, $rootsCount project folders, $releasesCount releases';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Failed to import backup: $error';
  }

  @override
  String get importBackupMessage => 'Choose how to import the backup:';

  @override
  String get mergeWithCurrentProfile => 'Merge with current active profile';

  @override
  String get replaceCurrentProfile =>
      'Replace entirely the current profile (WARNING: This will delete all current profile data)';

  @override
  String get createNewProfileForImport => 'Create a new profile for this data';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup imported to new profile \"$profileName\": $projectsCount projects, $rootsCount project folders, $releasesCount releases';
  }

  @override
  String get noProfileSelected => 'No profile selected';

  @override
  String get exportBackupDialogTitle => 'Export Backup';

  @override
  String get importBackupDialogTitle => 'Import Backup';

  @override
  String get invalidBackupFileFormat =>
      'Invalid backup file format: missing version';

  @override
  String get profileNameRequiredForNewProfile =>
      'Profile name is required when creating a new profile';

  @override
  String get currentProfileRequired =>
      'Current profile is required for merge or replace mode';

  @override
  String get previewSong => 'Preview Song';

  @override
  String get noPreviewSongTitle => 'No Preview Song';

  @override
  String get noPreviewSongMessage =>
      'This project has no preview song set. Select an audio file to load and play it.';

  @override
  String get noPreviewSongDragHint =>
      'You can also drag and drop an audio file directly onto the project row in the table.';

  @override
  String get previewSongRemoved => 'Preview song removed';

  @override
  String get previewSongAdded => 'Preview song added';

  @override
  String get previewSongFileNotFound => 'Preview song file not found';

  @override
  String get previewSongFileNotFoundMessage =>
      'The preview song file could not be found on disk. Would you like to select a new file or remove the entry?';

  @override
  String get selectNewFile => 'Select New File';

  @override
  String failedToPlayPreview(String error) {
    return 'Failed to play preview: $error';
  }

  @override
  String get removePreviewSong => 'Remove preview song';

  @override
  String get removePreviewSongConfirm =>
      'Are you sure you want to remove the preview song? This action cannot be undone.';

  @override
  String get noPreviewSongSelected => 'No preview song selected';

  @override
  String get changePreviewSong => 'Change Preview Song';

  @override
  String get selectPreviewSong => 'Select Preview Song';

  @override
  String get dropAudioFileHere => 'Drop audio file here';

  @override
  String projectAge(String age) {
    return 'Project age: $age';
  }

  @override
  String createdDate(String date) {
    return 'created $date';
  }

  @override
  String completedIn(String duration) {
    return 'Completed in: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'finished $date';
  }

  @override
  String get dateToday => 'today';

  @override
  String get dateYesterday => 'yesterday';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
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
    return '$years year$yearPlural, $months month$monthPlural';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years year$plural';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months month$monthPlural, $days day$dayPlural';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months month$plural';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days day$plural';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours hour$plural';
  }

  @override
  String get ageJustNow => 'Just now';

  @override
  String get ageLessThanHour => 'Less than an hour';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get googleDriveSync => 'Google Drive Sync';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Sync your data with Google Drive to backup and restore across devices.';

  @override
  String get manageGoogleDriveSync => 'Manage Google Drive Sync';

  @override
  String get signInToGoogleDrive => 'Sign in to Google Drive';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get uploadBackup => 'Upload Backup';

  @override
  String get downloadBackup => 'Download Backup';

  @override
  String get newerBackupAvailable => 'New backup available on cloud';

  @override
  String get restoreProjectFromDrive => 'Restore from Drive';

  @override
  String get restoringProjectFromDrive => 'Restoring from Drive...';

  @override
  String get projectRestoredFromDrive => 'Project restored from Drive';

  @override
  String get projectNotFoundInBackup =>
      'This project was not found in the Drive backup';

  @override
  String get signInToGoogleDriveFirst =>
      'Please sign in to Google Drive first (open Drive Sync settings)';

  @override
  String get signOut => 'Sign Out';

  @override
  String get downloadPreviewSongs => 'Download preview songs';

  @override
  String get downloadPreviewSongsExplanation =>
      'If unchecked, preview songs will be skipped (saves time and storage). You can download them later if needed.';

  @override
  String get replaceLocalData => 'Replace Local Data';

  @override
  String get downloadBackupConfirmation =>
      'This will replace your local data with the backup from Google Drive.\n\nAre you sure you want to continue?';

  @override
  String get enterAuthorizationCode => 'Enter Authorization Code';

  @override
  String get authorizationCode => 'Authorization Code';

  @override
  String get pasteCodeFromBrowser => 'Paste the code from the browser';

  @override
  String get sessionActive => 'Session active';

  @override
  String get signedIn => 'Signed in';

  @override
  String get creatingInitialBackup => 'Creating initial backup...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Successfully signed in and backed up to Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Successfully signed in and backed up to Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Successfully signed in to Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Successfully signed in to Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Sign in cancelled or failed. Check console for details.';

  @override
  String get failedToLaunchBrowser => 'Failed to launch browser';

  @override
  String get signInCancelled => 'Sign in cancelled';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Failed to exchange authorization code';

  @override
  String errorSigningIn(String error) {
    return 'Error signing in: $error';
  }

  @override
  String get unknownError => 'Unknown error';

  @override
  String get googleSignInError => 'Google Sign-In Error';

  @override
  String get developerConsoleNotSetUp =>
      'Developer console is not set up correctly. Please check your OAuth configuration in Google Cloud Console.';

  @override
  String get platformError => 'Platform Error';

  @override
  String get signedOutFromGoogleDrive => 'Signed out from Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get syncing => 'Syncing...';

  @override
  String get errorNoProfileSelected => 'Error: No profile selected';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Sync completed! Projects: +$projectsAdded ~$projectsUpdated, Releases: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Error syncing: $error';
  }

  @override
  String get uploadingBackup => 'Uploading backup...';

  @override
  String get backupUploadedSuccessfully => 'Backup uploaded successfully!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Backup uploaded successfully to Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Error uploading backup: $error';
  }

  @override
  String get downloadingBackup => 'Downloading backup...';

  @override
  String get checkingForBackup => 'Checking for backup...';

  @override
  String get backupUpToDate => 'Backup is up to date';

  @override
  String errorCheckingBackup(String error) {
    return 'Error checking backup: $error';
  }

  @override
  String get download => 'Download';

  @override
  String get remoteBackupIsNewer =>
      'Remote backup is newer than local data. Uploading will overwrite it.';

  @override
  String get confirmUpload => 'Confirm Upload';

  @override
  String get noBackupFileFound =>
      'No backup file found in Google Drive. Create a backup first by syncing your data.';

  @override
  String get noBackupFileFoundStatus =>
      'No backup file found. Create a backup first.';

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Backup downloaded! Projects: +$projectsAdded ~$projectsUpdated, Releases: +$releasesAdded ~$releasesUpdated';
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
    return 'Backup downloaded!\n\nProjects:\n  • $projectsAdded added\n  • $projectsUpdated updated\n\nReleases:\n  • $releasesAdded added\n  • $releasesUpdated updated\n\nPreview Songs:\n  • $previewSongsDownloaded downloaded\n  • $previewSongsUpdated updated';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Error downloading backup: $error';
  }

  @override
  String get notSignedInYet => 'Not signed in';

  @override
  String get never => 'Never';

  @override
  String signedInAs(String email) {
    return 'Signed in as: $email';
  }

  @override
  String lastSync(String date) {
    return 'Last sync: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Remote backup: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Last upload: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Last download: $date';
  }

  @override
  String get checkForBackup => 'Check for Backup';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationsOnlyOnAndroid =>
      'Deadline notifications are only available on Android devices.';

  @override
  String get notificationPermissionRequired =>
      'Notification Permission Required';

  @override
  String get notificationPermissionDescription =>
      'Please enable notifications to receive deadline reminders.';

  @override
  String get notificationPermissionDenied =>
      'Notification permission denied. Please enable it in settings.';

  @override
  String get notificationSettingsSaved =>
      'Notification settings saved successfully';

  @override
  String get errorSavingSettings => 'Error saving settings';

  @override
  String get enableDeadlineNotifications => 'Enable Deadline Notifications';

  @override
  String get receiveRemindersForDeadlines =>
      'Receive reminders for project deadlines';

  @override
  String get notificationTime => 'Notification Time';

  @override
  String get timeToReceiveNotifications =>
      'Time of day to receive notifications';

  @override
  String get reminderDays => 'Reminder Days';

  @override
  String get selectDaysBeforeDeadline =>
      'Select how many days before the deadline you want to be notified';

  @override
  String get notifyOnDeadlineDay => 'Notify on Deadline Day';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Also receive a notification on the deadline day itself';

  @override
  String get howItWorks => 'How It Works';

  @override
  String get deadlineNotificationsHelp =>
      'You will receive notifications at the specified time on the selected days before each project deadline. Tap a notification to open the project details.';

  @override
  String get oneDay => '1 day';

  @override
  String xDays(int count) {
    return '$count days';
  }

  @override
  String get settings => 'Settings';

  @override
  String get searchSettings => 'Search settings';

  @override
  String noSettingsFoundFor(String query) {
    return 'No settings found for \"$query\"';
  }

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get languageSettingDescription =>
      'The language used throughout the app.';

  @override
  String get themeSettingDescription => 'The app\'s color theme.';

  @override
  String get waveformStyle => 'Waveform Style';

  @override
  String get waveformStyleSettingDescription =>
      'How the audio preview waveform is drawn.';

  @override
  String get waveformStyleDetailed => 'Detailed';

  @override
  String get waveformStyleDetailedDescription =>
      'Per-pixel bars with a shaded body, like a DAW.';

  @override
  String get waveformStyleClassic => 'Classic';

  @override
  String get waveformStyleClassicDescription => 'A single filled outline.';

  @override
  String get waveformChannels => 'Channels';

  @override
  String get waveformChannelsSettingDescription =>
      'Whether the waveform splits stereo into two lanes.';

  @override
  String get waveformChannelsSingle => 'Single';

  @override
  String get waveformChannelsDual => 'Dual';

  @override
  String get waveformChannelsSingleDescription =>
      'One lane showing the stereo mixdown.';

  @override
  String get waveformChannelsDualDescription =>
      'Left and right stacked as separate lanes.';

  @override
  String get waveformChannelsUnavailable => 'This file has only one channel';

  @override
  String get support => 'Support';

  @override
  String get shareDiagnosticLog => 'Share Diagnostic Log';

  @override
  String get shareDiagnosticLogEmpty => 'No diagnostic log yet';

  @override
  String get shareDiagnosticLogFolderOpened =>
      'Sharing isn\'t available here — opened the log folder instead so you can attach the file manually.';

  @override
  String get enableDiagnosticLogging => 'Enable Diagnostic Logging';

  @override
  String get enableDiagnosticLoggingDescription =>
      'Keeps a small log of crashes and errors on this device, so you can share it if something goes wrong. Off by default.';

  @override
  String get clearDiagnosticLog => 'Clear Diagnostic Log';

  @override
  String get clearDiagnosticLogConfirmTitle => 'Clear Diagnostic Log?';

  @override
  String get clearDiagnosticLogConfirmMessage =>
      'This will permanently delete the diagnostic log file. This can\'t be undone.';

  @override
  String get diagnosticLogCleared => 'Diagnostic log cleared';

  @override
  String get supportTheProject => 'Support the project';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Could not open browser. Please visit: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Error opening browser: $error';
  }

  @override
  String get generateTestingDatabase => 'Generate Testing Database';

  @override
  String get generateTestingDatabaseMessage =>
      'This will create (or refresh) a dedicated \"Demo — Screenshots\" profile filled with a large variety of sample projects, releases, and playlists across every supported DAW, and switch you to it. Your other profiles are left untouched. Continue?';

  @override
  String get testingDatabaseGenerated => 'Demo profile ready — switched to it!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Failed to generate testing database: $error';
  }

  @override
  String get removeTestingDatabase => 'Remove Testing Database';

  @override
  String get removeTestingDatabaseMessage =>
      'This will permanently delete the \"Demo — Screenshots\" profile and all of its sample projects, releases, playlists, and preview audio files. Continue?';

  @override
  String get testingDatabaseRemoved => 'Demo data removed.';

  @override
  String get noTestingDatabaseFound => 'No demo data found to remove.';

  @override
  String failedToRemoveTestingDatabase(String error) {
    return 'Failed to remove testing database: $error';
  }

  @override
  String get playlists => 'Playlists';

  @override
  String get playlistsDesktopOnly => 'Playlists are only available on Android.';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get createFirstPlaylist =>
      'Tap the + button to create your first playlist';

  @override
  String playlistSongCount(int count) {
    return '$count songs';
  }

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get playlistNameHint => 'My Playlist';

  @override
  String get playlistNameRequired => 'Playlist name is required';

  @override
  String get editPlaylist => 'Edit Playlist';

  @override
  String get stopPlaybackBeforeEditing =>
      'Please stop playback before editing the playlist';

  @override
  String get selectPreviewSongs => 'Select Preview Songs';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get playlistDeleted => 'Playlist deleted';

  @override
  String get errorDeletingPlaylist => 'Error deleting playlist';

  @override
  String get playlistUpdated => 'Playlist updated';

  @override
  String get changeSong => 'Change Song';

  @override
  String get changeSongConfirm =>
      'A song is currently playing. Do you want to switch to this song?';

  @override
  String get changeSongButton => 'Change';

  @override
  String playlistProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get noPreviewSongsInPlaylist =>
      'No preview songs available in this playlist';

  @override
  String get tapEditToAddSongs => 'Tap edit to add songs to this playlist';

  @override
  String get noProjectsAvailableForPlaylist =>
      'No projects with preview songs available to add';

  @override
  String get noProjectsInDatabase =>
      'No projects found in database. Please sync your projects first.';

  @override
  String get firstTimeSyncTitle => 'It seems it\'s your first time here!';

  @override
  String get firstTimeSyncMessage =>
      'Let\'s sync your data from Google Drive to get started';

  @override
  String get syncWithGoogleDrive => 'Sync with Google Drive';

  @override
  String get errorLoadingPlaylists => 'Error loading playlists';

  @override
  String get playlistItems => 'Playlist Items';

  @override
  String get addSongs => 'Add Songs';

  @override
  String get addAudioFiles => 'Add Audio Files';

  @override
  String get selectAudioFiles => 'Select Audio Files';

  @override
  String get selectFromProjects => 'Select from Projects';

  @override
  String get add => 'Add';

  @override
  String get addTaskAtTimestamp => 'Add task at current time';

  @override
  String get taskDescriptionHint => 'Task description';

  @override
  String get taskAdded => 'Task added';

  @override
  String get fromProject => 'From Project';

  @override
  String get projectDeadline => 'Project Deadline';

  @override
  String get noDeadlineSet => 'No deadline set';

  @override
  String get camelotCode => 'Camelot Code';

  @override
  String get deadline => 'Deadline';

  @override
  String get dueToday => 'Due today';

  @override
  String daysLate(int days) {
    return '${days}d late';
  }

  @override
  String daysLeft(int days) {
    return '${days}d left';
  }

  @override
  String get hideFinished => 'Hide Finished';

  @override
  String get showOnlyDeadlines => 'Show Deadline';

  @override
  String get filterByDeadline => 'Filter by Deadline';

  @override
  String get allDeadlines => 'All Deadlines';

  @override
  String get hasDeadline => 'Has Deadline';

  @override
  String get overdue => 'Overdue';

  @override
  String get dueSoon => 'Due Soon (7d)';

  @override
  String get today => 'Today';

  @override
  String get noPreviewSong => 'No preview song';

  @override
  String get playPreview => 'Play Preview';

  @override
  String get uploadCancelled => 'Upload cancelled';

  @override
  String get backupUploadCancelledByUser => 'Backup upload cancelled by user';

  @override
  String get collectingData => 'Collecting data...';

  @override
  String get uploadingPreviewSongs => 'Uploading preview songs...';

  @override
  String get uploadingProfilePhotos => 'Uploading profile photos...';

  @override
  String get uploadingReleaseArtwork => 'Uploading release artwork...';

  @override
  String get uploadingDatabase => 'Uploading database...';

  @override
  String get completed => 'Completed!';

  @override
  String get cancelling => 'Cancelling...';

  @override
  String get uploadingBackupTitle => 'Uploading Backup';

  @override
  String get cancellingUpload => 'Cancelling upload...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Please wait while we stop the upload...';

  @override
  String get downloadingDatabase => 'Downloading database...';

  @override
  String get downloadingPreviewSongs => 'Downloading preview songs...';

  @override
  String get downloadingProfilePhotos => 'Downloading profile photos...';

  @override
  String get downloadingReleaseArtwork => 'Downloading release artwork...';

  @override
  String get mergingData => 'Merging data...';

  @override
  String get downloadingBackupTitle => 'Downloading Backup';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Source file not found on this machine';

  @override
  String get metadataExtractionNotSupportedForDaw =>
      'Metadata extraction is not supported for this DAW';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Source file not found on this machine — metadata-only mode. You can still edit and export metadata.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Preview song not available. Please download backup first.';

  @override
  String get sharePreviewSong => 'Share preview song';

  @override
  String get shareAsZip => 'Share as ZIP';

  @override
  String get share => 'Share';

  @override
  String get convertingAudioForSharing => 'Preparing audio for sharing…';

  @override
  String get shareSheetUnavailable =>
      'The system share menu isn\'t available here — use the \"Drag to Share\" chip on the song preview to drag the file onto another app instead.';

  @override
  String get dragToShare => 'Drag to Share';

  @override
  String get dragToShareTooltip =>
      'Drag this onto another app\'s window (e.g. WhatsApp) to share the file directly — useful when the Share button doesn\'t open a share menu.';

  @override
  String get mp3ConversionFailed =>
      'Audio conversion isn\'t available on this system — sharing the original file, which some apps like WhatsApp may reject.';

  @override
  String get shareZip => 'Share ZIP';

  @override
  String get saveCopy => 'Save a copy';

  @override
  String savedCopyTo(String path) {
    return 'Saved to $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Failed to share preview song: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Failed to share preview song as ZIP: $error';
  }

  @override
  String get biographySaved => 'Biography saved';

  @override
  String failedToSaveBiography(String error) {
    return 'Failed to save biography: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'File saved to $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Failed to download file: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'All files saved to $filename';
  }

  @override
  String get artworkAdded => 'Artwork added';

  @override
  String failedToAddArtwork(String error) {
    return 'Failed to add artwork: $error';
  }

  @override
  String get artworkRemoved => 'Artwork removed';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Failed to remove artwork: $error';
  }

  @override
  String get pressKitFileAdded => 'Press kit file added';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Failed to add press kit file: $error';
  }

  @override
  String get pressKitFileRemoved => 'Press kit file removed';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Failed to remove press kit file: $error';
  }

  @override
  String get selectFilesToDownload => 'Select Files to Download';

  @override
  String get biography => 'Biography';

  @override
  String get biographyWillBeSaved => 'Will be saved as biography.txt';

  @override
  String get artworkFiles => 'Artwork Files';

  @override
  String get pressKitFiles => 'Press Kit Files';

  @override
  String get additionalAssets => 'Additional Assets';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Download $count file$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count file$plural saved to $filename';
  }

  @override
  String get addAsset => 'Add Asset';

  @override
  String get assetNameLabel => 'Asset Name';

  @override
  String get assetNameHint => 'e.g., Logo, Banner, Photo';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName added successfully';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Failed to add asset: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName removed';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Failed to remove asset: $error';
  }

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get downloadFilesSectionTitle => 'Download Files';

  @override
  String get downloadFilesSectionDescription =>
      'Download all of this profile\'s files — biography, artwork, press kit, and additional assets — as a single ZIP, or select which ones to include.';

  @override
  String get selectFiles => 'Select Files';

  @override
  String get downloadAll => 'Download All';

  @override
  String get saveBiographyTooltip => 'Save Biography';

  @override
  String get enterBiographyHint => 'Enter profile biography...';

  @override
  String get addArtwork => 'Add Artwork';

  @override
  String get addFile => 'Add File';

  @override
  String get openFile => 'Open File';

  @override
  String get menuView => 'View';

  @override
  String get menuAbout => 'About DAW Project Manager';

  @override
  String get menuDocumentation => 'Documentation';

  @override
  String get menuLanguage => 'Language';

  @override
  String get menuWarnBeforeQuit => 'Warn Before Quitting (⌘+Q)';

  @override
  String get menuQuit => 'Quit DAW Project Manager';

  @override
  String get quitConfirmTitle => 'Quit DAW Project Manager?';

  @override
  String get quitConfirmMessage => 'Are you sure you want to quit?';

  @override
  String get quit => 'Quit';

  @override
  String get trayNoticeTitle => 'Still running in the background';

  @override
  String get trayNoticeBody =>
      'DAW Project Manager was minimized to the system tray. Use the tray icon to reopen or quit it.';

  @override
  String get trayShowWindow => 'Show DAW Project Manager';

  @override
  String trayLastBackup(String when) {
    return 'Last backup: $when';
  }

  @override
  String get trayNeverBackedUp => 'Never backed up';

  @override
  String get trayBackupNow => 'Back Up Now';

  @override
  String get trayPauseSession => 'Pause Session';

  @override
  String get trayResumeSession => 'Resume Session';

  @override
  String get closeToTray => 'Close to tray';

  @override
  String get closeToTrayDescription =>
      'Keep running in the background (tray icon) when you close the window, so auto-backup and notifications keep working';

  @override
  String get autoStart => 'Launch at startup';

  @override
  String get autoStartDescription =>
      'Open DAW Project Manager automatically when you sign in to your computer';

  @override
  String get startMinimized => 'Start minimized to tray';

  @override
  String get startMinimizedDescription =>
      'When the app starts with your computer, open it hidden in the tray instead of showing the window';

  @override
  String get onboardingStartMinimized => 'Start minimized';

  @override
  String get autoStartFailed =>
      'Could not change the startup setting. Your system may not allow it.';

  @override
  String get onboardingStartupTitle => 'Launch at Startup';

  @override
  String get onboardingStartupBody =>
      'Have DAW Project Manager open automatically when you sign in, so background backups and deadline reminders keep running.';

  @override
  String get menuWindow => 'Window';

  @override
  String get donate => 'Donate';

  @override
  String get website => 'Website';

  @override
  String get license => 'License';

  @override
  String get reportIssue => 'Report an Issue';

  @override
  String get switchToClassicDark => 'Switch to Classic Dark';

  @override
  String get switchToNeonDark => 'Switch to Neon Dark';

  @override
  String get switchToClassicTheme => 'Switch to Classic Theme';

  @override
  String get switchToNeonTheme => 'Switch to Neon Theme';

  @override
  String get switchToStudioLight => 'Switch to Studio Light';

  @override
  String get menuTheme => 'Theme';

  @override
  String get appDescription =>
      'A project manager for music producers and sound designers.';

  @override
  String get neonDarkThemeName => 'Neon Dark';

  @override
  String get classicDarkThemeName => 'Classic Dark';

  @override
  String get studioLightThemeName => 'Studio Light';

  @override
  String get statisticsTab => 'Statistics';

  @override
  String get statsTotalProjects => 'Total Projects';

  @override
  String get statsInProgress => 'In Progress';

  @override
  String get statsFinished => 'Finished';

  @override
  String get statsAvgCompletion => 'Avg. Completion';

  @override
  String get statsPhaseDistribution => 'Projects by Phase';

  @override
  String get statsAvgTimePerPhase => 'Avg. Days per Phase';

  @override
  String get statsProductivity => 'Productivity';

  @override
  String get statsCreatedSeries => 'Created';

  @override
  String get statsProjectHealth => 'Project Age & Health';

  @override
  String get statsCatalogInsights => 'Catalog Insights';

  @override
  String get statsBpmDistribution => 'BPM Distribution';

  @override
  String get statsTopKeys => 'Top Musical Keys';

  @override
  String get statsDawTypes => 'DAW Types';

  @override
  String get statsProjectActivity => 'Project Activity';

  @override
  String get statsSingleProjectActivity => 'Project Activity';

  @override
  String get statsNoData => 'No data yet';

  @override
  String get statsNoPhaseData =>
      'Phase data will appear after projects move between phases.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Last activity: $days days ago';
  }

  @override
  String get statsLastActivityToday => 'Active today';

  @override
  String get statsNoEvents => 'No events recorded yet';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Phase: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Updated: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Completed: $text';
  }

  @override
  String get statsEventFileModified => 'File modified on disk';

  @override
  String get statsClearHistory => 'Clear history';

  @override
  String get statsClearHistoryConfirm =>
      'Clear all recorded events for this project?';

  @override
  String get statsSearchProjects => 'Search projects…';

  @override
  String statsEventCount(int count) {
    return '$count events';
  }

  @override
  String get statsViewHistory => 'Project Statistics';

  @override
  String get statsPhaseHistory => 'Phase History';

  @override
  String get statsEventBreakdown => 'Event Breakdown';

  @override
  String statsDaysSoFar(int days) {
    return '${days}d so far';
  }

  @override
  String get statsNoProjectsFound => 'No projects found';

  @override
  String statsNotTouchedDays(int days) {
    return 'Not touched in $days days';
  }

  @override
  String get sortByLastModified => 'Last modified';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByPhase => 'Phase';

  @override
  String get sortByCreatedAt => 'Date added';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get sortNewestFirst => 'Newest first';

  @override
  String get sortOldestFirst => 'Oldest first';

  @override
  String get sortTitleAZ => 'Title A–Z';

  @override
  String get sortTitleZA => 'Title Z–A';

  @override
  String get musicPlayerTab => 'Music Player';

  @override
  String get previewAudioChangedRefreshing =>
      'Preview audio changed on disk — refreshing waveform…';

  @override
  String get audioFileChangedRefreshing =>
      'Audio file changed on disk — refreshing waveform…';

  @override
  String get autoFitAllColumns => 'Auto-resize columns';

  @override
  String get uploadAutoDetectedPreviewSongs =>
      'Upload auto-detected preview songs';

  @override
  String get uploadAutoDetectedPreviewSongsSubtitle =>
      'Include songs found automatically by the scanner, not just ones you set manually.';

  @override
  String get monoGenerating => 'Mono...';

  @override
  String errorHandlingDroppedFiles(String error) {
    return 'Error handling dropped files: $error';
  }

  @override
  String get resetOnboardingConfirm =>
      'This will restart the setup wizard. Continue?';

  @override
  String couldNotLaunchDaw(String daw, String error) {
    return 'Could not launch $daw: $error';
  }

  @override
  String get couldNotOpenLink => 'Could not open link.';

  @override
  String get githubButtonLabel => 'GitHub';

  @override
  String get monoLabel => 'Mono';

  @override
  String get monoToggleTooltip => 'Toggle mono playback';

  @override
  String get monoRequiresWav => 'Mono mixing requires a WAV file';

  @override
  String get monoUnsupportedFormat =>
      'Could not create mono mix — unsupported format';

  @override
  String monoSwitchFailed(String error) {
    return 'Mono switch failed: $error';
  }

  @override
  String get analyzeLabel => 'Analyze';

  @override
  String get reAnalyzeLabel => 'Re-analyze';

  @override
  String get analysisRequiresWav => 'Analysis requires a WAV file';

  @override
  String get noResultsForFilter => 'No results for current filter';

  @override
  String get noResultsForFilterHint =>
      'Try adjusting your search or filters to find projects.';

  @override
  String get noProjectsFound => 'No projects found';

  @override
  String get noProjectsFoundHint =>
      'Add a scan folder in settings to get started.';

  @override
  String get noProjectsFoundInFoldersHint =>
      'Try adding another folder that contains DAW projects.';

  @override
  String get queueTab => 'Tasks';

  @override
  String get queueSearchHint => 'Search tasks...';

  @override
  String get queueNoPendingTasks => 'All caught up!';

  @override
  String get queueNoPendingTasksHint =>
      'No pending tasks across your projects.';

  @override
  String get queueNoMatchingTasks => 'No matching tasks';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks pending tasks in $projects projects';
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
  String get renameProjectFileTitle => 'Rename Project File';

  @override
  String get renameFileButtonLabel => 'Rename File';

  @override
  String get newFileNameLabel => 'New file name (without extension)';

  @override
  String renameAlreadyExists(String name) {
    return 'A file named \"$name\" already exists.';
  }

  @override
  String renameSuccess(String name) {
    return 'Renamed to \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Failed to rename: $error';
  }

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get nameInvalidCharacters => 'Name cannot contain / \\ :';

  @override
  String get alsoRenameContainingFolder => 'Also rename containing folder';

  @override
  String get renameButton => 'Rename';

  @override
  String get previewMixdownFolderTitle => 'Preview Mixdown Folders';

  @override
  String get previewMixdownFolderSubtitle =>
      'Subfolder names inside each project folder to check first, in order, when auto-detecting preview songs. Leave empty to use DAW defaults.';

  @override
  String get previewMixdownFolderHint => 'e.g. Mixdowns';

  @override
  String get mixdownFoldersInfoTooltip => 'How this works';

  @override
  String get mixdownFoldersInfoDialogTitle => 'How preview detection works';

  @override
  String get mixdownFoldersInfoDialogBody =>
      'When a project has no manually chosen preview song, the app looks for the most recently modified audio file to use as a preview. It checks your custom folders below first, in order, then falls back to a list of default folder names based on the project\'s DAW.';

  @override
  String get mixdownFoldersDawDefaultsHeading =>
      'Default folders checked per DAW';

  @override
  String get mixdownFoldersOtherDawLabel => 'Other / unrecognized DAW';

  @override
  String get addMixdownFolder => 'Add';

  @override
  String get noCustomMixdownFolders =>
      'No custom folders added — DAW defaults will be used.';

  @override
  String get mixdownFoldersTabLabel => 'Mixdown Folders';

  @override
  String get mixdownFoldersSectionDescription =>
      'Controls which folder the app looks in for a project\'s exported/bounced audio, used as its preview song when none is set manually. Expand a DAW below to see the folder names it already checks by default, and add your own on top of them if your setup uses a different name.';

  @override
  String get mixdownFoldersDefaultsLabel => 'Default folders checked:';

  @override
  String get mixdownFoldersCustomLabel => 'Your additions for this DAW:';

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
    return 'Key: $key';
  }

  @override
  String get audioFileNotFound => 'Audio file not found';

  @override
  String errorPlayingAudio(String error) {
    return 'Error playing audio: $error';
  }

  @override
  String get notificationTestTitle =>
      'Test notifications to verify timezone and scheduling:';

  @override
  String get notificationSendNow => 'Send Now';

  @override
  String get notificationSchedule30s => 'Schedule +30s';

  @override
  String get notificationShowDebugInfo => 'Show Debug Info';

  @override
  String get notificationRescheduleAll => 'Re-schedule All';

  @override
  String get notificationTestSent => '✅ Test notification sent!';

  @override
  String get notificationTestScheduled =>
      '✅ Test notification scheduled for 30 seconds! Check console logs.';

  @override
  String notificationTestError(String error) {
    return '❌ Error: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Debug Information';

  @override
  String get autoDetected => 'Auto-detected';

  @override
  String get matchedInDescription => 'Matched in description';

  @override
  String get matchedInProjectNotes => 'Matched in DAW project notes';

  @override
  String get relocateFolderDialogTitle => 'Relocate Folder';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count project paths updated',
      one: '1 project path updated',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Customize Tabs';

  @override
  String get alwaysVisible => '(always visible)';

  @override
  String get customizeTabsDescription =>
      'Choose which tabs to show in the navigation bar. The Projects tab is always visible.';

  @override
  String get keyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get shortcutGroupGlobal => 'Global';

  @override
  String get shortcutGroupProjectsTable =>
      'Projects Table (table must be focused)';

  @override
  String get shortcutGroupReleasesTable =>
      'Releases Table (table must be focused)';

  @override
  String get shortcutGroupNavigation => 'Navigation';

  @override
  String get shortcutFocusSearch => 'Focus search bar';

  @override
  String get shortcutRescan => 'Rescan project folders';

  @override
  String get shortcutFocusTable => 'Focus projects table';

  @override
  String get shortcutPlayPause => 'Play / pause preview song';

  @override
  String get shortcutOpenInDaw => 'Open project in DAW';

  @override
  String get shortcutViewDetails => 'View project details';

  @override
  String get shortcutOpenFolder => 'Open project folder';

  @override
  String get shortcutNavigateRows => 'Navigate rows';

  @override
  String get shortcutEditCell => 'Open project details';

  @override
  String get shortcutViewRelease => 'View release details';

  @override
  String get shortcutGoBack => 'Go back';

  @override
  String get shortcutGroupProjectsTableStandardMode => 'Standard mode';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'Session mode';

  @override
  String get shortcutToggleSession => 'Start / End session';

  @override
  String get shortcutGroupPreviewPlayer => 'Preview Player';

  @override
  String get shortcutPlayerPlayPause => 'Play / pause';

  @override
  String get shortcutPlayerSeek5 => 'Seek ±5 seconds';

  @override
  String get shortcutPlayerSeek30 => 'Seek ±30 seconds';

  @override
  String get startupDialogTitle => 'Welcome to DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Get started by adding your project folder or restoring a backup from Google Drive.';

  @override
  String get startupAddFolderTitle => 'Add Project Folder';

  @override
  String get startupAddFolderSubtitle =>
      'Select a folder containing your DAW projects.';

  @override
  String get startupGoogleDriveTitle => 'Sync Google Drive Backup';

  @override
  String get startupGoogleDriveSubtitle =>
      'Restore your projects from a Google Drive backup.';

  @override
  String get startupDontShowAgain => 'Don\'t show this on startup';

  @override
  String get pinnedLibraryWarningTitle => 'Test library in use';

  @override
  String get pinnedLibraryWarningBody =>
      'This build keeps its data in a separate test library, so it cannot touch the library your installed copy of the app uses. Projects, profiles and settings you change here will not appear there.';

  @override
  String get pinnedLibraryWarningLibraryLabel => 'Library';

  @override
  String get pinnedLibraryWarningLocationLabel => 'Location';

  @override
  String get pinnedLibraryWarningDontShowAgain =>
      'Don\'t warn me again for this library';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteAllDataSubtitle =>
      'Remove all profiles, projects, releases, playlists, and settings from this device.';

  @override
  String get deleteAllDataConfirm1Title => 'Delete All Data?';

  @override
  String get deleteAllDataConfirm1Message =>
      'This will permanently erase all profiles, projects, releases, playlists, and settings from this device. Your Google Drive backup (if any) will not be affected.';

  @override
  String get deleteAllDataConfirm2Title => 'Are you absolutely sure?';

  @override
  String get deleteAllDataConfirm2Message =>
      'This action cannot be undone. The app will return to its initial state.';

  @override
  String get deleteEverything => 'Delete Everything';

  @override
  String get allDataDeleted => 'All data has been deleted.';

  @override
  String get newerExportFound => 'Newer Export Found';

  @override
  String newerExportFoundMessage(String filename) {
    return 'A newer file was found in the same folder:\n$filename\n\nReplace the preview song?';
  }

  @override
  String get replaceAndPlay => 'Replace & Play';

  @override
  String get keepCurrent => 'Keep Current';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get autoBackupDescription =>
      'Automatically upload a backup to Google Drive at the selected interval.';

  @override
  String get autoBackupInterval => 'Backup interval';

  @override
  String get autoBackupOff => 'Off';

  @override
  String get autoBackupEvery30Min => 'Every 30 minutes';

  @override
  String get autoBackupHourly => 'Every hour';

  @override
  String get autoBackupEvery6Hours => 'Every 6 hours';

  @override
  String get autoBackupDaily => 'Daily';

  @override
  String autoBackupNextBackup(String time) {
    return 'Next backup: $time';
  }

  @override
  String get autoBackupNextSoon => 'soon';

  @override
  String autoBackupNextInMinutes(int count) {
    return 'in $count min';
  }

  @override
  String get autoBackupNextInOneHour => 'in 1 hour';

  @override
  String autoBackupNextInHours(int count) {
    return 'in $count hours';
  }

  @override
  String get autoBackupNextInOneDay => 'in 1 day';

  @override
  String autoBackupNextInDays(int count) {
    return 'in $count days';
  }

  @override
  String get playerTitle => 'Music Player';

  @override
  String get playerToggleQueue => 'Toggle queue';

  @override
  String get playerSearchHint => 'Search tracks…';

  @override
  String playerTrackCount(int count) {
    return '$count tracks';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'No preview songs found.\nOpen a project and set a preview song.';

  @override
  String playerNoTracksMatch(String query) {
    return 'No tracks match\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay => 'Double-click a track to start playing';

  @override
  String get playerSingleClickToPreview =>
      'Single-click to preview in the player bar below';

  @override
  String get playerQueueTitle => 'Queue';

  @override
  String get playerClearQueue => 'Clear queue';

  @override
  String get playerQueueEmptyHint =>
      'Double-click a track to start,\nor drag tracks here to queue.';

  @override
  String get playerPrev => 'Previous';

  @override
  String get playerNext => 'Next';

  @override
  String get playerGoToProject => 'Go to project';

  @override
  String get playerAddToQueue => 'Add to queue';

  @override
  String get playerRemoveFromQueue => 'Remove from queue';

  @override
  String get playerDismissDetail => 'Dismiss detail';

  @override
  String get playerNotes => 'NOTES';

  @override
  String get playerTasks => 'TASKS';

  @override
  String get playerNoTasks => 'No tasks yet.';

  @override
  String get playerAddTaskHint => 'Add a task…';

  @override
  String playerCompletedTasks(int count) {
    return '$count completed';
  }

  @override
  String get playerPreviousTrack => 'Previous track';

  @override
  String get playerNextTrack => 'Next track';

  @override
  String get playerOpenProject => 'Open project';

  @override
  String get playerRepeatAll => 'Repeat all';

  @override
  String get playerShuffle => 'Shuffle';

  @override
  String get volumeMute => 'Mute';

  @override
  String get volumeUnmute => 'Unmute';

  @override
  String totalWorkTime(String time) {
    return 'Total work: $time';
  }

  @override
  String sessionTime(String time) {
    return 'Session: $time';
  }

  @override
  String headerAgeOld(String age) {
    return '$age old';
  }

  @override
  String headerEdited(String when) {
    return 'edited $when';
  }

  @override
  String headerWorked(String time) {
    return '$time worked';
  }

  @override
  String get sessionHistory => 'Session History';

  @override
  String get noSessionsYet => 'No sessions recorded yet';

  @override
  String get removeSessionTitle => 'Remove session?';

  @override
  String get editSessionTitle => 'Edit session duration';

  @override
  String get editSessionHours => 'Hours';

  @override
  String get editSessionInvalid => 'Duration must be at least 1 minute';

  @override
  String get sessionTableDate => 'Date';

  @override
  String get sessionTableTime => 'Time';

  @override
  String get sessionTableDuration => 'Duration';

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
  String get sessionByPhase => 'Work by Phase';

  @override
  String get tabPosition => 'Tab position';

  @override
  String get tabPositionTop => 'Top';

  @override
  String get tabPositionLeft => 'Left';

  @override
  String updateAvailableMessage(String version) {
    return 'Version $version is available';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkForUpdatesDescription =>
      'Get notified when a new version of the app is available.';

  @override
  String get checkNow => 'Check now';

  @override
  String updateAvailable(String version) {
    return 'Update available: v$version';
  }

  @override
  String get upToDate => 'App is up to date';

  @override
  String get updateAvailableTitle => 'Update Available';

  @override
  String updateAvailableVersion(String version) {
    return 'A new version $version is ready.';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'You are running v$version.';
  }

  @override
  String get viewUpdateDetails => 'View Details';

  @override
  String get getOnMicrosoftStore => 'Get on Microsoft Store';

  @override
  String get downloadFromGitHub => 'Download from GitHub';

  @override
  String get updateWindowsInstructions =>
      'Open the Microsoft Store and update DAW Project Manager, or click the button below.';

  @override
  String get updateMacInstructions =>
      'Download the latest release from GitHub and replace the current app.';

  @override
  String get updateAppImageSourceLabel => 'AppImage';

  @override
  String get updateAppImageInstructions => 'Update in place and restart.';

  @override
  String get updateNowButtonLabel => 'Update Now';

  @override
  String get appImageUpdateFetching => 'Looking for the update…';

  @override
  String get appImageUpdateDownloading => 'Downloading update…';

  @override
  String appImageUpdateDownloadingProgress(int percent) {
    return 'Downloading update… $percent%';
  }

  @override
  String get appImageUpdateVerifying => 'Verifying and installing…';

  @override
  String get appImageUpdateReadyTitle => 'Update Ready';

  @override
  String appImageUpdateReadyMessage(String version) {
    return 'Updated to v$version. Restart now to finish.';
  }

  @override
  String get appImageUpdateRestartNow => 'Restart Now';

  @override
  String get appImageUpdateFailedTitle => 'Update Failed';

  @override
  String get appImageUpdateRetry => 'Retry';

  @override
  String get appImageUpdateErrorMessage =>
      'Something went wrong while updating. You can try again, or check the error details below.';

  @override
  String get appImageUpdateErrorDetailsLabel => 'Error Details';

  @override
  String get appImageUpdateCopyErrorDetails => 'Copy Error Details';

  @override
  String get appImageUpdateErrorDetailsCopied => 'Error details copied';

  @override
  String get resetOnboarding => 'Reset onboarding';

  @override
  String get onboardingWelcomeTitle => 'Welcome to DAW Project Manager';

  @override
  String get onboardingWelcomeBody =>
      'Organize all your music projects across every DAW in one place.';

  @override
  String get onboardingFeatureScanFolders =>
      'Scan DAW project folders automatically';

  @override
  String get onboardingFeatureTrackMetadata =>
      'Track BPM, key, status and deadlines';

  @override
  String get onboardingFeatureSyncDrive => 'Sync metadata to Google Drive';

  @override
  String get onboardingFeatureTrackTime => 'Track time spent on each project';

  @override
  String get onboardingLanguageTitle => 'Choose Your Language';

  @override
  String get onboardingThemeTitle => 'Choose a Theme';

  @override
  String get onboardingFoldersTitle => 'Add Project Folders';

  @override
  String get onboardingFoldersBody =>
      'Add the root folder where your DAW projects are stored.';

  @override
  String get onboardingDriveTitle => 'Google Drive Sync';

  @override
  String get onboardingDriveBody =>
      'Optionally back up and sync project metadata to Google Drive.';

  @override
  String get onboardingUpdatesTitle => 'Update Checks';

  @override
  String get onboardingUpdatesBody =>
      'Get notified when a new version is available.';

  @override
  String get onboardingDoneTitle => 'You\'re All Set!';

  @override
  String get onboardingDoneBody => 'Start exploring your projects.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get dawSession => 'DAW Session';

  @override
  String get clearDawSession => 'Clear session';

  @override
  String get stop => 'Stop';

  @override
  String get pause => 'Pause';

  @override
  String get playPauseTooltip => 'Play / Pause';

  @override
  String get resume => 'Resume';

  @override
  String get workTimerSection => 'Work Session Reminders';

  @override
  String get workTimerSectionDesc =>
      'Get notified periodically while you have an active work session';

  @override
  String get workTimerRequiresSessionMode =>
      'Enable Session Mode above to use work session reminders';

  @override
  String get workTimerEnabled => 'Enable work session reminders';

  @override
  String get workTimerIntervalLabel => 'Notify every';

  @override
  String get minutes => 'minutes';

  @override
  String workTimerNotifBody(String time) {
    return 'You have been working for $time';
  }

  @override
  String get sendTestNotification => 'Send Test Notification';

  @override
  String get testNotificationTitle => 'Test Notification';

  @override
  String get testNotificationBody =>
      'This is a test notification from DAW Project Manager.';

  @override
  String get general => 'General';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get lastModifiedColors => 'Last Modified date colors';

  @override
  String get lastModifiedColorsDescription =>
      'Colors the Last Modified date based on age and status. Green = Finished. Older dates fade from yellow to red — stronger red means the project hasn\'t been touched in longer.';

  @override
  String get sessionMode => 'Session mode';

  @override
  String get sessionModeDescription =>
      'Start a session on a project to track your work time and manage it from the toolbar';

  @override
  String get workSessionsTabLabel => 'Work Sessions';

  @override
  String get normalMode => 'Normal Mode';

  @override
  String get normalModeDescription =>
      'Projects open directly in their DAW when launched.';

  @override
  String get sessionModeCardDescription =>
      'Start a session to track your activity and time on the project.';

  @override
  String get startSession => 'Start Session';

  @override
  String get endSession => 'End session';

  @override
  String get switchSession => 'Switch session';

  @override
  String get switchSessionBody =>
      'Stop the current session and start a new one?';

  @override
  String switchSessionCurrent(String project) {
    return 'Current: $project';
  }

  @override
  String switchSessionNew(String project) {
    return 'New: $project';
  }

  @override
  String get sessionDuration => 'Session time';

  @override
  String get scanModeLabel => 'Scan mode:';

  @override
  String get scanModeSectionTitle => 'Scan Mode';

  @override
  String get scanModeSectionDescription =>
      'Controls how projects in each folder are displayed in the table — as a plain flat list or grouped by subfolder.';

  @override
  String get smartFolderOptionsSectionTitle => 'Smart Folder Options';

  @override
  String get smartFolderOptionsSectionDescription =>
      'Fine-tune how smart-folder groups behave in the Projects table.';

  @override
  String get excludeSmartFoldersFromSort => 'Keep smart folders out of sorting';

  @override
  String get excludeSmartFoldersFromSortDescription =>
      'When you sort the Projects table by a column, smart-folder groups stay in place instead of moving with the sort — only the projects inside them (and any ungrouped projects) get reordered. Experimental: off by default.';

  @override
  String get mergeSmartFoldersByName =>
      'Merge smart folders with the same name';

  @override
  String get mergeSmartFoldersByNameDescription =>
      'When two scan roots (e.g. different DAWs) have a top-level folder with the same name, treat them as a single merged group in the Projects table instead of two separate ones.';

  @override
  String get alwaysShowSmartFolders => 'Always show smart folders';

  @override
  String get alwaysShowSmartFoldersDescription =>
      'Show a smart folder as its own group row even when only one of its projects is currently visible (e.g. after a search or filter), instead of collapsing it into a plain ungrouped row.';

  @override
  String get scanModeFlat => 'Flat';

  @override
  String get scanModeSmartFolder => 'Smart Folder';

  @override
  String get scanModeFlatDescription =>
      'Shows every project as a flat list. Simple and fast.';

  @override
  String get scanModeSmartFolderDescription =>
      'Groups projects by folder when a folder contains more than one project.';

  @override
  String get skip => 'Skip';

  @override
  String get suggestionsLabel => 'Suggestions';

  @override
  String get suggestionsRefresh => 'Refresh';

  @override
  String get suggestionsEmptyState =>
      'No suggestions right now. Tap Refresh to reset dismissed items.';

  @override
  String get suggestionNewProject => 'New';

  @override
  String get showSuggestions => 'Show suggestions';

  @override
  String get showSuggestionsDescription =>
      'Show smart suggestions in the toolbar when no session is running';

  @override
  String get onboardingSuggestionsTitle => 'Smart Suggestions';

  @override
  String get onboardingSuggestionsBody =>
      'Get personalized project recommendations in the toolbar while you work';

  @override
  String get onboardingSessionModeTitle => 'Session Mode';

  @override
  String get onboardingSessionModeBody =>
      'Start focused work sessions and automatically track time spent on each project';

  @override
  String get suggestionsFeatureDeadlines =>
      'Deadline reminders for upcoming projects';

  @override
  String get suggestionsFeatureResume =>
      'Resume the last project you worked on';

  @override
  String get suggestionsFeatureRecentlyModified =>
      'Continue recently modified tracks';

  @override
  String get suggestionsEnableToggle => 'Enable smart suggestions';

  @override
  String get canBeChangedInSettings => 'Can be changed later in Settings';

  @override
  String get next => 'Next';

  @override
  String get createProject => 'Create';

  @override
  String get createProjectTooltip => 'Create a new project folder';

  @override
  String get createProjectSelectFolder => 'Choose Location';

  @override
  String get createProjectSelectFolderHint =>
      'Select which project folder to create the new project in';

  @override
  String get createProjectNameTitle => 'Name Your Project';

  @override
  String get createProjectNameHint =>
      'Choose a naming scheme for the new project folder';

  @override
  String get createProjectSchemeArtistTrack => 'Artist — Track';

  @override
  String get createProjectSchemeCollab => 'Collab';

  @override
  String get createProjectSchemeDate => 'Date — Track';

  @override
  String get createProjectSchemeCustom => 'Custom';

  @override
  String get createProjectSchemeRemix => 'Remix';

  @override
  String get createProjectArtistName => 'Artist Name';

  @override
  String get createProjectTrackName => 'Track Name';

  @override
  String get createProjectCustomName => 'Folder Name';

  @override
  String get createProjectAddArtist => 'Add artist';

  @override
  String get createProjectOriginalArtist => 'Original Artist';

  @override
  String get createProjectRemixerName => 'Remixer';

  @override
  String get createProjectAddRemixer => 'Add remixer';

  @override
  String get createProjectSelectDaw => 'Open in DAW';

  @override
  String get createProjectSelectDawHint =>
      'Choose which DAW to open to start working on this project';

  @override
  String get createProjectDetectDaws => 'Detect Installed DAWs';

  @override
  String get createProjectSkipDaw => 'Just create the folder';

  @override
  String get createProjectNoDawsFound =>
      'No DAWs were found on this system. The folder will still be created.';

  @override
  String get createProjectCreateOnly => 'Create Folder';

  @override
  String get createProjectCreateAndOpen => 'Create & Open';

  @override
  String get createProjectFolderExists =>
      'A folder with this name already exists';

  @override
  String get createProjectInvalidChars =>
      'Folder name contains invalid characters';

  @override
  String get createProjectError => 'Failed to create folder';

  @override
  String get createProjectIncludeDate => 'Include date prefix';

  @override
  String get createProjectCreatedTitle => 'Folder Created';

  @override
  String get createProjectCreatedMessage =>
      'Your project folder has been created:';

  @override
  String get createProjectCopyName => 'Copy Folder Name';

  @override
  String get createProjectNameCopied => 'Folder name copied';

  @override
  String get createProjectTrackSession => 'Track session from now';

  @override
  String get pendingFolderSessionTitle => 'Work Session Detected';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return 'You\'ve worked on \"$projectName\" for $duration.';
  }

  @override
  String get pendingFolderSessionContinue => 'Continue Session';

  @override
  String get pendingFolderSessionEndRecord => 'End & Record';

  @override
  String get activeSessionSwitchTitle => 'Session Already Active';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return 'A session is running for \"$current\". Switch to \"$next\" and save the current session?';
  }

  @override
  String get activeSessionSwitch => 'Switch';

  @override
  String get pendingProjectWaiting => 'Waiting for project file…';

  @override
  String get pendingProjectDelete => 'Delete empty folder';

  @override
  String get pendingProjectDeleteTitle => 'Delete Folder?';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return 'Delete \"$folderName\" and its contents?';
  }

  @override
  String get pendingProjectDismiss => 'Stop tracking this folder';

  @override
  String get pendingProjectDismissTitle => 'Stop Tracking?';

  @override
  String get pendingProjectDismissKeep => 'Keep Folder';

  @override
  String get pendingProjectDismissDelete => 'Delete & Dismiss';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'Folder is not empty';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '\"$folderName\" contains files. Delete everything permanently?';
  }

  @override
  String get pendingProjectRefresh => 'Check for project file';

  @override
  String get pendingProjectNotFound => 'No project file found yet';

  @override
  String get phases => 'Phases';

  @override
  String get phasesSubtitle => 'Add, remove, and reorder project phases';

  @override
  String get phasesDescription =>
      'Phases track each project\'s stage in your workflow (e.g. Idea → Mixing → Mastering). Drag to reorder, tap a color dot to recolor, and flag a phase as finished to treat it as complete throughout the app.';

  @override
  String get resetToDefaults => 'Reset to defaults';

  @override
  String get addPhase => 'Add phase';

  @override
  String get phaseNameHint => 'Phase name';

  @override
  String get phaseDuplicateError => 'A phase with that name already exists';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projects use this phase',
      one: '1 project uses this phase',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => 'Select color';

  @override
  String get markAsFinished => 'Mark as finished phase';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projects use phases that will no longer exist.',
      one: '1 project uses a phase that will no longer exist.',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      'Those projects will keep their current status but won\'t appear in phase filters. You can always re-add those phases later.';

  @override
  String get resetPhasesConfirm =>
      'Reset all custom phases, colors, and finished-phase flags back to the defaults?';

  @override
  String get camelotGenerateButton => 'Generate Mix';

  @override
  String get camelotDialogTitle => 'Camelot Mix';

  @override
  String get camelotDialogDescription =>
      'Orders your tracks by harmonic key compatibility using the Camelot wheel. BPM proximity is used as a tiebreaker within compatible keys.';

  @override
  String camelotEligibleTracks(int count) {
    return '$count tracks eligible (key set)';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$count will be skipped (no key set)';
  }

  @override
  String get camelotNoEligibleTracks =>
      'No tracks have a musical key set. Open a project and set its key to use this feature.';

  @override
  String get camelotGenerate => 'Generate';

  @override
  String camelotQueueGenerated(int count) {
    return 'Queue filled with $count harmonically ordered tracks';
  }

  @override
  String get camelotWheelGuideTooltip => 'Camelot wheel guide';

  @override
  String get camelotWheelGuideTitle => 'Camelot Wheel Guide';

  @override
  String get camelotGuideRingsTitle => 'The Rings';

  @override
  String get camelotGuideRingsBody =>
      'Inner ring (A)  →  minor keys\nOuter ring (B)  →  major keys';

  @override
  String get camelotGuideNumbersTitle => 'Numbers 1–12';

  @override
  String get camelotGuideNumbersBody =>
      'Positions arranged clockwise. Each number represents a harmonic neighbourhood — neighbours share strong tonal relationships.';

  @override
  String get camelotGuideColoursTitle => 'Colour Guide';

  @override
  String get camelotGuideColoursBody =>
      '● Bright  →  your song\'s key\n● Softly lit  →  compatible for mixing\n● Dimmed  →  avoid for smooth mixing';

  @override
  String get camelotGuideTransitionsTitle => 'Compatible Transitions';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  (same number, switch ring)\n  Relative major / minor — virtually seamless.\n\n8A → 7A or 9A  (±1, same ring)\n  Adjacent key — smooth, subtle change.\n\n8A → 1A or 3A  (±7, same ring)\n  Energy boost or drop — more dramatic shift.';

  @override
  String get playerMixSuggestions => 'MIX SUGGESTIONS';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get noPreviewSongsAvailable => 'No preview songs available';

  @override
  String get upNext => 'Up Next';

  @override
  String get playbackModeNormal => 'Normal';

  @override
  String get playbackModeRepeat => 'Repeat';

  @override
  String get playbackModeShuffle => 'Shuffle';

  @override
  String get hideDatesInNames => 'Hide dates in project names';

  @override
  String get hideDatesInNamesDescription =>
      'Some DAWs prefix project files with the date they were created (for example \"2026-08-02 - My Track\"). Hide it so only the title is shown. The files themselves are never renamed.';

  @override
  String get findPreviewAutomatically => 'Auto-Find';

  @override
  String get noPreviewSongFoundAutomatically =>
      'No preview song found in this project\'s mixdown folders.';

  @override
  String get selectProjects => 'Select';

  @override
  String sharePreviewSongText(String name) {
    return 'Preview song: $name';
  }

  @override
  String sharePreviewSongZipText(String name) {
    return 'Preview song (ZIP): $name';
  }

  @override
  String get songParts => 'Instruments & Parts';

  @override
  String partsProgress(int done, int total) {
    return '$done of $total final takes';
  }

  @override
  String get noPartsYet => 'No parts tracked yet';

  @override
  String get noPartsYetHint =>
      'List the instruments this song needs, who plays them, and how far each take has got.';

  @override
  String get addPart => 'Add part';

  @override
  String get addPartHint => 'e.g. Drums, Lead Vocals, Bass';

  @override
  String get partNameLabel => 'Part';

  @override
  String get partNameRequired => 'A part name is required';

  @override
  String get partPerformerLabel => 'Performer';

  @override
  String get partPerformerHint => 'Who plays it';

  @override
  String get partNotesLabel => 'Part notes';

  @override
  String get partStatusLabel => 'Take status';

  @override
  String get partStatusNeeded => 'Needed';

  @override
  String get partStatusRecording => 'Recording';

  @override
  String get partStatusEarlyTake => 'Early take';

  @override
  String get partStatusFinalTake => 'Final take';

  @override
  String get editPart => 'Edit part';

  @override
  String get deletePart => 'Delete part';

  @override
  String get partsUnassignedPerformer => 'Unassigned';

  @override
  String get partTemplates => 'Part Templates';

  @override
  String get importPartsFromTemplate => 'Import parts from template';

  @override
  String get managePartTemplates => 'Manage part templates';

  @override
  String get selectPartTemplate => 'Select a part template';

  @override
  String get noPartTemplatesAvailable => 'No part templates available';

  @override
  String get noPartTemplatesYet => 'No part templates yet';

  @override
  String get createFirstPartTemplate =>
      'Create one to reuse the same lineup across songs';

  @override
  String get createPartTemplate => 'Create part template';

  @override
  String get editPartTemplate => 'Edit part template';

  @override
  String get deletePartTemplate => 'Delete part template';

  @override
  String deletePartTemplateConfirm(String name) {
    return 'Are you sure you want to delete the part template \"$name\"?';
  }

  @override
  String get partTemplateCreated => 'Part template created';

  @override
  String get partTemplateUpdated => 'Part template updated';

  @override
  String get partTemplateDeleted => 'Part template deleted';

  @override
  String get partTemplateItems => 'Parts (one per line)';

  @override
  String get partTemplateItemsHint => 'Drums — Alex\nBass — Sam\nLead Vocals';

  @override
  String get partTemplateItemsHelp =>
      'One part per line. Name a performer after a dash: Drums — Alex';

  @override
  String get partTemplateItemsRequired => 'Add at least one part';

  @override
  String get partTemplateNameAndItemsRequired =>
      'A name and at least one part are required';

  @override
  String partTemplateItemCount(int count) {
    return '$count part(s)';
  }

  @override
  String partTemplateImported(String name, int count) {
    return 'Part template \"$name\" imported ($count parts)';
  }

  @override
  String get errorLoadingPartTemplates => 'Error loading part templates';

  @override
  String get exportPartsCsv => 'Export parts as CSV';

  @override
  String get exportAllPartsCsv => 'Export all song parts as CSV';

  @override
  String get exportAllPartsCsvSubtitle =>
      'One spreadsheet row per part, across every project — for sharing progress with collaborators';

  @override
  String get noPartsToExport => 'No parts to export';

  @override
  String partsCsvExported(int count) {
    return 'Exported $count parts';
  }

  @override
  String get projectExportPartsLabel => 'Parts:';

  @override
  String get csvHeaderProject => 'Project';

  @override
  String get csvHeaderPart => 'Part';

  @override
  String get csvHeaderPerformer => 'Performer';

  @override
  String get csvHeaderStatus => 'Status';

  @override
  String get csvHeaderNotes => 'Notes';

  @override
  String get exportPartsXlsx => 'Export parts as Excel (.xlsx)';

  @override
  String get exportAllPartsXlsx => 'Export all song parts as Excel (.xlsx)';

  @override
  String get exportAllPartsXlsxSubtitle =>
      'The same sheet as the CSV, with a frozen header row, column filters and colour-coded take statuses';

  @override
  String get importPartsFromSpreadsheet => 'Import parts from a spreadsheet';

  @override
  String get partsImportPickerTitle => 'Select a CSV or Excel file';

  @override
  String partsImported(int added, int updated) {
    return '$added parts added, $updated updated';
  }

  @override
  String get partsImportNothingFound => 'No parts found in that file';

  @override
  String partsImportFailed(String error) {
    return 'Couldn\'t read that spreadsheet: $error';
  }

  @override
  String get partsMoreActions => 'More part actions';

  @override
  String partsPageTitle(String name) {
    return '$name — Parts';
  }

  @override
  String get manageParts => 'Manage parts';

  @override
  String partsMoreCount(int count) {
    return '+$count more';
  }

  @override
  String get searchParts => 'Search parts';

  @override
  String get allStatuses => 'All statuses';

  @override
  String get allPerformers => 'All performers';

  @override
  String partsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get setPartStatus => 'Set status';

  @override
  String get assignPartPerformer => 'Assign performer';

  @override
  String get deleteSelectedParts => 'Delete selected';

  @override
  String deleteSelectedPartsConfirm(int count) {
    return 'Delete $count parts from this song?';
  }

  @override
  String partsDeleted(int count) {
    return '$count parts deleted';
  }

  @override
  String get noPartsMatchFilters => 'No parts match these filters';

  @override
  String get reorderNeedsUnfilteredList =>
      'Clear the search, filters and sorting to drag parts into order';

  @override
  String get projectMarkers => 'Markers';

  @override
  String projectMarkerUnnamed(int index) {
    return 'Marker $index';
  }

  @override
  String projectRegionUnnamed(int index) {
    return 'Region $index';
  }

  @override
  String get projectMarkerJumpTooltip =>
      'Jump to this point in the preview song';

  @override
  String get projectMarkerNoPreviewSong =>
      'Add a preview song to jump to markers';

  @override
  String get projectDetailLayout => 'Project Detail Layout';

  @override
  String get projectDetailLayoutSettingDescription =>
      'How the project detail page is arranged.';

  @override
  String get projectDetailLayoutClassic => 'Classic';

  @override
  String get projectDetailLayoutClassicDescription =>
      'Everything in one scroll.';

  @override
  String get projectDetailLayoutSectioned => 'Sections';

  @override
  String get projectDetailLayoutSectionedDescription =>
      'A rail on the left picks one section at a time.';

  @override
  String get stackAsVersions => 'Stack as Versions';

  @override
  String get stackNeedsTwoVersions =>
      'Select at least two projects to stack them as versions of one main project.';

  @override
  String stackCreatedMessage(int count) {
    return 'Stacked $count versions into one main project.';
  }

  @override
  String get stackVersionsTitle => 'Versions';

  @override
  String stackVersionCount(int count) {
    return '$count versions';
  }

  @override
  String get stackAddVersion => 'Add Version';

  @override
  String get stackAddVersionTitle => 'Add a version';

  @override
  String get stackAddVersionEmpty => 'No unstacked projects available to add.';

  @override
  String get stackRemoveVersion => 'Remove from stack';

  @override
  String get stackRemoveVersionMessage =>
      'The project file stays on disk and returns to the list as its own project.';

  @override
  String get stackUnstack => 'Unstack';

  @override
  String get stackUnstackTitle => 'Unstack this main project?';

  @override
  String get stackUnstackMessage =>
      'Every version becomes its own project again with the metadata it had before stacking. The shared notes, tasks and deadline kept on the main project are deleted.';

  @override
  String get stackDefaultVersion => 'Opens by default';

  @override
  String get stackSetDefaultVersion => 'Open this version by default';

  @override
  String get stackChooseVersionToOpen => 'Which version do you want to open?';

  @override
  String get stackMemberOf => 'Version of';

  @override
  String get stackMemberNotice =>
      'This file is one version of a stacked project. Shared metadata, tasks and work time live on the main project, not here.';

  @override
  String get stackOpenMainProject => 'Open main project';

  @override
  String get stackWorkTimeAcrossVersions => 'Total across all versions';

  @override
  String get scanModeVersionStack => 'Version Stack';

  @override
  String get scanModeVersionStackDescription =>
      'Every project file in a folder becomes one main project sharing metadata, tasks and work time. Newly found files join it automatically.';

  @override
  String stackTooltipStacked(int count) {
    return '$count versions stacked into one main project';
  }

  @override
  String get stackMetadataSourceTitle =>
      'Which project should become the main project?';

  @override
  String get stackMetadataSourceBody =>
      'More than one of these already has details of its own. The one you pick becomes the main project: its name, BPM, key, notes, tasks and deadline are the ones the stack uses. Nothing is merged and nothing is lost — the others keep their own details, and unstacking gives them back.';

  @override
  String get stackMetadataSourceOldestHint => 'Oldest — suggested';

  @override
  String get stackMetadataNoneLabel => 'No details yet';

  @override
  String stackMetadataTodosLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataNotesLabel => 'notes';

  @override
  String get stackNotStackedYet => 'Not stacked yet';

  @override
  String get stackStartFromHere =>
      'Add other project files and they become versions of one main project, sharing metadata, tasks and work time.';

  @override
  String get stackSearchProjects => 'Search projects';

  @override
  String get stackSearchNoMatches => 'No projects match your search.';

  @override
  String get stackStartedMessage => 'Stacked into one main project.';

  @override
  String get stackDefaultVersionTooltip =>
      'This version opens by default when you launch the DAW.';

  @override
  String stackAddVersionsConfirm(int count) {
    return 'Add $count';
  }

  @override
  String get stackAddVersionMultiTitle => 'Add versions';

  @override
  String get stackSelectAll => 'Select all';

  @override
  String get stackClearSelection => 'Clear';

  @override
  String stackMetadataPartsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parts',
      one: '1 part',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataDeadlineLabel => 'deadline';

  @override
  String get stackMetadataRenamedLabel => 'custom name';

  @override
  String stackMetadataWorkHours(String hours) {
    return '${hours}h logged';
  }

  @override
  String get stackUnstackReleaseTitle => 'Which version stays on the release?';

  @override
  String stackUnstackReleaseBody(String releases) {
    return 'This project is a track on $releases. Unstacking removes the stacked entry, so one of its versions has to take that place — pick the one the release should point to.';
  }

  @override
  String get stackAutoConfirmTitle => 'Stack these versions?';

  @override
  String stackAutoConfirmBody(int projects, int folders) {
    return 'Version Stack will group $projects projects in $folders folders. Each folder becomes one main project sharing metadata, tasks and work time. Nothing is deleted, and you can unstack any of them later.';
  }

  @override
  String get stackAutoConfirmApply => 'Stack them';

  @override
  String stackAutoFolderEntry(String folder, int count) {
    return '$folder — $count versions';
  }

  @override
  String get stackAutoJoinsExisting => 'joins the existing main project';

  @override
  String get untitledTheme => 'Untitled theme';

  @override
  String switchToTheme(String themeName) {
    return 'Switch to $themeName';
  }

  @override
  String get newTheme => 'New theme';

  @override
  String get editTheme => 'Edit theme';

  @override
  String get duplicateTheme => 'Duplicate';

  @override
  String get deleteThemeTitle => 'Delete theme?';

  @override
  String deleteThemeMessage(String name) {
    return '\"$name\" will be removed. This cannot be undone.';
  }

  @override
  String get themeNameLabel => 'Theme name';

  @override
  String get themeNameHint => 'e.g. Studio Amber';

  @override
  String get themeNameRequired => 'Give the theme a name.';

  @override
  String get themeColorAccent => 'Accent';

  @override
  String get themeColorSecondaryAccent => 'Secondary accent';

  @override
  String get themeColorBackground => 'Background';

  @override
  String get themeColorCards => 'Cards and panels';

  @override
  String get themeCardRoundness => 'Card roundness';

  @override
  String get themeButtonRoundness => 'Button roundness';

  @override
  String themeLowContrastWarning(String ratio) {
    return 'Low contrast ($ratio:1). Text may be hard to read.';
  }

  @override
  String get exportTheme => 'Export theme';

  @override
  String get importTheme => 'Import theme';

  @override
  String themeExported(String path) {
    return 'Theme exported to $path';
  }

  @override
  String themeImported(String name) {
    return 'Imported \"$name\"';
  }

  @override
  String get themeImportFailed => 'That file isn\'t a valid theme.';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexInvalid => 'Use #RRGGBB';

  @override
  String get apply => 'Apply';

  @override
  String get pickColor => 'Pick a color';

  @override
  String themeCopyName(String name) {
    return '$name copy';
  }
}
