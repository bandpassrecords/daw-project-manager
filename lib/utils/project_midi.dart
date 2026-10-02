import '../models/music_project.dart';

/// Whether [project] holds MIDI — notes stored in the project file, or in a
/// `.mid` file it references — as its last full read found: at least one
/// clip. A version stack owns no file, so it holds MIDI when one of its
/// versions does; [all] is where those versions are looked up.
///
/// A project that has never been read in full doesn't count: nothing is
/// known about it yet.
bool projectHasMidi(MusicProject project, Iterable<MusicProject> all) {
  bool own(MusicProject p) => (p.stats?.midiClipCount ?? 0) > 0;
  if (!project.isVirtual) return own(project);
  return all.any((m) => m.stackId == project.id && own(m));
}
