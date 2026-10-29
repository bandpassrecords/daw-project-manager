import 'package:material_ui/material_ui.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/missing_preview_songs.dart';

/// Settings > Mixdown folders > Missing preview songs: the current profile's
/// preview songs this computer can't find, sorted by why
/// ([MissingPreviewKind]), each one downloaded, found again, picked or
/// removed only when asked. Plain values and callbacks, so it can be tested
/// without Riverpod, Hive or Drive.
class MissingPreviewSongsCard extends StatelessWidget {
  const MissingPreviewSongsCard({
    super.key,
    required this.items,
    required this.checking,
    required this.onCheck,
    required this.onDownload,
    required this.onFind,
    required this.onChoose,
    required this.onRemove,
    this.showSignInHint = false,
    this.busy = false,
  });

  /// Null until the first check has run.
  final List<MissingPreviewSong>? items;
  final bool checking;

  /// Whether to say Drive could be searched too, once signed in.
  final bool showSignInHint;

  /// While an action runs, every button waits.
  final bool busy;

  final VoidCallback onCheck;
  final ValueChanged<List<MissingPreviewSong>> onDownload;
  final ValueChanged<List<MissingPreviewSong>> onFind;
  final ValueChanged<MissingPreviewSong> onChoose;

  /// One song, or a group's "Remove all" (which the caller confirms).
  final void Function(List<MissingPreviewSong> songs, {required bool all}) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = this.items;
    final idle = !busy && !checking;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.music_off_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.missingPreviewSongsTitle, style: theme.textTheme.titleMedium),
                ),
                OutlinedButton(
                  onPressed: idle ? onCheck : null,
                  child: Text(l10n.missingPreviewSongsCheck),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.missingPreviewSongsSubtitle, style: theme.textTheme.bodySmall),
            if (checking) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              Text(l10n.missingPreviewSongsChecking, style: theme.textTheme.bodySmall),
            ] else if (items != null) ...[
              if (showSignInHint) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.missingPreviewSongsSignInHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
              const SizedBox(height: 8),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.missingPreviewSongsNone,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                )
              else ...[
                for (final kind in MissingPreviewKind.values)
                  if (items.any((i) => i.kind == kind))
                    _group(context, l10n, kind, [for (final i in items) if (i.kind == kind) i]),
                const SizedBox(height: 12),
                // Every group at once; the caller's confirmation says how
                // many of them Drive or another computer still has.
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    key: const ValueKey('missing-preview-remove-everything'),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    onPressed: busy ? null : () => onRemove(items, all: true),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: Text(l10n.missingPreviewRemoveEverything(items.length)),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _group(
    BuildContext context,
    AppLocalizations l10n,
    MissingPreviewKind kind,
    List<MissingPreviewSong> songs,
  ) {
    final theme = Theme.of(context);
    final (title, description) = switch (kind) {
      MissingPreviewKind.onDrive => (
          l10n.missingPreviewOnDriveTitle(songs.length),
          l10n.missingPreviewOnDriveDescription,
        ),
      MissingPreviewKind.otherComputer => (
          l10n.missingPreviewOtherComputerTitle(songs.length),
          l10n.missingPreviewOtherComputerDescription,
        ),
      MissingPreviewKind.folderMissing => (
          l10n.missingPreviewFolderMissingTitle(songs.length),
          l10n.missingPreviewFolderMissingDescription,
        ),
      MissingPreviewKind.fileMissing => (
          l10n.missingPreviewFileMissingTitle(songs.length),
          l10n.missingPreviewFileMissingDescription,
        ),
    };
    // Another computer's songs may play fine there: one at a time only.
    final canRemoveAll =
        kind == MissingPreviewKind.folderMissing || kind == MissingPreviewKind.fileMissing;
    // Finding looks in the project's own folders, which another computer's
    // paths don't name here.
    final canFindAll = canRemoveAll;
    return Padding(
      key: ValueKey('missing-preview-${kind.name}'),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              if (kind == MissingPreviewKind.onDrive)
                TextButton(
                  onPressed: busy ? null : () => onDownload(songs),
                  child: Text(l10n.missingPreviewDownloadAll),
                ),
              if (canFindAll)
                TextButton(
                  onPressed: busy ? null : () => onFind(songs),
                  child: Text(l10n.missingPreviewFindAll),
                ),
              if (canRemoveAll)
                TextButton(
                  onPressed: busy ? null : () => onRemove(songs, all: true),
                  child: Text(l10n.missingPreviewRemoveAll),
                ),
            ],
          ),
          Text(description, style: theme.textTheme.bodySmall),
          for (final song in songs) _row(context, l10n, song),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppLocalizations l10n, MissingPreviewSong song) {
    final theme = Theme.of(context);
    final where = song.manual ? song.path : '${l10n.missingPreviewAutoDetected} · ${song.path}';
    return ListTile(
      key: ValueKey('missing-preview-song-${song.project.id}'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(song.project.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(where, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Wrap(
        spacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (song.kind == MissingPreviewKind.onDrive)
            TextButton(
              onPressed: busy ? null : () => onDownload([song]),
              child: Text(l10n.missingPreviewDownload),
            )
          else if (song.kind != MissingPreviewKind.otherComputer)
            IconButton(
              tooltip: l10n.findPreviewAutomatically,
              icon: const Icon(Icons.manage_search),
              onPressed: busy ? null : () => onFind([song]),
            ),
          IconButton(
            tooltip: l10n.selectNewFile,
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: busy ? null : () => onChoose(song),
          ),
          IconButton(
            tooltip: l10n.removePreviewSong,
            icon: Icon(Icons.link_off, color: theme.colorScheme.error),
            onPressed: busy ? null : () => onRemove([song], all: false),
          ),
        ],
      ),
    );
  }
}
