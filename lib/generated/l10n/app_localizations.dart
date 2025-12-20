import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'DAW Project Manager'**
  String get appTitle;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @launch.
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get launch;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @openInDaw.
  ///
  /// In en, this message translates to:
  /// **'Open in DAW'**
  String get openInDaw;

  /// No description provided for @extract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get extract;

  /// No description provided for @extracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting…'**
  String get extracting;

  /// No description provided for @extractingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Extracting metadata...'**
  String get extractingMetadata;

  /// No description provided for @deepScan.
  ///
  /// In en, this message translates to:
  /// **'Deep Scan'**
  String get deepScan;

  /// No description provided for @rescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescan;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @bpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get bpm;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'Key (e.g., C#m, F major)'**
  String get key;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @projectPhase.
  ///
  /// In en, this message translates to:
  /// **'Project Phase'**
  String get projectPhase;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @fileMissing.
  ///
  /// In en, this message translates to:
  /// **'File missing.'**
  String get fileMissing;

  /// No description provided for @launchingProject.
  ///
  /// In en, this message translates to:
  /// **'Launching {projectName}…'**
  String launchingProject(String projectName);

  /// No description provided for @clearLibrary.
  ///
  /// In en, this message translates to:
  /// **'Clear Library'**
  String get clearLibrary;

  /// No description provided for @clearLibraryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove all saved projects and source folders. Continue?'**
  String get clearLibraryMessage;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @roots.
  ///
  /// In en, this message translates to:
  /// **'Roots'**
  String get roots;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'hidden'**
  String get hidden;

  /// No description provided for @profileManager.
  ///
  /// In en, this message translates to:
  /// **'Profile Manager'**
  String get profileManager;

  /// No description provided for @createNewProfile.
  ///
  /// In en, this message translates to:
  /// **'Create New Profile'**
  String get createNewProfile;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchProfile;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get addFolder;

  /// No description provided for @searchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects...'**
  String get searchProjects;

  /// No description provided for @deepScanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Deep Scan extracts full metadata from project files:\n• BPM (Beats Per Minute)\n• Musical Key\n• DAW Version\nThis is slower but provides complete information.'**
  String get deepScanTooltip;

  /// No description provided for @deepScanConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will scan all projects and extract full metadata (BPM, Key, DAW Version). This may take a while. Continue?'**
  String get deepScanConfirm;

  /// No description provided for @metadataExtractedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Metadata extracted successfully'**
  String get metadataExtractedSuccessfully;

  /// No description provided for @failedToExtractMetadata.
  ///
  /// In en, this message translates to:
  /// **'Failed to extract metadata: {error}'**
  String failedToExtractMetadata(String error);

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @failedToLaunchDaw.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch DAW'**
  String get failedToLaunchDaw;

  /// No description provided for @releaseDetails.
  ///
  /// In en, this message translates to:
  /// **'Release Details'**
  String get releaseDetails;

  /// No description provided for @releaseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Release Not Found'**
  String get releaseNotFound;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfile;

  /// No description provided for @deleteProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{profileName}\"? This will delete all projects, roots, and releases for this profile.'**
  String deleteProfileMessage(String profileName);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @saveName.
  ///
  /// In en, this message translates to:
  /// **'Save Name'**
  String get saveName;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed.'**
  String get profilePhotoRemoved;

  /// No description provided for @profileRenamed.
  ///
  /// In en, this message translates to:
  /// **'Profile renamed to \"{newName}\"'**
  String profileRenamed(String newName);

  /// No description provided for @profileCreated.
  ///
  /// In en, this message translates to:
  /// **'Profile \"{name}\" created successfully'**
  String profileCreated(String name);

  /// No description provided for @profileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Profile \"{name}\" deleted'**
  String profileDeleted(String name);

  /// No description provided for @pleaseEnterProfileName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a profile name'**
  String get pleaseEnterProfileName;

  /// No description provided for @failedToCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to create profile: {error}'**
  String failedToCreateProfile(String error);

  /// No description provided for @noProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No profiles found. Create one above.'**
  String get noProfilesFound;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String created(String date);

  /// No description provided for @toggleSort.
  ///
  /// In en, this message translates to:
  /// **'Toggle sort'**
  String get toggleSort;

  /// No description provided for @clearLibraryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear Library (projects & roots)'**
  String get clearLibraryTooltip;

  /// No description provided for @lastModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified: {date}'**
  String lastModified(String date);

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @daw.
  ///
  /// In en, this message translates to:
  /// **'DAW'**
  String get daw;

  /// No description provided for @lastModifiedColumn.
  ///
  /// In en, this message translates to:
  /// **'Last Modified'**
  String get lastModifiedColumn;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @unhide.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get unhide;

  /// No description provided for @extractMetadata.
  ///
  /// In en, this message translates to:
  /// **'Extract Metadata'**
  String get extractMetadata;

  /// No description provided for @createRelease.
  ///
  /// In en, this message translates to:
  /// **'Create Release'**
  String get createRelease;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @selectAllProjects.
  ///
  /// In en, this message translates to:
  /// **'Select all projects'**
  String get selectAllProjects;

  /// No description provided for @switchingProfiles.
  ///
  /// In en, this message translates to:
  /// **'Switching Profiles...'**
  String get switchingProfiles;

  /// No description provided for @scanningProjects.
  ///
  /// In en, this message translates to:
  /// **'Scanning projects...'**
  String get scanningProjects;

  /// No description provided for @projectsTab.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTab;

  /// No description provided for @releasesTab.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get releasesTab;

  /// No description provided for @showHidden.
  ///
  /// In en, this message translates to:
  /// **'Show Hidden'**
  String get showHidden;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @showOnlyHidden.
  ///
  /// In en, this message translates to:
  /// **'Show Only Hidden'**
  String get showOnlyHidden;

  /// No description provided for @deleteRootPath.
  ///
  /// In en, this message translates to:
  /// **'Delete Root Path'**
  String get deleteRootPath;

  /// No description provided for @deleteRootPathMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{path}\"? This will also remove all projects from this folder that are not in releases.'**
  String deleteRootPathMessage(String path);

  /// No description provided for @rootsCount.
  ///
  /// In en, this message translates to:
  /// **'Roots: {count}'**
  String rootsCount(int count);

  /// No description provided for @projectsCount.
  ///
  /// In en, this message translates to:
  /// **'Projects: {count}'**
  String projectsCount(int count);

  /// No description provided for @hiddenOnly.
  ///
  /// In en, this message translates to:
  /// **'(hidden only)'**
  String get hiddenOnly;

  /// No description provided for @hiddenCount.
  ///
  /// In en, this message translates to:
  /// **'({count} hidden)'**
  String hiddenCount(int count);

  /// No description provided for @projectsHidden.
  ///
  /// In en, this message translates to:
  /// **'{count} project{plural} hidden.'**
  String projectsHidden(int count, String plural);

  /// No description provided for @projectsUnhidden.
  ///
  /// In en, this message translates to:
  /// **'{count} project{plural} unhidden.'**
  String projectsUnhidden(int count, String plural);

  /// No description provided for @failedToHideProjects.
  ///
  /// In en, this message translates to:
  /// **'Failed to hide projects: {error}'**
  String failedToHideProjects(String error);

  /// No description provided for @failedToUnhideProjects.
  ///
  /// In en, this message translates to:
  /// **'Failed to unhide projects: {error}'**
  String failedToUnhideProjects(String error);

  /// No description provided for @releaseCreated.
  ///
  /// In en, this message translates to:
  /// **'Release \"{title}\" created successfully.'**
  String releaseCreated(String title);

  /// No description provided for @failedToCreateRelease.
  ///
  /// In en, this message translates to:
  /// **'Failed to create release: {error}'**
  String failedToCreateRelease(String error);

  /// No description provided for @errorAddingFolder.
  ///
  /// In en, this message translates to:
  /// **'Error adding folder: {error}'**
  String errorAddingFolder(String error);

  /// No description provided for @noProjectsFoundInRoots.
  ///
  /// In en, this message translates to:
  /// **'No projects found in selected roots.'**
  String get noProjectsFoundInRoots;

  /// No description provided for @selectProjectsFolder.
  ///
  /// In en, this message translates to:
  /// **'Select a projects folder'**
  String get selectProjectsFolder;

  /// No description provided for @enterReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Release Title'**
  String get enterReleaseTitle;

  /// No description provided for @releaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Release Title'**
  String get releaseTitle;

  /// No description provided for @enterReleaseTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter release title'**
  String get enterReleaseTitleHint;

  /// No description provided for @metadataExtractedForProjects.
  ///
  /// In en, this message translates to:
  /// **'Extracted metadata for {count} project{plural}. {failures}'**
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  );

  /// No description provided for @extractionFailures.
  ///
  /// In en, this message translates to:
  /// **'{count} failed.'**
  String extractionFailures(int count, Object plural);

  /// No description provided for @failedToWriteBpmFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to write BPM file: {error}'**
  String failedToWriteBpmFile(String error);

  /// No description provided for @failedToWriteKeyFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to write key file: {error}'**
  String failedToWriteKeyFile(String error);

  /// No description provided for @failedToLaunch.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch: {error}'**
  String failedToLaunch(String error);

  /// No description provided for @libraryCleared.
  ///
  /// In en, this message translates to:
  /// **'Library cleared.'**
  String get libraryCleared;

  /// No description provided for @scanType.
  ///
  /// In en, this message translates to:
  /// **'{type} scan'**
  String scanType(String type);

  /// No description provided for @scanComplete.
  ///
  /// In en, this message translates to:
  /// **'{type} complete: {count} project{plural} added/updated.'**
  String scanComplete(String type, int count, String plural);

  /// No description provided for @projectsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} project{plural} selected'**
  String projectsSelected(int count, String plural);

  /// No description provided for @openingFolder.
  ///
  /// In en, this message translates to:
  /// **'Opening folder for {projectName}…'**
  String openingFolder(String projectName);

  /// No description provided for @failedToOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder: {error}'**
  String failedToOpenFolder(String error);

  /// No description provided for @osNotSupportedForOpeningFolder.
  ///
  /// In en, this message translates to:
  /// **'OS not supported for opening folder.'**
  String get osNotSupportedForOpeningFolder;

  /// No description provided for @noProjectsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No projects available. Please add projects first.'**
  String get noProjectsAvailable;

  /// No description provided for @createNewRelease.
  ///
  /// In en, this message translates to:
  /// **'Create New Release'**
  String get createNewRelease;

  /// No description provided for @deleteRelease.
  ///
  /// In en, this message translates to:
  /// **'Delete Release'**
  String get deleteRelease;

  /// No description provided for @deleteReleaseMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteReleaseMessage(String title);

  /// No description provided for @releaseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Release \"{title}\" deleted.'**
  String releaseDeleted(String title);

  /// No description provided for @selectTracks.
  ///
  /// In en, this message translates to:
  /// **'Select Tracks'**
  String get selectTracks;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @noReleasesYet.
  ///
  /// In en, this message translates to:
  /// **'No releases yet'**
  String get noReleasesYet;

  /// No description provided for @createFirstRelease.
  ///
  /// In en, this message translates to:
  /// **'Create your first release by selecting tracks from your projects'**
  String get createFirstRelease;

  /// No description provided for @releasesCount.
  ///
  /// In en, this message translates to:
  /// **'Releases ({count})'**
  String releasesCount(int count);

  /// No description provided for @errorLoadingReleases.
  ///
  /// In en, this message translates to:
  /// **'Error loading releases: {error}'**
  String errorLoadingReleases(String error);

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'Tracks ({count})'**
  String tracksCount(int count);

  /// No description provided for @addTracks.
  ///
  /// In en, this message translates to:
  /// **'Add Tracks'**
  String get addTracks;

  /// No description provided for @allProjectsAlreadyInRelease.
  ///
  /// In en, this message translates to:
  /// **'All projects are already in this release.'**
  String get allProjectsAlreadyInRelease;

  /// No description provided for @addedTracksToRelease.
  ///
  /// In en, this message translates to:
  /// **'Added {count} track{plural} to release.'**
  String addedTracksToRelease(int count, String plural);

  /// No description provided for @releaseFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Release Files ({count})'**
  String releaseFilesCount(int count);

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get addFiles;

  /// No description provided for @addedFilesToRelease.
  ///
  /// In en, this message translates to:
  /// **'Added {count} file{plural} to release.'**
  String addedFilesToRelease(int count, String plural);

  /// No description provided for @failedToAddFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to add files: {error}'**
  String failedToAddFiles(String error);

  /// No description provided for @noFilesToDownload.
  ///
  /// In en, this message translates to:
  /// **'No files to download.'**
  String get noFilesToDownload;

  /// No description provided for @zipFileSaved.
  ///
  /// In en, this message translates to:
  /// **'ZIP file saved to: {path}'**
  String zipFileSaved(String path);

  /// No description provided for @failedToCreateZip.
  ///
  /// In en, this message translates to:
  /// **'Failed to create ZIP: {error}'**
  String failedToCreateZip(String error);

  /// No description provided for @selectedFileDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'Selected file does not exist.'**
  String get selectedFileDoesNotExist;

  /// No description provided for @imageSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image saved successfully!'**
  String get imageSavedSuccessfully;

  /// No description provided for @failedToSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to save image: {error}'**
  String failedToSaveImage(String error);

  /// No description provided for @errorLoadingRelease.
  ///
  /// In en, this message translates to:
  /// **'Error loading release: {error}'**
  String errorLoadingRelease(String error);

  /// No description provided for @errorLoadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Error loading projects: {error}'**
  String errorLoadingProjects(String error);

  /// No description provided for @releaseSaved.
  ///
  /// In en, this message translates to:
  /// **'Release saved.'**
  String get releaseSaved;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDate;

  /// No description provided for @failedToSaveReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Failed to save release date: {error}'**
  String failedToSaveReleaseDate(String error);

  /// No description provided for @releaseDateSaved.
  ///
  /// In en, this message translates to:
  /// **'Release date saved.'**
  String get releaseDateSaved;

  /// No description provided for @releaseDateCleared.
  ///
  /// In en, this message translates to:
  /// **'Release date cleared.'**
  String get releaseDateCleared;

  /// No description provided for @saveReleaseFilesZip.
  ///
  /// In en, this message translates to:
  /// **'Save release files ZIP'**
  String get saveReleaseFilesZip;

  /// No description provided for @failedToOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to open file: {error}'**
  String failedToOpenFile(String error);

  /// No description provided for @failedToPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio: {error}'**
  String failedToPlayAudio(String error);

  /// No description provided for @renameFile.
  ///
  /// In en, this message translates to:
  /// **'Rename File'**
  String get renameFile;

  /// No description provided for @selectTracksToAdd.
  ///
  /// In en, this message translates to:
  /// **'Select Tracks to Add'**
  String get selectTracksToAdd;

  /// No description provided for @fileNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'File name updated.'**
  String get fileNameUpdated;

  /// No description provided for @errorUpdatingFileName.
  ///
  /// In en, this message translates to:
  /// **'Error updating file name: {error}'**
  String errorUpdatingFileName(String error);

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// No description provided for @deleteFileMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{fileName}\"?'**
  String deleteFileMessage(String fileName);

  /// No description provided for @fileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File \"{fileName}\" deleted.'**
  String fileDeleted(String fileName);

  /// No description provided for @failedToDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete file: {error}'**
  String failedToDeleteFile(String error);

  /// No description provided for @couldNotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not open folder: {error}'**
  String couldNotOpenFolder(String error);

  /// No description provided for @artwork.
  ///
  /// In en, this message translates to:
  /// **'Artwork'**
  String get artwork;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @tracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracks;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @selectTracksToInclude.
  ///
  /// In en, this message translates to:
  /// **'Select tracks to include in the release ({count} selected)'**
  String selectTracksToInclude(int count, Object plural);

  /// No description provided for @searchTracks.
  ///
  /// In en, this message translates to:
  /// **'Search tracks'**
  String get searchTracks;

  /// No description provided for @searchTracksHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or DAW type'**
  String get searchTracksHint;

  /// No description provided for @noTracksFound.
  ///
  /// In en, this message translates to:
  /// **'No tracks found'**
  String get noTracksFound;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @editTodo.
  ///
  /// In en, this message translates to:
  /// **'Edit Todo'**
  String get editTodo;

  /// No description provided for @todoText.
  ///
  /// In en, this message translates to:
  /// **'Todo text'**
  String get todoText;

  /// No description provided for @enterTodoText.
  ///
  /// In en, this message translates to:
  /// **'Enter todo text'**
  String get enterTodoText;

  /// No description provided for @addNewTodo.
  ///
  /// In en, this message translates to:
  /// **'Add new todo'**
  String get addNewTodo;

  /// No description provided for @enterTodoItem.
  ///
  /// In en, this message translates to:
  /// **'Enter todo item'**
  String get enterTodoItem;

  /// No description provided for @todoList.
  ///
  /// In en, this message translates to:
  /// **'TODO List'**
  String get todoList;

  /// No description provided for @addToRelease.
  ///
  /// In en, this message translates to:
  /// **'Add to Release'**
  String get addToRelease;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No description provided for @addToExisting.
  ///
  /// In en, this message translates to:
  /// **'Add to Existing'**
  String get addToExisting;

  /// No description provided for @createAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Create and Add'**
  String get createAndAdd;

  /// No description provided for @selectRelease.
  ///
  /// In en, this message translates to:
  /// **'Select a release'**
  String get selectRelease;

  /// No description provided for @noExistingReleasesFound.
  ///
  /// In en, this message translates to:
  /// **'No existing releases found.'**
  String get noExistingReleasesFound;

  /// No description provided for @addToSelectedRelease.
  ///
  /// In en, this message translates to:
  /// **'Add to Selected Release'**
  String get addToSelectedRelease;

  /// No description provided for @failedToSaveProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile photo: {error}'**
  String failedToSaveProfilePhoto(String error);

  /// No description provided for @failedToRemoveProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove profile photo: {error}'**
  String failedToRemoveProfilePhoto(String error);

  /// No description provided for @failedToRenameProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename profile: {error}'**
  String failedToRenameProfile(String error);

  /// No description provided for @failedToDeleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete profile: {error}'**
  String failedToDeleteProfile(String error);

  /// No description provided for @errorLoadingProfiles.
  ///
  /// In en, this message translates to:
  /// **'Error loading profiles: {error}'**
  String errorLoadingProfiles(String error);

  /// No description provided for @projectPhaseIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get projectPhaseIdea;

  /// No description provided for @projectPhaseArranging.
  ///
  /// In en, this message translates to:
  /// **'Arranging'**
  String get projectPhaseArranging;

  /// No description provided for @projectPhaseMixing.
  ///
  /// In en, this message translates to:
  /// **'Mixing'**
  String get projectPhaseMixing;

  /// No description provided for @projectPhaseMastering.
  ///
  /// In en, this message translates to:
  /// **'Mastering'**
  String get projectPhaseMastering;

  /// No description provided for @projectPhaseFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get projectPhaseFinished;

  /// No description provided for @tooltipEditProfileName.
  ///
  /// In en, this message translates to:
  /// **'Edit profile name'**
  String get tooltipEditProfileName;

  /// No description provided for @tooltipAddTodo.
  ///
  /// In en, this message translates to:
  /// **'Add todo'**
  String get tooltipAddTodo;

  /// No description provided for @tooltipClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get tooltipClearDate;

  /// No description provided for @tooltipPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get tooltipPickDate;

  /// No description provided for @tooltipViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get tooltipViewDetails;

  /// No description provided for @tooltipLaunchInDaw.
  ///
  /// In en, this message translates to:
  /// **'Launch in DAW'**
  String get tooltipLaunchInDaw;

  /// No description provided for @tooltipRemoveFromRelease.
  ///
  /// In en, this message translates to:
  /// **'Remove from Release'**
  String get tooltipRemoveFromRelease;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @noDateSet.
  ///
  /// In en, this message translates to:
  /// **'No date set'**
  String get noDateSet;

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// No description provided for @clickToBrowseArtwork.
  ///
  /// In en, this message translates to:
  /// **'Click to browse artwork'**
  String get clickToBrowseArtwork;

  /// No description provided for @noFilesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No files added yet.\nClick \"Add Files\" to upload release files.'**
  String get noFilesAddedYet;

  /// No description provided for @noTodosYet.
  ///
  /// In en, this message translates to:
  /// **'No todos yet. Add one above.'**
  String get noTodosYet;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @backupExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully'**
  String get backupExportedSuccessfully;

  /// Error message when backup export fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup: {error}'**
  String failedToExportBackup(String error);

  /// Success message after importing backup
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully: {projectsCount} projects, {rootsCount} roots, {releasesCount} releases'**
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  );

  /// Error message when backup import fails
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup: {error}'**
  String failedToImportBackup(String error);

  /// No description provided for @importBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose how to import the backup:'**
  String get importBackupMessage;

  /// No description provided for @mergeWithCurrentProfile.
  ///
  /// In en, this message translates to:
  /// **'Merge with current active profile'**
  String get mergeWithCurrentProfile;

  /// No description provided for @replaceCurrentProfile.
  ///
  /// In en, this message translates to:
  /// **'Replace entirely the current profile (WARNING: This will delete all current profile data)'**
  String get replaceCurrentProfile;

  /// No description provided for @createNewProfileForImport.
  ///
  /// In en, this message translates to:
  /// **'Create a new profile for this data'**
  String get createNewProfileForImport;

  /// Success message after importing backup to a new profile
  ///
  /// In en, this message translates to:
  /// **'Backup imported to new profile \"{profileName}\": {projectsCount} projects, {rootsCount} roots, {releasesCount} releases'**
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  );

  /// No description provided for @noProfileSelected.
  ///
  /// In en, this message translates to:
  /// **'No profile selected'**
  String get noProfileSelected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
