import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../generated/l10n/app_localizations.dart';
import '../models/project_anatomy.dart';
import '../providers/providers.dart';
import '../services/project_inspector/compare/anatomy_diff.dart';
import '../services/project_inspector/compare/anatomy_diff_csv.dart';
import '../services/project_inspector/media_check.dart';
import '../services/project_inspector/report/anatomy_report_csv.dart';
import '../services/project_inspector/relink/relink_writer.dart';
import '../services/project_inspector/safe_copy/safe_copy.dart';
import '../services/scanner_service.dart';
import '../utils/cloud_file.dart';
import '../utils/save_file_dialog.dart';
import 'app_snack_bar.dart';
import 'dialogs/archive_project_dialog.dart' show formatByteSize;
import 'dialogs/relink_dialog.dart';
import 'dialogs/safe_copy_dialog.dart';
import 'widgets/anatomy_compare_text.dart';
import 'widgets/inspector_report_text.dart';
import 'widgets/project_compare_view.dart';
import 'widgets/project_inspector_view.dart';

/// Opens [path] in the Inspector tab and brings the tab to the front: the
/// one way in, for the project menu, Open project… and a dropped file. A
/// comparison open there is closed.
///
/// A file this app can't read is refused with a note. A cloud placeholder
/// (its contents not on this computer) is read only once the user says so:
/// reading it downloads all of it. Returns whether the file was opened.
Future<bool> openInInspector(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  final file = await _inspectable(context, path);
  if (file == null) return false;
  ref.read(inspectorCompareFileProvider.notifier).close();
  ref.read(inspectorFileProvider.notifier).open(file);
  ref.read(inspectorShowRequestProvider.notifier).request();
  return true;
}

/// Opens the Inspector comparing [aPath] with [bPath] (#223) — for "Compare
/// with previous version", A is the older one. Each file is checked as
/// [openInInspector] checks it.
Future<bool> compareInInspector(
  BuildContext context,
  WidgetRef ref,
  String aPath,
  String bPath,
) async {
  final a = await _inspectable(context, aPath);
  if (a == null || !context.mounted) return false;
  final b = await _inspectable(context, bPath);
  if (b == null) return false;
  ref.read(inspectorFileProvider.notifier).open(a);
  ref.read(inspectorCompareFileProvider.notifier).open(b);
  ref.read(inspectorShowRequestProvider.notifier).request();
  return true;
}

/// [path] as the Inspector reads it, or null — with a note — for a file it
/// can't read, or a cloud placeholder the user chose not to download.
Future<InspectedFile?> _inspectable(BuildContext context, String path) async {
  final l10n = AppLocalizations.of(context)!;
  final ext = p.extension(path).toLowerCase();
  final file = File(path);
  if (!ScannerService.supportedExtensions.contains(ext) || !file.existsSync()) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(
        content: Text(l10n.inspectorUnsupported(ext.isEmpty ? path : ext)),
      ),
    );
    return null;
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
    if (read != true) return null;
  }
  return (
    path: path,
    size: stat.size,
    modifiedMs: stat.modified.millisecondsSinceEpoch,
  );
}

