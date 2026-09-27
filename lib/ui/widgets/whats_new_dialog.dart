import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/changelog_service.dart';

/// Shows the "What's New" dialog for [releases]. No-op when there is nothing
/// to show, so callers don't have to check first.
Future<void> showWhatsNewDialog(
  BuildContext context,
  List<ChangelogRelease> releases, {
  VoidCallback? onViewFullChangelog,
}) async {
  if (releases.isEmpty) return;
  final localeCode = Localizations.localeOf(context).toLanguageTag();
  await showDialog<void>(
    context: context,
    // Dismissible: this is good news, not a warning that has to be
    // acknowledged, and it has already been marked seen by the time it opens.
    barrierDismissible: true,
    builder: (ctx) => WhatsNewView(
      releases: releases,
      localeCode: localeCode,
      onClose: () => Navigator.of(ctx).pop(),
      onViewFullChangelog: onViewFullChangelog == null
          ? null
          : () {
              Navigator.of(ctx).pop();
              onViewFullChangelog();
            },
    ),
  );
}

/// The dialog's contents, with no Hive, asset or provider dependency of its
/// own so it can be widget-tested directly.
class WhatsNewView extends StatelessWidget {
  const WhatsNewView({
    super.key,
    required this.releases,
    required this.localeCode,
    required this.onClose,
    this.onViewFullChangelog,
  });

  /// Newest first. More than one entry when the user skipped a version or
  /// two — each keeps its own heading so it stays clear what arrived when.
  final List<ChangelogRelease> releases;

  /// Which locale's highlight text to pull out of each entry. Passed in
  /// rather than read from [Localizations] so the view stays a pure function
  /// of its inputs.
  final String localeCode;

  /// Responsible for closing the dialog.
  final VoidCallback onClose;

  /// Opens the full history. Omitted where there is nowhere to send the user.
  final VoidCallback? onViewFullChangelog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final showVersionHeadings = releases.length > 1;

    return AlertDialog(
      // The list grows with each version the user skipped, and this shows on
      // phones too — without this it overflows instead of scrolling.
      scrollable: true,
      backgroundColor: theme.cardColor,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      icon: const Icon(Icons.auto_awesome, size: 32),
      iconColor: theme.colorScheme.primary,
      title: Text(
        showVersionHeadings
            ? l10n.whatsNewTitle
            : l10n.whatsNewTitleWithVersion(releases.first.version),
      ),
      content: SizedBox(
        width: math.min(460, MediaQuery.of(context).size.width - 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.whatsNewIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            for (final release in releases) ...[
              if (showVersionHeadings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    l10n.versionLabel(release.version),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              for (final text in release.highlightsFor(localeCode))
                ChangelogHighlightRow(text: text),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      actions: [
        if (onViewFullChangelog != null)
          TextButton(
            onPressed: onViewFullChangelog,
            child: Text(l10n.changelogFullButton),
          ),
        FilledButton(
          onPressed: onClose,
          child: Text(l10n.whatsNewGotIt),
        ),
      ],
    );
  }
}

/// One bulleted highlight line. Shared with the full-changelog page so both
/// lists read identically.
class ChangelogHighlightRow extends StatelessWidget {
  const ChangelogHighlightRow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 10),
            child: Icon(
              Icons.check_circle_outline,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
