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

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Snackbar action to reverse the action just performed (e.g. hiding projects)
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @customInterval.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customInterval;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

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
  /// **'Launch in DAW'**
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

  /// No description provided for @refreshProject.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshProject;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @newProjectBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newProjectBadge;

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

  /// No description provided for @expandNotes.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expandNotes;

  /// No description provided for @collapseNotes.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapseNotes;

  /// No description provided for @projectNotesFromDaw.
  ///
  /// In en, this message translates to:
  /// **'Project Notes (from DAW file)'**
  String get projectNotesFromDaw;

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

  /// No description provided for @failedToLaunchProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch {projectName}'**
  String failedToLaunchProject(String projectName);

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
  /// **'Project Folders'**
  String get roots;

  /// No description provided for @pathsSettingsDangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get pathsSettingsDangerZoneTitle;

  /// No description provided for @pathsSettingsDangerZoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all projects and project folders for the current profile.'**
  String get pathsSettingsDangerZoneSubtitle;

  /// No description provided for @projectFoldersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Project folders'**
  String get projectFoldersSectionTitle;

  /// No description provided for @projectFoldersSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Folders that will be scanned for DAW projects.'**
  String get projectFoldersSectionSubtitle;

  /// No description provided for @projectFoldersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No project folders yet'**
  String get projectFoldersEmptyTitle;

  /// No description provided for @projectFoldersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add at least one folder to start scanning for projects.'**
  String get projectFoldersEmptySubtitle;

  /// No description provided for @notScannedYet.
  ///
  /// In en, this message translates to:
  /// **'Not scanned yet'**
  String get notScannedYet;

  /// No description provided for @lastScan.
  ///
  /// In en, this message translates to:
  /// **'Last scan: {date}'**
  String lastScan(String date);

  /// No description provided for @excludedFoldersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Excluded folders'**
  String get excludedFoldersSectionTitle;

  /// No description provided for @excludedFoldersSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These folders will be skipped during scanning, even if they are inside a project folder.'**
  String get excludedFoldersSectionSubtitle;

  /// No description provided for @addExcludedFolder.
  ///
  /// In en, this message translates to:
  /// **'Add excluded'**
  String get addExcludedFolder;

  /// No description provided for @selectExcludedFolder.
  ///
  /// In en, this message translates to:
  /// **'Select a folder to exclude'**
  String get selectExcludedFolder;

  /// No description provided for @excludedFoldersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No excluded folders'**
  String get excludedFoldersEmptyTitle;

  /// No description provided for @excludedFoldersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional: add folders you never want to scan.'**
  String get excludedFoldersEmptySubtitle;

  /// No description provided for @removeExcludedFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove excluded folder?'**
  String get removeExcludedFolderTitle;

  /// No description provided for @removeExcludedFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'This folder will no longer be excluded:\n\n{path}'**
  String removeExcludedFolderMessage(String path);

  /// No description provided for @removeExcludedFolderMessageNoPath.
  ///
  /// In en, this message translates to:
  /// **'This folder will no longer be excluded.'**
  String get removeExcludedFolderMessageNoPath;

  /// No description provided for @desktopOnlyPathsSettings.
  ///
  /// In en, this message translates to:
  /// **'This page is available only on the desktop app.'**
  String get desktopOnlyPathsSettings;

  /// No description provided for @renameProjectFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get renameProjectFolderTitle;

  /// No description provided for @flatpakPortalPathExplanation.
  ///
  /// In en, this message translates to:
  /// **'This path is a sandboxed location, not the real folder location — Flatpak doesn\'t share that with the app. Use the name above to identify it instead.'**
  String get flatpakPortalPathExplanation;

  /// No description provided for @removeProjectFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove project folder?'**
  String get removeProjectFolderTitle;

  /// No description provided for @removeProjectFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{path}\"? This will also remove all projects from this folder that are not in releases.'**
  String removeProjectFolderMessage(String path);

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
  /// **'Activate Profile'**
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

  /// No description provided for @searchReleases.
  ///
  /// In en, this message translates to:
  /// **'Search releases...'**
  String get searchReleases;

  /// No description provided for @searchPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Search playlists...'**
  String get searchPlaylists;

  /// No description provided for @noReleasesFound.
  ///
  /// In en, this message translates to:
  /// **'No releases found'**
  String get noReleasesFound;

  /// No description provided for @noPlaylistsFound.
  ///
  /// In en, this message translates to:
  /// **'No playlists found'**
  String get noPlaylistsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @deepScanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deep Scan extracts full metadata from project files:\n• BPM (Beats Per Minute)\n• Musical Key\n• DAW Version\n• Project Notes (where supported)\n\nThis is slower than a regular scan and may take a while. Continue?'**
  String get deepScanConfirm;

  /// No description provided for @deepScanViewSupportedDaws.
  ///
  /// In en, this message translates to:
  /// **'View supported DAWs & fields'**
  String get deepScanViewSupportedDaws;

  /// No description provided for @deepScanOnlyUnscanned.
  ///
  /// In en, this message translates to:
  /// **'Only scan projects without metadata'**
  String get deepScanOnlyUnscanned;

  /// No description provided for @metadataExtractionTitle.
  ///
  /// In en, this message translates to:
  /// **'Metadata Extraction'**
  String get metadataExtractionTitle;

  /// No description provided for @metadataExtractionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See which data each DAW supports'**
  String get metadataExtractionSubtitle;

  /// No description provided for @metadataExtractionIntro.
  ///
  /// In en, this message translates to:
  /// **'Deep Scan can automatically read some of these fields straight from a project file — the rest have to be entered by hand. This table shows what\'s automatic for each supported DAW today.'**
  String get metadataExtractionIntro;

  /// No description provided for @metadataFieldKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get metadataFieldKey;

  /// No description provided for @metadataFieldVersion.
  ///
  /// In en, this message translates to:
  /// **'DAW Version'**
  String get metadataFieldVersion;

  /// No description provided for @metadataExtractionManualNote.
  ///
  /// In en, this message translates to:
  /// **'Any field without automatic support can still be entered manually in Project Detail. For BPM and Key specifically, dropping a bpm.txt or key.txt file next to the project is also picked up on the next scan.'**
  String get metadataExtractionManualNote;

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
  /// **'Are you sure you want to delete \"{profileName}\"? This will delete all projects, project folders, and releases for this profile.'**
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

  /// Confirmation message when removing a track from a release
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{trackName}\" from this release?'**
  String removeTrackFromReleaseMessage(String trackName);

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

  /// No description provided for @clearLibraryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear Library (projects & project folders)'**
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

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @filterByPhase.
  ///
  /// In en, this message translates to:
  /// **'Filter by Phase'**
  String get filterByPhase;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @allPhases.
  ///
  /// In en, this message translates to:
  /// **'All Phases'**
  String get allPhases;

  /// No description provided for @filterByDaw.
  ///
  /// In en, this message translates to:
  /// **'Filter by DAW'**
  String get filterByDaw;

  /// No description provided for @allDaws.
  ///
  /// In en, this message translates to:
  /// **'All DAWs'**
  String get allDaws;

  /// No description provided for @daw.
  ///
  /// In en, this message translates to:
  /// **'DAW'**
  String get daw;

  /// No description provided for @clearDaw.
  ///
  /// In en, this message translates to:
  /// **'Clear DAW'**
  String get clearDaw;

  /// No description provided for @filterByKey.
  ///
  /// In en, this message translates to:
  /// **'Filter by Key'**
  String get filterByKey;

  /// No description provided for @allKeys.
  ///
  /// In en, this message translates to:
  /// **'All Keys'**
  String get allKeys;

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

  /// No description provided for @scanProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading project {current} of {total}…'**
  String scanProgressLabel(int current, int total);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

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
  /// **'Remove project folder'**
  String get deleteRootPath;

  /// No description provided for @deleteRootPathMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{path}\"? This will also remove all projects from this folder that are not in releases.'**
  String deleteRootPathMessage(String path);

  /// No description provided for @rootsCount.
  ///
  /// In en, this message translates to:
  /// **'Project Folders: {count}'**
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

  /// No description provided for @deleteMissingProjects.
  ///
  /// In en, this message translates to:
  /// **'Delete Missing'**
  String get deleteMissingProjects;

  /// No description provided for @deleteMissingProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete missing projects?'**
  String get deleteMissingProjectsTitle;

  /// No description provided for @deleteMissingProjectsConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count} project{plural} whose file could not be found on this machine will be permanently deleted, along with all notes, deadlines, and session history. This can\'t be undone.'**
  String deleteMissingProjectsConfirm(int count, String plural);

  /// No description provided for @deleteMissingProjectsConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deleteMissingProjectsConfirmButton;

  /// No description provided for @missingProjectsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} missing project{plural} deleted.'**
  String missingProjectsDeleted(int count, String plural);

  /// No description provided for @deleteMissingProjectsAlsoDeleteReleaseTracked.
  ///
  /// In en, this message translates to:
  /// **'Also delete {count} project{plural} that are part of a release (removes them from that release too)'**
  String deleteMissingProjectsAlsoDeleteReleaseTracked(
    int count,
    String plural,
  );

  /// Confirmation message when hiding a project
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to hide \"{projectName}\"?'**
  String hideProjectMessage(String projectName);

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

  /// No description provided for @folderAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This folder has already been added.'**
  String get folderAlreadyAdded;

  /// No description provided for @noProjectsFoundInRoots.
  ///
  /// In en, this message translates to:
  /// **'No projects found in selected project folders.'**
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

  /// No description provided for @scanCancelled.
  ///
  /// In en, this message translates to:
  /// **'Scan cancelled.'**
  String get scanCancelled;

  /// No description provided for @scanFailuresSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{count} project{plural} failed to load.'**
  String scanFailuresSnackbar(int count, String plural);

  /// No description provided for @scanFailuresSnackbarAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get scanFailuresSnackbarAction;

  /// No description provided for @scanFailuresDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Errors'**
  String get scanFailuresDialogTitle;

  /// No description provided for @scanFailuresDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'These files could not be read during the scan (they may have been deleted, moved, or locked by another program):'**
  String get scanFailuresDialogIntro;

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

  /// Button to continue with authorization code
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

  /// No description provided for @creatingZipFile.
  ///
  /// In en, this message translates to:
  /// **'Creating ZIP file...'**
  String get creatingZipFile;

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

  /// Error message when projects fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading projects'**
  String get errorLoadingProjects;

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

  /// Error message when opening a file fails
  ///
  /// In en, this message translates to:
  /// **'Failed to open file'**
  String get failedToOpenFile;

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

  /// No description provided for @addTodoAtTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Add todo at {timestamp}'**
  String addTodoAtTimestamp(String timestamp);

  /// No description provided for @todoAddedAtTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Added todo at {timestamp}'**
  String todoAddedAtTimestamp(String timestamp);

  /// No description provided for @todoList.
  ///
  /// In en, this message translates to:
  /// **'TODO List'**
  String get todoList;

  /// No description provided for @todoTemplates.
  ///
  /// In en, this message translates to:
  /// **'TODO Templates'**
  String get todoTemplates;

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get createTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get editTemplate;

  /// No description provided for @deleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get deleteTemplate;

  /// No description provided for @deleteTemplateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete template \"{name}\"?'**
  String deleteTemplateConfirm(String name);

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get templateName;

  /// No description provided for @templateNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Mixing Checklist'**
  String get templateNameHint;

  /// No description provided for @templateItems.
  ///
  /// In en, this message translates to:
  /// **'Template Items'**
  String get templateItems;

  /// No description provided for @templateItemsHint.
  ///
  /// In en, this message translates to:
  /// **'One item per line'**
  String get templateItemsHint;

  /// No description provided for @templateNameAndItemsRequired.
  ///
  /// In en, this message translates to:
  /// **'Template name and items are required'**
  String get templateNameAndItemsRequired;

  /// No description provided for @templateItemsRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one item is required'**
  String get templateItemsRequired;

  /// No description provided for @templateCreated.
  ///
  /// In en, this message translates to:
  /// **'Template created'**
  String get templateCreated;

  /// No description provided for @templateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Template updated'**
  String get templateUpdated;

  /// No description provided for @templateDeleted.
  ///
  /// In en, this message translates to:
  /// **'Template deleted'**
  String get templateDeleted;

  /// No description provided for @noTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get noTemplatesYet;

  /// No description provided for @createFirstTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create your first TODO template'**
  String get createFirstTemplate;

  /// No description provided for @templateItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s)'**
  String templateItemCount(int count);

  /// No description provided for @selectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select Template'**
  String get selectTemplate;

  /// No description provided for @importFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'Import from Template'**
  String get importFromTemplate;

  /// No description provided for @manageTemplates.
  ///
  /// In en, this message translates to:
  /// **'Manage Templates'**
  String get manageTemplates;

  /// No description provided for @noTemplatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No templates available. Create one first.'**
  String get noTemplatesAvailable;

  /// No description provided for @templateImported.
  ///
  /// In en, this message translates to:
  /// **'Template \"{name}\" imported ({count} items)'**
  String templateImported(String name, int count);

  /// No description provided for @errorLoadingTemplates.
  ///
  /// In en, this message translates to:
  /// **'Error loading templates'**
  String get errorLoadingTemplates;

  /// No description provided for @createProjectStartFrom.
  ///
  /// In en, this message translates to:
  /// **'How do you want to start?'**
  String get createProjectStartFrom;

  /// No description provided for @createProjectStartFromHint.
  ///
  /// In en, this message translates to:
  /// **'Start from an empty folder or copy a registered template.'**
  String get createProjectStartFromHint;

  /// No description provided for @createProjectEmptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Empty Folder'**
  String get createProjectEmptyFolder;

  /// No description provided for @createProjectFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'From Template'**
  String get createProjectFromTemplate;

  /// No description provided for @selectTemplateMainFile.
  ///
  /// In en, this message translates to:
  /// **'Select the Template\'s Main Project File'**
  String get selectTemplateMainFile;

  /// No description provided for @registerTemplate.
  ///
  /// In en, this message translates to:
  /// **'Register Template'**
  String get registerTemplate;

  /// No description provided for @projectTemplates.
  ///
  /// In en, this message translates to:
  /// **'Project Templates'**
  String get projectTemplates;

  /// No description provided for @searchTemplates.
  ///
  /// In en, this message translates to:
  /// **'Search templates...'**
  String get searchTemplates;

  /// No description provided for @createFirstProjectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Register a template folder to reuse for new projects'**
  String get createFirstProjectTemplate;

  /// No description provided for @noMatchingTemplates.
  ///
  /// In en, this message translates to:
  /// **'No matching templates'**
  String get noMatchingTemplates;

  /// No description provided for @templateSourceMissing.
  ///
  /// In en, this message translates to:
  /// **'Template source folder not found'**
  String get templateSourceMissing;

  /// No description provided for @useTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useTemplate;

  /// No description provided for @selectTemplatesParentFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Parent Folder of Templates'**
  String get selectTemplatesParentFolder;

  /// No description provided for @templateSourceFolder.
  ///
  /// In en, this message translates to:
  /// **'Source Folder'**
  String get templateSourceFolder;

  /// No description provided for @dateCreatedColumn.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get dateCreatedColumn;

  /// No description provided for @dateModifiedColumn.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get dateModifiedColumn;

  /// No description provided for @manageTemplateFolders.
  ///
  /// In en, this message translates to:
  /// **'Manage Folders'**
  String get manageTemplateFolders;

  /// No description provided for @addTemplateFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get addTemplateFolder;

  /// No description provided for @removeTemplateFolder.
  ///
  /// In en, this message translates to:
  /// **'Remove Template Folder'**
  String get removeTemplateFolder;

  /// No description provided for @removeTemplateFolderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{path}\" from your registered template folders? Templates already imported from it will not be deleted.'**
  String removeTemplateFolderConfirm(String path);

  /// No description provided for @noTemplateFoldersRegistered.
  ///
  /// In en, this message translates to:
  /// **'No template folders registered'**
  String get noTemplateFoldersRegistered;

  /// No description provided for @refreshTemplateFolders.
  ///
  /// In en, this message translates to:
  /// **'Refresh templates from registered folders'**
  String get refreshTemplateFolders;

  /// No description provided for @lastRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Last refreshed {date}'**
  String lastRefreshed(String date);

  /// No description provided for @templatesRefreshedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} new template(s) added'**
  String templatesRefreshedSummary(int count);

  /// No description provided for @templatesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} template{plural} selected'**
  String templatesSelected(int count, String plural);

  /// No description provided for @deleteSelectedTemplates.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelectedTemplates;

  /// No description provided for @deleteSelectedTemplatesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} template{plural}?'**
  String deleteSelectedTemplatesConfirm(int count, String plural);

  /// No description provided for @templatesDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} template{plural} deleted'**
  String templatesDeleted(int count, String plural);

  /// No description provided for @templateDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get templateDetailTitle;

  /// No description provided for @templateNotFound.
  ///
  /// In en, this message translates to:
  /// **'Template not found'**
  String get templateNotFound;

  /// No description provided for @saveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as Template'**
  String get saveAsTemplate;

  /// No description provided for @newTemplateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get newTemplateNameLabel;

  /// No description provided for @savedAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Saved as template'**
  String get savedAsTemplate;

  /// No description provided for @duplicateTemplate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateTemplate;

  /// No description provided for @templateDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Template duplicated'**
  String get templateDuplicated;

  /// No description provided for @fileInfo.
  ///
  /// In en, this message translates to:
  /// **'File Info'**
  String get fileInfo;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @filePath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get filePath;

  /// No description provided for @fileModified.
  ///
  /// In en, this message translates to:
  /// **'Last Modified'**
  String get fileModified;

  /// No description provided for @projectsFromThisTemplate.
  ///
  /// In en, this message translates to:
  /// **'Projects Created From This Template ({count})'**
  String projectsFromThisTemplate(int count);

  /// No description provided for @noProjectsFromThisTemplate.
  ///
  /// In en, this message translates to:
  /// **'No projects created from this template yet'**
  String get noProjectsFromThisTemplate;

  /// No description provided for @importTodos.
  ///
  /// In en, this message translates to:
  /// **'Import Todos from File'**
  String get importTodos;

  /// No description provided for @noTodosInFile.
  ///
  /// In en, this message translates to:
  /// **'No todos found in file'**
  String get noTodosInFile;

  /// No description provided for @todosImported.
  ///
  /// In en, this message translates to:
  /// **'{count} todo(s) imported successfully'**
  String todosImported(int count);

  /// No description provided for @errorImportingTodos.
  ///
  /// In en, this message translates to:
  /// **'Error importing todos: {error}'**
  String errorImportingTodos(String error);

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

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Phase'**
  String get changeStatus;

  /// No description provided for @selectNewStatus.
  ///
  /// In en, this message translates to:
  /// **'Select new phase:'**
  String get selectNewStatus;

  /// Success message when status is changed for multiple projects
  ///
  /// In en, this message translates to:
  /// **'Phase changed to \"{status}\" for {count} project{plural}'**
  String statusChangedForProjects(int count, String plural, String status);

  /// Message when status change partially fails
  ///
  /// In en, this message translates to:
  /// **'Phase changed to \"{status}\" for {successCount} project{successPlural}, {failCount} failed{failPlural}'**
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  );

  /// Error message when status change fails
  ///
  /// In en, this message translates to:
  /// **'Failed to change phase: {error}'**
  String failedToChangeStatus(String error);

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
  /// **'Click to browse or drop an image'**
  String get clickToBrowseArtwork;

  /// Hint shown when dragging an image onto the artwork drop zone
  ///
  /// In en, this message translates to:
  /// **'Drop image here'**
  String get dropImageHere;

  /// Label for the remove artwork button and menu item
  ///
  /// In en, this message translates to:
  /// **'Remove Artwork'**
  String get removeArtwork;

  /// Confirmation message when removing artwork
  ///
  /// In en, this message translates to:
  /// **'Remove this artwork? The image file will be deleted.'**
  String get removeArtworkConfirm;

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

  /// No description provided for @backupTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTabLabel;

  /// No description provided for @aboutTabLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTabLabel;

  /// No description provided for @localBackup.
  ///
  /// In en, this message translates to:
  /// **'Local Backup'**
  String get localBackup;

  /// No description provided for @appearanceTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTabLabel;

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

  /// No description provided for @exportProjectInfo.
  ///
  /// In en, this message translates to:
  /// **'Export Info'**
  String get exportProjectInfo;

  /// No description provided for @exportProjectInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save this project\'s info to a text file'**
  String get exportProjectInfoTooltip;

  /// No description provided for @exportAllProjectsInfo.
  ///
  /// In en, this message translates to:
  /// **'Export All Projects to TXT'**
  String get exportAllProjectsInfo;

  /// No description provided for @exportAllProjectsInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a plain text record of every project\'s info, so it\'s kept even if you delete the DAW file later'**
  String get exportAllProjectsInfoSubtitle;

  /// No description provided for @projectInfoExported.
  ///
  /// In en, this message translates to:
  /// **'Project info exported'**
  String get projectInfoExported;

  /// Success message after exporting all projects' info to a text file
  ///
  /// In en, this message translates to:
  /// **'Exported info for {count} projects'**
  String allProjectsInfoExported(int count);

  /// Error message when exporting project info to text fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export project info: {error}'**
  String failedToExportProjectInfo(String error);

  /// No description provided for @projectExportHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'DAW PROJECT MANAGER — PROJECT EXPORT'**
  String get projectExportHeaderTitle;

  /// Timestamp line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'Exported: {dateTime}'**
  String projectExportExportedLabel(String dateTime);

  /// Project count line in a plain-text bulk export
  ///
  /// In en, this message translates to:
  /// **'Total projects: {count}'**
  String projectExportTotalProjectsLabel(int count);

  /// Project name line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'Project: {name}'**
  String projectExportProjectLabel(String name);

  /// DAW type line in a plain-text project export, no version known
  ///
  /// In en, this message translates to:
  /// **'DAW: {dawType}'**
  String projectExportDawLabel(String dawType);

  /// DAW type + version line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'DAW: {dawType} {version}'**
  String projectExportDawWithVersionLabel(String dawType, String version);

  /// Status line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String projectExportStatusLabel(String status);

  /// BPM line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'BPM: {bpm}'**
  String projectExportBpmLabel(String bpm);

  /// Musical key line in a plain-text project export, no Camelot code known
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String projectExportKeyLabel(String key);

  /// Musical key + Camelot code line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'Key: {key} (Camelot {code})'**
  String projectExportKeyWithCamelotLabel(String key, String code);

  /// File path line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'File path: {path}'**
  String projectExportFilePathLabel(String path);

  /// File size line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'File size: {size}'**
  String projectExportFileSizeLabel(String size);

  /// File creation date line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'File created: {date}'**
  String projectExportFileCreatedLabel(String date);

  /// Date added to library line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'Added to library: {date}'**
  String projectExportAddedToLibraryLabel(String date);

  /// Last modified date line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'Last modified: {date}'**
  String projectExportLastModifiedLabel(String date);

  /// Deadline line in a plain-text project export, no status known
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date}'**
  String projectExportDeadlineLabel(String date);

  /// Deadline + status line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date} ({status})'**
  String projectExportDeadlineWithStatusLabel(String date, String status);

  /// Total time worked line in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'Total time worked: {duration}'**
  String projectExportTotalTimeWorkedLabel(String duration);

  /// No description provided for @projectExportNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get projectExportNotesLabel;

  /// No description provided for @projectExportTodosLabel.
  ///
  /// In en, this message translates to:
  /// **'To-dos:'**
  String get projectExportTodosLabel;

  /// Work sessions section header in a plain-text project export
  ///
  /// In en, this message translates to:
  /// **'Work sessions ({count}):'**
  String projectExportWorkSessionsLabel(int count);

  /// No description provided for @noProjectsToExport.
  ///
  /// In en, this message translates to:
  /// **'No projects to export'**
  String get noProjectsToExport;

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
  /// **'Backup imported successfully: {projectsCount} projects, {rootsCount} project folders, {releasesCount} releases'**
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
  /// **'Backup imported to new profile \"{profileName}\": {projectsCount} projects, {rootsCount} project folders, {releasesCount} releases'**
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

  /// No description provided for @exportBackupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackupDialogTitle;

  /// No description provided for @importBackupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackupDialogTitle;

  /// No description provided for @invalidBackupFileFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file format: missing version'**
  String get invalidBackupFileFormat;

  /// No description provided for @profileNameRequiredForNewProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile name is required when creating a new profile'**
  String get profileNameRequiredForNewProfile;

  /// No description provided for @currentProfileRequired.
  ///
  /// In en, this message translates to:
  /// **'Current profile is required for merge or replace mode'**
  String get currentProfileRequired;

  /// No description provided for @previewSong.
  ///
  /// In en, this message translates to:
  /// **'Preview Song'**
  String get previewSong;

  /// No description provided for @noPreviewSongTitle.
  ///
  /// In en, this message translates to:
  /// **'No Preview Song'**
  String get noPreviewSongTitle;

  /// No description provided for @noPreviewSongMessage.
  ///
  /// In en, this message translates to:
  /// **'This project has no preview song set. Select an audio file to load and play it.'**
  String get noPreviewSongMessage;

  /// No description provided for @noPreviewSongDragHint.
  ///
  /// In en, this message translates to:
  /// **'You can also drag and drop an audio file directly onto the project row in the table.'**
  String get noPreviewSongDragHint;

  /// No description provided for @previewSongRemoved.
  ///
  /// In en, this message translates to:
  /// **'Preview song removed'**
  String get previewSongRemoved;

  /// No description provided for @previewSongAdded.
  ///
  /// In en, this message translates to:
  /// **'Preview song added'**
  String get previewSongAdded;

  /// No description provided for @previewSongFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Preview song file not found'**
  String get previewSongFileNotFound;

  /// No description provided for @previewSongFileNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The preview song file could not be found on disk. Would you like to select a new file or remove the entry?'**
  String get previewSongFileNotFoundMessage;

  /// No description provided for @selectNewFile.
  ///
  /// In en, this message translates to:
  /// **'Select New File'**
  String get selectNewFile;

  /// No description provided for @failedToPlayPreview.
  ///
  /// In en, this message translates to:
  /// **'Failed to play preview: {error}'**
  String failedToPlayPreview(String error);

  /// No description provided for @removePreviewSong.
  ///
  /// In en, this message translates to:
  /// **'Remove preview song'**
  String get removePreviewSong;

  /// No description provided for @removePreviewSongConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the preview song? This action cannot be undone.'**
  String get removePreviewSongConfirm;

  /// No description provided for @noPreviewSongSelected.
  ///
  /// In en, this message translates to:
  /// **'No preview song selected'**
  String get noPreviewSongSelected;

  /// No description provided for @changePreviewSong.
  ///
  /// In en, this message translates to:
  /// **'Change Preview Song'**
  String get changePreviewSong;

  /// No description provided for @selectPreviewSong.
  ///
  /// In en, this message translates to:
  /// **'Select Preview Song'**
  String get selectPreviewSong;

  /// No description provided for @dropAudioFileHere.
  ///
  /// In en, this message translates to:
  /// **'Drop audio file here'**
  String get dropAudioFileHere;

  /// No description provided for @projectAge.
  ///
  /// In en, this message translates to:
  /// **'Project age: {age}'**
  String projectAge(String age);

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'created {date}'**
  String createdDate(String date);

  /// No description provided for @completedIn.
  ///
  /// In en, this message translates to:
  /// **'Completed in: {duration}'**
  String completedIn(String duration);

  /// No description provided for @finishedDate.
  ///
  /// In en, this message translates to:
  /// **'finished {date}'**
  String finishedDate(String date);

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String dateDaysAgo(int count);

  /// No description provided for @dateWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String dateWeeksAgo(int count);

  /// No description provided for @dateMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String dateMonthsAgo(int count);

  /// No description provided for @dateYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String dateYearsAgo(int count, Object plural);

  /// No description provided for @ageYearsMonths.
  ///
  /// In en, this message translates to:
  /// **'{years} year{yearPlural}, {months} month{monthPlural}'**
  String ageYearsMonths(
    int years,
    String yearPlural,
    int months,
    String monthPlural,
  );

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{years} year{plural}'**
  String ageYears(int years, String plural);

  /// No description provided for @ageMonthsDays.
  ///
  /// In en, this message translates to:
  /// **'{months} month{monthPlural}, {days} day{dayPlural}'**
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  );

  /// No description provided for @ageMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} month{plural}'**
  String ageMonths(int months, String plural);

  /// No description provided for @ageDays.
  ///
  /// In en, this message translates to:
  /// **'{days} day{plural}'**
  String ageDays(int days, String plural);

  /// No description provided for @ageHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hour{plural}'**
  String ageHours(int hours, String plural);

  /// No description provided for @ageJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get ageJustNow;

  /// No description provided for @ageLessThanHour.
  ///
  /// In en, this message translates to:
  /// **'Less than an hour'**
  String get ageLessThanHour;

  /// Button to view profile details
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// Title for Google Drive sync section
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get googleDriveSync;

  /// Short label for the Google Drive navigation button
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// Description text for Google Drive sync feature
  ///
  /// In en, this message translates to:
  /// **'Sync your data with Google Drive to backup and restore across devices.'**
  String get googleDriveSyncDescription;

  /// Button to open Google Drive sync management page
  ///
  /// In en, this message translates to:
  /// **'Manage Google Drive Sync'**
  String get manageGoogleDriveSync;

  /// Button to sign in to Google Drive
  ///
  /// In en, this message translates to:
  /// **'Sign in to Google Drive'**
  String get signInToGoogleDrive;

  /// Button to sync data with Google Drive
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// Button to upload backup to Google Drive
  ///
  /// In en, this message translates to:
  /// **'Upload Backup'**
  String get uploadBackup;

  /// Button to download backup from Google Drive
  ///
  /// In en, this message translates to:
  /// **'Download Backup'**
  String get downloadBackup;

  /// No description provided for @newerBackupAvailable.
  ///
  /// In en, this message translates to:
  /// **'New backup available on cloud'**
  String get newerBackupAvailable;

  /// Context menu option to restore a single project from Google Drive backup
  ///
  /// In en, this message translates to:
  /// **'Restore from Drive'**
  String get restoreProjectFromDrive;

  /// Progress message shown while restoring a single project from Drive
  ///
  /// In en, this message translates to:
  /// **'Restoring from Drive...'**
  String get restoringProjectFromDrive;

  /// Success message shown after restoring a project from Drive
  ///
  /// In en, this message translates to:
  /// **'Project restored from Drive'**
  String get projectRestoredFromDrive;

  /// Error shown when the project doesn't exist in the remote backup
  ///
  /// In en, this message translates to:
  /// **'This project was not found in the Drive backup'**
  String get projectNotFoundInBackup;

  /// Error shown when trying to restore from Drive but not authenticated
  ///
  /// In en, this message translates to:
  /// **'Please sign in to Google Drive first (open Drive Sync settings)'**
  String get signInToGoogleDriveFirst;

  /// Button to sign out from Google Drive
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Checkbox label for downloading preview songs
  ///
  /// In en, this message translates to:
  /// **'Download preview songs'**
  String get downloadPreviewSongs;

  /// Explanation text for preview songs download option
  ///
  /// In en, this message translates to:
  /// **'If unchecked, preview songs will be skipped (saves time and storage). You can download them later if needed.'**
  String get downloadPreviewSongsExplanation;

  /// Button to confirm replacing local data with backup
  ///
  /// In en, this message translates to:
  /// **'Replace Local Data'**
  String get replaceLocalData;

  /// Confirmation message for downloading backup
  ///
  /// In en, this message translates to:
  /// **'This will replace your local data with the backup from Google Drive.\n\nAre you sure you want to continue?'**
  String get downloadBackupConfirmation;

  /// Dialog title for entering authorization code
  ///
  /// In en, this message translates to:
  /// **'Enter Authorization Code'**
  String get enterAuthorizationCode;

  /// Label for authorization code input field
  ///
  /// In en, this message translates to:
  /// **'Authorization Code'**
  String get authorizationCode;

  /// Hint text for authorization code input field
  ///
  /// In en, this message translates to:
  /// **'Paste the code from the browser'**
  String get pasteCodeFromBrowser;

  /// Status message when Google Drive session is active
  ///
  /// In en, this message translates to:
  /// **'Session active'**
  String get sessionActive;

  /// Status message when signed in to Google Drive
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// Status message when creating initial backup
  ///
  /// In en, this message translates to:
  /// **'Creating initial backup...'**
  String get creatingInitialBackup;

  /// Success message when signed in and backed up
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in and backed up to Google Drive'**
  String get successfullySignedInAndBackedUp;

  /// Snackbar message when signed in and backed up
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in and backed up to Google Drive!'**
  String get successfullySignedInAndBackedUpMessage;

  /// Success message when signed in
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in to Google Drive'**
  String get successfullySignedInToGoogleDrive;

  /// Snackbar message when signed in
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in to Google Drive!'**
  String get successfullySignedInToGoogleDriveMessage;

  /// Error message when sign in is cancelled or failed
  ///
  /// In en, this message translates to:
  /// **'Sign in cancelled or failed. Check console for details.'**
  String get signInCancelledOrFailed;

  /// Error message when browser launch fails
  ///
  /// In en, this message translates to:
  /// **'Failed to launch browser'**
  String get failedToLaunchBrowser;

  /// Status message when sign in is cancelled
  ///
  /// In en, this message translates to:
  /// **'Sign in cancelled'**
  String get signInCancelled;

  /// Error message when authorization code exchange fails
  ///
  /// In en, this message translates to:
  /// **'Failed to exchange authorization code'**
  String get failedToExchangeAuthorizationCode;

  /// No description provided for @errorSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Error signing in: {error}'**
  String errorSigningIn(String error);

  /// Generic unknown error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// Error title for Google Sign-In errors
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In Error'**
  String get googleSignInError;

  /// Error message for OAuth configuration issues
  ///
  /// In en, this message translates to:
  /// **'Developer console is not set up correctly. Please check your OAuth configuration in Google Cloud Console.'**
  String get developerConsoleNotSetUp;

  /// Error title for platform errors
  ///
  /// In en, this message translates to:
  /// **'Platform Error'**
  String get platformError;

  /// Status message when signed out
  ///
  /// In en, this message translates to:
  /// **'Signed out from Google Drive'**
  String get signedOutFromGoogleDrive;

  /// No description provided for @errorSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out: {error}'**
  String errorSigningOut(String error);

  /// Status message when syncing
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// Error message when no profile is selected
  ///
  /// In en, this message translates to:
  /// **'Error: No profile selected'**
  String get errorNoProfileSelected;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed! Projects: +{projectsAdded} ~{projectsUpdated}, Releases: +{releasesAdded} ~{releasesUpdated}'**
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  );

  /// No description provided for @errorSyncing.
  ///
  /// In en, this message translates to:
  /// **'Error syncing: {error}'**
  String errorSyncing(String error);

  /// Status message when uploading backup
  ///
  /// In en, this message translates to:
  /// **'Uploading backup...'**
  String get uploadingBackup;

  /// Status message when backup is uploaded
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded successfully!'**
  String get backupUploadedSuccessfully;

  /// Snackbar message when backup is uploaded
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded successfully to Google Drive!'**
  String get backupUploadedSuccessfullyMessage;

  /// No description provided for @errorUploadingBackup.
  ///
  /// In en, this message translates to:
  /// **'Error uploading backup: {error}'**
  String errorUploadingBackup(String error);

  /// Status message when downloading backup
  ///
  /// In en, this message translates to:
  /// **'Downloading backup...'**
  String get downloadingBackup;

  /// Status message when checking for backup
  ///
  /// In en, this message translates to:
  /// **'Checking for backup...'**
  String get checkingForBackup;

  /// Message when backup is current
  ///
  /// In en, this message translates to:
  /// **'Backup is up to date'**
  String get backupUpToDate;

  /// No description provided for @errorCheckingBackup.
  ///
  /// In en, this message translates to:
  /// **'Error checking backup: {error}'**
  String errorCheckingBackup(String error);

  /// Download button label
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Warning when remote backup is newer
  ///
  /// In en, this message translates to:
  /// **'Remote backup is newer than local data. Uploading will overwrite it.'**
  String get remoteBackupIsNewer;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Upload'**
  String get confirmUpload;

  /// Message when no backup file is found
  ///
  /// In en, this message translates to:
  /// **'No backup file found in Google Drive. Create a backup first by syncing your data.'**
  String get noBackupFileFound;

  /// Status message when no backup file is found
  ///
  /// In en, this message translates to:
  /// **'No backup file found. Create a backup first.'**
  String get noBackupFileFoundStatus;

  /// Status message when download is cancelled
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get downloadCancelled;

  /// No description provided for @backupDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Backup downloaded! Projects: +{projectsAdded} ~{projectsUpdated}, Releases: +{releasesAdded} ~{releasesUpdated}'**
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  );

  /// No description provided for @backupDownloadedDetailed.
  ///
  /// In en, this message translates to:
  /// **'Backup downloaded!\n\nProjects:\n  • {projectsAdded} added\n  • {projectsUpdated} updated\n\nReleases:\n  • {releasesAdded} added\n  • {releasesUpdated} updated\n\nPreview Songs:\n  • {previewSongsDownloaded} downloaded\n  • {previewSongsUpdated} updated'**
  String backupDownloadedDetailed(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
    int previewSongsDownloaded,
    int previewSongsUpdated,
  );

  /// No description provided for @errorDownloadingBackup.
  ///
  /// In en, this message translates to:
  /// **'Error downloading backup: {error}'**
  String errorDownloadingBackup(String error);

  /// No description provided for @notSignedInYet.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedInYet;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as: {email}'**
  String signedInAs(String email);

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {date}'**
  String lastSync(String date);

  /// No description provided for @remoteBackupTime.
  ///
  /// In en, this message translates to:
  /// **'Remote backup: {date}'**
  String remoteBackupTime(String date);

  /// No description provided for @lastUploadTime.
  ///
  /// In en, this message translates to:
  /// **'Last upload: {date}'**
  String lastUploadTime(String date);

  /// No description provided for @lastDownloadTime.
  ///
  /// In en, this message translates to:
  /// **'Last download: {date}'**
  String lastDownloadTime(String date);

  /// Button to check if newer backup is available
  ///
  /// In en, this message translates to:
  /// **'Check for Backup'**
  String get checkForBackup;

  /// Title for notification settings page
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Message shown on non-Android platforms
  ///
  /// In en, this message translates to:
  /// **'Deadline notifications are only available on Android devices.'**
  String get notificationsOnlyOnAndroid;

  /// Title for permission request card
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Required'**
  String get notificationPermissionRequired;

  /// Description for permission request
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications to receive deadline reminders.'**
  String get notificationPermissionDescription;

  /// Error message when permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied. Please enable it in settings.'**
  String get notificationPermissionDenied;

  /// Success message after saving settings
  ///
  /// In en, this message translates to:
  /// **'Notification settings saved successfully'**
  String get notificationSettingsSaved;

  /// Error message when saving fails
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get errorSavingSettings;

  /// Toggle to enable/disable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Deadline Notifications'**
  String get enableDeadlineNotifications;

  /// Description for enable toggle
  ///
  /// In en, this message translates to:
  /// **'Receive reminders for project deadlines'**
  String get receiveRemindersForDeadlines;

  /// Title for time picker
  ///
  /// In en, this message translates to:
  /// **'Notification Time'**
  String get notificationTime;

  /// Description for time picker
  ///
  /// In en, this message translates to:
  /// **'Time of day to receive notifications'**
  String get timeToReceiveNotifications;

  /// Title for reminder days section
  ///
  /// In en, this message translates to:
  /// **'Reminder Days'**
  String get reminderDays;

  /// Description for reminder days
  ///
  /// In en, this message translates to:
  /// **'Select how many days before the deadline you want to be notified'**
  String get selectDaysBeforeDeadline;

  /// Toggle for deadline day notification
  ///
  /// In en, this message translates to:
  /// **'Notify on Deadline Day'**
  String get notifyOnDeadlineDay;

  /// Description for deadline day toggle
  ///
  /// In en, this message translates to:
  /// **'Also receive a notification on the deadline day itself'**
  String get receiveNotificationOnDeadlineDay;

  /// Title for help section
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// Help text explaining notifications
  ///
  /// In en, this message translates to:
  /// **'You will receive notifications at the specified time on the selected days before each project deadline. Tap a notification to open the project details.'**
  String get deadlineNotificationsHelp;

  /// One day label for reminder chips
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get oneDay;

  /// Multiple days label for reminder chips
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String xDays(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @searchSettings.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get searchSettings;

  /// No description provided for @noSettingsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No settings found for \"{query}\"'**
  String noSettingsFoundFor(String query);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @languageSettingDescription.
  ///
  /// In en, this message translates to:
  /// **'The language used throughout the app.'**
  String get languageSettingDescription;

  /// No description provided for @themeSettingDescription.
  ///
  /// In en, this message translates to:
  /// **'The app\'s color theme.'**
  String get themeSettingDescription;

  /// Appearance setting: which waveform rendering the audio preview uses
  ///
  /// In en, this message translates to:
  /// **'Waveform Style'**
  String get waveformStyle;

  /// Subtitle under the Waveform Style setting
  ///
  /// In en, this message translates to:
  /// **'How the audio preview waveform is drawn.'**
  String get waveformStyleSettingDescription;

  /// Waveform style option: the per-pixel bar rendering with an RMS body
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get waveformStyleDetailed;

  /// No description provided for @waveformStyleDetailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Per-pixel bars with a shaded body, like a DAW.'**
  String get waveformStyleDetailedDescription;

  /// Waveform style option: the original filled envelope rendering
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get waveformStyleClassic;

  /// No description provided for @waveformStyleClassicDescription.
  ///
  /// In en, this message translates to:
  /// **'A single filled outline.'**
  String get waveformStyleClassicDescription;

  /// Appearance setting and waveform context menu: single vs dual channel lanes
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get waveformChannels;

  /// Subtitle under the Channels setting
  ///
  /// In en, this message translates to:
  /// **'Whether the waveform splits stereo into two lanes.'**
  String get waveformChannelsSettingDescription;

  /// Channel option: one lane showing the stereo mixdown
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get waveformChannelsSingle;

  /// Channel option: left and right drawn as separate stacked lanes
  ///
  /// In en, this message translates to:
  /// **'Dual'**
  String get waveformChannelsDual;

  /// No description provided for @waveformChannelsSingleDescription.
  ///
  /// In en, this message translates to:
  /// **'One lane showing the stereo mixdown.'**
  String get waveformChannelsSingleDescription;

  /// No description provided for @waveformChannelsDualDescription.
  ///
  /// In en, this message translates to:
  /// **'Left and right stacked as separate lanes.'**
  String get waveformChannelsDualDescription;

  /// Shown in the waveform context menu when the file is mono
  ///
  /// In en, this message translates to:
  /// **'This file has only one channel'**
  String get waveformChannelsUnavailable;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @shareDiagnosticLog.
  ///
  /// In en, this message translates to:
  /// **'Share Diagnostic Log'**
  String get shareDiagnosticLog;

  /// No description provided for @shareDiagnosticLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No diagnostic log yet'**
  String get shareDiagnosticLogEmpty;

  /// No description provided for @shareDiagnosticLogFolderOpened.
  ///
  /// In en, this message translates to:
  /// **'Sharing isn\'t available here — opened the log folder instead so you can attach the file manually.'**
  String get shareDiagnosticLogFolderOpened;

  /// No description provided for @enableDiagnosticLogging.
  ///
  /// In en, this message translates to:
  /// **'Enable Diagnostic Logging'**
  String get enableDiagnosticLogging;

  /// No description provided for @enableDiagnosticLoggingDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeps a small log of crashes and errors on this device, so you can share it if something goes wrong. Off by default.'**
  String get enableDiagnosticLoggingDescription;

  /// No description provided for @clearDiagnosticLog.
  ///
  /// In en, this message translates to:
  /// **'Clear Diagnostic Log'**
  String get clearDiagnosticLog;

  /// No description provided for @clearDiagnosticLogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Diagnostic Log?'**
  String get clearDiagnosticLogConfirmTitle;

  /// No description provided for @clearDiagnosticLogConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the diagnostic log file. This can\'t be undone.'**
  String get clearDiagnosticLogConfirmMessage;

  /// No description provided for @diagnosticLogCleared.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic log cleared'**
  String get diagnosticLogCleared;

  /// No description provided for @supportTheProject.
  ///
  /// In en, this message translates to:
  /// **'Support the project'**
  String get supportTheProject;

  /// No description provided for @couldNotOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open browser. Please visit: {url}'**
  String couldNotOpenBrowser(String url);

  /// No description provided for @errorOpeningBrowser.
  ///
  /// In en, this message translates to:
  /// **'Error opening browser: {error}'**
  String errorOpeningBrowser(String error);

  /// No description provided for @generateTestingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Generate Testing Database'**
  String get generateTestingDatabase;

  /// No description provided for @generateTestingDatabaseMessage.
  ///
  /// In en, this message translates to:
  /// **'This will create (or refresh) a dedicated \"Demo — Screenshots\" profile filled with a large variety of sample projects, releases, and playlists across every supported DAW, and switch you to it. Your other profiles are left untouched. Continue?'**
  String get generateTestingDatabaseMessage;

  /// No description provided for @testingDatabaseGenerated.
  ///
  /// In en, this message translates to:
  /// **'Demo profile ready — switched to it!'**
  String get testingDatabaseGenerated;

  /// No description provided for @failedToGenerateTestingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate testing database: {error}'**
  String failedToGenerateTestingDatabase(String error);

  /// No description provided for @removeTestingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Remove Testing Database'**
  String get removeTestingDatabase;

  /// No description provided for @removeTestingDatabaseMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the \"Demo — Screenshots\" profile and all of its sample projects, releases, playlists, and preview audio files. Continue?'**
  String get removeTestingDatabaseMessage;

  /// No description provided for @testingDatabaseRemoved.
  ///
  /// In en, this message translates to:
  /// **'Demo data removed.'**
  String get testingDatabaseRemoved;

  /// No description provided for @noTestingDatabaseFound.
  ///
  /// In en, this message translates to:
  /// **'No demo data found to remove.'**
  String get noTestingDatabaseFound;

  /// No description provided for @failedToRemoveTestingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove testing database: {error}'**
  String failedToRemoveTestingDatabase(String error);

  /// Playlists tab title
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// Message shown on desktop when trying to access playlists
  ///
  /// In en, this message translates to:
  /// **'Playlists are only available on Android.'**
  String get playlistsDesktopOnly;

  /// Message when there are no playlists
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylistsYet;

  /// Hint text for creating first playlist
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to create your first playlist'**
  String get createFirstPlaylist;

  /// Number of songs in playlist
  ///
  /// In en, this message translates to:
  /// **'{count} songs'**
  String playlistSongCount(int count);

  /// Dialog title for creating a playlist
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// Label for playlist name field
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// Placeholder for playlist name input
  ///
  /// In en, this message translates to:
  /// **'My Playlist'**
  String get playlistNameHint;

  /// Error message when playlist name is empty
  ///
  /// In en, this message translates to:
  /// **'Playlist name is required'**
  String get playlistNameRequired;

  /// Dialog title for editing a playlist
  ///
  /// In en, this message translates to:
  /// **'Edit Playlist'**
  String get editPlaylist;

  /// Message shown when trying to edit playlist while music is playing
  ///
  /// In en, this message translates to:
  /// **'Please stop playback before editing the playlist'**
  String get stopPlaybackBeforeEditing;

  /// Label for selecting preview songs in playlist
  ///
  /// In en, this message translates to:
  /// **'Select Preview Songs'**
  String get selectPreviewSongs;

  /// Dialog title for deleting a playlist
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// Confirmation message for deleting a playlist
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deletePlaylistConfirm(String name);

  /// Success message after deleting a playlist
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get playlistDeleted;

  /// Error message when playlist deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting playlist'**
  String get errorDeletingPlaylist;

  /// No description provided for @playlistUpdated.
  ///
  /// In en, this message translates to:
  /// **'Playlist updated'**
  String get playlistUpdated;

  /// No description provided for @changeSong.
  ///
  /// In en, this message translates to:
  /// **'Change Song'**
  String get changeSong;

  /// No description provided for @changeSongConfirm.
  ///
  /// In en, this message translates to:
  /// **'A song is currently playing. Do you want to switch to this song?'**
  String get changeSongConfirm;

  /// No description provided for @changeSongButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeSongButton;

  /// Current position in playlist
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String playlistProgress(int current, int total);

  /// Message when playlist has no valid preview songs
  ///
  /// In en, this message translates to:
  /// **'No preview songs available in this playlist'**
  String get noPreviewSongsInPlaylist;

  /// Hint message to edit empty playlist
  ///
  /// In en, this message translates to:
  /// **'Tap edit to add songs to this playlist'**
  String get tapEditToAddSongs;

  /// Error message when trying to add songs but no projects available
  ///
  /// In en, this message translates to:
  /// **'No projects with preview songs available to add'**
  String get noProjectsAvailableForPlaylist;

  /// Error message when there are no projects at all in the database
  ///
  /// In en, this message translates to:
  /// **'No projects found in database. Please sync your projects first.'**
  String get noProjectsInDatabase;

  /// Title for first-time sync message on mobile
  ///
  /// In en, this message translates to:
  /// **'It seems it\'s your first time here!'**
  String get firstTimeSyncTitle;

  /// Message explaining to sync data from Google Drive
  ///
  /// In en, this message translates to:
  /// **'Let\'s sync your data from Google Drive to get started'**
  String get firstTimeSyncMessage;

  /// Button text to sync with Google Drive
  ///
  /// In en, this message translates to:
  /// **'Sync with Google Drive'**
  String get syncWithGoogleDrive;

  /// Error message when playlists fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading playlists'**
  String get errorLoadingPlaylists;

  /// Label for playlist items section
  ///
  /// In en, this message translates to:
  /// **'Playlist Items'**
  String get playlistItems;

  /// Button to add songs to playlist
  ///
  /// In en, this message translates to:
  /// **'Add Songs'**
  String get addSongs;

  /// Button to add audio files directly
  ///
  /// In en, this message translates to:
  /// **'Add Audio Files'**
  String get addAudioFiles;

  /// Dialog title for selecting audio files
  ///
  /// In en, this message translates to:
  /// **'Select Audio Files'**
  String get selectAudioFiles;

  /// Label for selecting from existing projects
  ///
  /// In en, this message translates to:
  /// **'Select from Projects'**
  String get selectFromProjects;

  /// Button to add selected items
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Tooltip/title for adding a to-do from the player, tagged with the current playback time
  ///
  /// In en, this message translates to:
  /// **'Add task at current time'**
  String get addTaskAtTimestamp;

  /// Hint text for the to-do description field in the player's add-task sheet
  ///
  /// In en, this message translates to:
  /// **'Task description'**
  String get taskDescriptionHint;

  /// Snackbar shown after adding a to-do from the player
  ///
  /// In en, this message translates to:
  /// **'Task added'**
  String get taskAdded;

  /// Label indicating item is from a project
  ///
  /// In en, this message translates to:
  /// **'From Project'**
  String get fromProject;

  /// Label for project deadline field
  ///
  /// In en, this message translates to:
  /// **'Project Deadline'**
  String get projectDeadline;

  /// Message when no deadline is set for a project
  ///
  /// In en, this message translates to:
  /// **'No deadline set'**
  String get noDeadlineSet;

  /// Label for Camelot Wheel notation
  ///
  /// In en, this message translates to:
  /// **'Camelot Code'**
  String get camelotCode;

  /// Label for deadline column
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// Status text when deadline is today
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// Status text when deadline is overdue
  ///
  /// In en, this message translates to:
  /// **'{days}d late'**
  String daysLate(int days);

  /// Status text for days remaining until deadline
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String daysLeft(int days);

  /// Checkbox label to hide finished projects
  ///
  /// In en, this message translates to:
  /// **'Hide Finished'**
  String get hideFinished;

  /// No description provided for @showOnlyDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Show Deadline'**
  String get showOnlyDeadlines;

  /// Dropdown hint for deadline filter
  ///
  /// In en, this message translates to:
  /// **'Filter by Deadline'**
  String get filterByDeadline;

  /// Show all projects regardless of deadline
  ///
  /// In en, this message translates to:
  /// **'All Deadlines'**
  String get allDeadlines;

  /// Show only projects with deadlines
  ///
  /// In en, this message translates to:
  /// **'Has Deadline'**
  String get hasDeadline;

  /// Show only overdue projects
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// Show projects due within 7 days
  ///
  /// In en, this message translates to:
  /// **'Due Soon (7d)'**
  String get dueSoon;

  /// Short text for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Tooltip when project has no preview song
  ///
  /// In en, this message translates to:
  /// **'No preview song'**
  String get noPreviewSong;

  /// Tooltip for play preview button
  ///
  /// In en, this message translates to:
  /// **'Play Preview'**
  String get playPreview;

  /// Status message when backup upload is cancelled
  ///
  /// In en, this message translates to:
  /// **'Upload cancelled'**
  String get uploadCancelled;

  /// Message shown when user cancels backup upload
  ///
  /// In en, this message translates to:
  /// **'Backup upload cancelled by user'**
  String get backupUploadCancelledByUser;

  /// Status message when collecting data for backup
  ///
  /// In en, this message translates to:
  /// **'Collecting data...'**
  String get collectingData;

  /// Status message when uploading preview song files
  ///
  /// In en, this message translates to:
  /// **'Uploading preview songs...'**
  String get uploadingPreviewSongs;

  /// Status message when uploading profile photo files
  ///
  /// In en, this message translates to:
  /// **'Uploading profile photos...'**
  String get uploadingProfilePhotos;

  /// Status message when uploading release artwork files
  ///
  /// In en, this message translates to:
  /// **'Uploading release artwork...'**
  String get uploadingReleaseArtwork;

  /// Status message when uploading database file
  ///
  /// In en, this message translates to:
  /// **'Uploading database...'**
  String get uploadingDatabase;

  /// Status message when operation is completed
  ///
  /// In en, this message translates to:
  /// **'Completed!'**
  String get completed;

  /// Status message when cancelling an operation
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get cancelling;

  /// Title for backup upload progress dialog
  ///
  /// In en, this message translates to:
  /// **'Uploading Backup'**
  String get uploadingBackupTitle;

  /// Status message during upload cancellation
  ///
  /// In en, this message translates to:
  /// **'Cancelling upload...'**
  String get cancellingUpload;

  /// Message shown while stopping upload operation
  ///
  /// In en, this message translates to:
  /// **'Please wait while we stop the upload...'**
  String get pleaseWaitCancellingUpload;

  /// Status message when downloading database file
  ///
  /// In en, this message translates to:
  /// **'Downloading database...'**
  String get downloadingDatabase;

  /// Status message when downloading preview song files
  ///
  /// In en, this message translates to:
  /// **'Downloading preview songs...'**
  String get downloadingPreviewSongs;

  /// Status message when downloading profile photo files
  ///
  /// In en, this message translates to:
  /// **'Downloading profile photos...'**
  String get downloadingProfilePhotos;

  /// Status message when downloading release artwork files
  ///
  /// In en, this message translates to:
  /// **'Downloading release artwork...'**
  String get downloadingReleaseArtwork;

  /// Status message when merging downloaded data
  ///
  /// In en, this message translates to:
  /// **'Merging data...'**
  String get mergingData;

  /// Title for backup download progress dialog
  ///
  /// In en, this message translates to:
  /// **'Downloading Backup'**
  String get downloadingBackupTitle;

  /// Tooltip shown when the project source file does not exist on the current machine
  ///
  /// In en, this message translates to:
  /// **'Source file not found on this machine'**
  String get sourceFileNotFoundOnThisMachine;

  /// Tooltip shown when the Extract Metadata action is disabled because this project's DAW has no metadata extraction implemented
  ///
  /// In en, this message translates to:
  /// **'Metadata extraction is not supported for this DAW'**
  String get metadataExtractionNotSupportedForDaw;

  /// Banner shown in project detail when the source file is missing; user can still edit metadata
  ///
  /// In en, this message translates to:
  /// **'Source file not found on this machine — metadata-only mode. You can still edit and export metadata.'**
  String get sourceFileNotFoundMetadataOnly;

  /// Message shown when preview song is not available locally and needs to be downloaded
  ///
  /// In en, this message translates to:
  /// **'Preview song not available. Please download backup first.'**
  String get previewSongNotAvailableDownloadFirst;

  /// Tooltip for the share preview song button
  ///
  /// In en, this message translates to:
  /// **'Share preview song'**
  String get sharePreviewSong;

  /// Tooltip for the share as ZIP button
  ///
  /// In en, this message translates to:
  /// **'Share as ZIP'**
  String get shareAsZip;

  /// Label for the share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @convertingAudioForSharing.
  ///
  /// In en, this message translates to:
  /// **'Preparing audio for sharing…'**
  String get convertingAudioForSharing;

  /// No description provided for @shareSheetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The system share menu isn\'t available here — use the \"Drag to Share\" chip on the song preview to drag the file onto another app instead.'**
  String get shareSheetUnavailable;

  /// No description provided for @dragToShare.
  ///
  /// In en, this message translates to:
  /// **'Drag to Share'**
  String get dragToShare;

  /// No description provided for @dragToShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Drag this onto another app\'s window (e.g. WhatsApp) to share the file directly — useful when the Share button doesn\'t open a share menu.'**
  String get dragToShareTooltip;

  /// No description provided for @mp3ConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Audio conversion isn\'t available on this system — sharing the original file, which some apps like WhatsApp may reject.'**
  String get mp3ConversionFailed;

  /// Label for the share as ZIP button
  ///
  /// In en, this message translates to:
  /// **'Share ZIP'**
  String get shareZip;

  /// Desktop save a copy: saveCopy
  ///
  /// In en, this message translates to:
  /// **'Save a copy'**
  String get saveCopy;

  /// Desktop save a copy: savedCopyTo
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String savedCopyTo(String path);

  /// Error message when sharing preview song fails
  ///
  /// In en, this message translates to:
  /// **'Failed to share preview song: {error}'**
  String failedToSharePreviewSong(String error);

  /// Error message when sharing preview song as ZIP fails
  ///
  /// In en, this message translates to:
  /// **'Failed to share preview song as ZIP: {error}'**
  String failedToSharePreviewSongAsZip(String error);

  /// Success message when biography is saved
  ///
  /// In en, this message translates to:
  /// **'Biography saved'**
  String get biographySaved;

  /// Error message when saving biography fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save biography: {error}'**
  String failedToSaveBiography(String error);

  /// Success message when a file is saved
  ///
  /// In en, this message translates to:
  /// **'File saved to {filename}'**
  String fileSavedTo(String filename);

  /// Error message when downloading a file fails
  ///
  /// In en, this message translates to:
  /// **'Failed to download file: {error}'**
  String failedToDownloadFile(String error);

  /// Success message when all files are saved to a zip
  ///
  /// In en, this message translates to:
  /// **'All files saved to {filename}'**
  String allFilesSavedTo(String filename);

  /// Success message when artwork is added
  ///
  /// In en, this message translates to:
  /// **'Artwork added'**
  String get artworkAdded;

  /// Error message when adding artwork fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add artwork: {error}'**
  String failedToAddArtwork(String error);

  /// Success message when artwork is removed
  ///
  /// In en, this message translates to:
  /// **'Artwork removed'**
  String get artworkRemoved;

  /// Error message when removing artwork fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove artwork: {error}'**
  String failedToRemoveArtwork(String error);

  /// Success message when a press kit file is added
  ///
  /// In en, this message translates to:
  /// **'Press kit file added'**
  String get pressKitFileAdded;

  /// Error message when adding press kit file fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add press kit file: {error}'**
  String failedToAddPressKitFile(String error);

  /// Success message when a press kit file is removed
  ///
  /// In en, this message translates to:
  /// **'Press kit file removed'**
  String get pressKitFileRemoved;

  /// Error message when removing press kit file fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove press kit file: {error}'**
  String failedToRemovePressKitFile(String error);

  /// Title for the dialog to select files for download
  ///
  /// In en, this message translates to:
  /// **'Select Files to Download'**
  String get selectFilesToDownload;

  /// Label for the biography field
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get biography;

  /// Subtitle explaining how the biography file will be saved
  ///
  /// In en, this message translates to:
  /// **'Will be saved as biography.txt'**
  String get biographyWillBeSaved;

  /// Section header for artwork files
  ///
  /// In en, this message translates to:
  /// **'Artwork Files'**
  String get artworkFiles;

  /// Section header for press kit files
  ///
  /// In en, this message translates to:
  /// **'Press Kit Files'**
  String get pressKitFiles;

  /// Section header for additional assets
  ///
  /// In en, this message translates to:
  /// **'Additional Assets'**
  String get additionalAssets;

  /// Button label to download N files
  ///
  /// In en, this message translates to:
  /// **'Download {count} file{plural}'**
  String downloadNFiles(int count, String plural);

  /// Success message when N files are saved
  ///
  /// In en, this message translates to:
  /// **'{count} file{plural} saved to {filename}'**
  String nFilesSavedTo(int count, String plural, String filename);

  /// Dialog title and button label for adding an asset
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get addAsset;

  /// Label for asset name input field
  ///
  /// In en, this message translates to:
  /// **'Asset Name'**
  String get assetNameLabel;

  /// Hint text for asset name input field
  ///
  /// In en, this message translates to:
  /// **'e.g., Logo, Banner, Photo'**
  String get assetNameHint;

  /// Success message when an asset is added
  ///
  /// In en, this message translates to:
  /// **'{assetName} added successfully'**
  String assetAddedSuccessfully(String assetName);

  /// Error message when adding an asset fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add asset: {error}'**
  String failedToAddAsset(String error);

  /// Success message when an asset is removed
  ///
  /// In en, this message translates to:
  /// **'{assetName} removed'**
  String assetRemoved(String assetName);

  /// Error message when removing an asset fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove asset: {error}'**
  String failedToRemoveAsset(String error);

  /// Message when a profile cannot be found
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @downloadFilesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Files'**
  String get downloadFilesSectionTitle;

  /// No description provided for @downloadFilesSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Download all of this profile\'s files — biography, artwork, press kit, and additional assets — as a single ZIP, or select which ones to include.'**
  String get downloadFilesSectionDescription;

  /// Button label to select files
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get selectFiles;

  /// Button label to download all files
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get downloadAll;

  /// Tooltip for the save biography button
  ///
  /// In en, this message translates to:
  /// **'Save Biography'**
  String get saveBiographyTooltip;

  /// Hint text for biography input field
  ///
  /// In en, this message translates to:
  /// **'Enter profile biography...'**
  String get enterBiographyHint;

  /// Button label to add artwork
  ///
  /// In en, this message translates to:
  /// **'Add Artwork'**
  String get addArtwork;

  /// Button label to add a press kit file
  ///
  /// In en, this message translates to:
  /// **'Add File'**
  String get addFile;

  /// Tooltip for the open file button
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// macOS menu bar View menu label
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// macOS menu item for About dialog
  ///
  /// In en, this message translates to:
  /// **'About DAW Project Manager'**
  String get menuAbout;

  /// macOS menu item that opens the online documentation
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get menuDocumentation;

  /// macOS menu item for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get menuLanguage;

  /// macOS menu item to toggle quit warning
  ///
  /// In en, this message translates to:
  /// **'Warn Before Quitting (⌘+Q)'**
  String get menuWarnBeforeQuit;

  /// macOS menu item to quit the app
  ///
  /// In en, this message translates to:
  /// **'Quit DAW Project Manager'**
  String get menuQuit;

  /// No description provided for @quitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Quit DAW Project Manager?'**
  String get quitConfirmTitle;

  /// No description provided for @quitConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to quit?'**
  String get quitConfirmMessage;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @trayNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Still running in the background'**
  String get trayNoticeTitle;

  /// No description provided for @trayNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'DAW Project Manager was minimized to the system tray. Use the tray icon to reopen or quit it.'**
  String get trayNoticeBody;

  /// No description provided for @trayShowWindow.
  ///
  /// In en, this message translates to:
  /// **'Show DAW Project Manager'**
  String get trayShowWindow;

  /// No description provided for @trayLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {when}'**
  String trayLastBackup(String when);

  /// No description provided for @trayNeverBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Never backed up'**
  String get trayNeverBackedUp;

  /// No description provided for @trayBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Back Up Now'**
  String get trayBackupNow;

  /// No description provided for @trayPauseSession.
  ///
  /// In en, this message translates to:
  /// **'Pause Session'**
  String get trayPauseSession;

  /// No description provided for @trayResumeSession.
  ///
  /// In en, this message translates to:
  /// **'Resume Session'**
  String get trayResumeSession;

  /// No description provided for @closeToTray.
  ///
  /// In en, this message translates to:
  /// **'Close to tray'**
  String get closeToTray;

  /// No description provided for @closeToTrayDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep running in the background (tray icon) when you close the window, so auto-backup and notifications keep working'**
  String get closeToTrayDescription;

  /// Settings switch: start the app automatically when the user signs in to their computer
  ///
  /// In en, this message translates to:
  /// **'Launch at startup'**
  String get autoStart;

  /// No description provided for @autoStartDescription.
  ///
  /// In en, this message translates to:
  /// **'Open DAW Project Manager automatically when you sign in to your computer'**
  String get autoStartDescription;

  /// Settings switch: on an auto-start launch, open hidden in the tray
  ///
  /// In en, this message translates to:
  /// **'Start minimized to tray'**
  String get startMinimized;

  /// Explanation under the start-minimized switch
  ///
  /// In en, this message translates to:
  /// **'When the app starts with your computer, open it hidden in the tray instead of showing the window'**
  String get startMinimizedDescription;

  /// Compact label for the start-minimized option in the onboarding wizard
  ///
  /// In en, this message translates to:
  /// **'Start minimized'**
  String get onboardingStartMinimized;

  /// Snackbar shown when registering the app to launch at startup fails
  ///
  /// In en, this message translates to:
  /// **'Could not change the startup setting. Your system may not allow it.'**
  String get autoStartFailed;

  /// Onboarding wizard step title for the launch-at-startup option
  ///
  /// In en, this message translates to:
  /// **'Launch at Startup'**
  String get onboardingStartupTitle;

  /// Onboarding wizard step subtitle for the launch-at-startup option
  ///
  /// In en, this message translates to:
  /// **'Have DAW Project Manager open automatically when you sign in, so background backups and deadline reminders keep running.'**
  String get onboardingStartupBody;

  /// macOS menu bar Window menu label
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// Button label for the donate button in the About dialog
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// Button label for the website button in the About dialog
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Button label for the license button in the About dialog
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// Button label for the report-an-issue button in the About dialog, links to the GitHub issue tracker
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportIssue;

  /// Theme switcher label to switch to classic dark theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Classic Dark'**
  String get switchToClassicDark;

  /// Theme switcher label to switch to neon dark theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Neon Dark'**
  String get switchToNeonDark;

  /// Tooltip to switch to classic theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Classic Theme'**
  String get switchToClassicTheme;

  /// Tooltip to switch to neon theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Neon Theme'**
  String get switchToNeonTheme;

  /// Tooltip to switch to studio light theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Studio Light'**
  String get switchToStudioLight;

  /// macOS menu item for theme switching
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get menuTheme;

  /// Short description of the app shown in the About dialog
  ///
  /// In en, this message translates to:
  /// **'A project manager for music producers and sound designers.'**
  String get appDescription;

  /// Display name for the Neon Dark theme
  ///
  /// In en, this message translates to:
  /// **'Neon Dark'**
  String get neonDarkThemeName;

  /// Display name for the Classic Dark theme
  ///
  /// In en, this message translates to:
  /// **'Classic Dark'**
  String get classicDarkThemeName;

  /// Display name for the Studio Light theme
  ///
  /// In en, this message translates to:
  /// **'Studio Light'**
  String get studioLightThemeName;

  /// No description provided for @statisticsTab.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTab;

  /// No description provided for @statsTotalProjects.
  ///
  /// In en, this message translates to:
  /// **'Total Projects'**
  String get statsTotalProjects;

  /// No description provided for @statsInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statsInProgress;

  /// No description provided for @statsFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statsFinished;

  /// No description provided for @statsAvgCompletion.
  ///
  /// In en, this message translates to:
  /// **'Avg. Completion'**
  String get statsAvgCompletion;

  /// No description provided for @statsPhaseDistribution.
  ///
  /// In en, this message translates to:
  /// **'Projects by Phase'**
  String get statsPhaseDistribution;

  /// No description provided for @statsAvgTimePerPhase.
  ///
  /// In en, this message translates to:
  /// **'Avg. Days per Phase'**
  String get statsAvgTimePerPhase;

  /// No description provided for @statsProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get statsProductivity;

  /// No description provided for @statsCreatedSeries.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get statsCreatedSeries;

  /// No description provided for @statsProjectHealth.
  ///
  /// In en, this message translates to:
  /// **'Project Age & Health'**
  String get statsProjectHealth;

  /// No description provided for @statsCatalogInsights.
  ///
  /// In en, this message translates to:
  /// **'Catalog Insights'**
  String get statsCatalogInsights;

  /// No description provided for @statsBpmDistribution.
  ///
  /// In en, this message translates to:
  /// **'BPM Distribution'**
  String get statsBpmDistribution;

  /// No description provided for @statsTopKeys.
  ///
  /// In en, this message translates to:
  /// **'Top Musical Keys'**
  String get statsTopKeys;

  /// No description provided for @statsDawTypes.
  ///
  /// In en, this message translates to:
  /// **'DAW Types'**
  String get statsDawTypes;

  /// No description provided for @statsProjectActivity.
  ///
  /// In en, this message translates to:
  /// **'Project Activity'**
  String get statsProjectActivity;

  /// Section/button title for a single project's own activity history (project detail page, per-project stats page) — as opposed to statsProjectActivity, which titles the aggregate activity panel across all projects on the Statistics dashboard. In English both read the same, but other locales need distinct singular vs. plural phrasing.
  ///
  /// In en, this message translates to:
  /// **'Project Activity'**
  String get statsSingleProjectActivity;

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get statsNoData;

  /// No description provided for @statsNoPhaseData.
  ///
  /// In en, this message translates to:
  /// **'Phase data will appear after projects move between phases.'**
  String get statsNoPhaseData;

  /// No description provided for @statsLastActivityDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Last activity: {days} days ago'**
  String statsLastActivityDaysAgo(int days);

  /// No description provided for @statsLastActivityToday.
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get statsLastActivityToday;

  /// No description provided for @statsNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events recorded yet'**
  String get statsNoEvents;

  /// No description provided for @statsEventPhaseChanged.
  ///
  /// In en, this message translates to:
  /// **'Phase: {from} → {to}'**
  String statsEventPhaseChanged(String from, String to);

  /// No description provided for @statsEventMetadataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated: {fields}'**
  String statsEventMetadataUpdated(String fields);

  /// No description provided for @statsEventTodoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed: {text}'**
  String statsEventTodoCompleted(String text);

  /// No description provided for @statsEventFileModified.
  ///
  /// In en, this message translates to:
  /// **'File modified on disk'**
  String get statsEventFileModified;

  /// No description provided for @statsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get statsClearHistory;

  /// No description provided for @statsClearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all recorded events for this project?'**
  String get statsClearHistoryConfirm;

  /// No description provided for @statsSearchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects…'**
  String get statsSearchProjects;

  /// No description provided for @statsEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String statsEventCount(int count);

  /// Button/page title for per-project statistics
  ///
  /// In en, this message translates to:
  /// **'Project Statistics'**
  String get statsViewHistory;

  /// Section title: phase history
  ///
  /// In en, this message translates to:
  /// **'Phase History'**
  String get statsPhaseHistory;

  /// Section title: event breakdown
  ///
  /// In en, this message translates to:
  /// **'Event Breakdown'**
  String get statsEventBreakdown;

  /// Current phase duration indicator
  ///
  /// In en, this message translates to:
  /// **'{days}d so far'**
  String statsDaysSoFar(int days);

  /// No description provided for @statsNoProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get statsNoProjectsFound;

  /// No description provided for @statsNotTouchedDays.
  ///
  /// In en, this message translates to:
  /// **'Not touched in {days} days'**
  String statsNotTouchedDays(int days);

  /// No description provided for @sortByLastModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get sortByLastModified;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByPhase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get sortByPhase;

  /// No description provided for @sortByCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get sortByCreatedAt;

  /// No description provided for @sortByBpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get sortByBpm;

  /// No description provided for @sortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewestFirst;

  /// No description provided for @sortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldestFirst;

  /// No description provided for @sortTitleAZ.
  ///
  /// In en, this message translates to:
  /// **'Title A–Z'**
  String get sortTitleAZ;

  /// No description provided for @sortTitleZA.
  ///
  /// In en, this message translates to:
  /// **'Title Z–A'**
  String get sortTitleZA;

  /// No description provided for @musicPlayerTab.
  ///
  /// In en, this message translates to:
  /// **'Music Player'**
  String get musicPlayerTab;

  /// No description provided for @previewAudioChangedRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Preview audio changed on disk — refreshing waveform…'**
  String get previewAudioChangedRefreshing;

  /// No description provided for @audioFileChangedRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Audio file changed on disk — refreshing waveform…'**
  String get audioFileChangedRefreshing;

  /// No description provided for @autoFitAllColumns.
  ///
  /// In en, this message translates to:
  /// **'Auto-resize columns'**
  String get autoFitAllColumns;

  /// No description provided for @uploadAutoDetectedPreviewSongs.
  ///
  /// In en, this message translates to:
  /// **'Upload auto-detected preview songs'**
  String get uploadAutoDetectedPreviewSongs;

  /// No description provided for @uploadAutoDetectedPreviewSongsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Include songs found automatically by the scanner, not just ones you set manually.'**
  String get uploadAutoDetectedPreviewSongsSubtitle;

  /// No description provided for @monoGenerating.
  ///
  /// In en, this message translates to:
  /// **'Mono...'**
  String get monoGenerating;

  /// No description provided for @errorHandlingDroppedFiles.
  ///
  /// In en, this message translates to:
  /// **'Error handling dropped files: {error}'**
  String errorHandlingDroppedFiles(String error);

  /// No description provided for @resetOnboardingConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will restart the setup wizard. Continue?'**
  String get resetOnboardingConfirm;

  /// No description provided for @couldNotLaunchDaw.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {daw}: {error}'**
  String couldNotLaunchDaw(String daw, String error);

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get couldNotOpenLink;

  /// No description provided for @githubButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get githubButtonLabel;

  /// No description provided for @monoLabel.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get monoLabel;

  /// No description provided for @monoToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle mono playback'**
  String get monoToggleTooltip;

  /// No description provided for @monoRequiresWav.
  ///
  /// In en, this message translates to:
  /// **'Mono mixing requires a WAV file'**
  String get monoRequiresWav;

  /// No description provided for @monoUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Could not create mono mix — unsupported format'**
  String get monoUnsupportedFormat;

  /// No description provided for @monoSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Mono switch failed: {error}'**
  String monoSwitchFailed(String error);

  /// No description provided for @analyzeLabel.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyzeLabel;

  /// No description provided for @reAnalyzeLabel.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze'**
  String get reAnalyzeLabel;

  /// No description provided for @analysisRequiresWav.
  ///
  /// In en, this message translates to:
  /// **'Analysis requires a WAV file'**
  String get analysisRequiresWav;

  /// No description provided for @noResultsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No results for current filter'**
  String get noResultsForFilter;

  /// No description provided for @noResultsForFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters to find projects.'**
  String get noResultsForFilterHint;

  /// No description provided for @noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get noProjectsFound;

  /// No description provided for @noProjectsFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Add a scan folder in settings to get started.'**
  String get noProjectsFoundHint;

  /// No description provided for @noProjectsFoundInFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'Try adding another folder that contains DAW projects.'**
  String get noProjectsFoundInFoldersHint;

  /// No description provided for @queueTab.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get queueTab;

  /// No description provided for @queueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get queueSearchHint;

  /// No description provided for @queueNoPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get queueNoPendingTasks;

  /// No description provided for @queueNoPendingTasksHint.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks across your projects.'**
  String get queueNoPendingTasksHint;

  /// No description provided for @queueNoMatchingTasks.
  ///
  /// In en, this message translates to:
  /// **'No matching tasks'**
  String get queueNoMatchingTasks;

  /// No description provided for @queuePendingSummary.
  ///
  /// In en, this message translates to:
  /// **'{tasks} pending tasks in {projects} projects'**
  String queuePendingSummary(int tasks, int projects);

  /// No description provided for @appTitleWithVersion.
  ///
  /// In en, this message translates to:
  /// **'DAW Project Manager {version}'**
  String appTitleWithVersion(String version);

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @renameProjectFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Project File'**
  String get renameProjectFileTitle;

  /// No description provided for @renameFileButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rename File'**
  String get renameFileButtonLabel;

  /// No description provided for @newFileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'New file name (without extension)'**
  String get newFileNameLabel;

  /// No description provided for @renameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A file named \"{name}\" already exists.'**
  String renameAlreadyExists(String name);

  /// No description provided for @renameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{name}\"'**
  String renameSuccess(String name);

  /// No description provided for @renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename: {error}'**
  String renameFailed(String error);

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @nameInvalidCharacters.
  ///
  /// In en, this message translates to:
  /// **'Name cannot contain / \\ :'**
  String get nameInvalidCharacters;

  /// No description provided for @alsoRenameContainingFolder.
  ///
  /// In en, this message translates to:
  /// **'Also rename containing folder'**
  String get alsoRenameContainingFolder;

  /// No description provided for @renameButton.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameButton;

  /// No description provided for @previewMixdownFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview Mixdown Folders'**
  String get previewMixdownFolderTitle;

  /// No description provided for @previewMixdownFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subfolder names inside each project folder to check first, in order, when auto-detecting preview songs. Leave empty to use DAW defaults.'**
  String get previewMixdownFolderSubtitle;

  /// No description provided for @previewMixdownFolderHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mixdowns'**
  String get previewMixdownFolderHint;

  /// No description provided for @mixdownFoldersInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'How this works'**
  String get mixdownFoldersInfoTooltip;

  /// No description provided for @mixdownFoldersInfoDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'How preview detection works'**
  String get mixdownFoldersInfoDialogTitle;

  /// No description provided for @mixdownFoldersInfoDialogBody.
  ///
  /// In en, this message translates to:
  /// **'When a project has no manually chosen preview song, the app looks for the most recently modified audio file to use as a preview. It checks your custom folders below first, in order, then falls back to a list of default folder names based on the project\'s DAW.'**
  String get mixdownFoldersInfoDialogBody;

  /// No description provided for @mixdownFoldersDawDefaultsHeading.
  ///
  /// In en, this message translates to:
  /// **'Default folders checked per DAW'**
  String get mixdownFoldersDawDefaultsHeading;

  /// No description provided for @mixdownFoldersOtherDawLabel.
  ///
  /// In en, this message translates to:
  /// **'Other / unrecognized DAW'**
  String get mixdownFoldersOtherDawLabel;

  /// No description provided for @addMixdownFolder.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addMixdownFolder;

  /// No description provided for @noCustomMixdownFolders.
  ///
  /// In en, this message translates to:
  /// **'No custom folders added — DAW defaults will be used.'**
  String get noCustomMixdownFolders;

  /// No description provided for @mixdownFoldersTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Mixdown Folders'**
  String get mixdownFoldersTabLabel;

  /// No description provided for @mixdownFoldersSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls which folder the app looks in for a project\'s exported/bounced audio, used as its preview song when none is set manually. Expand a DAW below to see the folder names it already checks by default, and add your own on top of them if your setup uses a different name.'**
  String get mixdownFoldersSectionDescription;

  /// No description provided for @mixdownFoldersDefaultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Default folders checked:'**
  String get mixdownFoldersDefaultsLabel;

  /// No description provided for @mixdownFoldersCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Your additions for this DAW:'**
  String get mixdownFoldersCustomLabel;

  /// No description provided for @dawLaunchCommandsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'DAW Locations'**
  String get dawLaunchCommandsTabLabel;

  /// No description provided for @dawLaunchCommandsSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'\"Launch in DAW\" normally hands the project to the system\'s default application. When that doesn\'t work, point it here at the exact DAW program to run — an executable on Windows and Linux (or an AppImage), or the .app on macOS — and the app will open projects of that type with it directly. On Linux this is usually required; on Windows and macOS it\'s a fallback for when the standard launch fails. You can add more than one location per DAW (e.g. two versions); the app asks which to use when you launch.'**
  String get dawLaunchCommandsSectionDescription;

  /// No description provided for @dawLaunchCommandNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get dawLaunchCommandNotConfigured;

  /// No description provided for @dawLaunchCommandMissingTooltip.
  ///
  /// In en, this message translates to:
  /// **'This location no longer exists'**
  String get dawLaunchCommandMissingTooltip;

  /// No description provided for @dawLaunchCommandConfigureButton.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get dawLaunchCommandConfigureButton;

  /// No description provided for @dawLaunchCommandAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get dawLaunchCommandAddButton;

  /// No description provided for @dawLaunchCommandDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Launch command for {dawType}'**
  String dawLaunchCommandDialogTitle(String dawType);

  /// No description provided for @dawLaunchCommandDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Point this at the {dawType} program — an executable on Windows and Linux (or an AppImage), or the .app on macOS. The app will run it directly with the project file as its only argument.'**
  String dawLaunchCommandDialogBody(String dawType);

  /// No description provided for @dawLaunchCommandDialogLaunchFailedBanner.
  ///
  /// In en, this message translates to:
  /// **'DAW Project Manager couldn\'t open this project through the system. Point it at the {dawType} program below and it will try launching the project with it directly.'**
  String dawLaunchCommandDialogLaunchFailedBanner(String dawType);

  /// No description provided for @dawLaunchCommandDialogMissingBanner.
  ///
  /// In en, this message translates to:
  /// **'The saved location(s) for {dawType} no longer exist:\n{path}'**
  String dawLaunchCommandDialogMissingBanner(String dawType, String path);

  /// No description provided for @dawLaunchPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Which {dawType}?'**
  String dawLaunchPickerTitle(String dawType);

  /// No description provided for @dawLaunchPickerBody.
  ///
  /// In en, this message translates to:
  /// **'Choose which {dawType} location to open “{project}” with.'**
  String dawLaunchPickerBody(String dawType, String project);

  /// No description provided for @dawLaunchCommandDialogDetectedHeading.
  ///
  /// In en, this message translates to:
  /// **'Detected on this system'**
  String get dawLaunchCommandDialogDetectedHeading;

  /// No description provided for @dawLaunchCommandDialogManualHint.
  ///
  /// In en, this message translates to:
  /// **'/path/to/executable'**
  String get dawLaunchCommandDialogManualHint;

  /// No description provided for @dawLaunchCommandDialogBrowseButton.
  ///
  /// In en, this message translates to:
  /// **'Browse…'**
  String get dawLaunchCommandDialogBrowseButton;

  /// No description provided for @dawLaunchCommandDialogSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dawLaunchCommandDialogSaveButton;

  /// No description provided for @dawLaunchCommandDialogSaveAndLaunchButton.
  ///
  /// In en, this message translates to:
  /// **'Save & Launch'**
  String get dawLaunchCommandDialogSaveAndLaunchButton;

  /// No description provided for @dawLaunchCommandDialogInvalidPath.
  ///
  /// In en, this message translates to:
  /// **'This file doesn\'t exist'**
  String get dawLaunchCommandDialogInvalidPath;

  /// No description provided for @dawLaunchCommandsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'DAWs will appear here once you scan projects for them.'**
  String get dawLaunchCommandsEmptyState;

  /// No description provided for @dawInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'DAW: {daw}'**
  String dawInfoLabel(String daw);

  /// No description provided for @bpmInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'BPM: {bpm}'**
  String bpmInfoLabel(String bpm);

  /// No description provided for @keyInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String keyInfoLabel(String key);

  /// No description provided for @audioFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Audio file not found'**
  String get audioFileNotFound;

  /// No description provided for @errorPlayingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error playing audio: {error}'**
  String errorPlayingAudio(String error);

  /// No description provided for @notificationTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test notifications to verify timezone and scheduling:'**
  String get notificationTestTitle;

  /// No description provided for @notificationSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send Now'**
  String get notificationSendNow;

  /// No description provided for @notificationSchedule30s.
  ///
  /// In en, this message translates to:
  /// **'Schedule +30s'**
  String get notificationSchedule30s;

  /// No description provided for @notificationShowDebugInfo.
  ///
  /// In en, this message translates to:
  /// **'Show Debug Info'**
  String get notificationShowDebugInfo;

  /// No description provided for @notificationRescheduleAll.
  ///
  /// In en, this message translates to:
  /// **'Re-schedule All'**
  String get notificationRescheduleAll;

  /// No description provided for @notificationTestSent.
  ///
  /// In en, this message translates to:
  /// **'✅ Test notification sent!'**
  String get notificationTestSent;

  /// No description provided for @notificationTestScheduled.
  ///
  /// In en, this message translates to:
  /// **'✅ Test notification scheduled for 30 seconds! Check console logs.'**
  String get notificationTestScheduled;

  /// No description provided for @notificationTestError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String notificationTestError(String error);

  /// No description provided for @notificationDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'🐛 Debug Information'**
  String get notificationDebugTitle;

  /// No description provided for @autoDetected.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected'**
  String get autoDetected;

  /// No description provided for @matchedInDescription.
  ///
  /// In en, this message translates to:
  /// **'Matched in description'**
  String get matchedInDescription;

  /// No description provided for @matchedInProjectNotes.
  ///
  /// In en, this message translates to:
  /// **'Matched in DAW project notes'**
  String get matchedInProjectNotes;

  /// No description provided for @relocateFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Relocate Folder'**
  String get relocateFolderDialogTitle;

  /// No description provided for @relocateFolderSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 project path updated} other{{count} project paths updated}}'**
  String relocateFolderSuccess(int count);

  /// No description provided for @customizeTabs.
  ///
  /// In en, this message translates to:
  /// **'Customize Tabs'**
  String get customizeTabs;

  /// No description provided for @alwaysVisible.
  ///
  /// In en, this message translates to:
  /// **'(always visible)'**
  String get alwaysVisible;

  /// No description provided for @customizeTabsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which tabs to show in the navigation bar. The Projects tab is always visible.'**
  String get customizeTabsDescription;

  /// No description provided for @keyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get keyboardShortcuts;

  /// No description provided for @shortcutGroupGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get shortcutGroupGlobal;

  /// No description provided for @shortcutGroupProjectsTable.
  ///
  /// In en, this message translates to:
  /// **'Projects Table (table must be focused)'**
  String get shortcutGroupProjectsTable;

  /// No description provided for @shortcutGroupReleasesTable.
  ///
  /// In en, this message translates to:
  /// **'Releases Table (table must be focused)'**
  String get shortcutGroupReleasesTable;

  /// No description provided for @shortcutGroupNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get shortcutGroupNavigation;

  /// No description provided for @shortcutFocusSearch.
  ///
  /// In en, this message translates to:
  /// **'Focus search bar'**
  String get shortcutFocusSearch;

  /// No description provided for @shortcutRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan project folders'**
  String get shortcutRescan;

  /// No description provided for @shortcutFocusTable.
  ///
  /// In en, this message translates to:
  /// **'Focus projects table'**
  String get shortcutFocusTable;

  /// No description provided for @shortcutPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play / pause preview song'**
  String get shortcutPlayPause;

  /// No description provided for @shortcutOpenInDaw.
  ///
  /// In en, this message translates to:
  /// **'Open project in DAW'**
  String get shortcutOpenInDaw;

  /// No description provided for @shortcutViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View project details'**
  String get shortcutViewDetails;

  /// No description provided for @shortcutOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open project folder'**
  String get shortcutOpenFolder;

  /// No description provided for @shortcutNavigateRows.
  ///
  /// In en, this message translates to:
  /// **'Navigate rows'**
  String get shortcutNavigateRows;

  /// No description provided for @shortcutEditCell.
  ///
  /// In en, this message translates to:
  /// **'Open project details'**
  String get shortcutEditCell;

  /// No description provided for @shortcutViewRelease.
  ///
  /// In en, this message translates to:
  /// **'View release details'**
  String get shortcutViewRelease;

  /// No description provided for @shortcutGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get shortcutGoBack;

  /// No description provided for @shortcutGroupProjectsTableStandardMode.
  ///
  /// In en, this message translates to:
  /// **'Standard mode'**
  String get shortcutGroupProjectsTableStandardMode;

  /// No description provided for @shortcutGroupProjectsTableSessionMode.
  ///
  /// In en, this message translates to:
  /// **'Session mode'**
  String get shortcutGroupProjectsTableSessionMode;

  /// No description provided for @shortcutToggleSession.
  ///
  /// In en, this message translates to:
  /// **'Start / End session'**
  String get shortcutToggleSession;

  /// No description provided for @shortcutGroupPreviewPlayer.
  ///
  /// In en, this message translates to:
  /// **'Preview Player'**
  String get shortcutGroupPreviewPlayer;

  /// No description provided for @shortcutPlayerPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play / pause'**
  String get shortcutPlayerPlayPause;

  /// No description provided for @shortcutPlayerSeek5.
  ///
  /// In en, this message translates to:
  /// **'Seek ±5 seconds'**
  String get shortcutPlayerSeek5;

  /// No description provided for @shortcutPlayerSeek30.
  ///
  /// In en, this message translates to:
  /// **'Seek ±30 seconds'**
  String get shortcutPlayerSeek30;

  /// No description provided for @startupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to DAW Project Manager'**
  String get startupDialogTitle;

  /// No description provided for @startupDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get started by adding your project folder or restoring a backup from Google Drive.'**
  String get startupDialogSubtitle;

  /// No description provided for @startupAddFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Project Folder'**
  String get startupAddFolderTitle;

  /// No description provided for @startupAddFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a folder containing your DAW projects.'**
  String get startupAddFolderSubtitle;

  /// No description provided for @startupGoogleDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Google Drive Backup'**
  String get startupGoogleDriveTitle;

  /// No description provided for @startupGoogleDriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore your projects from a Google Drive backup.'**
  String get startupGoogleDriveSubtitle;

  /// No description provided for @startupDontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show this on startup'**
  String get startupDontShowAgain;

  /// No description provided for @pinnedLibraryWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Test library in use'**
  String get pinnedLibraryWarningTitle;

  /// No description provided for @pinnedLibraryWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This build keeps its data in a separate test library, so it cannot touch the library your installed copy of the app uses. Projects, profiles and settings you change here will not appear there.'**
  String get pinnedLibraryWarningBody;

  /// No description provided for @pinnedLibraryWarningLibraryLabel.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get pinnedLibraryWarningLibraryLabel;

  /// No description provided for @pinnedLibraryWarningLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get pinnedLibraryWarningLocationLabel;

  /// No description provided for @pinnedLibraryWarningDontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t warn me again for this library'**
  String get pinnedLibraryWarningDontShowAgain;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all profiles, projects, releases, playlists, and settings from this device.'**
  String get deleteAllDataSubtitle;

  /// No description provided for @deleteAllDataConfirm1Title.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data?'**
  String get deleteAllDataConfirm1Title;

  /// No description provided for @deleteAllDataConfirm1Message.
  ///
  /// In en, this message translates to:
  /// **'This will permanently erase all profiles, projects, releases, playlists, and settings from this device. Your Google Drive backup (if any) will not be affected.'**
  String get deleteAllDataConfirm1Message;

  /// No description provided for @deleteAllDataConfirm2Title.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get deleteAllDataConfirm2Title;

  /// No description provided for @deleteAllDataConfirm2Message.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The app will return to its initial state.'**
  String get deleteAllDataConfirm2Message;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get deleteEverything;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data has been deleted.'**
  String get allDataDeleted;

  /// No description provided for @newerExportFound.
  ///
  /// In en, this message translates to:
  /// **'Newer Export Found'**
  String get newerExportFound;

  /// No description provided for @newerExportFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'A newer file was found in the same folder:\n{filename}\n\nReplace the preview song?'**
  String newerExportFoundMessage(String filename);

  /// No description provided for @replaceAndPlay.
  ///
  /// In en, this message translates to:
  /// **'Replace & Play'**
  String get replaceAndPlay;

  /// No description provided for @keepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Keep Current'**
  String get keepCurrent;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @autoBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically upload a backup to Google Drive at the selected interval.'**
  String get autoBackupDescription;

  /// No description provided for @autoBackupInterval.
  ///
  /// In en, this message translates to:
  /// **'Backup interval'**
  String get autoBackupInterval;

  /// No description provided for @autoBackupOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autoBackupOff;

  /// No description provided for @autoBackupEvery30Min.
  ///
  /// In en, this message translates to:
  /// **'Every 30 minutes'**
  String get autoBackupEvery30Min;

  /// No description provided for @autoBackupHourly.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get autoBackupHourly;

  /// No description provided for @autoBackupEvery6Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 6 hours'**
  String get autoBackupEvery6Hours;

  /// No description provided for @autoBackupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get autoBackupDaily;

  /// No description provided for @autoBackupNextBackup.
  ///
  /// In en, this message translates to:
  /// **'Next backup: {time}'**
  String autoBackupNextBackup(String time);

  /// No description provided for @autoBackupNextSoon.
  ///
  /// In en, this message translates to:
  /// **'soon'**
  String get autoBackupNextSoon;

  /// No description provided for @autoBackupNextInMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {count} min'**
  String autoBackupNextInMinutes(int count);

  /// No description provided for @autoBackupNextInOneHour.
  ///
  /// In en, this message translates to:
  /// **'in 1 hour'**
  String get autoBackupNextInOneHour;

  /// No description provided for @autoBackupNextInHours.
  ///
  /// In en, this message translates to:
  /// **'in {count} hours'**
  String autoBackupNextInHours(int count);

  /// No description provided for @autoBackupNextInOneDay.
  ///
  /// In en, this message translates to:
  /// **'in 1 day'**
  String get autoBackupNextInOneDay;

  /// No description provided for @autoBackupNextInDays.
  ///
  /// In en, this message translates to:
  /// **'in {count} days'**
  String autoBackupNextInDays(int count);

  /// No description provided for @playerTitle.
  ///
  /// In en, this message translates to:
  /// **'Music Player'**
  String get playerTitle;

  /// No description provided for @playerToggleQueue.
  ///
  /// In en, this message translates to:
  /// **'Toggle queue'**
  String get playerToggleQueue;

  /// No description provided for @playerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tracks…'**
  String get playerSearchHint;

  /// No description provided for @playerTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String playerTrackCount(int count);

  /// No description provided for @playerTrackCountFiltered.
  ///
  /// In en, this message translates to:
  /// **'{filtered}/{total}'**
  String playerTrackCountFiltered(int filtered, int total);

  /// No description provided for @playerNoPreviewSongs.
  ///
  /// In en, this message translates to:
  /// **'No preview songs found.\nOpen a project and set a preview song.'**
  String get playerNoPreviewSongs;

  /// No description provided for @playerNoTracksMatch.
  ///
  /// In en, this message translates to:
  /// **'No tracks match\n\"{query}\"'**
  String playerNoTracksMatch(String query);

  /// No description provided for @playerDoubleClickToPlay.
  ///
  /// In en, this message translates to:
  /// **'Double-click a track to start playing'**
  String get playerDoubleClickToPlay;

  /// No description provided for @playerSingleClickToPreview.
  ///
  /// In en, this message translates to:
  /// **'Single-click to preview in the player bar below'**
  String get playerSingleClickToPreview;

  /// No description provided for @playerQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get playerQueueTitle;

  /// No description provided for @playerClearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get playerClearQueue;

  /// No description provided for @playerQueueEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Double-click a track to start,\nor drag tracks here to queue.'**
  String get playerQueueEmptyHint;

  /// No description provided for @playerPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get playerPrev;

  /// No description provided for @playerNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get playerNext;

  /// No description provided for @playerGoToProject.
  ///
  /// In en, this message translates to:
  /// **'Go to project'**
  String get playerGoToProject;

  /// No description provided for @playerAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get playerAddToQueue;

  /// No description provided for @playerRemoveFromQueue.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get playerRemoveFromQueue;

  /// No description provided for @playerDismissDetail.
  ///
  /// In en, this message translates to:
  /// **'Dismiss detail'**
  String get playerDismissDetail;

  /// No description provided for @playerNotes.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get playerNotes;

  /// No description provided for @playerTasks.
  ///
  /// In en, this message translates to:
  /// **'TASKS'**
  String get playerTasks;

  /// No description provided for @playerNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet.'**
  String get playerNoTasks;

  /// No description provided for @playerAddTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Add a task…'**
  String get playerAddTaskHint;

  /// No description provided for @playerCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String playerCompletedTasks(int count);

  /// No description provided for @playerPreviousTrack.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get playerPreviousTrack;

  /// No description provided for @playerNextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get playerNextTrack;

  /// No description provided for @playerOpenProject.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get playerOpenProject;

  /// No description provided for @playerRepeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get playerRepeatAll;

  /// No description provided for @playerShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playerShuffle;

  /// No description provided for @volumeMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get volumeMute;

  /// No description provided for @volumeUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get volumeUnmute;

  /// No description provided for @totalWorkTime.
  ///
  /// In en, this message translates to:
  /// **'Total work: {time}'**
  String totalWorkTime(String time);

  /// No description provided for @sessionTime.
  ///
  /// In en, this message translates to:
  /// **'Session: {time}'**
  String sessionTime(String time);

  /// Project age segment of the detail header meta line, e.g. '3 months old'
  ///
  /// In en, this message translates to:
  /// **'{age} old'**
  String headerAgeOld(String age);

  /// Last-edited segment of the detail header meta line; {when} is a relative date like '2 days ago'
  ///
  /// In en, this message translates to:
  /// **'edited {when}'**
  String headerEdited(String when);

  /// Total work time segment of the detail header meta line, e.g. '5h 32m worked'
  ///
  /// In en, this message translates to:
  /// **'{time} worked'**
  String headerWorked(String time);

  /// No description provided for @sessionHistory.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistory;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions recorded yet'**
  String get noSessionsYet;

  /// No description provided for @removeSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove session?'**
  String get removeSessionTitle;

  /// No description provided for @editSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit session duration'**
  String get editSessionTitle;

  /// No description provided for @editSessionHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get editSessionHours;

  /// No description provided for @editSessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Duration must be at least 1 minute'**
  String get editSessionInvalid;

  /// No description provided for @sessionTableDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sessionTableDate;

  /// No description provided for @sessionTableTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get sessionTableTime;

  /// No description provided for @sessionTableDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sessionTableDuration;

  /// No description provided for @sessionTableTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get sessionTableTotal;

  /// No description provided for @sessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String sessionCount(int count);

  /// No description provided for @sessionByPhase.
  ///
  /// In en, this message translates to:
  /// **'Work by Phase'**
  String get sessionByPhase;

  /// No description provided for @tabPosition.
  ///
  /// In en, this message translates to:
  /// **'Tab position'**
  String get tabPosition;

  /// No description provided for @tabPositionTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get tabPositionTop;

  /// No description provided for @tabPositionLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get tabPositionLeft;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailableMessage(String version);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkForUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a new version of the app is available.'**
  String get checkForUpdatesDescription;

  /// No description provided for @checkNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkNow;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: v{version}'**
  String updateAvailable(String version);

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'App is up to date'**
  String get upToDate;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableVersion.
  ///
  /// In en, this message translates to:
  /// **'A new version {version} is ready.'**
  String updateAvailableVersion(String version);

  /// No description provided for @updateCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'You are running v{version}.'**
  String updateCurrentVersion(String version);

  /// No description provided for @viewUpdateDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewUpdateDetails;

  /// No description provided for @getOnMicrosoftStore.
  ///
  /// In en, this message translates to:
  /// **'Get on Microsoft Store'**
  String get getOnMicrosoftStore;

  /// No description provided for @downloadFromGitHub.
  ///
  /// In en, this message translates to:
  /// **'Download from GitHub'**
  String get downloadFromGitHub;

  /// No description provided for @updateWindowsInstructions.
  ///
  /// In en, this message translates to:
  /// **'Open the Microsoft Store and update DAW Project Manager, or click the button below.'**
  String get updateWindowsInstructions;

  /// No description provided for @updateMacInstructions.
  ///
  /// In en, this message translates to:
  /// **'Download the latest release from GitHub and replace the current app.'**
  String get updateMacInstructions;

  /// No description provided for @updateAppImageSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'AppImage'**
  String get updateAppImageSourceLabel;

  /// No description provided for @updateAppImageInstructions.
  ///
  /// In en, this message translates to:
  /// **'Update in place and restart.'**
  String get updateAppImageInstructions;

  /// No description provided for @updateNowButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNowButtonLabel;

  /// No description provided for @appImageUpdateFetching.
  ///
  /// In en, this message translates to:
  /// **'Looking for the update…'**
  String get appImageUpdateFetching;

  /// No description provided for @appImageUpdateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update…'**
  String get appImageUpdateDownloading;

  /// No description provided for @appImageUpdateDownloadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading update… {percent}%'**
  String appImageUpdateDownloadingProgress(int percent);

  /// No description provided for @appImageUpdateVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying and installing…'**
  String get appImageUpdateVerifying;

  /// No description provided for @appImageUpdateReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Ready'**
  String get appImageUpdateReadyTitle;

  /// No description provided for @appImageUpdateReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Updated to v{version}. Restart now to finish.'**
  String appImageUpdateReadyMessage(String version);

  /// No description provided for @appImageUpdateRestartNow.
  ///
  /// In en, this message translates to:
  /// **'Restart Now'**
  String get appImageUpdateRestartNow;

  /// No description provided for @appImageUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Failed'**
  String get appImageUpdateFailedTitle;

  /// No description provided for @appImageUpdateRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get appImageUpdateRetry;

  /// No description provided for @appImageUpdateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while updating. You can try again, or check the error details below.'**
  String get appImageUpdateErrorMessage;

  /// No description provided for @appImageUpdateErrorDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Error Details'**
  String get appImageUpdateErrorDetailsLabel;

  /// No description provided for @appImageUpdateCopyErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy Error Details'**
  String get appImageUpdateCopyErrorDetails;

  /// No description provided for @appImageUpdateErrorDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Error details copied'**
  String get appImageUpdateErrorDetailsCopied;

  /// No description provided for @resetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Reset onboarding'**
  String get resetOnboarding;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to DAW Project Manager'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Organize all your music projects across every DAW in one place.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingFeatureScanFolders.
  ///
  /// In en, this message translates to:
  /// **'Scan DAW project folders automatically'**
  String get onboardingFeatureScanFolders;

  /// No description provided for @onboardingFeatureTrackMetadata.
  ///
  /// In en, this message translates to:
  /// **'Track BPM, key, status and deadlines'**
  String get onboardingFeatureTrackMetadata;

  /// No description provided for @onboardingFeatureSyncDrive.
  ///
  /// In en, this message translates to:
  /// **'Sync metadata to Google Drive'**
  String get onboardingFeatureSyncDrive;

  /// No description provided for @onboardingFeatureTrackTime.
  ///
  /// In en, this message translates to:
  /// **'Track time spent on each project'**
  String get onboardingFeatureTrackTime;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Theme'**
  String get onboardingThemeTitle;

  /// No description provided for @onboardingFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Project Folders'**
  String get onboardingFoldersTitle;

  /// No description provided for @onboardingFoldersBody.
  ///
  /// In en, this message translates to:
  /// **'Add the root folder where your DAW projects are stored.'**
  String get onboardingFoldersBody;

  /// No description provided for @onboardingDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get onboardingDriveTitle;

  /// No description provided for @onboardingDriveBody.
  ///
  /// In en, this message translates to:
  /// **'Optionally back up and sync project metadata to Google Drive.'**
  String get onboardingDriveBody;

  /// No description provided for @onboardingUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Checks'**
  String get onboardingUpdatesTitle;

  /// No description provided for @onboardingUpdatesBody.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a new version is available.'**
  String get onboardingUpdatesBody;

  /// No description provided for @onboardingDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get onboardingDoneTitle;

  /// No description provided for @onboardingDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Start exploring your projects.'**
  String get onboardingDoneBody;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @dawSession.
  ///
  /// In en, this message translates to:
  /// **'DAW Session'**
  String get dawSession;

  /// No description provided for @clearDawSession.
  ///
  /// In en, this message translates to:
  /// **'Clear session'**
  String get clearDawSession;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @playPauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause'**
  String get playPauseTooltip;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @workTimerSection.
  ///
  /// In en, this message translates to:
  /// **'Work Session Reminders'**
  String get workTimerSection;

  /// No description provided for @workTimerSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified periodically while you have an active work session'**
  String get workTimerSectionDesc;

  /// No description provided for @workTimerRequiresSessionMode.
  ///
  /// In en, this message translates to:
  /// **'Enable Session Mode above to use work session reminders'**
  String get workTimerRequiresSessionMode;

  /// No description provided for @workTimerEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable work session reminders'**
  String get workTimerEnabled;

  /// No description provided for @workTimerIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notify every'**
  String get workTimerIntervalLabel;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @workTimerNotifBody.
  ///
  /// In en, this message translates to:
  /// **'You have been working for {time}'**
  String workTimerNotifBody(String time);

  /// Button that fires a test notification through the OS notification pipeline, to verify delivery works on this build/distribution
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// Title of the notification fired by the Send Test Notification button
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotificationTitle;

  /// Body of the notification fired by the Send Test Notification button
  ///
  /// In en, this message translates to:
  /// **'This is a test notification from DAW Project Manager.'**
  String get testNotificationBody;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @lastModifiedColors.
  ///
  /// In en, this message translates to:
  /// **'Last Modified date colors'**
  String get lastModifiedColors;

  /// No description provided for @lastModifiedColorsDescription.
  ///
  /// In en, this message translates to:
  /// **'Colors the Last Modified date based on age and status. Green = Finished. Older dates fade from yellow to red — stronger red means the project hasn\'t been touched in longer.'**
  String get lastModifiedColorsDescription;

  /// No description provided for @sessionMode.
  ///
  /// In en, this message translates to:
  /// **'Session mode'**
  String get sessionMode;

  /// No description provided for @sessionModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a session on a project to track your work time and manage it from the toolbar'**
  String get sessionModeDescription;

  /// No description provided for @workSessionsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Sessions'**
  String get workSessionsTabLabel;

  /// No description provided for @normalMode.
  ///
  /// In en, this message translates to:
  /// **'Normal Mode'**
  String get normalMode;

  /// No description provided for @normalModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Projects open directly in their DAW when launched.'**
  String get normalModeDescription;

  /// No description provided for @sessionModeCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a session to track your activity and time on the project.'**
  String get sessionModeCardDescription;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @switchSession.
  ///
  /// In en, this message translates to:
  /// **'Switch session'**
  String get switchSession;

  /// No description provided for @switchSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Stop the current session and start a new one?'**
  String get switchSessionBody;

  /// No description provided for @switchSessionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {project}'**
  String switchSessionCurrent(String project);

  /// No description provided for @switchSessionNew.
  ///
  /// In en, this message translates to:
  /// **'New: {project}'**
  String switchSessionNew(String project);

  /// No description provided for @sessionDuration.
  ///
  /// In en, this message translates to:
  /// **'Session time'**
  String get sessionDuration;

  /// No description provided for @scanModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan mode:'**
  String get scanModeLabel;

  /// No description provided for @scanModeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Mode'**
  String get scanModeSectionTitle;

  /// No description provided for @scanModeSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls how projects in each folder are displayed in the table — as a plain flat list or grouped by subfolder.'**
  String get scanModeSectionDescription;

  /// No description provided for @smartFolderOptionsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Folder Options'**
  String get smartFolderOptionsSectionTitle;

  /// No description provided for @smartFolderOptionsSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune how smart-folder groups behave in the Projects table.'**
  String get smartFolderOptionsSectionDescription;

  /// No description provided for @excludeSmartFoldersFromSort.
  ///
  /// In en, this message translates to:
  /// **'Keep smart folders out of sorting'**
  String get excludeSmartFoldersFromSort;

  /// No description provided for @excludeSmartFoldersFromSortDescription.
  ///
  /// In en, this message translates to:
  /// **'When you sort the Projects table by a column, smart-folder groups stay in place instead of moving with the sort — only the projects inside them (and any ungrouped projects) get reordered. Experimental: off by default.'**
  String get excludeSmartFoldersFromSortDescription;

  /// No description provided for @mergeSmartFoldersByName.
  ///
  /// In en, this message translates to:
  /// **'Merge smart folders with the same name'**
  String get mergeSmartFoldersByName;

  /// No description provided for @mergeSmartFoldersByNameDescription.
  ///
  /// In en, this message translates to:
  /// **'When two scan roots (e.g. different DAWs) have a top-level folder with the same name, treat them as a single merged group in the Projects table instead of two separate ones.'**
  String get mergeSmartFoldersByNameDescription;

  /// No description provided for @alwaysShowSmartFolders.
  ///
  /// In en, this message translates to:
  /// **'Always show smart folders'**
  String get alwaysShowSmartFolders;

  /// No description provided for @alwaysShowSmartFoldersDescription.
  ///
  /// In en, this message translates to:
  /// **'Show a smart folder as its own group row even when only one of its projects is currently visible (e.g. after a search or filter), instead of collapsing it into a plain ungrouped row.'**
  String get alwaysShowSmartFoldersDescription;

  /// No description provided for @scanModeFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get scanModeFlat;

  /// No description provided for @scanModeSmartFolder.
  ///
  /// In en, this message translates to:
  /// **'Smart Folder'**
  String get scanModeSmartFolder;

  /// No description provided for @scanModeFlatDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows every project as a flat list. Simple and fast.'**
  String get scanModeFlatDescription;

  /// No description provided for @scanModeSmartFolderDescription.
  ///
  /// In en, this message translates to:
  /// **'Groups projects by folder when a folder contains more than one project.'**
  String get scanModeSmartFolderDescription;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @suggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsLabel;

  /// No description provided for @suggestionsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get suggestionsRefresh;

  /// No description provided for @suggestionsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No suggestions right now. Tap Refresh to reset dismissed items.'**
  String get suggestionsEmptyState;

  /// No description provided for @suggestionNewProject.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get suggestionNewProject;

  /// No description provided for @showSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Show suggestions'**
  String get showSuggestions;

  /// No description provided for @showSuggestionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Show smart suggestions in the toolbar when no session is running'**
  String get showSuggestionsDescription;

  /// No description provided for @onboardingSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Suggestions'**
  String get onboardingSuggestionsTitle;

  /// No description provided for @onboardingSuggestionsBody.
  ///
  /// In en, this message translates to:
  /// **'Get personalized project recommendations in the toolbar while you work'**
  String get onboardingSuggestionsBody;

  /// No description provided for @onboardingSessionModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Mode'**
  String get onboardingSessionModeTitle;

  /// No description provided for @onboardingSessionModeBody.
  ///
  /// In en, this message translates to:
  /// **'Start focused work sessions and automatically track time spent on each project'**
  String get onboardingSessionModeBody;

  /// No description provided for @suggestionsFeatureDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadline reminders for upcoming projects'**
  String get suggestionsFeatureDeadlines;

  /// No description provided for @suggestionsFeatureResume.
  ///
  /// In en, this message translates to:
  /// **'Resume the last project you worked on'**
  String get suggestionsFeatureResume;

  /// No description provided for @suggestionsFeatureRecentlyModified.
  ///
  /// In en, this message translates to:
  /// **'Continue recently modified tracks'**
  String get suggestionsFeatureRecentlyModified;

  /// No description provided for @suggestionsEnableToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable smart suggestions'**
  String get suggestionsEnableToggle;

  /// No description provided for @canBeChangedInSettings.
  ///
  /// In en, this message translates to:
  /// **'Can be changed later in Settings'**
  String get canBeChangedInSettings;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createProject;

  /// No description provided for @createProjectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create a new project folder'**
  String get createProjectTooltip;

  /// No description provided for @createProjectSelectFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Location'**
  String get createProjectSelectFolder;

  /// No description provided for @createProjectSelectFolderHint.
  ///
  /// In en, this message translates to:
  /// **'Select which project folder to create the new project in'**
  String get createProjectSelectFolderHint;

  /// No description provided for @createProjectNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name Your Project'**
  String get createProjectNameTitle;

  /// No description provided for @createProjectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a naming scheme for the new project folder'**
  String get createProjectNameHint;

  /// No description provided for @createProjectSchemeArtistTrack.
  ///
  /// In en, this message translates to:
  /// **'Artist — Track'**
  String get createProjectSchemeArtistTrack;

  /// No description provided for @createProjectSchemeCollab.
  ///
  /// In en, this message translates to:
  /// **'Collab'**
  String get createProjectSchemeCollab;

  /// No description provided for @createProjectSchemeDate.
  ///
  /// In en, this message translates to:
  /// **'Date — Track'**
  String get createProjectSchemeDate;

  /// No description provided for @createProjectSchemeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get createProjectSchemeCustom;

  /// No description provided for @createProjectSchemeRemix.
  ///
  /// In en, this message translates to:
  /// **'Remix'**
  String get createProjectSchemeRemix;

  /// No description provided for @createProjectArtistName.
  ///
  /// In en, this message translates to:
  /// **'Artist Name'**
  String get createProjectArtistName;

  /// No description provided for @createProjectTrackName.
  ///
  /// In en, this message translates to:
  /// **'Track Name'**
  String get createProjectTrackName;

  /// No description provided for @createProjectCustomName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get createProjectCustomName;

  /// No description provided for @createProjectAddArtist.
  ///
  /// In en, this message translates to:
  /// **'Add artist'**
  String get createProjectAddArtist;

  /// No description provided for @createProjectOriginalArtist.
  ///
  /// In en, this message translates to:
  /// **'Original Artist'**
  String get createProjectOriginalArtist;

  /// No description provided for @createProjectRemixerName.
  ///
  /// In en, this message translates to:
  /// **'Remixer'**
  String get createProjectRemixerName;

  /// No description provided for @createProjectAddRemixer.
  ///
  /// In en, this message translates to:
  /// **'Add remixer'**
  String get createProjectAddRemixer;

  /// No description provided for @createProjectSelectDaw.
  ///
  /// In en, this message translates to:
  /// **'Open in DAW'**
  String get createProjectSelectDaw;

  /// No description provided for @createProjectSelectDawHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which DAW to open to start working on this project'**
  String get createProjectSelectDawHint;

  /// No description provided for @createProjectDetectDaws.
  ///
  /// In en, this message translates to:
  /// **'Detect Installed DAWs'**
  String get createProjectDetectDaws;

  /// No description provided for @createProjectSkipDaw.
  ///
  /// In en, this message translates to:
  /// **'Just create the folder'**
  String get createProjectSkipDaw;

  /// No description provided for @createProjectNoDawsFound.
  ///
  /// In en, this message translates to:
  /// **'No DAWs were found on this system. The folder will still be created.'**
  String get createProjectNoDawsFound;

  /// No description provided for @createProjectCreateOnly.
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createProjectCreateOnly;

  /// No description provided for @createProjectCreateAndOpen.
  ///
  /// In en, this message translates to:
  /// **'Create & Open'**
  String get createProjectCreateAndOpen;

  /// No description provided for @createProjectFolderExists.
  ///
  /// In en, this message translates to:
  /// **'A folder with this name already exists'**
  String get createProjectFolderExists;

  /// No description provided for @createProjectInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Folder name contains invalid characters'**
  String get createProjectInvalidChars;

  /// No description provided for @createProjectError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create folder'**
  String get createProjectError;

  /// No description provided for @createProjectIncludeDate.
  ///
  /// In en, this message translates to:
  /// **'Include date prefix'**
  String get createProjectIncludeDate;

  /// No description provided for @createProjectCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder Created'**
  String get createProjectCreatedTitle;

  /// No description provided for @createProjectCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your project folder has been created:'**
  String get createProjectCreatedMessage;

  /// No description provided for @createProjectCopyName.
  ///
  /// In en, this message translates to:
  /// **'Copy Folder Name'**
  String get createProjectCopyName;

  /// No description provided for @createProjectNameCopied.
  ///
  /// In en, this message translates to:
  /// **'Folder name copied'**
  String get createProjectNameCopied;

  /// No description provided for @createProjectTrackSession.
  ///
  /// In en, this message translates to:
  /// **'Track session from now'**
  String get createProjectTrackSession;

  /// No description provided for @pendingFolderSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Session Detected'**
  String get pendingFolderSessionTitle;

  /// No description provided for @pendingFolderSessionBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve worked on \"{projectName}\" for {duration}.'**
  String pendingFolderSessionBody(String projectName, String duration);

  /// No description provided for @pendingFolderSessionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue Session'**
  String get pendingFolderSessionContinue;

  /// No description provided for @pendingFolderSessionEndRecord.
  ///
  /// In en, this message translates to:
  /// **'End & Record'**
  String get pendingFolderSessionEndRecord;

  /// No description provided for @activeSessionSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Already Active'**
  String get activeSessionSwitchTitle;

  /// No description provided for @activeSessionSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'A session is running for \"{current}\". Switch to \"{next}\" and save the current session?'**
  String activeSessionSwitchBody(String current, String next);

  /// No description provided for @activeSessionSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get activeSessionSwitch;

  /// No description provided for @pendingProjectWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for project file…'**
  String get pendingProjectWaiting;

  /// No description provided for @pendingProjectDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete empty folder'**
  String get pendingProjectDelete;

  /// No description provided for @pendingProjectDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder?'**
  String get pendingProjectDeleteTitle;

  /// No description provided for @pendingProjectDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{folderName}\" and its contents?'**
  String pendingProjectDeleteBody(String folderName);

  /// No description provided for @pendingProjectDismiss.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking this folder'**
  String get pendingProjectDismiss;

  /// No description provided for @pendingProjectDismissTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop Tracking?'**
  String get pendingProjectDismissTitle;

  /// No description provided for @pendingProjectDismissKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep Folder'**
  String get pendingProjectDismissKeep;

  /// No description provided for @pendingProjectDismissDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete & Dismiss'**
  String get pendingProjectDismissDelete;

  /// No description provided for @pendingProjectDeleteNotEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder is not empty'**
  String get pendingProjectDeleteNotEmptyTitle;

  /// No description provided for @pendingProjectDeleteNotEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'\"{folderName}\" contains files. Delete everything permanently?'**
  String pendingProjectDeleteNotEmptyBody(String folderName);

  /// No description provided for @pendingProjectRefresh.
  ///
  /// In en, this message translates to:
  /// **'Check for project file'**
  String get pendingProjectRefresh;

  /// No description provided for @pendingProjectNotFound.
  ///
  /// In en, this message translates to:
  /// **'No project file found yet'**
  String get pendingProjectNotFound;

  /// No description provided for @phases.
  ///
  /// In en, this message translates to:
  /// **'Phases'**
  String get phases;

  /// No description provided for @phasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, remove, and reorder project phases'**
  String get phasesSubtitle;

  /// No description provided for @phasesDescription.
  ///
  /// In en, this message translates to:
  /// **'Phases track each project\'s stage in your workflow (e.g. Idea → Mixing → Mastering). Drag to reorder, tap a color dot to recolor, and flag a phase as finished to treat it as complete throughout the app.'**
  String get phasesDescription;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetToDefaults;

  /// No description provided for @addPhase.
  ///
  /// In en, this message translates to:
  /// **'Add phase'**
  String get addPhase;

  /// No description provided for @phaseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Phase name'**
  String get phaseNameHint;

  /// No description provided for @phaseDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'A phase with that name already exists'**
  String get phaseDuplicateError;

  /// No description provided for @deletePhaseWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 project uses this phase} other{{count} projects use this phase}}'**
  String deletePhaseWarning(int count);

  /// No description provided for @selectPhaseColor.
  ///
  /// In en, this message translates to:
  /// **'Select color'**
  String get selectPhaseColor;

  /// No description provided for @markAsFinished.
  ///
  /// In en, this message translates to:
  /// **'Mark as finished phase'**
  String get markAsFinished;

  /// No description provided for @resetPhasesWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 project uses a phase that will no longer exist.} other{{count} projects use phases that will no longer exist.}}'**
  String resetPhasesWarning(int count);

  /// No description provided for @resetPhasesWarningNote.
  ///
  /// In en, this message translates to:
  /// **'Those projects will keep their current status but won\'t appear in phase filters. You can always re-add those phases later.'**
  String get resetPhasesWarningNote;

  /// No description provided for @resetPhasesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset all custom phases, colors, and finished-phase flags back to the defaults?'**
  String get resetPhasesConfirm;

  /// No description provided for @camelotGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Mix'**
  String get camelotGenerateButton;

  /// No description provided for @camelotDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Camelot Mix'**
  String get camelotDialogTitle;

  /// No description provided for @camelotDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Orders your tracks by harmonic key compatibility using the Camelot wheel. BPM proximity is used as a tiebreaker within compatible keys.'**
  String get camelotDialogDescription;

  /// No description provided for @camelotEligibleTracks.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks eligible (key set)'**
  String camelotEligibleTracks(int count);

  /// No description provided for @camelotSkippedTracks.
  ///
  /// In en, this message translates to:
  /// **'{count} will be skipped (no key set)'**
  String camelotSkippedTracks(int count);

  /// No description provided for @camelotNoEligibleTracks.
  ///
  /// In en, this message translates to:
  /// **'No tracks have a musical key set. Open a project and set its key to use this feature.'**
  String get camelotNoEligibleTracks;

  /// No description provided for @camelotGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get camelotGenerate;

  /// No description provided for @camelotQueueGenerated.
  ///
  /// In en, this message translates to:
  /// **'Queue filled with {count} harmonically ordered tracks'**
  String camelotQueueGenerated(int count);

  /// No description provided for @camelotWheelGuideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Camelot wheel guide'**
  String get camelotWheelGuideTooltip;

  /// No description provided for @camelotWheelGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Camelot Wheel Guide'**
  String get camelotWheelGuideTitle;

  /// No description provided for @camelotGuideRingsTitle.
  ///
  /// In en, this message translates to:
  /// **'The Rings'**
  String get camelotGuideRingsTitle;

  /// No description provided for @camelotGuideRingsBody.
  ///
  /// In en, this message translates to:
  /// **'Inner ring (A)  →  minor keys\nOuter ring (B)  →  major keys'**
  String get camelotGuideRingsBody;

  /// No description provided for @camelotGuideNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Numbers 1–12'**
  String get camelotGuideNumbersTitle;

  /// No description provided for @camelotGuideNumbersBody.
  ///
  /// In en, this message translates to:
  /// **'Positions arranged clockwise. Each number represents a harmonic neighbourhood — neighbours share strong tonal relationships.'**
  String get camelotGuideNumbersBody;

  /// No description provided for @camelotGuideColoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Colour Guide'**
  String get camelotGuideColoursTitle;

  /// No description provided for @camelotGuideColoursBody.
  ///
  /// In en, this message translates to:
  /// **'● Bright  →  your song\'s key\n● Softly lit  →  compatible for mixing\n● Dimmed  →  avoid for smooth mixing'**
  String get camelotGuideColoursBody;

  /// No description provided for @camelotGuideTransitionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatible Transitions'**
  String get camelotGuideTransitionsTitle;

  /// No description provided for @camelotGuideTransitionsBody.
  ///
  /// In en, this message translates to:
  /// **'8A → 8B  (same number, switch ring)\n  Relative major / minor — virtually seamless.\n\n8A → 7A or 9A  (±1, same ring)\n  Adjacent key — smooth, subtle change.\n\n8A → 1A or 3A  (±7, same ring)\n  Energy boost or drop — more dramatic shift.'**
  String get camelotGuideTransitionsBody;

  /// No description provided for @playerMixSuggestions.
  ///
  /// In en, this message translates to:
  /// **'MIX SUGGESTIONS'**
  String get playerMixSuggestions;

  /// Title for the mobile player page
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// No description provided for @noPreviewSongsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No preview songs available'**
  String get noPreviewSongsAvailable;

  /// Queue panel title - tracks coming up next
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get upNext;

  /// Playback mode: play queue once in order
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get playbackModeNormal;

  /// Playback mode: loop the entire queue
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get playbackModeRepeat;

  /// Playback mode: random order
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playbackModeShuffle;

  /// Appearance setting: strip date stamps from displayed project names
  ///
  /// In en, this message translates to:
  /// **'Hide dates in project names'**
  String get hideDatesInNames;

  /// Explanation of the hide-dates-in-names appearance setting
  ///
  /// In en, this message translates to:
  /// **'Some DAWs prefix project files with the date they were created (for example \"2026-08-02 - My Track\"). Hide it so only the title is shown. The files themselves are never renamed.'**
  String get hideDatesInNamesDescription;

  /// Button that scans the project's mixdown folders for a preview song: in the missing-preview dialog and in the project-detail player
  ///
  /// In en, this message translates to:
  /// **'Auto-Find'**
  String get findPreviewAutomatically;

  /// Snackbar shown when automatic preview detection finds nothing
  ///
  /// In en, this message translates to:
  /// **'No preview song found in this project\'s mixdown folders.'**
  String get noPreviewSongFoundAutomatically;

  /// Mobile long-press action sheet entry: enter multi-select mode
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectProjects;

  /// Message body accompanying a shared preview song file
  ///
  /// In en, this message translates to:
  /// **'Preview song: {name}'**
  String sharePreviewSongText(String name);

  /// Message body accompanying a shared preview song zipped for transport
  ///
  /// In en, this message translates to:
  /// **'Preview song (ZIP): {name}'**
  String sharePreviewSongZipText(String name);

  /// Section title on the project detail page for the song's instruments/parts
  ///
  /// In en, this message translates to:
  /// **'Instruments & Parts'**
  String get songParts;

  /// Progress summary for a song's parts: how many are on their final take
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} final takes'**
  String partsProgress(int done, int total);

  /// Empty state for the parts section
  ///
  /// In en, this message translates to:
  /// **'No parts tracked yet'**
  String get noPartsYet;

  /// Explanation shown under the parts empty state
  ///
  /// In en, this message translates to:
  /// **'List the instruments this song needs, who plays them, and how far each take has got.'**
  String get noPartsYetHint;

  /// Label of the field/button that adds a part to a song
  ///
  /// In en, this message translates to:
  /// **'Add part'**
  String get addPart;

  /// Hint text for the add-part field
  ///
  /// In en, this message translates to:
  /// **'e.g. Drums, Lead Vocals, Bass'**
  String get addPartHint;

  /// Field label for an instrument/role name
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get partNameLabel;

  /// Validation message when a part is saved without a name
  ///
  /// In en, this message translates to:
  /// **'A part name is required'**
  String get partNameRequired;

  /// Field label for who plays a part
  ///
  /// In en, this message translates to:
  /// **'Performer'**
  String get partPerformerLabel;

  /// Hint text for the performer field
  ///
  /// In en, this message translates to:
  /// **'Who plays it'**
  String get partPerformerHint;

  /// Field label for notes about a single part
  ///
  /// In en, this message translates to:
  /// **'Part notes'**
  String get partNotesLabel;

  /// Field label for the take status of a part
  ///
  /// In en, this message translates to:
  /// **'Take status'**
  String get partStatusLabel;

  /// Take status: the part is needed but nothing is recorded
  ///
  /// In en, this message translates to:
  /// **'Needed'**
  String get partStatusNeeded;

  /// Take status: the part is currently being tracked
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get partStatusRecording;

  /// Take status: a scratch/reference take exists
  ///
  /// In en, this message translates to:
  /// **'Early take'**
  String get partStatusEarlyTake;

  /// Take status: the keeper take is recorded
  ///
  /// In en, this message translates to:
  /// **'Final take'**
  String get partStatusFinalTake;

  /// Dialog title / tooltip for editing a part
  ///
  /// In en, this message translates to:
  /// **'Edit part'**
  String get editPart;

  /// Tooltip for deleting a part
  ///
  /// In en, this message translates to:
  /// **'Delete part'**
  String get deletePart;

  /// Shown in place of a performer name when nobody is assigned to a part
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get partsUnassignedPerformer;

  /// Title of the part templates page
  ///
  /// In en, this message translates to:
  /// **'Part Templates'**
  String get partTemplates;

  /// Tooltip for importing a saved lineup into a song
  ///
  /// In en, this message translates to:
  /// **'Import parts from template'**
  String get importPartsFromTemplate;

  /// Tooltip that opens the part templates page
  ///
  /// In en, this message translates to:
  /// **'Manage part templates'**
  String get managePartTemplates;

  /// Title of the dialog listing part templates to import from
  ///
  /// In en, this message translates to:
  /// **'Select a part template'**
  String get selectPartTemplate;

  /// Snackbar shown when importing parts with no templates saved
  ///
  /// In en, this message translates to:
  /// **'No part templates available'**
  String get noPartTemplatesAvailable;

  /// Empty state on the part templates page
  ///
  /// In en, this message translates to:
  /// **'No part templates yet'**
  String get noPartTemplatesYet;

  /// Hint under the part templates empty state
  ///
  /// In en, this message translates to:
  /// **'Create one to reuse the same lineup across songs'**
  String get createFirstPartTemplate;

  /// Dialog title for creating a part template
  ///
  /// In en, this message translates to:
  /// **'Create part template'**
  String get createPartTemplate;

  /// Dialog title for editing a part template
  ///
  /// In en, this message translates to:
  /// **'Edit part template'**
  String get editPartTemplate;

  /// Dialog title for deleting a part template
  ///
  /// In en, this message translates to:
  /// **'Delete part template'**
  String get deletePartTemplate;

  /// Confirmation body when deleting a part template
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the part template \"{name}\"?'**
  String deletePartTemplateConfirm(String name);

  /// Snackbar after creating a part template
  ///
  /// In en, this message translates to:
  /// **'Part template created'**
  String get partTemplateCreated;

  /// Snackbar after updating a part template
  ///
  /// In en, this message translates to:
  /// **'Part template updated'**
  String get partTemplateUpdated;

  /// Snackbar after deleting a part template
  ///
  /// In en, this message translates to:
  /// **'Part template deleted'**
  String get partTemplateDeleted;

  /// Field label for the multi-line list of parts in a template
  ///
  /// In en, this message translates to:
  /// **'Parts (one per line)'**
  String get partTemplateItems;

  /// Example content for the part template items field
  ///
  /// In en, this message translates to:
  /// **'Drums — Alex\nBass — Sam\nLead Vocals'**
  String get partTemplateItemsHint;

  /// Helper text explaining the 'Part - Performer' line format
  ///
  /// In en, this message translates to:
  /// **'One part per line. Name a performer after a dash: Drums — Alex'**
  String get partTemplateItemsHelp;

  /// Validation message when a part template has no items
  ///
  /// In en, this message translates to:
  /// **'Add at least one part'**
  String get partTemplateItemsRequired;

  /// Validation message when a part template is missing a name or items
  ///
  /// In en, this message translates to:
  /// **'A name and at least one part are required'**
  String get partTemplateNameAndItemsRequired;

  /// Subtitle showing how many parts a template contains
  ///
  /// In en, this message translates to:
  /// **'{count} part(s)'**
  String partTemplateItemCount(int count);

  /// Snackbar after importing a part template into a song
  ///
  /// In en, this message translates to:
  /// **'Part template \"{name}\" imported ({count} parts)'**
  String partTemplateImported(String name, int count);

  /// Error state on the part templates page
  ///
  /// In en, this message translates to:
  /// **'Error loading part templates'**
  String get errorLoadingPartTemplates;

  /// Tooltip for exporting one song's parts to a CSV file
  ///
  /// In en, this message translates to:
  /// **'Export parts as CSV'**
  String get exportPartsCsv;

  /// Settings entry exporting every project's parts to one CSV file
  ///
  /// In en, this message translates to:
  /// **'Export all song parts as CSV'**
  String get exportAllPartsCsv;

  /// Subtitle of the export-all-parts settings entry
  ///
  /// In en, this message translates to:
  /// **'One spreadsheet row per part, across every project — for sharing progress with collaborators'**
  String get exportAllPartsCsvSubtitle;

  /// Snackbar when a parts CSV export has nothing to write
  ///
  /// In en, this message translates to:
  /// **'No parts to export'**
  String get noPartsToExport;

  /// Snackbar reporting how many parts were written to the CSV
  ///
  /// In en, this message translates to:
  /// **'Exported {count} parts'**
  String partsCsvExported(int count);

  /// Heading of the parts block in the plain text project export
  ///
  /// In en, this message translates to:
  /// **'Parts:'**
  String get projectExportPartsLabel;

  /// CSV column header: project name
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get csvHeaderProject;

  /// CSV column header: instrument/part name
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get csvHeaderPart;

  /// CSV column header: who plays the part
  ///
  /// In en, this message translates to:
  /// **'Performer'**
  String get csvHeaderPerformer;

  /// CSV column header: take status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get csvHeaderStatus;

  /// CSV column header: notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get csvHeaderNotes;

  /// Menu entry exporting one song's parts to an .xlsx workbook
  ///
  /// In en, this message translates to:
  /// **'Export parts as Excel (.xlsx)'**
  String get exportPartsXlsx;

  /// Settings entry exporting every project's parts to one .xlsx workbook
  ///
  /// In en, this message translates to:
  /// **'Export all song parts as Excel (.xlsx)'**
  String get exportAllPartsXlsx;

  /// Subtitle of the export-all-parts-to-Excel settings entry
  ///
  /// In en, this message translates to:
  /// **'The same sheet as the CSV, with a frozen header row, column filters and colour-coded take statuses'**
  String get exportAllPartsXlsxSubtitle;

  /// Menu entry that reads a parts list back in from a CSV or Excel file
  ///
  /// In en, this message translates to:
  /// **'Import parts from a spreadsheet'**
  String get importPartsFromSpreadsheet;

  /// Title of the file picker for importing parts
  ///
  /// In en, this message translates to:
  /// **'Select a CSV or Excel file'**
  String get partsImportPickerTitle;

  /// Snackbar summarising how many parts an import added and updated
  ///
  /// In en, this message translates to:
  /// **'{added} parts added, {updated} updated'**
  String partsImported(int added, int updated);

  /// Snackbar shown when an imported spreadsheet contained no usable parts
  ///
  /// In en, this message translates to:
  /// **'No parts found in that file'**
  String get partsImportNothingFound;

  /// Snackbar shown when a spreadsheet could not be read
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that spreadsheet: {error}'**
  String partsImportFailed(String error);

  /// Tooltip of the overflow menu in the parts section header
  ///
  /// In en, this message translates to:
  /// **'More part actions'**
  String get partsMoreActions;

  /// Title bar of the full-page parts workspace for one project
  ///
  /// In en, this message translates to:
  /// **'{name} — Parts'**
  String partsPageTitle(String name);

  /// Button on the project detail summary card that opens the parts workspace
  ///
  /// In en, this message translates to:
  /// **'Manage parts'**
  String get manageParts;

  /// Shown on the summary card when it lists only the first few parts
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String partsMoreCount(int count);

  /// Placeholder of the parts workspace search field
  ///
  /// In en, this message translates to:
  /// **'Search parts'**
  String get searchParts;

  /// Take-status filter entry that applies no filtering
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// Performer filter entry that applies no filtering
  ///
  /// In en, this message translates to:
  /// **'All performers'**
  String get allPerformers;

  /// How many parts are currently multi-selected
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String partsSelectedCount(int count);

  /// Bulk action: set the take status of every selected part
  ///
  /// In en, this message translates to:
  /// **'Set status'**
  String get setPartStatus;

  /// Bulk action: assign one performer to every selected part
  ///
  /// In en, this message translates to:
  /// **'Assign performer'**
  String get assignPartPerformer;

  /// Bulk action: delete every selected part
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelectedParts;

  /// Confirmation body before deleting the selected parts
  ///
  /// In en, this message translates to:
  /// **'Delete {count} parts from this song?'**
  String deleteSelectedPartsConfirm(int count);

  /// Snackbar reporting how many parts were deleted
  ///
  /// In en, this message translates to:
  /// **'{count} parts deleted'**
  String partsDeleted(int count);

  /// Empty state when search or filters hide every part
  ///
  /// In en, this message translates to:
  /// **'No parts match these filters'**
  String get noPartsMatchFilters;

  /// Explains that drag-reordering needs the unfiltered, unsorted list
  ///
  /// In en, this message translates to:
  /// **'Clear the search, filters and sorting to drag parts into order'**
  String get reorderNeedsUnfilteredList;

  /// Section heading for the timeline markers and regions read out of a DAW project file
  ///
  /// In en, this message translates to:
  /// **'Markers'**
  String get projectMarkers;

  /// Fallback label for a marker the user never named
  ///
  /// In en, this message translates to:
  /// **'Marker {index}'**
  String projectMarkerUnnamed(int index);

  /// Fallback label for a region the user never named
  ///
  /// In en, this message translates to:
  /// **'Region {index}'**
  String projectRegionUnnamed(int index);

  /// Tooltip on a marker row that will seek the preview player
  ///
  /// In en, this message translates to:
  /// **'Jump to this point in the preview song'**
  String get projectMarkerJumpTooltip;

  /// Tooltip on marker rows when the project has no preview song to seek in
  ///
  /// In en, this message translates to:
  /// **'Add a preview song to jump to markers'**
  String get projectMarkerNoPreviewSong;

  /// Appearance setting: how the project detail page is arranged
  ///
  /// In en, this message translates to:
  /// **'Project Detail Layout'**
  String get projectDetailLayout;

  /// Subtitle under the Project Detail Layout setting
  ///
  /// In en, this message translates to:
  /// **'How the project detail page is arranged.'**
  String get projectDetailLayoutSettingDescription;

  /// Layout option: everything in one scroll
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get projectDetailLayoutClassic;

  /// Description of the classic project detail layout
  ///
  /// In en, this message translates to:
  /// **'Everything in one scroll.'**
  String get projectDetailLayoutClassicDescription;

  /// Layout option: a nav rail picks one section at a time
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get projectDetailLayoutSectioned;

  /// Description of the sectioned project detail layout
  ///
  /// In en, this message translates to:
  /// **'A rail on the left picks one section at a time.'**
  String get projectDetailLayoutSectionedDescription;
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
