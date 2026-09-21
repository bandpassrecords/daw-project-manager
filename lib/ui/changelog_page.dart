import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../generated/l10n/app_localizations.dart';
import '../services/changelog_service.dart';
import '../utils/mobile_utils.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/whats_new_dialog.dart' show ChangelogHighlightRow;

/// The whole accumulated changelog — every shipped version's highlights,
/// newest first.
///
/// The counterpart to the one-shot "What's New" dialog: that interrupts once
/// after an update, this is where someone goes to read what they dismissed,
/// or to catch up after skipping several versions. Reached from
/// Settings > About.
class ChangelogPage extends StatelessWidget {
  const ChangelogPage({super.key, this.currentVersion});

  /// The running build's version, marked in the list so it is obvious which
  /// entries are already installed. Null hides the marker entirely.
  final String? currentVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = !kIsWeb && MobileUtils.isDesktop();

    return Scaffold(
      body: Column(
        children: [
          DesktopTitleBar(title: l10n.changelogPageTitle, showBack: true),
          if (!isDesktop)
            AppBar(
              title: Text(l10n.changelogPageTitle),
              leading: const BackButton(),
            ),
          Expanded(
            child: FutureBuilder<List<ChangelogRelease>>(
              future: ChangelogService.loadChangelog(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ChangelogListView(
                  releases: snapshot.data ?? const [],
                  currentVersion: currentVersion,
                  localeCode: Localizations.localeOf(context).toLanguageTag(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The list itself, with no asset loading of its own so it can be
/// widget-tested against a handful of hand-built entries.
class ChangelogListView extends StatelessWidget {
  const ChangelogListView({
    super.key,
    required this.releases,
    required this.localeCode,
    this.currentVersion,
  });

  final List<ChangelogRelease> releases;
  final String localeCode;
  final String? currentVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDesktop = !kIsWeb && MobileUtils.isDesktop();
    final dateFormat = DateFormat.yMMMd(localeCode);

    if (releases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.changelogEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final release in releases)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.versionLabel(release.version),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (currentVersion != null &&
                                  compareVersions(
                                        release.version,
                                        currentVersion!,
                                      ) ==
                                      0) ...[
                                const SizedBox(width: 8),
                                _CurrentVersionBadge(
                                  label: l10n.changelogCurrentVersionBadge,
                                ),
                              ],
                              const Spacer(),
                              if (release.date != null)
                                Text(
                                  dateFormat.format(release.date!),
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                          const Divider(height: 20),
                          for (final text
                              in release.highlightsFor(localeCode))
                            ChangelogHighlightRow(text: text),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
