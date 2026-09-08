import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../providers/theme_provider.dart';
import '../services/auto_start_service.dart';
import '../services/scan_import_service.dart';
import '../services/update_check_service.dart';
import '../utils/mobile_utils.dart';
import 'dashboard_page.dart' show DashboardPage;
import 'widgets/language_switcher.dart';
import 'theme_labels.dart';
import 'widgets/theme_preview_card.dart';

class OnboardingWizardPage extends ConsumerStatefulWidget {
  const OnboardingWizardPage({super.key});

  @override
  ConsumerState<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends ConsumerState<OnboardingWizardPage> {
  final _controller = PageController();
  int _page = 0;

  // Project-folder management is desktop-only (see the Project Folders
  // section of settings_page.dart).
  bool get _showFolders => !MobileUtils.isMobile();

  // The startup step is skipped entirely on platforms that have no
  // launch-at-login concept (mobile).
  bool get _showStartup => AutoStartService.isSupported;

  // Update checks are skipped on Linux, except for the AppImage build — see
  // UpdateCheckService.isSupported for why.
  bool get _showUpdates => UpdateCheckService.isSupported;

  List<Widget> _pages(AppLocalizations l10n) => [
        _WelcomePage(l10n: l10n),
        _LanguagePage(l10n: l10n),
        _ThemePage(l10n: l10n),
        _TabsPage(l10n: l10n),
        if (_showFolders) _FoldersPage(l10n: l10n),
        if (_showUpdates) _UpdatesPage(l10n: l10n),
        _SuggestionsPage(l10n: l10n),
        _SessionModePage(l10n: l10n),
        _PhasesPage(l10n: l10n),
        if (_showStartup) _StartupPage(l10n: l10n),
        _DonePage(l10n: l10n),
      ];

  // Welcome, Language, Theme, Tabs, [Folders], [Updates], Suggestions, SessionMode, Phases, [Startup], Done.
  int get _totalPages =>
      8 + (_showFolders ? 1 : 0) + (_showUpdates ? 1 : 0) + (_showStartup ? 1 : 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_page > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _finish() async {
    // Captura notifiers antes do await — ref não pode ser usado após unmount.
    final completeNotifier = ref.read(onboardingCompleteProvider.notifier);
    final playerNotifier = ref.read(desktopPlayerProvider.notifier);
    await completeNotifier.complete();
    if (!mounted) return;
    playerNotifier.close();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pages = _pages(l10n);
    assert(pages.length == _totalPages);
    final isLast = _page == _totalPages - 1;

    return Scaffold(
      body: Column(
        children: [
          _WizardProgress(current: _page, total: _totalPages),
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: pages,
            ),
          ),
          _WizardNav(
            page: _page,
            isLast: isLast,
            onBack: _back,
            onNext: _next,
            onFinish: _finish,
            onSkip: _finish,
            l10n: l10n,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

// ── Progress indicator ────────────────────────────────────────────────────────

class _WizardProgress extends StatelessWidget {
  final int current;
  final int total;
  const _WizardProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LinearProgressIndicator(
      value: (current + 1) / total,
      color: color,
      backgroundColor: color.withValues(alpha: 0.15),
      minHeight: 3,
    );
  }
}

// ── Navigation row ────────────────────────────────────────────────────────────

class _WizardNav extends StatelessWidget {
  final int page;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onSkip;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _WizardNav({
    required this.page,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onFinish,
    required this.onSkip,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Row(
        children: [
          // Back button
          if (page > 0)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.onboardingBack),
            )
          else
            const SizedBox.shrink(),

          const Spacer(),

          // Skip link (hidden on last page)
          if (!isLast)
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              child: Text(l10n.skip),
            ),

          if (!isLast) const SizedBox(width: 8),

          // Next / Finish button
          if (isLast)
            FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.onboardingGetStarted),
            )
          else
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(l10n.onboardingNext),
            ),
        ],
      ),
    );
  }
}

// ── Shared page scaffold ──────────────────────────────────────────────────────

