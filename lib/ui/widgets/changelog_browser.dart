import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/changelog_service.dart';
import 'whats_new_dialog.dart' show ChangelogHighlightRow;

/// Every release as a card, newest first — without a scroll view of its own,
/// so it can sit inside a page that already scrolls (the Settings pane).
///
/// Each card collapses to its version and date. The newest
/// [expandedCount] start open: the history runs back to 1.0, and seventy-odd
/// open cards would bury the release anyone is actually looking for.
class ChangelogReleaseCards extends StatelessWidget {
  const ChangelogReleaseCards({
    super.key,
    required this.releases,
    required this.localeCode,
    this.currentVersion,
    this.expandedCount = 3,
    this.expandAll = false,
  });

  final List<ChangelogRelease> releases;
  final String localeCode;
  final String? currentVersion;
  final int expandedCount;

  /// Opens every card — for search results, where each card is there because
  /// something in it matched and a folded one would hide the match.
  final bool expandAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(localeCode);

    if (releases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l10n.changelogEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < releases.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              // Keyed by version so expanding one card never carries over
              // to another when the list is rebuilt.
              // A separate key in search mode, so results open expanded
              // rather than inheriting the folded state of the full list.
              key: expandAll
                  ? ValueKey('changelog-search-${releases[i].version}')
                  : PageStorageKey('changelog-${releases[i].version}'),
              initiallyExpanded: expandAll || i < expandedCount,
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: Row(
                children: [
                  Text(
                    l10n.versionLabel(releases[i].version),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentVersion != null &&
                      compareVersions(releases[i].version, currentVersion!) ==
                          0) ...[
                    const SizedBox(width: 8),
                    _CurrentVersionBadge(
                      label: l10n.changelogCurrentVersionBadge,
                    ),
                  ],
                  const Spacer(),
                  if (releases[i].date != null)
                    Text(
                      dateFormat.format(releases[i].date!),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              children: [
                for (final text in releases[i].highlightsFor(localeCode))
                  ChangelogHighlightRow(text: text),
              ],
            ),
          ),
      ],
    );
  }
}

class _CurrentVersionBadge extends StatelessWidget {
  const _CurrentVersionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The changelog with a search field above it: [ChangelogReleaseCards]
/// filtered to what matches as the user types.
///
/// Like the cards, it has no scroll view of its own, so it sits inside the
/// Settings pane, which already scrolls.
class ChangelogBrowser extends StatefulWidget {
  const ChangelogBrowser({
    super.key,
    required this.releases,
    required this.localeCode,
    this.currentVersion,
  });

  final List<ChangelogRelease> releases;
  final String localeCode;
  final String? currentVersion;

  @override
  State<ChangelogBrowser> createState() => _ChangelogBrowserState();
}

class _ChangelogBrowserState extends State<ChangelogBrowser> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searching = _query.trim().isNotEmpty;
    final shown = filterChangelog(
      widget.releases,
      _query,
      localeCode: widget.localeCode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.releases.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: l10n.changelogSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: searching
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: l10n.clear,
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        if (searching && shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.changelogNoMatches(_query.trim()),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          ChangelogReleaseCards(
            releases: shown,
            localeCode: widget.localeCode,
            currentVersion: widget.currentVersion,
            expandAll: searching,
          ),
      ],
    );
  }
}
