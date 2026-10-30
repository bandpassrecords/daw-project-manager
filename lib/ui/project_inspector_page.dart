import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../generated/l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../services/project_inspector/relink/relink_writer.dart';
import '../services/project_inspector/safe_copy/safe_copy.dart';
import '../services/scanner_service.dart';
import '../utils/cloud_file.dart';
import 'app_snack_bar.dart';
import 'dialogs/archive_project_dialog.dart' show formatByteSize;
import 'dialogs/relink_dialog.dart';
import 'dialogs/safe_copy_dialog.dart';
import 'widgets/project_inspector_view.dart';

/// Opens [path] in the Inspector tab and brings the tab to the front: the
/// one way in, for the project menu, Open project… and a dropped file.
///
/// A file this app can't read is refused with a note. A cloud placeholder
/// (its contents not on this computer) is read only once the user says so:
/// reading it downloads all of it. Returns whether the file was opened.
Future<bool> openInInspector(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ext = p.extension(path).toLowerCase();
  final file = File(path);
  if (!ScannerService.supportedExtensions.contains(ext) || !file.existsSync()) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(
        content: Text(l10n.inspectorUnsupported(ext.isEmpty ? path : ext)),
      ),
    );
    return false;
  }
  final stat = file.statSync();
  if (isCloudOnlyFile(path)) {
    final read = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.inspectorCloudTitle),
        content: Text(l10n.inspectorCloudBody(formatByteSize(stat.size))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.inspectorCloudRead),
          ),
        ],
      ),
    );
    if (read != true) return false;
  }
  ref.read(inspectorFileProvider.notifier).open((
    path: path,
    size: stat.size,
    modifiedMs: stat.modified.millisecondsSinceEpoch,
  ));
  ref.read(inspectorShowRequestProvider.notifier).request();
  return true;
}

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

  void _open(String path) => openInInspector(context, ref, path);

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
    final inspected = ref.watch(inspectorFileProvider);

    final Widget body;
    if (inspected == null) {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.manage_search,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
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
      final path = inspected.path;
      final anatomy = ref.watch(projectAnatomyProvider(inspected));
      final media = ref.watch(inspectorMediaChecksProvider(inspected));
      void close() => ref.read(inspectorFileProvider.notifier).close();
      // "Read again" reads even an unchanged file: the user asked.
      void reload() => ref.invalidate(projectAnatomyProvider(inspected));
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
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.inspectorReadFailed,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(path, style: theme.textTheme.bodySmall),
                Text('$error', style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: reload,
                      child: Text(l10n.inspectorReload),
                    ),
                    TextButton(
                      onPressed: close,
                      child: Text(l10n.inspectorClose),
                    ),
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
          onRelink: relinkWriterFor(a.filePath) == null || media.value == null
              ? null
              : () => showRelinkDialog(
                  context,
                  ref,
                  projectPath: a.filePath,
                  checks: media.value!,
                ),
          onSafeCopy: safeCopyWriterFor(a.filePath) == null
              ? null
              : () => showSafeCopyDialog(context, ref, projectPath: a.filePath),
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
