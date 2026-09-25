import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/utils/cover_art_refs.dart';

import '../helpers/test_factories.dart';

void main() {
  String path(List<String> parts) => parts.join(Platform.pathSeparator);
  final cover = path(['data', 'project_cover_art', 'abc.png']);

  Release release({String? artwork}) => Release(
        id: 'r1',
        title: 'EP',
        trackIds: const [],
        releaseDate: DateTime(2026, 1, 1),
        artworkImagePath: artwork,
      );

  group('isImageInUse', () {
    // The regression: a version stack is a copy of its promoted member,
    // thumbnailPath included. Changing the stack's cover deleted the shared
    // file, and the member came back from unstacking with a dead cover.
    test('another project still using the file keeps it', () {
      final member = TestFactories.makeProject(id: 'v1', thumbnailPath: cover);
      final stackAfterEdit = TestFactories.makeProject(
        id: 'stack',
        thumbnailPath: path(['data', 'project_cover_art', 'new.png']),
      );

      expect(
        isImageInUse(cover,
            projects: [member, stackAfterEdit], releases: const []),
        isTrue,
      );
    });

    test('a release using the file keeps it', () {
      expect(
        isImageInUse(cover,
            projects: const [], releases: [release(artwork: cover)]),
        isTrue,
      );
    });

    test('nothing pointing at it any more means it can go', () {
      final edited = TestFactories.makeProject(id: 'p', thumbnailPath: null);
      expect(
        isImageInUse(cover,
            projects: [edited], releases: [release(artwork: null)]),
        isFalse,
      );
    });

    test('matches the same file written slightly differently', () {
      final member = TestFactories.makeProject(
        id: 'v1',
        thumbnailPath: path(['data', 'project_cover_art', '.', 'abc.png']),
      );
      expect(
        isImageInUse(cover, projects: [member], releases: const []),
        isTrue,
      );
    });

    test('blank paths never count as a match', () {
      final blank = TestFactories.makeProject(id: 'p', thumbnailPath: '  ');
      expect(
        isImageInUse(cover,
            projects: [blank], releases: [release(artwork: '')]),
        isFalse,
      );
    });
  });
}
