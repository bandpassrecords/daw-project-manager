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
  String get cancel => 'Cancel';

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
  String get scanning => 'Scanning…';

  @override
  String get projectName => 'Project Name';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Key (e.g., C#m, F major)';

  @override
  String get notes => 'Notes';

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
  String get clearLibrary => 'Clear Library';

  @override
  String get clearLibraryMessage =>
      'This will remove all saved projects and source folders. Continue?';

  @override
  String get clear => 'Clear';

  @override
  String get roots => 'Project Folders';

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
  String get switchProfile => 'Switch';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get addFolder => 'Add Folder';

  @override
  String get searchProjects => 'Search projects...';

  @override
  String get deepScanTooltip =>
      'Deep Scan extracts full metadata from project files:\n• BPM (Beats Per Minute)\n• Musical Key\n• DAW Version\nThis is slower but provides complete information.';

  @override
  String get deepScanConfirm =>
      'This will scan all projects and extract full metadata (BPM, Key, DAW Version). This may take a while. Continue?';

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
  String created(String date) {
    return 'Created';
  }

  @override
  String get toggleSort => 'Toggle sort';

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
  String get allPhases => 'All Phases';

  @override
  String get daw => 'DAW';

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
  String get deleteRootPath => 'Delete Root Path';

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
  String errorLoadingProjects(String error) {
    return 'Error loading projects: $error';
  }

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
  String failedToOpenFile(String error) {
    return 'Failed to open file: $error';
  }

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
  String get todoList => 'TODO List';

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
  String get clickToBrowseArtwork => 'Click to browse artwork';

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
  String get exportBackup => 'Export Backup';

  @override
  String get importBackup => 'Import Backup';

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
}
