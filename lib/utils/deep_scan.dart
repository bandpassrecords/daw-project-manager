import '../models/music_project.dart';
import '../services/metadata_extractor.dart';

/// Whether "only projects not fully read yet" deep scanning should read
/// [project] — null for a file the library doesn't know yet.
///
/// True when it was never deep-scanned, and also when it was but its
/// contents (tracks, plug-ins, MIDI clips) never were: projects deep-scanned
/// before the app could read contents carry `metadataScanned` but no
/// `stats`, and would otherwise never get their MIDI clips. `stats` follows
/// the null contract — null means "never read" — so a project whose format
/// has contents to read and still has none is not finished.
///
/// A project whose contents can't be parsed keeps null stats, so it is
/// tried again on the next such scan rather than given up on.
bool needsDeepScan(MusicProject? project) {
  if (project == null || !project.metadataScanned) return true;
  return project.stats == null &&
      MetadataExtractor.readsProjectContents(project.filePath);
}