class _WizardStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final double iconSize;

  const _WizardStep({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(icon, size: iconSize, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page 0: Welcome ───────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _WelcomePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _WizardStep(
      icon: Icons.music_note,
      iconSize: 80,
      title: l10n.onboardingWelcomeTitle,
      subtitle: l10n.onboardingWelcomeBody,
      child: _FeatureList(theme: theme, l10n: l10n),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations l10n;
  const _FeatureList({required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.folder_open, l10n.onboardingFeatureScanFolders),
      (Icons.bar_chart, l10n.onboardingFeatureTrackMetadata),
      (Icons.cloud_upload_outlined, l10n.onboardingFeatureSyncDrive),
      (Icons.timer_outlined, l10n.onboardingFeatureTrackTime),
    ];
    return Column(
      children: items
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(e.$1, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.$2, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ── Page 1: Language ──────────────────────────────────────────────────────────

class _LanguagePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _LanguagePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _WizardStep(
      icon: Icons.language,
      title: l10n.onboardingLanguageTitle,
      child: Center(child: _LanguageGrid()),
    );
  }
}

class _LanguageGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final languages = LanguageSwitcher.languageNames;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: languages.entries.map((e) {
        final selected = current.languageCode == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          selectedColor: theme.colorScheme.primaryContainer,
          onSelected: (_) => ref.read(localeProvider.notifier).setLocale(Locale(e.key)),
        );
      }).toList(),
    );
  }
}

// ── Page 2: Theme ─────────────────────────────────────────────────────────────

class _ThemePage extends ConsumerWidget {
  final AppLocalizations l10n;
  const _ThemePage({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(selectedThemeIdProvider);
    // Built-ins only. A first run has no user themes yet, and onboarding is
    // not the place to open a theme editor — Settings > Appearance is.
    // AppThemes.visibleBuiltIns already leaves out the hidden studioLight.
    return _WizardStep(
      icon: Icons.palette_outlined,
      title: l10n.onboardingThemeTitle,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final spec in AppThemes.visibleBuiltIns)
            ThemeChoiceCard(
              spec: spec,
              label: themeDisplayName(spec, l10n),
              selected: current == spec.id,
              onTap: () =>
                  ref.read(selectedThemeIdProvider.notifier).select(spec.id),
            ),
        ],
      ),
    );
  }
}

// ── Scan root folders ─────────────────────────────────────────────────────────

