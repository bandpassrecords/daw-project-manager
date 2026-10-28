import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/audio_analysis_service.dart';
import 'semantics_safe.dart';

/// Resolves the path that should actually be dragged for [sourcePath]:
/// the source itself when it's already messaging-app compatible, otherwise
/// a converted copy (cached in [cache] keyed by source path, so repeated
/// drags of the same song don't reconvert).
///
/// [onConverting] fires with true only when a real conversion starts (cache
/// miss) and always with false afterwards — it never fires at all for
/// passthrough or cache-hit resolutions. Extracted from the widget with
/// injectable [convert]/[getTempDir] so this logic is unit-testable
/// (DragItemWidget itself needs the super_native_extensions native plugin).
Future<String?> resolveDragSharePath(
  String sourcePath, {
  required Map<String, String> cache,
  Future<File?> Function(String inputPath, String outputDir)? convert,
  Future<Directory> Function()? getTempDir,
  void Function(bool converting)? onConverting,
}) async {
  if (!AudioAnalysisService.needsConversionForSharing(sourcePath)) {
    return sourcePath;
  }
  final cached = cache[sourcePath];
  if (cached != null && await File(cached).exists()) return cached;

  onConverting?.call(true);
  try {
    final tempDir = await (getTempDir ?? getTemporaryDirectory)();
    final converted = await (convert ?? AudioAnalysisService.convertForSharing)(
        sourcePath, tempDir.path);
    if (converted == null) return null;
    cache[sourcePath] = converted.path;
    return converted.path;
  } finally {
    onConverting?.call(false);
  }
}

/// Desktop-only: a chip the user can drag straight onto another app's
/// window (e.g. WhatsApp Desktop) to share the file.
///
/// This exists because `Share.shareXFiles` on Windows goes through the
/// `DataTransferManager` API, which only works when the app is
/// MSIX-packaged — an unpackaged dev/debug build gets
/// `ShareResultStatus.unavailable` with no share sheet ever appearing.
/// OS-level drag-and-drop uses a different mechanism (CF_HDROP on Windows,
/// public.file-url on macOS) that works regardless of packaging.
class DragToShareButton extends StatefulWidget {
  final String sourcePath;

  const DragToShareButton({super.key, required this.sourcePath});

  @override
  State<DragToShareButton> createState() => _DragToShareButtonState();
}

class _DragToShareButtonState extends State<DragToShareButton> {
  // Keyed by source path so repeated drags of the same song don't
  // re-convert every time. Conversion stays lazy (first drag), NOT
  // pre-warmed on build: pre-warming would run ffmpeg/afconvert for every
  // rendered chip, burning seconds of CPU and temp disk for songs that are
  // never dragged.
  static final Map<String, String> _conversionCache = {};

  // True while a first-drag conversion runs; the OS drag can't start until
  // it finishes, so the chip shows a spinner to explain the wait.
  bool _converting = false;

  void _setConverting(bool value) {
    if (mounted) setState(() => _converting = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DragItemWidget(
      allowedOperations: () => [DropOperation.copy],
      dragItemProvider: (request) async {
        final path = await resolveDragSharePath(
          widget.sourcePath,
          cache: _conversionCache,
          onConverting: _setConverting,
        );
        if (path == null) return null;
        final item = DragItem(suggestedName: p.basename(path));
        item.add(Formats.fileUri(Uri.file(path)));
        return item;
      },
      child: DraggableWidget(
        child: StandaloneTooltip(
          message: _converting ? l10n.convertingAudioForSharing : l10n.dragToShareTooltip,
          child: Chip(
            avatar: _converting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.drag_indicator, size: 16),
            label: Text(l10n.dragToShare),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}
