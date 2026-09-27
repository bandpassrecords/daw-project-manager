import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/release_artwork_service.dart';
import 'package:daw_project_manager/utils/project_visuals.dart';

import '../helpers/test_factories.dart';

void main() {
  /// Every path "exists" unless listed in [missing] — lets these tests state
  /// which thumbnails are on disk without creating any files.
  ImageExistsCheck existsExcept(Set<String> missing) =>
      (path) => !missing.contains(path);

  group('existingCoverArtPath', () {
    test('returns the cover art path when the file is there', () {
      final project = TestFactories.makeProject(thumbnailPath: '/art/a.png');
      expect(
        existingCoverArtPath(project, imageExists: existsExcept(const {})),
        '/art/a.png',
      );
    });

    test('returns null when the project has no cover art', () {
      final project = TestFactories.makeProject(thumbnailPath: null);
      expect(
        existingCoverArtPath(project, imageExists: existsExcept(const {})),
        isNull,
      );
    });

    test('returns null for a whitespace-only cover art path', () {
      // Deliberately checked against the real filesystem rather than the fake:
      // projectHasCoverArt (main's rule, which this defers to) treats a blank
      // string as "has cover", so it is the existence check that has to reject
      // it — and it does, because no such file is there.
      final project = TestFactories.makeProject(thumbnailPath: '   ');
      expect(existingCoverArtPath(project), isNull);
    });

    test('returns null when the stored file has since been deleted', () {
      final project = TestFactories.makeProject(thumbnailPath: '/art/gone.png');
      expect(
        existingCoverArtPath(
          project,
          imageExists: existsExcept({'/art/gone.png'}),
        ),
        isNull,
      );
    });
  });

  group('releaseArtworkCandidates', () {
    test('offers one candidate per project with a thumbnail', () {
      final candidates = releaseArtworkCandidates(
        [
          TestFactories.makeProject(
            id: 'p1',
            customDisplayName: 'First',
            thumbnailPath: '/art/a.png',
          ),
          TestFactories.makeProject(
            id: 'p2',
            customDisplayName: 'Second',
            thumbnailPath: '/art/b.png',
          ),
        ],
        imageExists: existsExcept(const {}),
      );

      expect(candidates, hasLength(2));
      expect(candidates.first.projectId, 'p1');
      expect(candidates.first.projectName, 'First');
      expect(candidates.first.imagePath, '/art/a.png');
    });

    test('keeps the order the projects were given', () {
      final candidates = releaseArtworkCandidates(
        [
          TestFactories.makeProject(id: 'p1', thumbnailPath: '/art/a.png'),
          TestFactories.makeProject(id: 'p2', thumbnailPath: '/art/b.png'),
          TestFactories.makeProject(id: 'p3', thumbnailPath: '/art/c.png'),
        ],
        imageExists: existsExcept(const {}),
      );

      expect(
        candidates.map((c) => c.imagePath).toList(),
        ['/art/a.png', '/art/b.png', '/art/c.png'],
      );
    });

    test('skips projects with no thumbnail', () {
      final candidates = releaseArtworkCandidates(
        [
          TestFactories.makeProject(id: 'p1', thumbnailPath: null),
          TestFactories.makeProject(id: 'p2', thumbnailPath: '/art/b.png'),
        ],
        imageExists: existsExcept(const {}),
      );

      expect(candidates.map((c) => c.projectId).toList(), ['p2']);
    });

    test('skips a thumbnail whose file is gone', () {
      // A broken-image tile is worse than one fewer choice.
      final candidates = releaseArtworkCandidates(
        [
          TestFactories.makeProject(id: 'p1', thumbnailPath: '/art/gone.png'),
          TestFactories.makeProject(id: 'p2', thumbnailPath: '/art/b.png'),
        ],
        imageExists: existsExcept({'/art/gone.png'}),
      );

      expect(candidates.map((c) => c.projectId).toList(), ['p2']);
    });

    test('collapses duplicate paths to a single entry', () {
      // Several versions of one song commonly share a cover — offering the
      // same picture three times is just noise.
      final candidates = releaseArtworkCandidates(
        [
          TestFactories.makeProject(id: 'p1', thumbnailPath: '/art/same.png'),
          TestFactories.makeProject(id: 'p2', thumbnailPath: '/art/same.png'),
          TestFactories.makeProject(id: 'p3', thumbnailPath: '/art/other.png'),
        ],
        imageExists: existsExcept(const {}),
      );

      expect(
        candidates.map((c) => c.imagePath).toList(),
        ['/art/same.png', '/art/other.png'],
      );
    });

    test('returns empty for an empty selection', () {
      expect(
        releaseArtworkCandidates(const [],
            imageExists: existsExcept(const {})),
        isEmpty,
      );
    });
  });

  group('shouldOfferArtworkCarryOver', () {
    test('does not interrupt when there is nothing to carry over', () {
      expect(shouldOfferArtworkCarryOver(const []), isFalse);
    });

    test('asks even for a single candidate', () {
      // A track's thumbnail is not automatically the release's cover — a
      // release created with artwork the user never chose is harder to notice
      // than one created without any.
      final candidates = releaseArtworkCandidates(
        [TestFactories.makeProject(thumbnailPath: '/art/a.png')],
        imageExists: existsExcept(const {}),
      );
      expect(shouldOfferArtworkCarryOver(candidates), isTrue);
    });
  });

  group('copyArtworkForRelease', () {
    late Directory tmp;
    late Directory artDir;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('release_art_copy_');
      artDir = Directory(p.join(tmp.path, 'release_artwork'));
    });

    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    // The regression: a release made with a carried-over cover pointed at the
    // project's own cover file, so removing the project's cover deleted the
    // release's artwork too.
    test('gives the release its own copy, not the project file', () async {
      final cover = File(p.join(tmp.path, 'project_cover_art', 'c.png'));
      await cover.create(recursive: true);
      await cover.writeAsString('pixels');

      final copy = await copyArtworkForRelease(
        cover.path,
        artworkDir: () async => artDir.path,
      );

      expect(copy, isNotNull);
      expect(p.equals(copy!, cover.path), isFalse);
      expect(p.dirname(copy), artDir.path);
      expect(p.extension(copy), '.png');
      expect(await File(copy).readAsString(), 'pixels');

      // Deleting the project's cover leaves the release's artwork alone.
      await cover.delete();
      expect(await File(copy).exists(), isTrue);
    });

    test('two releases from the same cover get separate files', () async {
      final cover = File(p.join(tmp.path, 'c.jpg'));
      await cover.writeAsString('pixels');

      final a = await copyArtworkForRelease(cover.path,
          artworkDir: () async => artDir.path);
      final b = await copyArtworkForRelease(cover.path,
          artworkDir: () async => artDir.path);

      expect(a, isNot(b));
    });

    test('no artwork chosen means none', () async {
      expect(
        await copyArtworkForRelease(null, artworkDir: () async => artDir.path),
        isNull,
      );
    });

    test('a cover that has gone missing gives no artwork, not a dead path',
        () async {
      expect(
        await copyArtworkForRelease(p.join(tmp.path, 'gone.png'),
            artworkDir: () async => artDir.path),
        isNull,
      );
    });
  });
}
