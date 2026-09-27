import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../utils/project_summary_text.dart';
import '../../utils/track_duration.dart';
import 'release_track_parts_chip.dart';

/// What a release's tracklist shows under each track name: DAW, BPM, key,
/// length, phase and the parts chip on one line, and the user's own note on
/// the next.
///
/// The note is the user's [MusicProject.notes] only — never the DAW-extracted
/// text (see `projectNoteExcerpt`).
///
/// One widget for both layouts: the desktop and mobile tracklists are built
/// separately, and extending only one of them is how they drifted apart
/// before. Takes the phase's label and colour rather than resolving them, so
/// the rows and the release's table view name and colour a phase identically.
class ReleaseTrackDetails extends StatelessWidget {
  const ReleaseTrackDetails({
    super.key,
    required this.project,
    required this.phaseLabel,
    required this.phaseColor,
  });

  final MusicProject project;
  final String phaseLabel;
  final Color phaseColor;

  /// Whether the details take two lines — the facts line *and* the note —
  /// which a ListTile needs to know to size itself (`isThreeLine`).
  static bool isTwoLines(MusicProject project) =>
      projectNoteExcerpt(project) != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;
    final bullet = Text('•', style: TextStyle(color: muted));
    final length = effectiveTrackDuration(project);
    final note = projectNoteExcerpt(project);
    final daw = project.dawType;
    final version = project.dawVersion;
    final key = project.musicalKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (daw != null && daw.isNotEmpty) ...[
              Text(
                version != null && version.isNotEmpty ? '$daw $version' : daw,
              ),
              bullet,
            ],
            if (project.bpm != null) ...[
              Text('${project.bpm!.toStringAsFixed(0)} ${l10n.bpm}'),
              bullet,
            ],
            if (key != null && key.isNotEmpty) ...[
              Text(key),
              bullet,
            ],
            if (length != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    formatTrackDuration(length),
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              bullet,
            ],
            Text(
              phaseLabel,
              style: TextStyle(color: phaseColor, fontWeight: FontWeight.w500),
            ),
            // Draws nothing for a song with no parts listed.
            ReleaseTrackPartsChip(project: project, compact: true),
          ],
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