/// The Inspector tab: a project file read without its DAW (#196), or two
/// compared (#223).
///
/// Riverpod glue around [ProjectInspectorView] and [ProjectCompareView]:
/// which files are open, reading them, the dashboard's search box, and the
/// ways a file gets here — the project menu's Inspect, Open project…, or
/// dropping a file anywhere on the tab.
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

  /// Picks B for the open project, A.
  Future<void> _pickCompare(String aPath) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.pickFiles(
      dialogTitle: l10n.compareWithTitle,
    );
    final path = picked.map((f) => f.path).whereType<String>().firstOrNull;
    if (path == null || !mounted) return;
    await compareInInspector(context, ref, aPath, path);
  }

  void _swap(InspectedFile a, InspectedFile b) {
    ref.read(inspectorFileProvider.notifier).open(b);
    ref.read(inspectorCompareFileProvider.notifier).open(a);
  }

  Future<void> _copySummary(
    AnatomyDiff diff,
    ProjectAnatomy a,
    ProjectAnatomy b,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(
      ClipboardData(
        text: compareSummaryText(
          l10n,
          diff,
          aName: p.basename(a.filePath),
          bName: p.basename(b.filePath),
        ),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showAppSnackBar(SnackBar(content: Text(l10n.compareSummaryCopied)));
  }

  Future<void> _exportCsv(
    AnatomyDiff diff,
    ProjectAnatomy a,
    ProjectAnatomy b,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await saveTextWithDialog(
      fileName:
          '${p.basenameWithoutExtension(a.filePath)} vs '
          '${p.basenameWithoutExtension(b.filePath)}.csv',
      text: anatomyDiffCsv(diff),
      dialogTitle: l10n.compareExportCsvTitle,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (saved == null || !mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(content: Text(l10n.compareSaved(p.basename(saved)))),
    );
  }

  /// Copies or saves a report of [a] (#224).
  Future<void> _report(
    InspectorReportAction action,
    ProjectAnatomy a,
    List<MediaCheck>? media,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (action == InspectorReportAction.copySummary) {
      await Clipboard.setData(
        ClipboardData(text: inspectorSummaryText(l10n, a, media: media)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showAppSnackBar(SnackBar(content: Text(l10n.reportCopied)));
      return;
    }
    final stem = p.basenameWithoutExtension(a.filePath);
    // File names stay English, like the CSVs' headers: files, not UI.
    final (name, text, ext) = switch (action) {
      InspectorReportAction.markdown => (
        '$stem report.md',
        inspectorReportMarkdown(l10n, a, media: media),
        'md',
      ),
      InspectorReportAction.tracksCsv => (
        '$stem tracks.csv',
        anatomyTracksCsv(a),
        'csv',
      ),
      _ => ('$stem plug-ins.csv', anatomyPluginsCsv(a), 'csv'),
    };
    final saved = await saveTextWithDialog(
      fileName: name,
      text: text,
      dialogTitle: l10n.reportSaveTitle,
      type: FileType.custom,
      allowedExtensions: [ext],
    );
    if (saved == null || !mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(content: Text(l10n.compareSaved(p.basename(saved)))),
    );
  }

  Widget _reading(String path) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
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
    );
  }

  Widget _failed(
    String path,
    Object error,
    VoidCallback reload,
    VoidCallback close,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(l10n.inspectorReadFailed, style: theme.textTheme.titleMedium),
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
                TextButton(onPressed: close, child: Text(l10n.inspectorClose)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final inspected = ref.watch(inspectorFileProvider);
    final other = ref.watch(inspectorCompareFileProvider);

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
    } else if (other != null) {
      final a = ref.watch(projectAnatomyProvider(inspected));
      final b = ref.watch(projectAnatomyProvider(other));
      void closeCompare() =>
          ref.read(inspectorCompareFileProvider.notifier).close();
      void reload() {
        ref.invalidate(projectAnatomyProvider(inspected));
        ref.invalidate(projectAnatomyProvider(other));
      }

      final pa = a.value;
      final pb = b.value;
      if (a.hasError || b.hasError) {
        body = _failed(
          a.hasError ? inspected.path : other.path,
          (a.error ?? b.error)!,
          reload,
          closeCompare,
        );
      } else if (pa != null && pb != null) {
        body = ProjectCompareView(
          a: pa,
          b: pb,
          search: ref.watch(inspectorSearchProvider),
          onSwap: () => _swap(inspected, other),
          onClose: closeCompare,
          onCopySummary: (diff) => _copySummary(diff, pa, pb),
          onExportCsv: (diff) => _exportCsv(diff, pa, pb),
        );
      } else {
        body = _reading(pa == null ? inspected.path : other.path);
      }
    } else {
      final path = inspected.path;
      final anatomy = ref.watch(projectAnatomyProvider(inspected));
      final media = ref.watch(inspectorMediaChecksProvider(inspected));
      void close() => ref.read(inspectorFileProvider.notifier).close();
      // "Read again" reads even an unchanged file: the user asked.
      void reload() => ref.invalidate(projectAnatomyProvider(inspected));
      body = anatomy.when(
        loading: () => _reading(path),
        error: (error, _) => _failed(path, error, reload, close),
        data: (a) => ProjectInspectorView(
          anatomy: a,
          search: ref.watch(inspectorSearchProvider),
          mediaChecks: media.value,
          mediaChecking: media.isLoading,
          onClose: close,
          onReload: reload,
          onOpenOther: _pick,
          onCompare: () => _pickCompare(path),
          onReport: (action) => _report(action, a, media.value),
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
