import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/desktop_title_bar.dart';
import '../models/profile.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../services/demo_data_service.dart';
import '../services/scanner_service.dart';
import '../utils/mobile_utils.dart';
import '../generated/l10n/app_localizations.dart';
import 'profile_edit_page.dart';
import '../services/crash_logger.dart';
import 'widgets/theme_switcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/language_switcher.dart';

// TODO: Set this back to `kDebugMode` once promotional screenshots are done.
// The demo-data generator/remover is normally a debug-only tool, but it's
// temporarily enabled in release builds too so it can be used to seed a
// screenshot-ready profile from a release build.
const bool _showTestingDatabaseTools = kDebugMode;

class ProfileManagerPage extends ConsumerStatefulWidget {
  const ProfileManagerPage({super.key});

  @override
  ConsumerState<ProfileManagerPage> createState() => _ProfileManagerPageState();
}

class _ProfileManagerPageState extends ConsumerState<ProfileManagerPage> {
  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showCreateProfileDialog() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createNewProfile),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.profileName,
            hintText: AppLocalizations.of(context)!.profileName,
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(ctx, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, nameController.text.trim());
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _createProfile(result);
    }
  }

  Future<void> _createProfile(String name) async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      await profileRepo.createProfile(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileCreated(name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateProfile(e.toString()))),
        );
      }
    }
  }

  Future<void> _switchProfile(String profileId) async {
    // Save provider references and container before any navigation that might unmount the widget
    final profileRepo = await ref.read(profileRepositoryProvider.future);
    if (!mounted) return;
    final profileSwitchingNotifier = ref.read(profileSwitchingProvider.notifier);
    final container = ProviderScope.containerOf(context);
    
    try {
      await profileRepo.setCurrentProfileId(profileId);
      
      // Set profile switching state to show "Switching Profiles..." message
      profileSwitchingNotifier.setSwitching(true);
      
      // Navigate back to dashboard first so it can show the loading overlay
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Invalidate all related providers to reload with new profile (using saved container)
      container.invalidate(repositoryProvider);
      container.invalidate(allProjectsStreamProvider);
      container.invalidate(releasesProvider);
      container.invalidate(scanRootsProvider);
      container.invalidate(currentProfileProvider);
      
      // Wait a bit for providers to invalidate
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Wait for repository to reload with new profile (using saved container)
      final repo = await container.read(repositoryProvider.future);
      
      if (kDebugMode) {
        print('Profile switched to: $profileId');
        print('Repository reloaded with ${repo.projectsBox.length} projects, ${repo.releasesBox.length} releases');
      }
      
      // Trigger scan for the new profile's root folders (same as dashboard scan)
      await _scanProfileRoots(repo);
      
      // Mark profile switching as complete (using saved notifier)
      profileSwitchingNotifier.complete();
      
      // The dashboard will automatically show the updated projects
    } catch (e) {
      // Mark profile switching as complete even on error (using saved notifier)
      profileSwitchingNotifier.complete();
      // Error will be visible in the dashboard if needed
      if (kDebugMode) {
        print('Error switching profile: $e');
      }
    }
  }

  Future<void> _scanProfileRoots(ProjectRepository repo) async {
    final scanner = ScannerService();
    final ignoredPaths = repo.getIgnoredPaths().map((p) => p.path).toList(growable: false);

    // Scan all root folders for the current profile (same logic as dashboard)
    // Use lightweight scan (fast, no full metadata extraction)
    final scanTime = DateTime.now();
    for (final root in repo.getRoots()) {
      final entities = <FileSystemEntity>[];
      await for (final entity in scanner.scanDirectory(root.path, ignoredPaths: ignoredPaths)) {
        entities.add(entity);
      }
      if (entities.isNotEmpty) {
        await repo.upsertManyFromFileSystemEntities(entities, fullMetadata: false);
      }
      // Update lastScanAt timestamp for this root
      await repo.updateRootLastScanAt(root.id, scanTime);
    }
    
    // The dashboard will automatically show the updated projects
    // No need to show a message here as the scan state change will trigger UI updates
  }

  Future<void> _deleteProfile(Profile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.deleteProfile),
        content: Text(AppLocalizations.of(context)!.deleteProfileMessage(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        await profileRepo.deleteProfile(profile.id);
        
        // Invalidate repository provider to reload with new profile
        ref.invalidate(repositoryProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.profileDeleted(profile.name))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToDeleteProfile(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _shareDiagnosticLog() async {
    final files = await CrashLogger.existingLogFiles();
    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.shareDiagnosticLogEmpty)),
        );
      }
      return;
    }
    final shared = await CrashLogger.shareOrRevealLogFiles(files);
    if (!shared && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.shareDiagnosticLogFolderOpened)),
      );
    }
  }

  Future<void> _clearDiagnosticLog() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.clearDiagnosticLogConfirmTitle),
        content: Text(l10n.clearDiagnosticLogConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await CrashLogger.clearLogs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.diagnosticLogCleared)),
      );
    }
  }

  /// Creates (or refreshes) a dedicated demo profile with a large, varied
  /// catalog of fake projects/releases/playlists for promotional
  /// screenshots, and switches to it — the user's real data is never
  /// touched, since it lives in a separate profile-scoped Hive box set.
  Future<void> _generateTestingDatabase() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.generateTestingDatabase),
        content: Text(AppLocalizations.of(context)!.generateTestingDatabaseMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);

      final demoProfile = await DemoDataService().generate(profileRepo);
      await profileRepo.setCurrentProfileId(demoProfile.id);

      // Invalidate providers so the app picks up the demo profile immediately.
      ref.invalidate(repositoryProvider);
      ref.invalidate(allProjectsStreamProvider);
      ref.invalidate(releasesProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(currentProfileProvider);

      await Future.delayed(const Duration(milliseconds: 100));
      await ref.read(repositoryProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.testingDatabaseGenerated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToGenerateTestingDatabase(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (kDebugMode) print('Error generating testing database: $e');
    }
  }

  /// Permanently deletes the "Demo — Screenshots" profile (if it exists),
  /// including its generated preview audio files. If it was the active
  /// profile, the app switches back to another one automatically.
  Future<void> _removeTestingDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeTestingDatabase),
        content: Text(AppLocalizations.of(context)!.removeTestingDatabaseMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.removeTestingDatabase),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final removed = await DemoDataService().remove(profileRepo);

      // Invalidate providers in case the active profile changed as a result.
      ref.invalidate(repositoryProvider);
      ref.invalidate(allProjectsStreamProvider);
      ref.invalidate(releasesProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(currentProfileProvider);

      await Future.delayed(const Duration(milliseconds: 100));
      await ref.read(repositoryProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(removed
                ? AppLocalizations.of(context)!.testingDatabaseRemoved
                : AppLocalizations.of(context)!.noTestingDatabaseFound),
            backgroundColor: removed ? Colors.green : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToRemoveTestingDatabase(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (kDebugMode) print('Error removing testing database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);
    final currentProfileAsync = ref.watch(currentProfileProvider);
    final isMobile = MobileUtils.isMobile();

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.profileManager),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(
            title: AppLocalizations.of(context)!.profileManager,
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: MobileUtils.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Settings section (Language, Theme, Support) - Mobile only
                  if (MobileUtils.isMobile()) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.settings,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            // Project Filters section
                            Text(
                              AppLocalizations.of(context)!.filters,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final finishedMode = ref.watch(showFinishedProjectsProvider);
                                final finishedNotifier = ref.read(showFinishedProjectsProvider.notifier);
                                return SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(AppLocalizations.of(context)!.hideFinished),
                                  value: finishedMode == 1,
                                  onChanged: (v) => v
                                      ? finishedNotifier.setHideFinished(true)
                                      : finishedNotifier.setHideFinished(false),
                                );
                              },
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final showDeadlines = ref.watch(showOnlyWithDeadlineProvider);
                                return SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(AppLocalizations.of(context)!.showOnlyDeadlines),
                                  value: showDeadlines,
                                  onChanged: (v) => ref
                                      .read(showOnlyWithDeadlineProvider.notifier)
                                      .setShowOnlyWithDeadline(v),
                                );
                              },
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final phaseFilter = ref.watch(phaseFilterProvider);
                                final customPhases = ref.watch(customPhasesProvider);
                                final l10n = AppLocalizations.of(context)!;
                                return Row(
                                  children: [
                                    const Icon(Icons.filter_list, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(l10n.filterByPhase)),
                                    DropdownButton<String?>(
                                      value: phaseFilter,
                                      underline: const SizedBox.shrink(),
                                      hint: Text(l10n.allPhases),
                                      items: [
                                        DropdownMenuItem(value: null, child: Text(l10n.allPhases)),
                                        ...customPhases.map((phase) => DropdownMenuItem(
                                          value: phase,
                                          child: Text(phase),
                                        )),
                                      ],
                                      onChanged: (v) => ref.read(phaseFilterProvider.notifier).setPhase(v),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const Divider(height: 32),
                            // Language selector
                            Row(
                              children: [
                                const Icon(Icons.language, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.language,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const LanguageSwitcher(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Theme selector
                            Row(
                              children: [
                                const Icon(Icons.palette, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.theme,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const ThemeSwitcher(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Support button
                            Row(
                              children: [
                                const Icon(Icons.card_giftcard, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.support,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.card_giftcard, size: 18),
                                  label: Text(AppLocalizations.of(context)!.support),
                                  onPressed: () async {
                                    try {
                                      final uri = Uri.parse('https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL');
                                      
                                      // Try to launch URL directly - canLaunchUrl can be unreliable on mobile
                                      // Use externalApplication mode to open in browser
                                      final launched = await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                      
                                      if (!launched && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.couldNotOpenBrowser('https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL')),
                                            duration: const Duration(seconds: 5),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.errorOpeningBrowser(e.toString())),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                      if (kDebugMode) print('Error launching support URL: $e');
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Diagnostic log — helps debug crashes that only
                            // happen after the app has been backgrounded
                            Row(
                              children: [
                                const Icon(Icons.bug_report_outlined, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.shareDiagnosticLog,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              value: ref.watch(diagnosticLoggingEnabledProvider),
                              onChanged: (v) =>
                                  ref.read(diagnosticLoggingEnabledProvider.notifier).toggle(),
                              title: Text(AppLocalizations.of(context)!.enableDiagnosticLogging),
                              subtitle: Text(
                                AppLocalizations.of(context)!.enableDiagnosticLoggingDescription,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.ios_share, size: 16),
                                  label: Text(AppLocalizations.of(context)!.shareDiagnosticLog),
                                  onPressed: _shareDiagnosticLog,
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: Text(AppLocalizations.of(context)!.clearDiagnosticLog),
                                  onPressed: _clearDiagnosticLog,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Generate/Remove Testing Database buttons — see _showTestingDatabaseTools above
                  if (_showTestingDatabaseTools) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.science, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.generateTestingDatabase,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.science, size: 18),
                                  label: Text(AppLocalizations.of(context)!.generateTestingDatabase),
                                  onPressed: _generateTestingDatabase,
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Icon(Icons.delete_sweep, size: 24, color: Colors.red.shade300),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.removeTestingDatabase,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  icon: Icon(Icons.delete_sweep, size: 18, color: Colors.red.shade300),
                                  label: Text(
                                    AppLocalizations.of(context)!.removeTestingDatabase,
                                    style: TextStyle(color: Colors.red.shade300),
                                  ),
                                  onPressed: _removeTestingDatabase,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade300,
                                    side: BorderSide(color: Colors.red.shade300),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Profiles list
                  if (profilesAsync.hasValue)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.profiles,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(AppLocalizations.of(context)!.createNewProfile),
                          onPressed: _showCreateProfileDialog,
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (profilesAsync.hasValue)
                    profilesAsync.value!.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                AppLocalizations.of(context)!.noProfilesFound,
                                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: profilesAsync.value!.length,
                            itemBuilder: (context, index) {
                              final profile = profilesAsync.value![index];
                              final isCurrentProfile = currentProfileAsync.hasValue &&
                                  currentProfileAsync.value?.id == profile.id;
                              return GestureDetector(
                                onDoubleTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProfileEditPage(profileId: profile.id),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: isCurrentProfile
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).cardColor,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: isMobile
                                      ? _buildMobileProfileTile(context, profile, isCurrentProfile)
                                      : ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          minVerticalPadding: 0,
                                          dense: false,
                                          isThreeLine: false,
                                          leading: profile.photoPath != null && File(profile.photoPath!).existsSync()
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: Image.file(
                                                    File(profile.photoPath!),
                                                    width: 48,
                                                    height: 48,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const SizedBox(
                                                        width: 48,
                                                        height: 48,
                                                        child: Icon(Icons.person),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: Icon(Icons.person),
                                                ),
                                          title: Text(profile.name),
                                          titleAlignment: ListTileTitleAlignment.center,
                                          subtitle: isCurrentProfile
                                              ? Text(
                                                  AppLocalizations.of(context)!.active,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : const SizedBox(height: 0),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!isCurrentProfile)
                                                TextButton(
                                                  onPressed: () => _switchProfile(profile.id),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                                  ),
                                                  child: Text(AppLocalizations.of(context)!.switchProfile),
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined),
                                                tooltip: AppLocalizations.of(context)!.editProfile,
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => ProfileEditPage(profileId: profile.id),
                                                    ),
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red.shade300),
                                                tooltip: AppLocalizations.of(context)!.deleteProfile,
                                                onPressed: () => _deleteProfile(profile),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProfileTile(BuildContext context, Profile profile, bool isCurrentProfile) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              profile.photoPath != null && File(profile.photoPath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(profile.photoPath!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(Icons.person),
                          );
                        },
                      ),
                    )
                  : const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.person),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (isCurrentProfile)
                      Text(
                        AppLocalizations.of(context)!.active,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!isCurrentProfile)
                ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(AppLocalizations.of(context)!.switchProfile),
                  onPressed: () => _switchProfile(profile.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(AppLocalizations.of(context)!.editProfile),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileEditPage(profileId: profile.id),
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: Icon(Icons.delete, size: 18, color: Colors.red.shade300),
                label: Text(
                  AppLocalizations.of(context)!.deleteProfile,
                  style: TextStyle(color: Colors.red.shade300),
                ),
                onPressed: () => _deleteProfile(profile),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

