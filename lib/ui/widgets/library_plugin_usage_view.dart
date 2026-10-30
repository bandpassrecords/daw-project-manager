import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/project_inspector/library/plugin_usage.dart';

/// Which plug-ins the library really uses, and which only once (#225):
/// CPR Inspector's "Dust Collector" on the library the app already knows.
///
/// Plain values and callbacks: the page builds the [report] and acts on
/// "Show these projects", counting instances and exporting.
class LibraryPluginUsageView extends StatefulWidget {
  const LibraryPluginUsageView({
    super.key,
    required this.report,
    required this.search,
    required this.onClose,
    required this.onShowProjects,
    required this.onExportCsv,
    this.onCountInstances,
  });

  final PluginUsageReport report;

  /// What the dashboard's search box holds: filters plug-ins by name.
  final String search;
  final VoidCallback onClose;

  /// Shows the projects using a plug-in in the projects list.
  final void Function(PluginUsage plugin) onShowProjects;
  final VoidCallback onExportCsv;

  /// Reads the Cubase projects not read yet, to count instances; null when
  /// there are none to read.
  final VoidCallback? onCountInstances;

  @override
  State<LibraryPluginUsageView> createState() => _LibraryPluginUsageViewState();
}

class _LibraryPluginUsageViewState extends State<LibraryPluginUsageView> {
  bool _rareOnly = false;
  bool _hideStock = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final r = widget.report;
    final needle = widget.search.trim().toLowerCase();
    final shown = [
      for (final u in r.plugins)
        if ((!_rareOnly || u.rare) &&
            !(_hideStock && u.stock == true) &&
            (needle.isEmpty || u.name.toLowerCase().contains(needle)))
          u,
    ];
    final date = DateFormat.yMMMd(l10n.localeName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(l10n.usageOpen, style: theme.textTheme.titleLarge),
              ),
              IconButton(
                tooltip: l10n.compareExportCsv,
                icon: const Icon(Icons.table_view),
                onPressed: r.plugins.isEmpty ? null : widget.onExportCsv,
              ),
              IconButton(
                tooltip: l10n.inspectorClose,
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.usageIntro, style: theme.textTheme.bodySmall),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                l10n.usagePluginsInUse(r.plugins.length),
                style: theme.textTheme.titleSmall,
              ),
              Text(l10n.usageProjectsRead(r.projectsRead)),
              Text(l10n.usageRareCount(r.rare)),
            ],
          ),
        ),
        if (r.projectsUnread > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              l10n.usageProjectsUnread(r.projectsUnread),
              style: theme.textTheme.bodySmall,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: Text(l10n.usageFilterMostUsed),
                selected: !_rareOnly,
                onSelected: (_) => setState(() => _rareOnly = false),
              ),
              ChoiceChip(
                label: Text(l10n.usageFilterRare),
                selected: _rareOnly,
                onSelected: (_) => setState(() => _rareOnly = true),
              ),
              FilterChip(
                label: Text(l10n.usageHideStock),
                selected: _hideStock,
                onSelected: (v) => setState(() => _hideStock = v),
              ),
              if (widget.onCountInstances != null)
                TextButton.icon(
                  onPressed: widget.onCountInstances,
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(l10n.usageCountInstances),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: r.plugins.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.usageNothing, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (r.projectsWithInstances > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.usageInstancesFrom(r.projectsWithInstances),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    for (final u in shown)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          key: ValueKey(u.name),
                          title: Text(u.name),
                          subtitle: Text(
                            [
                              l10n.usageSongs(u.songs),
                              l10n.usageProjects(u.projects.length),
                              if (u.instances != null)
                                l10n.safeCopyInstances(u.instances!),
                              l10n.usageLastUsed(date.format(u.lastUsed)),
                              (u.daws.toList()..sort()).join(', '),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            12,
                          ),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final p in u.projects.take(20))
                              Text(
                                '${p.displayName} · ${date.format(p.lastModifiedAt)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            if (u.projects.length > 20)
                              Text('…', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => widget.onShowProjects(u),
                              icon: const Icon(Icons.filter_list),
                              label: Text(l10n.usageShowProjects),
                            ),
                          ],
                        ),
                      ),
                    if (r.chains.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.inspectorStatUsualChains,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      for (final (chain, n) in r.chains)
                        Text(
                          '${chain.join(' → ')}  ×$n',
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
