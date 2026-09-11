import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/project_attachment.dart';
import 'file_launcher.dart';

/// What opening a [ProjectAttachment] should actually do.
enum AttachmentOpenAction {
  /// Hand the URL to the default browser.
  openUrl,

  /// Hand the path to the OS default application / file manager.
  openFile,

  /// A file attachment whose path no longer resolves. The user is told, the
  /// same way a missing project file is flagged, rather than the click
  /// failing silently.
  missingFile,

  /// Nothing usable to open — an empty target, or a link that isn't a URL.
  invalid,
}

/// Decides how [attachment] opens, given whether its target exists on disk.
///
/// Pure so the dispatch can be unit-tested without a file system, a browser or
/// a widget tree — same shape as `resolveDawLaunchAction` in
/// `lib/ui/session_actions.dart`. [targetExists] is only consulted for file
/// attachments; a link is never stat-ed.
AttachmentOpenAction resolveAttachmentAction({
  required ProjectAttachmentKind kind,
  required String target,
  required bool targetExists,
}) {
  final value = target.trim();
  if (value.isEmpty) return AttachmentOpenAction.invalid;
  if (kind == ProjectAttachmentKind.link) {
    final uri = Uri.tryParse(ProjectAttachment.normalizeUrl(value));
    if (uri == null || !uri.hasScheme) return AttachmentOpenAction.invalid;
    return AttachmentOpenAction.openUrl;
  }
  return targetExists
      ? AttachmentOpenAction.openFile
      : AttachmentOpenAction.missingFile;
}

/// Opens [attachment], returning the action that was taken.
///
/// [missingFile] and [invalid] are returned without doing anything — the
/// caller decides how to tell the user, because the message belongs in the
/// widget layer where `AppLocalizations` lives. [openUrl]/[openFile] are
/// returned even when the launch itself failed; use [launched] to distinguish
/// them.
Future<AttachmentOpenResult> openProjectAttachment(
  ProjectAttachment attachment,
) async {
  final action = resolveAttachmentAction(
    kind: attachment.kind,
    target: attachment.target,
    targetExists: FileLauncher.targetExists(attachment.target.trim()),
  );

  switch (action) {
    case AttachmentOpenAction.openUrl:
      final uri = Uri.parse(
        ProjectAttachment.normalizeUrl(attachment.target),
      );
      try {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        return AttachmentOpenResult(action, launched);
      } catch (e) {
        if (kDebugMode) print('[Attachment] Failed to open URL $uri: $e');
        return AttachmentOpenResult(action, false);
      }
    case AttachmentOpenAction.openFile:
      final launched =
          await FileLauncher.openFile(attachment.target.trim());
      return AttachmentOpenResult(action, launched);
    case AttachmentOpenAction.missingFile:
    case AttachmentOpenAction.invalid:
      return AttachmentOpenResult(action, false);
  }
}

/// The outcome of [openProjectAttachment]: which branch it took, and whether
/// the launch reported success.
class AttachmentOpenResult {
  const AttachmentOpenResult(this.action, this.launched);

  final AttachmentOpenAction action;
  final bool launched;
}
