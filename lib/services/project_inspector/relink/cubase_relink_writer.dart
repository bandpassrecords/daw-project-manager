import 'dart:convert';
import 'dart:typed_data';

import '../../daw_parsers/cubase_project_parser.dart';
import 'folder_rules.dart';
import 'relink_writer.dart';

/// Relinks a Cubase/Nuendo project by rewriting each moved file's `FNPath`
/// strings in place (#219).
///
/// A string that changes length would move every enclosing object's size
/// and every back-reference to a class defined after it, and the scan that
/// finds objects can't yet tell all of them from data. So the new folder
/// (and name, if it changed) is written into the room the old one had —
/// the text, NULs, then the UTF-8 BOM where the string had one — and not
/// one other byte of the project moves. Cubase 13 opened such a copy with
/// its kicks at their new place (2026-10-30). A path longer than the old
/// one is refused ([RelinkRefusal.doesNotFit]); a drive letter that
/// changed, or files moved to a shorter path, always fit.
class CubaseRelinkWriter implements ProjectRelinkWriter {
  const CubaseRelinkWriter();

  @override
  List<String> referencedPaths(Uint8List bytes) => [
        for (final r in CubaseProjectParser(bytes).readSampleReferences())
          r.candidates.first,
      ];

  @override
  RelinkWrite write(Uint8List bytes, Map<String, String> moves) {
    final byKey = {for (final m in moves.keys) m.toLowerCase(): m};
    final slots = <String, List<CubasePoolPath>>{};
    for (final f in CubaseProjectParser(bytes).readPoolPaths()) {
      final stored = byKey[f.path.toLowerCase()];
      if (stored != null) (slots[stored] ??= []).add(f);
    }

    final out = Uint8List.fromList(bytes);
    final relinked = <String>{};
    final refused = <String, RelinkRefusal>{};
    for (final MapEntry(key: stored, value: target) in moves.entries) {
      final found = slots[stored];
      if (found == null) {
        refused[stored] = RelinkRefusal.notFound;
        continue;
      }
      // Cubase keeps the folder ending in its separator, then the name.
      final name = pathSegments(target).last;
      final folder = target.substring(0, target.length - name.length);
      if (folder.isEmpty) {
        refused[stored] = RelinkRefusal.notFound;
        continue;
      }
      // Every object naming the file takes the new path, or none does.
      final problem = [
        for (final f in found) ...[
          _check(f.folder, folder),
          if (f.name.text != name) _check(f.name, name),
        ],
      ].whereType<RelinkRefusal>().firstOrNull;
      if (problem != null) {
        refused[stored] = problem;
        continue;
      }
      for (final f in found) {
        _put(out, f.folder, folder);
        if (f.name.text != name) _put(out, f.name, name);
      }
      relinked.add(stored);
    }
    return RelinkWrite(bytes: out, relinked: relinked, refused: refused);
  }

  static RelinkRefusal? _check(CubaseStringSlot slot, String text) {
    final encoded = utf8.encode(text);
    // Without the BOM, Cubase reads the text in the system's code page:
    // only ASCII is the same in every one.
    if (!slot.bom && encoded.any((b) => b > 0x7F)) {
      return RelinkRefusal.encoding;
    }
    return encoded.length > slot.room ? RelinkRefusal.doesNotFit : null;
  }

  static void _put(Uint8List out, CubaseStringSlot slot, String text) {
    final encoded = utf8.encode(text);
    final start = slot.offset + 4;
    final end = start + slot.length;
    final textEnd = end - (slot.bom ? 3 : 0);
    out.setRange(start, start + encoded.length, encoded);
    out.fillRange(start + encoded.length, textEnd, 0);
    if (slot.bom) out.setRange(textEnd, end, const [0xEF, 0xBB, 0xBF]);
  }
}
