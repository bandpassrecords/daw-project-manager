import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../providers/providers.dart';
import '../../utils/project_accent_color.dart';
import '../../utils/project_visuals.dart';

/// Edits the short label on a project's dashboard card (#111).
///
/// The label defaults to initials derived from the name, which is right often
/// enough to need no attention and wrong often enough to need an override —
/// three projects called "Untitled 1/2/3" all read "UN". Clearing the field
/// hands the project back to the derived label rather than blanking the card.
Future<void> showCardInitialsDialog(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: project.cardInitials ?? '');
  final result = await showDialog<String?>(
    context: context,
    builder: (ctx) => _CardInitialsDialog(
      project: project,
      controller: controller,
      l10n: l10n,
    ),
  );
  controller.dispose();
  if (result == null) return;

  final trimmed = result.trim();
  final repo = await ref.read(repositoryProvider.future);
  // Read the project back before writing: the dialog was open long enough for
  // a scan or a Drive restore to have touched it.
  final fresh = repo.getById(project.id) ?? project;
  await repo.updateProject(
    trimmed.isEmpty
        ? fresh.copyWith(clearCardInitials: true)
        : fresh.copyWith(cardInitials: trimmed),
  );
  ref.invalidate(allProjectsStreamProvider);
}

class _CardInitialsDialog extends StatefulWidget {
  const _CardInitialsDialog({
    required this.project,
    required this.controller,
    required this.l10n,
  });

  final MusicProject project;
  final TextEditingController controller;
  final AppLocalizations l10n;

  @override
  State<_CardInitialsDialog> createState() => _CardInitialsDialogState();
}

class _CardInitialsDialogState extends State<_CardInitialsDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final accent = resolvedAccentColor(widget.project);
    final preview = projectCardInitials(
      widget.controller.text,
      widget.project.displayName,
    );

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(l10n.cardInitialsTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cardInitialsDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            // A field paired with anything else centres, or the neighbour
            // top-aligns against the field's full decorated height.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Live preview of the cover this is drawn on, so the choice is
              // made against the real thing rather than against a text field.
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, Color.lerp(accent, Colors.black, 0.45)!],
                  ),
                ),
                child: Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                  inputFormatters: [LengthLimitingTextInputFormatter(3)],
                  decoration: InputDecoration(
                    labelText: l10n.cardInitialsTitle,
                    hintText: projectInitials(widget.project.displayName),
                    helperText: l10n.cardInitialsEmptyHint,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (value) => Navigator.pop(context, value),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            widget.controller.clear();
            setState(() {});
          },
          child: Text(l10n.clear),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, widget.controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
