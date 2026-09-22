import 'package:flutter/material.dart';

import '../../models/music_project.dart';
import '../../utils/project_summary_text.dart';
import '../../utils/track_duration.dart';
import 'release_track_parts_chip.dart';

/// What a release's tracklist shows under each track name: its length, its
/// parts progress, and its note — nothing else.
///
/// Deliberately narrower than a project row on the dashboard. DAW, BPM, key
/// and phase are properties of the *project*; on a release the questions are
/// "how long is it", "is it finished" and "what's left to say about it". The
/// release's table view still carries every column for anyone who wants them.
///
/// One widget for both layouts: the desktop and mobile tracklists are built
/// separately, and extending only one of them is how they drifted apart
/// before.
class ReleaseTrackDetails extends StatelessWidget {
  const ReleaseTrackDetails({super.key, required this.project});

  final MusicProject project;

  /// Whether there is anything to show at all. A track with no length, no
  /// parts and no note gets no subtitle rather than an empty one.
  static bool hasContent(MusicProject project) =>
      _hasFirstLine(project) || projectNoteExcerpt(project) != null;

  /// Whether the details take two lines — the length/parts line *and* the
  /// note — which a ListTile needs to know to size itself (`isThreeLine`).
  static bool isTwoLines(MusicProject project) =>
      _hasFirstLine(project) && projectNoteExcerpt(project) != null;

  static bool _hasFirstLine(MusicProject project) =>
      effectiveTrackDuration(project) != null || project.parts.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;
    final length = effectiveTrackDuration(project);
    final note = projectNoteExcerpt(project);
    final firstLine = _hasFirstLine(project);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (firstLine)
          Wrap(
            spacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (length != null)
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
              // Draws nothing for a song with no parts listed.
              ReleaseTrackPartsChip(project: project, compact: true),
            ],
          ),
        if (note != null)
          Padding(
            padding: EdgeInsets.only(top: firstLine ? 2 : 0),
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
