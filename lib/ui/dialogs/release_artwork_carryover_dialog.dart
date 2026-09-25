import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/release_artwork_service.dart';

/// Result of asking whether to carry a track's thumbnail over as the new
/// release's artwork.
///
/// A distinct type rather than a nullable String because "skip" and "the
/// dialog was dismissed" both mean *no artwork*, while `null` from
/// [showReleaseArtworkCarryOverDialog] would be ambiguous against a caller
/// that wanted to tell them apart. Here they are deliberately the same thing:
/// the release is created either way, just without a cover.
class ReleaseArtworkChoice {
  const ReleaseArtworkChoice(this.imagePath);

  /// The chosen thumbnail, or null when the user skipped.
  final String? imagePath;

  static const ReleaseArtworkChoice skipped = ReleaseArtworkChoice(null);
}

/// Asks whether one of the selected tracks' thumbnails should become the new
/// release's artwork. Returns [ReleaseArtworkChoice.skipped] when there is
/// nothing to offer, so callers can call it unconditionally.
Future<ReleaseArtworkChoice> showReleaseArtworkCarryOverDialog(
  BuildContext context,
  List<ReleaseArtworkCandidate> candidates,
) async {
  if (!shouldOfferArtworkCarryOver(candidates)) {
    return ReleaseArtworkChoice.skipped;
  }
  final chosen = await showDialog<ReleaseArtworkChoice>(
    context: context,
    builder: (ctx) => ReleaseArtworkCarryOverView(
      candidates: candidates,
      onChoice: (choice) => Navigator.of(ctx).pop(choice),
    ),
  );
  return chosen ?? ReleaseArtworkChoice.skipped;
}

/// The dialog's contents, with no repository or provider dependency of its
/// own so it can be widget-tested directly.
class ReleaseArtworkCarryOverView extends StatefulWidget {
  const ReleaseArtworkCarryOverView({
    super.key,
    required this.candidates,
    required this.onChoice,
  });

  final List<ReleaseArtworkCandidate> candidates;

  /// Responsible for closing the dialog.
  final void Function(ReleaseArtworkChoice choice) onChoice;

  @override
  State<ReleaseArtworkCarryOverView> createState() =>
      _ReleaseArtworkCarryOverViewState();
}

class _ReleaseArtworkCarryOverViewState
    extends State<ReleaseArtworkCarryOverView> {
  /// Pre-selects the first candidate: with one thumbnail to offer this makes
  /// the dialog a single confirming click, and with several it still has to be
  /// changed deliberately before Use is pressed.
  late String _selectedPath = widget.candidates.first.imagePath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      scrollable: true,
      icon: const Icon(Icons.image_outlined, size: 32),
      title: Text(l10n.releaseArtworkCarryOverTitle),
      content: SizedBox(
        width: math.min(460, MediaQuery.of(context).size.width - 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.releaseArtworkCarryOverBody(widget.candidates.length),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final candidate in widget.candidates)
                  _ArtworkOption(
                    candidate: candidate,
                    selected: candidate.imagePath == _selectedPath,
                    onTap: () =>
                        setState(() => _selectedPath = candidate.imagePath),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onChoice(ReleaseArtworkChoice.skipped),
          child: Text(l10n.releaseArtworkCarryOverSkip),
        ),
        FilledButton(
          onPressed: () => widget.onChoice(ReleaseArtworkChoice(_selectedPath)),
          child: Text(l10n.releaseArtworkCarryOverUse),
        ),
      ],
    );
  }
}

class _ArtworkOption extends StatelessWidget {
  const _ArtworkOption({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final ReleaseArtworkCandidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 108,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  width: selected ? 3 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                File(candidate.imagePath),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                // The candidate list already skipped missing files, but a
                // file can still turn out not to be a decodable image.
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  width: 100,
                  height: 100,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              candidate.projectName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
