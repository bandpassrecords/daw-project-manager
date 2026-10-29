import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../generated/l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../services/scanner_service.dart';
import 'app_snack_bar.dart';
import 'widgets/project_inspector_view.dart';

/// The Inspector tab: a project file read without its DAW (#196).
///
/// Riverpod glue around [ProjectInspectorView]: which file is open, reading
/// it, the dashboard's search box, and the ways a file gets here — the
/// project menu's Inspect, Open project…, or dropping a file anywhere on
/// the tab.
class ProjectInspectorPage extends ConsumerStatefulWidget {
  const ProjectInspectorPage({super.key});

  @override
  ConsumerState<ProjectInspectorPage> createState() =>
      _ProjectInspectorPageState();
}

class _ProjectInspectorPageState extends ConsumerState<ProjectInspectorPage> {
  bool _dragging = false;

  void _open(String path) {
    final l10n = AppLocalizations.of(context)!;
    final ext = p.extension(path).toLowerCase();
    if (!ScannerService.supportedExtensions.contains(ext)) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text(l10n.inspectorUnsupported(ext.isEmpty ? path : ext))),
      );
      return;
    }
    // A file read before may have changed since: read it again.
    ref.invalidate(projectAnatomyProvider(path));
    ref.read(inspectorFileProvider.notifier).open(path);
  }

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.pickFiles(
      dialogTitle: l10n.inspectorChooseProjectTitle,
    );
    final path = picked.map((f) => f.path).whereType<String>().firstOrNull;
    if (path == null || !mounted) return;
    _open(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final path = ref.watch(inspectorFileProvider);

    final Widget body;
    if (path == null) {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.manage_search,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.inspectorEmptyTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.inspectorEmptyBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.inspectorOpenProject),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final anatomy = ref.watch(projectAnatomyProvider(path));
      final media = ref.watch(inspectorMediaChecksProvider(path));
      void close() => ref.read(inspectorFileProvider.notifier).close();
      void reload() => ref.invalidate(projectAnatomyProvider(path));
      body = anatomy.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(l10n.inspectorReading),
              const SizedBox(height: 4),
              Text(p.basename(path), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 40, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text(l10n.inspectorReadFailed, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(path, style: theme.textTheme.bodySmall),
                Text('$error', style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(onPressed: reload, child: Text(l10n.inspectorReload)),
                    TextButton(onPressed: close, child: Text(l10n.inspectorClose)),
                  ],
                ),
              ],
            ),
          ),
        ),
        data: (a) => ProjectInspectorView(
          anatomy: a,
          search: ref.watch(inspectorSearchProvider),
          mediaChecks: media.value,
          mediaChecking: media.isLoading,
          onClose: close,
          onReload: reload,
          onOpenOther: _pick,
        ),
      );
    }

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        final first = details.files.firstOrNull;
        if (first != null) _open(first.path);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: _dragging ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: body,
      ),
    );
  }
}
