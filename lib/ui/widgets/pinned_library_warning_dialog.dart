import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/app_paths.dart';

/// Silences the warning for the library it is stored in.
///
/// Deliberately an unscoped key: the settings box lives *inside* the library
/// being warned about, so the preference is already per-library. Silencing
/// the warning for one pull request's build says nothing about the next one,
/// which opens its own library and so its own settings box.
const _kHidePinnedLibraryWarningKey = 'hidePinnedLibraryWarning';

/// The library a pinned build opened, as shown in the warning.
class PinnedLibraryWarning {
  /// Directory name, e.g. `daw_project_manager_pr141`.
  final String dirName;

  /// Absolute path to it, so the tester can find (or delete) the library.
  final String path;

  const PinnedLibraryWarning({required this.dirName, required this.path});
}

/// Whether a build should warn about the library it opened.
///
/// Pure — exposed for testing.
@visibleForTesting
bool shouldWarnAboutPinnedLibrary({
  required bool isPinned,
  required bool silenced,
}) =>
    isPinned && !silenced;

/// The warning to show at startup, or null when there is nothing to warn
/// about — this build is not pinned, or the warning was silenced for this
/// library.
///
/// Only pinned builds warn. A build run from source is isolated too, but it
/// picks its library at launch and names it in Settings, so it already knows;
/// a pinned build sees neither (both are gated on [canPickAppDataDir]) and is
/// the one handed to someone who did not build it.
Future<PinnedLibraryWarning?> loadPinnedLibraryWarning() async {
  final box = await Hive.openBox<String>('settings');
  final silenced = box.get(_kHidePinnedLibraryWarningKey) == 'true';
  if (!shouldWarnAboutPinnedLibrary(
    isPinned: isAppDataDirPinned,
    silenced: silenced,
  )) {
    return null;
  }
  return PinnedLibraryWarning(
    dirName: appDataDirName,
    path: await getLocalAppDataPath(),
  );
}

/// Shows the warning and stores the opt-out if it was ticked. Completes once
/// the dialog is dismissed, so a caller can chain the next startup dialog
/// rather than stacking one on top of it.
Future<void> showPinnedLibraryWarningDialog(
  BuildContext context,
  PinnedLibraryWarning warning,
) async {
  final dontShowAgain = await showDialog<bool>(
    context: context,
    // Must be acknowledged: silently dismissing the one notice that says
    // "this is not your real library" defeats the point of showing it.
    barrierDismissible: false,
    builder: (ctx) => PinnedLibraryWarningView(
      warning: warning,
      onContinue: (dontShowAgain) => Navigator.of(ctx).pop(dontShowAgain),
    ),
  );

  if (dontShowAgain == true) {
    final box = await Hive.openBox<String>('settings');
    await box.put(_kHidePinnedLibraryWarningKey, 'true');
  }
}

/// The warning's contents, with no Hive or provider dependency of its own so
/// it can be widget-tested directly.
class PinnedLibraryWarningView extends StatefulWidget {
  final PinnedLibraryWarning warning;

  /// Called with whether the opt-out was ticked. Responsible for closing the
  /// dialog.
  final void Function(bool dontShowAgain) onContinue;

  const PinnedLibraryWarningView({
    super.key,
    required this.warning,
    required this.onContinue,
  });

  @override
  State<PinnedLibraryWarningView> createState() =>
      _PinnedLibraryWarningViewState();
}

class _PinnedLibraryWarningViewState extends State<PinnedLibraryWarningView> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      // The body wraps to a dozen lines on a phone, where a pinned debug APK
      // shows this too — without this it overflows instead of scrolling.
      scrollable: true,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      icon: const Icon(Icons.warning_amber_rounded, size: 32),
      iconColor: Colors.amber,
      title: Text(l10n.pinnedLibraryWarningTitle),
      content: SizedBox(
        // Capped rather than fixed: a pinned debug APK shows this on a phone
        // too, where a hard 440 would overflow the dialog.
        width: math.min(440, MediaQuery.of(context).size.width - 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pinnedLibraryWarningBody,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            _Field(
              label: l10n.pinnedLibraryWarningLibraryLabel,
              value: widget.warning.dirName,
            ),
            const SizedBox(height: 10),
            _Field(
              label: l10n.pinnedLibraryWarningLocationLabel,
              value: widget.warning.path,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
              title: Text(l10n.pinnedLibraryWarningDontShowAgain,
                  style: theme.textTheme.bodySmall),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => widget.onContinue(_dontShowAgain),
          child: Text(l10n.continueButton),
        ),
      ],
    );
  }
}

/// A labelled, selectable value — the path is worth being able to copy out of
/// the dialog rather than retype.
class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
