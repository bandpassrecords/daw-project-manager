import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'cubase_relink_writer.dart';

/// Why a file a relink was asked to move stays where the project says.
enum RelinkRefusal {
  /// The project doesn't name it in a place the writer rewrites (a path in
  /// a plug-in's state, say).
  notFound,

  /// The new path is longer than the project has room for (Cubase).
  doesNotFit,

  /// The project stores the path in an encoding the new one can't be
  /// written in (an old Cubase's text, and a path with accents).
  encoding,
}

/// What a writer made of the moves it was asked for.
class RelinkWrite {
  const RelinkWrite({
    required this.bytes,
    required this.relinked,
    required this.refused,
  });

  /// The copy's bytes; the original's when nothing was relinked.
  final Uint8List bytes;

  /// The stored paths now pointing to their new place.
  final Set<String> relinked;
  final Map<String, RelinkRefusal> refused;
}

/// Writes a project's bytes with some of its audio files pointing to new
/// places, one DAW's format each (#215–#219). Pure: bytes in, bytes out —
/// the original is never touched (see `writeRelinkedCopy`).
abstract interface class ProjectRelinkWriter {
  /// The audio files [bytes] references, by the path it stores, as the
  /// DAW's reader reads them: what a written copy is checked against.
  List<String> referencedPaths(Uint8List bytes);

  /// [bytes] with each of [moves] (stored path → new path) applied, as far
  /// as the format allows: a move is applied everywhere the project names
  /// that file, or not at all.
  RelinkWrite write(Uint8List bytes, Map<String, String> moves);
}

/// The writer for [projectPath]'s format; null for a DAW with none yet.
ProjectRelinkWriter? relinkWriterFor(String projectPath) =>
    switch (p.extension(projectPath).toLowerCase()) {
      '.cpr' || '.npr' => const CubaseRelinkWriter(),
      _ => null,
    };