class _FoldersPage extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  const _FoldersPage({required this.l10n});

  @override
  ConsumerState<_FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends ConsumerState<_FoldersPage> {
  bool _busy = false;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> _addFolder() async {
    if (_busy || !_isDesktop) return;
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: widget.l10n.selectProjectsFolder,
    );
    if (picked == null || !mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      final root = await repo.addRoot(picked);
      container.invalidate(rootsWatchProvider);
      container.invalidate(scanRootsProvider);
      // Import the new folder's existing projects in the background instead
      // of blocking this step: the wizard shows no project list, the user
      // still has several steps to go, and a large library could take a
      // while. It drives initialScanStateProvider, so if the dashboard opens
      // before the scan finishes it shows the normal "scanning" indicator;
      // the project list (a Hive stream) fills in on its own when done.
      container.read(initialScanStateProvider.notifier).setScanning(true);
      importProjectsFromRoot(repo, root.id, root.path).whenComplete(
        () => container.read(initialScanStateProvider.notifier).complete(),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeFolder(String rootId) async {
    final repo = await ref.read(repositoryProvider.future);
    await repo.removeRoot(rootId);
    ref.invalidate(rootsWatchProvider);
    ref.invalidate(scanRootsProvider);
    ref.invalidate(allProjectsStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final roots = ref.watch(scanRootsProvider);
    final theme = Theme.of(context);

    return _WizardStep(
      icon: Icons.folder_open,
      title: l10n.onboardingFoldersTitle,
      subtitle: l10n.onboardingFoldersBody,
      child: Column(
        children: [
          if (roots.isNotEmpty)
            Column(
              children: roots
                  .map((r) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.folder, size: 20),
                        title: Text(r.path, style: theme.textTheme.bodySmall),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => _removeFolder(r.id),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 12),
          if (_isDesktop)
            OutlinedButton.icon(
              onPressed: _busy ? null : _addFolder,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add, size: 18),
              label: Text(l10n.addFolder),
            ),
        ],
      ),
    );
  }
}

// ── Update checks ─────────────────────────────────────────────────────────────

class _UpdatesPage extends ConsumerWidget {
  final AppLocalizations l10n;
  const _UpdatesPage({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(checkForUpdatesProvider);
    return _WizardStep(
      icon: Icons.system_update_alt,
      title: l10n.onboardingUpdatesTitle,
      subtitle: l10n.onboardingUpdatesBody,
      child: Center(
        child: SwitchListTile(
          value: enabled,
          onChanged: (_) => ref.read(checkForUpdatesProvider.notifier).toggle(),
          title: Text(l10n.checkForUpdates),
          subtitle: Text(l10n.checkForUpdatesDescription,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    );
  }
}

// ── Page 5: Phases ────────────────────────────────────────────────────────────

class _PhasesPage extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  const _PhasesPage({required this.l10n});

  @override
  ConsumerState<_PhasesPage> createState() => _PhasesPageState();
}

class _PhasesPageState extends ConsumerState<_PhasesPage> {
  final _addCtrl = TextEditingController();
  String? _addError;

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleFinished(String phase, Set<String> current) async {
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    final updated = Set<String>.from(current);
    if (updated.contains(phase)) {
      if (updated.length > 1) updated.remove(phase);
    } else {
      updated.add(phase);
    }
    await repo.setFinishedPhases(updated);
    ref.invalidate(finishedPhaseProvider);
  }

  Future<void> _addPhase(List<String> current) async {
    final name = _addCtrl.text.trim();
    if (name.isEmpty) return;
    if (current.any((p) => p.toLowerCase() == name.toLowerCase())) {
      setState(() => _addError = widget.l10n.phaseDuplicateError);
      return;
    }
    setState(() => _addError = null);
    _addCtrl.clear();
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    await repo.setCustomPhases([...current, name]);
    ref.invalidate(customPhasesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final phases = ref.watch(customPhasesProvider);
    final finishedPhases = ref.watch(finishedPhaseProvider);
    final theme = Theme.of(context);

    return _WizardStep(
      icon: Icons.tune,
      title: l10n.phases,
      subtitle: l10n.phasesSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.markAsFinished,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < phases.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      finishedPhases.contains(phases[i])
                          ? Icons.flag
                          : Icons.flag_outlined,
                      size: 20,
                      color: finishedPhases.contains(phases[i])
                          ? Colors.green
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    title: Text(phases[i]),
                    trailing: finishedPhases.contains(phases[i])
                        ? Chip(
                            label: Text(
                              'done',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade200,
                              ),
                            ),
                            backgroundColor:
                                Colors.green.withValues(alpha: 0.15),
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          )
                        : null,
                    onTap: () => _toggleFinished(phases[i], finishedPhases),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _addCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.phaseNameHint,
                    errorText: _addError,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addPhase(phases),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _addPhase(phases),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addPhase),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.canBeChangedInSettings,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Smart Suggestions ─────────────────────────────────────────────────────────

class _SuggestionsPage extends ConsumerWidget {
  final AppLocalizations l10n;
  const _SuggestionsPage({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(suggestionsEnabledProvider);
    final theme = Theme.of(context);
    return _WizardStep(
      icon: Icons.lightbulb_outline,
      title: l10n.onboardingSuggestionsTitle,
      subtitle: l10n.onboardingSuggestionsBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SuggestionsPreviewMockup(
              theme: theme, suggestionsLabel: l10n.suggestionsLabel),
          const SizedBox(height: 20),
          ...[
            (Icons.alarm_outlined, l10n.suggestionsFeatureDeadlines),
            (Icons.history, l10n.suggestionsFeatureResume),
            (Icons.edit_outlined, l10n.suggestionsFeatureRecentlyModified),
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(e.$1, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(e.$2, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: enabled,
            onChanged: (v) =>
                ref.read(suggestionsEnabledProvider.notifier).set(v),
            title: Text(l10n.suggestionsEnableToggle),
            subtitle: Text(
              l10n.canBeChangedInSettings,
              style: theme.textTheme.bodySmall,
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _SuggestionsPreviewMockup extends StatelessWidget {
  final ThemeData theme;
  final String suggestionsLabel;
  const _SuggestionsPreviewMockup(
      {required this.theme, required this.suggestionsLabel});

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final cardColor = theme.cardColor;
    final divider = theme.dividerColor;
    final dim = theme.textTheme.bodySmall?.color ?? Colors.grey;
    const deadline = Color(0xFFFBBF24);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Simulated toolbar row ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration:
                BoxDecoration(border: Border(bottom: BorderSide(color: divider))),
            child: Row(
              children: [
                // Suggestion chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: deadline.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: deadline.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alarm_outlined,
                          size: 11, color: deadline),
                      const SizedBox(width: 4),
                      const Text('2d left: My Track',
                          style: TextStyle(
                              fontSize: 10,
                              color: deadline,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      const Icon(Icons.bookmark_add_outlined,
                          size: 11, color: deadline),
                      const SizedBox(width: 3),
                      Icon(Icons.assignment,
                          size: 10, color: dim.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.expand_more, size: 14, color: dim),
              ],
            ),
          ),
          // ── Simulated popup panel ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 12, color: dim),
                    const SizedBox(width: 4),
                    Text(suggestionsLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: dim)),
                    const Spacer(),
                    Icon(Icons.refresh, size: 11, color: primary),
                    const SizedBox(width: 6),
                    Icon(Icons.expand_less, size: 11, color: dim),
                  ],
                ),
                const SizedBox(height: 5),
                Divider(height: 1, color: divider),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.alarm_outlined,
                        size: 13, color: deadline),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('2d left: My Track',
                          style: TextStyle(
                              fontSize: 11,
                              color: deadline,
                              fontWeight: FontWeight.w500)),
                    ),
                    Icon(Icons.bookmark_add_outlined, size: 14, color: primary),
                    const SizedBox(width: 4),
                    Icon(Icons.assignment, size: 13, color: dim),
                    const SizedBox(width: 4),
                    Icon(Icons.close,
                        size: 12, color: dim.withValues(alpha: 0.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.history, size: 13, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Resume: Summer Beat',
                          style: TextStyle(
                              fontSize: 11,
                              color: primary,
                              fontWeight: FontWeight.w500)),
                    ),
                    Icon(Icons.bookmark_add_outlined, size: 14, color: primary),
                    const SizedBox(width: 4),
                    Icon(Icons.assignment, size: 13, color: dim),
                    const SizedBox(width: 4),
                    Icon(Icons.close,
                        size: 12, color: dim.withValues(alpha: 0.5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session Mode ──────────────────────────────────────────────────────────────

class _SessionModePage extends ConsumerWidget {
  final AppLocalizations l10n;
  const _SessionModePage({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(sessionModeProvider);
    final theme = Theme.of(context);
    return _WizardStep(
      icon: Icons.timer_outlined,
      title: l10n.onboardingSessionModeTitle,
      subtitle: l10n.onboardingSessionModeBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...[
            (Icons.play_circle_outline, l10n.startSession),
            (Icons.access_time_outlined, l10n.sessionActive),
            (Icons.history, l10n.sessionHistory),
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(e.$1, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.$2, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: enabled,
            onChanged: (v) => ref.read(sessionModeProvider.notifier).set(v),
            title: Text(l10n.sessionMode),
            subtitle: Text(
              l10n.canBeChangedInSettings,
              style: theme.textTheme.bodySmall,
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }
}

// ── Page 5: Launch at startup (desktop only) ─────────────────────────────────

class _StartupPage extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  const _StartupPage({required this.l10n});

  @override
  ConsumerState<_StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<_StartupPage> {
  bool _busy = false;

  /// [apply] performs the toggle and reports whether the OS accepted it.
  Future<void> _run(Future<bool> Function() apply) async {
    setState(() => _busy = true);
    final ok = await apply();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.l10n.autoStartFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final enabled = ref.watch(autoStartProvider);
    final minimized = ref.watch(startMinimizedProvider);

    return _WizardStep(
      icon: Icons.rocket_launch_outlined,
      title: l10n.onboardingStartupTitle,
      subtitle: l10n.onboardingStartupBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: enabled,
                  onChanged: _busy
                      ? null
                      : (v) => _run(
                          () => ref.read(autoStartProvider.notifier).set(v)),
                  title: Text(l10n.autoStart),
                  subtitle: Text(
                    l10n.autoStartDescription,
                    style: theme.textTheme.bodySmall,
                  ),
                  secondary: const Icon(Icons.power_settings_new),
                ),
                const Divider(height: 1),
                // Only does anything alongside the switch above, so it stays
                // disabled until auto-start is on.
                SwitchListTile(
                  value: minimized,
                  onChanged: (_busy || !enabled)
                      ? null
                      : (v) => _run(() =>
                          ref.read(startMinimizedProvider.notifier).set(v)),
                  title: Text(l10n.onboardingStartMinimized),
                  subtitle: Text(
                    l10n.startMinimizedDescription,
                    style: theme.textTheme.bodySmall,
                  ),
                  secondary: const Icon(Icons.move_to_inbox_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.canBeChangedInSettings,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 8: Done ──────────────────────────────────────────────────────────────

class _DonePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _DonePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _WizardStep(
      icon: Icons.check_circle_outline,
      iconSize: 80,
      title: l10n.onboardingDoneTitle,
      subtitle: l10n.onboardingDoneBody,
      child: const SizedBox.shrink(),
    );
  }
}

// ── Page 3: Tab layout ────────────────────────────────────────────────────────

class _TabsPage extends ConsumerWidget {
  final AppLocalizations l10n;
  const _TabsPage({required this.l10n});

  static const _icons = {
    AppTab.projects:   Icons.library_music,
    AppTab.releases:   Icons.album,
    AppTab.playlists:  Icons.playlist_play,
    AppTab.queue:      Icons.checklist,
    AppTab.statistics: Icons.bar_chart_rounded,
    AppTab.player:     Icons.headphones,
  };

  String _label(AppTab tab, AppLocalizations l10n) => switch (tab) {
    AppTab.projects   => l10n.projectsTab,
    AppTab.releases   => l10n.releasesTab,
    AppTab.playlists  => l10n.playlists,
    AppTab.queue      => l10n.queueTab,
    AppTab.statistics => l10n.statisticsTab,
    AppTab.player     => l10n.musicPlayerTab,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabPos = ref.watch(tabPositionProvider);
    final visibleSet = ref.watch(visibleTabsProvider);
    final isMobile = MobileUtils.isMobile();

    final allTabs = VisibleTabsNotifier.canonicalOrder
        .where((t) => isMobile || t != AppTab.playlists)  // playlists is mobile-only
        .where((t) => !isMobile || t != AppTab.player)    // player is desktop-only
        .toList();

    return _WizardStep(
      icon: Icons.tab_outlined,
      title: l10n.customizeTabs,
      subtitle: l10n.customizeTabsDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab position cards (desktop only)
          if (!isMobile) ...[
            Text(l10n.tabPosition, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TabPositionCard(
                    position: TabPosition.left,
                    label: l10n.tabPositionLeft,
                    selected: tabPos == TabPosition.left,
                    onTap: () => ref.read(tabPositionProvider.notifier).set(TabPosition.left),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabPositionCard(
                    position: TabPosition.top,
                    label: l10n.tabPositionTop,
                    selected: tabPos == TabPosition.top,
                    onTap: () => ref.read(tabPositionProvider.notifier).set(TabPosition.top),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Tab visibility toggles
          Text(l10n.customizeTabs, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allTabs.map((tab) {
              final isProjects = tab == AppTab.projects;
              final visible = visibleSet.contains(tab);
              return FilterChip(
                avatar: Icon(_icons[tab], size: 16),
                label: Text(_label(tab, l10n)),
                selected: visible,
                onSelected: isProjects ? null : (v) =>
                    ref.read(visibleTabsProvider.notifier).setTabVisible(tab, v),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TabPositionCard extends StatelessWidget {
  final TabPosition position;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPositionCard({
    required this.position,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer.withValues(alpha: 0.25) : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            _TabLayoutDiagram(position: position, primary: cs.primary),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected)
                  Icon(Icons.radio_button_checked, size: 13, color: cs.primary)
                else
                  Icon(Icons.radio_button_unchecked, size: 13, color: cs.outline),
                const SizedBox(width: 4),
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  color: selected ? cs.primary : null,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabLayoutDiagram extends StatelessWidget {
  final TabPosition position;
  final Color primary;

  const _TabLayoutDiagram({required this.position, required this.primary});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final tabColor = primary.withValues(alpha: 0.8);
    final contentColor = Colors.white.withValues(alpha: 0.12);

    if (position == TabPosition.top) {
      return Container(
        height: 84,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Column(
          children: [
            // Tab bar at top
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  _tabChip(tabColor, active: true),
                  const SizedBox(width: 4),
                  _tabChip(tabColor.withValues(alpha: 0.35)),
                  const SizedBox(width: 4),
                  _tabChip(tabColor.withValues(alpha: 0.35)),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 5, width: double.infinity, color: contentColor),
                    Container(height: 5, width: 120, color: contentColor),
                    Container(height: 5, width: double.infinity, color: contentColor),
                    Container(height: 5, width: 80, color: contentColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Left rail layout
      return Container(
        height: 84,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            // Left rail
            Container(
              width: 26,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _tabDot(tabColor, active: true),
                  const SizedBox(height: 5),
                  _tabDot(tabColor.withValues(alpha: 0.35)),
                  const SizedBox(height: 5),
                  _tabDot(tabColor.withValues(alpha: 0.35)),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 5, width: double.infinity, color: contentColor),
                    Container(height: 5, width: 60, color: contentColor),
                    Container(height: 5, width: double.infinity, color: contentColor),
                    Container(height: 5, width: 40, color: contentColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _tabChip(Color color, {bool active = false}) {
    return Container(
      width: active ? 30 : 20,
      height: 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }

  Widget _tabDot(Color color, {bool active = false}) {
    return Container(
      width: 14,
      height: active ? 14 : 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }
}
