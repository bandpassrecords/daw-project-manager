import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_attachment.dart';
import 'package:daw_project_manager/utils/attachment_launcher.dart';

/// #112 — URL-vs-path dispatch. Getting this wrong either hands a file path to
/// the browser or hands a URL to the file manager, and a moved file has to be
/// *reported* missing rather than failing silently on click.
void main() {
  AttachmentOpenAction resolve(
    ProjectAttachmentKind kind,
    String target, {
    bool exists = true,
  }) =>
      resolveAttachmentAction(
        kind: kind,
        target: target,
        targetExists: exists,
      );

  group('resolveAttachmentAction', () {
    test('a link opens in the browser', () {
      expect(
        resolve(ProjectAttachmentKind.link, 'https://example.com/song'),
        AttachmentOpenAction.openUrl,
      );
    });

    test('a link is never stat-ed — nothing on disk is expected to match', () {
      expect(
        resolve(
          ProjectAttachmentKind.link,
          'https://drive.google.com/x',
          exists: false,
        ),
        AttachmentOpenAction.openUrl,
      );
    });

    test('a scheme-less link is normalized rather than rejected', () {
      expect(
        resolve(ProjectAttachmentKind.link, 'www.example.com'),
        AttachmentOpenAction.openUrl,
      );
    });

    test('a link with no usable scheme is invalid, not a file', () {
      expect(
        resolve(ProjectAttachmentKind.link, 'not a url at all'),
        AttachmentOpenAction.invalid,
      );
    });

    test('a file that exists opens with the default application', () {
      expect(
        resolve(ProjectAttachmentKind.file, '/Users/artist/Refs/ref.wav'),
        AttachmentOpenAction.openFile,
      );
    });

    test('a file that moved is reported missing, not opened', () {
      expect(
        resolve(
          ProjectAttachmentKind.file,
          '/Users/artist/Refs/gone.wav',
          exists: false,
        ),
        AttachmentOpenAction.missingFile,
      );
    });

    test('a Windows path is dispatched as a file, colon and all', () {
      expect(
        resolve(ProjectAttachmentKind.file, r'C:\Stems\ref.wav'),
        AttachmentOpenAction.openFile,
      );
    });

    test('an empty or blank target is invalid for either kind', () {
      expect(
        resolve(ProjectAttachmentKind.file, '   '),
        AttachmentOpenAction.invalid,
      );
      expect(
        resolve(ProjectAttachmentKind.link, ''),
        AttachmentOpenAction.invalid,
      );
    });
  });
}
