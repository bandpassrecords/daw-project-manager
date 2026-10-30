import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../services/project_inspector/media_check.dart';
import '../../services/project_inspector/relink/folder_rules.dart';
import '../../services/project_inspector/relink/relink_copy.dart';
import '../../services/project_inspector/relink/relink_plan.dart';
import '../../services/project_inspector/relink/relink_writer.dart';
import '../../services/sample_pack/sample_locator.dart';
import '../../services/sample_pack/sample_pack_prefs_store.dart';
import '../project_inspector_page.dart';

/// What [RelinkDialog] does to the world, handed in so the dialog can be
/// tested without files, pickers or a project.
class RelinkActions {
  const RelinkActions({
    required this.plan,
    required this.pickFolder,
    required this.pickFile,
    required this.exists,
    required this.write,
    this.inspect,
  });

  /// The missing files, with [folders] searched as well.
  final Future<List<RelinkItem>> Function(List<String> folders) plan;
  final Future<String?> Function() pickFolder;
  final Future<String?> Function(String fileName) pickFile;
  final Future<bool> Function(String path) exists;
  final Future<RelinkCopy> Function(Map<String, String> moves) write;

  /// Opens the written copy; null to offer nothing.
  final void Function(String copyPath)? inspect;
}

/// Opens [RelinkDialog] for the project at [projectPath]: its missing
/// files ([checks]) looked for in the project's folder, the sample pack's
/// library folders and any folder the user adds.
Future<void> showRelinkDialog(
  BuildContext context,
  WidgetRef ref, {
  required String projectPath,
  required List<MediaCheck> checks,
}) async {
  final l10n = AppLocalizations.of(context)!;
  List<String> libraries;
  try {
    libraries = (await SamplePackPrefsStore.load()).libraryFolders;
  } catch (_) {
    libraries = const []; // Device-local and optional.
  }
  final locator = SampleLocator(libraryFolders: libraries);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => RelinkDialog(
      projectName: p.basename(projectPath),
      actions: RelinkActions(
        plan: (folders) => planRelink(
          checks,
          projectDir: p.dirname(projectPath),
          locator: locator,
          searchFolders: folders,
        ),
        pickFolder: () => FilePicker.getDirectoryPath(
          dialogTitle: l10n.relinkSearchFolderTitle,
        ),
        pickFile: (name) async {
          final picked = await FilePicker.pickFiles(
            dialogTitle: l10n.relinkBrowseTitle(name),
          );
          return picked.map((f) => f.path).whereType<String>().firstOrNull;
        },
        exists: (path) => File(path).exists(),
        write: (moves) =>
            writeRelinkedCopy(projectPath: projectPath, moves: moves),
        inspect: (copy) {
          Navigator.of(dialogContext).pop();
          openInInspector(context, ref, copy);
        },
      ),
    ),
  );
}

/// Finds a project's missing audio files and writes a copy pointing to
/// where they are now (#214). Search a folder and every file it can tell
/// for sure is chosen; a file found more than once is picked from a menu,
/// one found nowhere is browsed for. Picking one by hand offers the same
/// folder move for every other file it finds. The project is never
/// written: "Write relinked copy" makes `<name> (relinked)` beside it.
class RelinkDialog extends StatefulWidget {
  const RelinkDialog({
    super.key,
    required this.projectName,
    required this.actions,
  });

  final String projectName;
  final RelinkActions actions;

  @override
  State<RelinkDialog> createState() => _RelinkDialogState();
}

class _RelinkDialogState extends State<RelinkDialog> {
  List<RelinkItem>? _items;
  final _folders = <String>[];
  final _rules = <FolderRule>[];

  /// Chosen by hand, by stored path; a null choice leaves the file as it is.
  final _byHand = <String, String?>{};
  ({FolderRule rule, int count})? _offer;
  bool _busy = true;
  bool _writing = false;
  bool _written = false;
  RelinkCopy? _copy;
  String? _error;

  RelinkActions get _actions => widget.actions;

  @override
  void initState() {
    super.initState();
    _replan();
  }

  Future<void> _replan() async {
    setState(() => _busy = true);
    var items = await _actions.plan(List.of(_folders));
    items = await applyRules(items, _rules, _actions.exists);
    items = [
      for (final i in items)
        _byHand.containsKey(i.stored)
            ? i.copyWith(choice: () => _byHand[i.stored], manual: true)
            : i,
    ];
    if (!mounted) return;
    setState(() {
      _items = items;
      _busy = false;
    });
  }

  Future<void> _searchFolder() async {
    final folder = await _actions.pickFolder();
    if (folder == null || _folders.contains(folder)) return;
    _folders.add(folder);
    await _replan();
  }

  Future<void> _choose(RelinkItem item, String? path) async {
    _byHand[item.stored] = path;
    final items = [
      for (final i in _items!)
        i.stored == item.stored
            ? i.copyWith(choice: () => path, manual: true)
            : i,
    ];
    setState(() => _items = items);
    if (path == null) return;
    final rule = suggestFolderRule(item.stored, path);
    if (rule == null) return;
    final open = [
      for (final i in items)
        if (i.choice == null && !i.manual) i,
    ];
    final count = await filesFixedBy(rule, open, _actions.exists);
    if (!mounted) return;
    setState(() => _offer = count == 0 ? null : (rule: rule, count: count));
  }

  Future<void> _browse(RelinkItem item) async {
    final path = await _actions.pickFile(item.reference.fileName);
    if (path != null) await _choose(item, path);
  }

