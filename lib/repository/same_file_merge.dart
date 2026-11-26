import 'package:hive_ce/hive.dart';

import '../models/music_project.dart';
import '../models/playlist.dart';
import '../models/release.dart';

/// After a merge folded arriving rows into rows already here
/// (`planIncomingRow`), points whatever named an arriving id at the row kept
/// for it: [aliases] maps each arriving id to the kept one.
///
/// * A release's tracks and a playlist's songs follow (a release never lists
///   one song twice).
/// * A stack holding an arriving id takes the kept row in its place when
///   that row is in no stack or already in this one; when the kept row
///   belongs to another stack, the arriving id is only dropped — one row is
///   never in two stacks.
Future<void> repointProjectIds({
  required Box<MusicProject> projects,
  required Box<Release> releases,
  required Box<Playlist> playlists,
  required Map<String, String> aliases,
}) async {
  if (aliases.isEmpty) return;
  final now = DateTime.now();

  for (final release in releases.values.toList(growable: false)) {
    if (!release.trackIds.any(aliases.containsKey)) continue;
    final ids = <String>[];
    for (final id in release.trackIds) {
      final next = aliases[id] ?? id;
      if (!ids.contains(next)) ids.add(next);
    }
    await releases.put(release.id, release.copyWith(trackIds: ids));
  }

  for (final playlist in playlists.values.toList(growable: false)) {
    if (!playlist.projectIds.any(aliases.containsKey)) continue;
    await playlists.put(
      playlist.id,
      playlist.copyWith(
        projectIds: [for (final id in playlist.projectIds) aliases[id] ?? id],
        updatedAt: now,
      ),
    );
  }

  for (final stack in projects.values.toList(growable: false)) {
    if (!stack.isVirtual || !stack.memberProjectIds.any(aliases.containsKey)) {
      continue;
    }
    final members = <String>[];
    for (final id in stack.memberProjectIds) {
      final keptId = aliases[id];
      if (keptId == null) {
        if (!members.contains(id)) members.add(id);
        continue;
      }
      final kept = projects.get(keptId);
      if (kept == null) continue;
      if (kept.stackId != null && kept.stackId != stack.id) continue;
      if (kept.stackId == null) {
        await projects.put(
          kept.id,
          kept.copyWith(stackId: stack.id, updatedAt: now),
        );
      }
      if (!members.contains(keptId)) members.add(keptId);
    }
    final launch = stack.defaultLaunchMemberId;
    final nextLaunch = launch == null ? null : (aliases[launch] ?? launch);
    await projects.put(
      stack.id,
      stack.copyWith(
        memberProjectIds: members,
        defaultLaunchMemberId: members.contains(nextLaunch) ? nextLaunch : null,
        clearDefaultLaunchMemberId: !members.contains(nextLaunch),
        updatedAt: now,
      ),
    );
  }
}
