/// The position to seek to when jumping [deltaSeconds] (positive or negative)
/// from [position], clamped into `[0, total]`.
///
/// A [total] of zero (or negative) means the track length isn't known yet —
/// only the lower bound is enforced then, so an early "+5s" tap never lands
/// at a bogus clamp. Shared by every ±Ns transport button (project-detail
/// player, mobile player).
Duration seekTarget(Duration position, int deltaSeconds, Duration total) {
  var target = position + Duration(seconds: deltaSeconds);
  if (target < Duration.zero) target = Duration.zero;
  if (total > Duration.zero && target > total) target = total;
  return target;
}

/// Which player a project-detail transport action (seek, volume, mono swap)
/// has to be sent to.
///
/// The detail page owns a local `AudioPlayer`, but it does *not* always own
/// playback: on mobile it delegates play/pause to the global mobile player so
/// the mini player and the Android notification stay in sync, and on desktop
/// the bottom player bar may already be playing this same track. Sending a
/// seek to the local player in either of those cases is a no-op against an
/// idle player — the reason seeking looked dead while audio kept playing.
enum PlaybackTarget {
  /// The page's own `AudioPlayer`.
  local,

  /// The global mobile player (`mobilePlayerProvider`).
  mobilePlayer,

  /// The desktop bottom player bar, addressed through its request providers.
  desktopPlayerBar,
}

/// Resolves the target for the project with id [projectId].
///
/// [mobilePlayerProjectId] / [desktopPlayerProjectId] are the ids of the track
/// each of those players currently holds (null when it holds none). A player
/// only claims the action when it holds *this* project; otherwise the page's
/// own player is the one making sound.
PlaybackTarget playbackTargetFor({
  required bool isMobile,
  required String projectId,
  String? mobilePlayerProjectId,
  String? desktopPlayerProjectId,
}) {
  if (isMobile) {
    return mobilePlayerProjectId == projectId
        ? PlaybackTarget.mobilePlayer
        : PlaybackTarget.local;
  }
  return desktopPlayerProjectId == projectId
      ? PlaybackTarget.desktopPlayerBar
      : PlaybackTarget.local;
}
