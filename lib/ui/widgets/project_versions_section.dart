import 'package:flutter/material.dart';

import '../../models/music_project.dart';

/// The version files a stacked song is made of (#94).
///
/// A stack is a virtual project owning the shared metadata for several real
/// files. This is where that membership is visible and editable: every version
/// is listed with the one that opens by default marked, and versions can be
/// added, removed or nominated as the default from here.
///
/// A plain view widget on purpose, exactly like [ProjectMarkersSection]: it
/// takes a list of projects and callbacks rather than a `Ref` or a repository,
/// so every state here can be widget-tested without opening Hive.
class ProjectVersionsSection extends StatelessWidget {
  const ProjectVersionsSection({
    super.key,
    required this.members,
    required this.defaultLaunchMemberId,
    required this.title,
    required this.countLabel,
    required this.addLabel,
    required this.unstackLabel,
    required this.defaultBadgeLabel,
    required this.setDefaultTooltip,
    required this.removeTooltip,
    required this.subtitleBuilder,
    this.emptyTitle,
    this.emptyDescription,
    this.onAdd,
    this.onRemove,
    this.onSetDefault,
    this.onOpen,
    this.onUnstack,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  /// The stack's versions, in the order the stack lists them.
  final List<MusicProject> members;

  /// Which member the "Launch in DAW" button opens without asking. Null means
  /// the launcher asks every time.
  final String? defaultLaunchMemberId;

  final String title;

  /// e.g. "3 versions" — built by the caller so it can go through the ARB
  /// plural rules rather than being assembled from parts here.
  final String countLabel;

  final String addLabel;
  final String unstackLabel;
  final String defaultBadgeLabel;
  final String setDefaultTooltip;
  final String removeTooltip;

  /// Shown instead of the version list when [members] is empty — the state an
  /// ordinary, unstacked project is in. The section is still offered there so
  /// a stack can be started from the project you are already looking at,
  /// rather than only from a multi-selection in the dashboard.
  final String? emptyTitle;
  final String? emptyDescription;

  /// Secondary line under each version — modified date, size, work time. Built
  /// by the caller because formatting those needs the locale and the app's
  /// duration helpers, neither of which belong in a view widget.
  final String Function(MusicProject member) subtitleBuilder;

  final VoidCallback? onAdd;
  final void Function(MusicProject member)? onRemove;
  final void Function(MusicProject member)? onSetDefault;
  final void Function(MusicProject member)? onOpen;
  final VoidCallback? onUnstack;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colors.primary,
                ),
              ),
              if (members.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    countLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (onAdd != null)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(addLabel),
                  onPressed: onAdd,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (members.isEmpty)
            // Full width, matching the populated list. Left to itself the
            // card would shrink-wrap its two lines of text and sit as a stub
            // against the left edge, while the version list it replaces fills
            // the section — ListTile takes the width it is offered.
            SizedBox(
              width: double.infinity,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (emptyTitle != null)
                        Text(
                          emptyTitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (emptyDescription != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          emptyDescription!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < members.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _VersionRow(
                      member: members[i],
                      isDefault: members[i].id == defaultLaunchMemberId,
                      subtitle: subtitleBuilder(members[i]),
                      defaultBadgeLabel: defaultBadgeLabel,
                      setDefaultTooltip: setDefaultTooltip,
                      removeTooltip: removeTooltip,
                      onRemove: onRemove,
                      onSetDefault: onSetDefault,
                      onOpen: onOpen,
                    ),
                  ],
                ],
              ),
            ),
          if (onUnstack != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.layers_clear, size: 18),
                label: Text(unstackLabel),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                ),
                onPressed: onUnstack,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.member,
    required this.isDefault,
    required this.subtitle,
    required this.defaultBadgeLabel,
    required this.setDefaultTooltip,
    required this.removeTooltip,
    required this.onRemove,
    required this.onSetDefault,
    required this.onOpen,
  });

  final MusicProject member;
  final bool isDefault;
  final String subtitle;
  final String defaultBadgeLabel;
  final String setDefaultTooltip;
  final String removeTooltip;
  final void Function(MusicProject member)? onRemove;
  final void Function(MusicProject member)? onSetDefault;
  final void Function(MusicProject member)? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      dense: true,
      leading: Icon(
        Icons.music_note,
        size: 20,
        color: isDefault ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.displayName,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isDefault ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                defaultBadgeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      onTap: onOpen == null ? null : () => onOpen!(member),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nominating the current default again is a no-op, so the star is
          // shown filled and inert rather than removed — a row that loses a
          // control when you pick it reads as the control breaking.
          if (onSetDefault != null)
            IconButton(
              icon: Icon(
                isDefault ? Icons.star : Icons.star_border,
                size: 18,
                color: isDefault ? colors.primary : null,
              ),
              tooltip: isDefault ? null : setDefaultTooltip,
              onPressed: isDefault ? null : () => onSetDefault!(member),
            ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: removeTooltip,
              onPressed: () => onRemove!(member),
            ),
        ],
      ),
    );
  }
}
