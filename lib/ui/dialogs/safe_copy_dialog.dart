import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../services/project_inspector/project_copy.dart';
import '../../services/project_inspector/safe_copy/safe_copy.dart';
import '../project_inspector_page.dart';

/// What [SafeCopyDialog] does to the world, handed in so the dialog can be
/// tested without files or a project.
class SafeCopyActions {
  const SafeCopyActions({
    required this.load,
    required this.write,
    this.inspect,
  });

  /// Every plug-in instance in the project.
  final Future<List<PluginSwitch>> Function() load;

  /// Writes the copy with [plugins] switched off.
  final Future<SafeCopy> Function(Set<String> plugins) write;

  /// Opens the written copy; null to offer nothing.
  final void Function(String copyPath)? inspect;
}

/// Opens [SafeCopyDialog] for the project at [projectPath].
Future<void> showSafeCopyDialog(
  BuildContext context,
  WidgetRef ref, {
  required String projectPath,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (dialogContext) => SafeCopyDialog(
    projectName: p.basename(projectPath),
    actions: SafeCopyActions(
      load: () => readPluginSwitches(projectPath),
      write: (plugins) => writeSafeCopyInBackground(projectPath, plugins),
      inspect: (copy) {
        Navigator.of(dialogContext).pop();
        openInInspector(context, ref, copy);
      },
    ),
  ),
);

/// Writes a copy of a project that doesn't load the plug-ins picked here
/// (#220): for a project a plug-in crashes on open, or one that isn't
/// installed. Every plug-in the project uses is listed with how often it is
/// on; ticking one switches every instance of it off in the copy, which is
/// written beside the project as `<name> (safe copy)`.
class SafeCopyDialog extends StatefulWidget {
  const SafeCopyDialog({
    super.key,
    required this.projectName,
    required this.actions,
  });

  final String projectName;
  final SafeCopyActions actions;

  @override
  State<SafeCopyDialog> createState() => _SafeCopyDialogState();
}

class _SafeCopyDialogState extends State<SafeCopyDialog> {
  List<SafeCopyChoice>? _choices;
  final _picked = <String>{};
  String _filter = '';
  bool _writing = false;
  bool _written = false;
  SafeCopy? _copy;
  String? _readError;
  String? _writeError;

  SafeCopyActions get _actions => widget.actions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final switches = await _actions.load();
      if (!mounted) return;
      setState(() => _choices = safeCopyChoices(switches));
    } catch (e) {
      if (!mounted) return;
      setState(() => _readError = '$e');
    }
  }

  int get _willSwitchOff => [
    for (final c in _choices ?? const <SafeCopyChoice>[])
      if (_picked.contains(c.plugin)) c.on,
  ].fold(0, (a, b) => a + b);

  Future<void> _write() async {
    setState(() => _writing = true);
    try {
      final copy = await _actions.write(Set.of(_picked));
      if (!mounted) return;
      setState(() => _copy = copy);
    } on CopyCheckFailed catch (e) {
      if (!mounted) return;
      setState(() => _writeError = e.reason);
    } catch (e) {
      if (!mounted) return;
      setState(() => _writeError = '$e');
    }
    if (!mounted) return;
    setState(() {
      _writing = false;
      _written = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text('${l10n.safeCopyTitle} — ${widget.projectName}'),
      content: SizedBox(
        width: 640,
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
                onPressed: _writing || _willSwitchOff == 0 ? null : _write,
                child: Text(l10n.safeCopyWrite),
              ),
            ],
    );
  }

  Widget _editor(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final choices = _choices;
    final needle = _filter.trim().toLowerCase();
    final shown = [
      for (final c in choices ?? const <SafeCopyChoice>[])
        if (needle.isEmpty || c.plugin.toLowerCase().contains(needle)) c,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.safeCopyIntro, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.safeCopyFilter,
          ),
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: _readError != null
              ? Center(
                  child: Text(
                    l10n.safeCopyReadFailed(_readError!),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                )
              : choices == null
              ? Center(child: Text(l10n.safeCopyReading))
              : ListView(children: [for (final c in shown) _row(context, c)]),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_writing) ...[
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(l10n.relinkWriting),
            ] else if (choices != null)
              Text(l10n.safeCopyWillSwitchOff(_willSwitchOff)),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, SafeCopyChoice c) {
    final l10n = AppLocalizations.of(context)!;
    final status = c.on == 0
        ? l10n.safeCopyAllOff
        : [
            l10n.safeCopyInstances(c.on),
            if (c.off > 0) l10n.safeCopyAlreadyOff(c.off),
          ].join(' · ');
    return CheckboxListTile(
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      value: c.on > 0 && _picked.contains(c.plugin),
      onChanged: c.on == 0 || _writing
          ? null
          : (v) => setState(
              () => v == true ? _picked.add(c.plugin) : _picked.remove(c.plugin),
            ),
      title: Text(c.plugin, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$status\n${c.channels.join(', ')}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
    );
  }

  Widget _result(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final copy = _copy;
    return ListView(
      children: [
        if (_writeError != null)
          Text(
            l10n.relinkFailed(_writeError!),
            style: TextStyle(color: theme.colorScheme.error),
          )
        else if (copy?.path == null)
          Text(l10n.safeCopyNothingWritten)
        else ...[
          Text(
            l10n.relinkWrote(p.basename(copy!.path!)),
            style: theme.textTheme.titleMedium,
          ),
          Text(copy.path!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(l10n.safeCopySwitchedOff(copy.total)),
          for (final MapEntry(key: plugin, value: n)
              in copy.switchedOff.entries)
            Text('  $plugin ×$n', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(l10n.safeCopyNextStep),
        ],
      ],
    );
  }
}