  Future<void> _applyOffer() async {
    final offer = _offer;
    if (offer == null) return;
    _rules.add(offer.rule);
    final items = await applyRules(_items!, _rules, _actions.exists);
    if (!mounted) return;
    setState(() {
      _items = items;
      _offer = null;
    });
  }

  Future<void> _write() async {
    setState(() {
      _busy = true;
      _writing = true;
    });
    try {
      final copy = await _actions.write(relinkMoves(_items!));
      if (!mounted) return;
      setState(() => _copy = copy);
    } on RelinkCheckFailed catch (e) {
      if (!mounted) return;
      setState(() => _error = e.reason);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _written = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text('${l10n.relinkTitle} — ${widget.projectName}'),
      content: SizedBox(
        width: 760,
        height: 520,
        child: _written ? _result(context) : _editor(context),
      ),
      actions: _written
          ? [
              if (_copy?.path != null && _actions.inspect != null)
                OutlinedButton(
                  onPressed: () => _actions.inspect!(_copy!.path!),
                  child: Text(l10n.relinkInspectCopy),
                ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: _busy || relinkMoves(_items ?? const []).isEmpty
                    ? null
                    : _write,
                child: Text(l10n.relinkWrite),
              ),
            ],
    );
  }

  Widget _editor(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = _items;
    final chosen = items == null ? 0 : relinkMoves(items).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.relinkIntro, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _searchFolder,
              icon: const Icon(Icons.travel_explore),
              label: Text(l10n.relinkSearchFolder),
            ),
            const SizedBox(width: 12),
            if (_folders.isNotEmpty)
              Expanded(
                child: Text(
                  l10n.relinkSearchedIn(_folders.join(', ')),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
        if (_offer case final offer?) ...[
          const SizedBox(height: 8),
          Material(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      l10n.relinkRuleOffer(
                        offer.count,
                        offer.rule.from,
                        offer.rule.to,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _applyOffer,
                    child: Text(l10n.relinkApplyRule),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: items == null
              ? Center(child: Text(l10n.relinkSearching))
              : ListView(children: [for (final i in items) _row(context, i)]),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_busy) ...[
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(_writing ? l10n.relinkWriting : l10n.relinkSearching),
            ] else if (items != null)
              Text(l10n.relinkWillFix(chosen, items.length)),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, RelinkItem item) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final choice = item.choice;
    final status = choice != null
        ? '→ $choice'
        : item.manual
        ? l10n.relinkLeave
        : item.ambiguous
        ? l10n.relinkChooseOne(item.candidates.length)
        : item.candidates.isEmpty
        ? l10n.relinkNotFound
        : l10n.relinkLeave;
    return ListTile(
      dense: true,
      leading: Icon(
        choice != null
            ? Icons.link
            : item.ambiguous
            ? Icons.help_outline
            : Icons.link_off,
        color: choice != null
            ? theme.colorScheme.primary
            : item.ambiguous
            ? theme.colorScheme.tertiary
            : theme.colorScheme.error,
      ),
      title: Text(item.reference.fileName, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${item.stored}\n$status',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: item.candidates.isEmpty && choice == null
          ? TextButton(
              onPressed: () => _browse(item),
              child: Text(l10n.relinkBrowse),
            )
          : PopupMenuButton<_Pick>(
              tooltip: l10n.relinkChange,
              icon: const Icon(Icons.arrow_drop_down_circle_outlined),
              onSelected: (pick) => switch (pick) {
                _Path(:final path) => _choose(item, path),
                _Browse() => _browse(item),
                _Leave() => _choose(item, null),
              },
              itemBuilder: (_) => [
                for (final c in item.candidates)
                  CheckedPopupMenuItem<_Pick>(
                    value: _Path(c),
                    checked: c == choice,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem<_Pick>(
                  value: const _Browse(),
                  child: Text(l10n.relinkBrowse),
                ),
                PopupMenuItem<_Pick>(
                  value: const _Leave(),
                  child: Text(l10n.relinkLeave),
                ),
              ],
            ),
    );
  }

  Widget _result(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final copy = _copy;
    final refused = copy?.refused ?? const <String, RelinkRefusal>{};
    int count(RelinkRefusal r) => refused.values.where((v) => v == r).length;
    final lines = <Widget>[
      if (_error != null)
        Text(
          l10n.relinkFailed(_error!),
          style: TextStyle(color: theme.colorScheme.error),
        )
      else if (copy?.path == null)
        Text(l10n.relinkNothingWritten)
      else ...[
        Text(
          l10n.relinkWrote(p.basename(copy!.path!)),
          style: theme.textTheme.titleMedium,
        ),
        Text(copy.path!, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(l10n.relinkRelinkedCount(copy.relinked.length)),
      ],
      for (final (r, text) in [
        (RelinkRefusal.doesNotFit, l10n.relinkRefusedTooLong),
        (RelinkRefusal.encoding, l10n.relinkRefusedEncoding),
        (RelinkRefusal.notFound, l10n.relinkRefusedNotFound),
      ])
        if (count(r) > 0) ...[
          const SizedBox(height: 8),
          Text(
            text(count(r)),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          for (final MapEntry(key: stored, value: why) in refused.entries)
            if (why == r) Text('  $stored', style: theme.textTheme.bodySmall),
        ],
    ];
    return ListView(children: lines);
  }
}

sealed class _Pick {
  const _Pick();
}

class _Path extends _Pick {
  const _Path(this.path);
  final String path;
}

class _Browse extends _Pick {
  const _Browse();
}

class _Leave extends _Pick {
  const _Leave();
}
