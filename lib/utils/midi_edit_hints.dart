import 'package:flutter/foundation.dart';

/// One thing the piano roll's editor can teach, a short line at a time.
///
/// Rather than one tooltip listing every gesture, the roll shows the hint
/// that fits what the user is pointing at and doing ([nextMidiEditHint]),
/// and each hint retires for good once the user has done what it describes
/// or dismissed it ([MidiEditHints]) — so the concepts arrive one by one.
enum MidiEditHint {
  /// Pick the pencil to add notes with a single click.
  pencil,

  /// Double-click empty space to add a note, a note to delete it.
  doubleClick,

  /// Drag across empty space to select several notes.
  boxSelect,

  /// With the pencil: click to add, drag to make it longer.
  pencilDraw,

  /// With the pencil: click a note to erase it.
  pencilErase,

  /// Drag a note's edge to change its length.
  resize,

  /// ↑/↓ a semitone, Shift an octave.
  transpose,

  /// Alt-drag copies.
  altCopy,

  /// Ctrl-drag ignores the grid.
  ctrlFree,

  /// Drag across the velocity lane to set many notes at once.
  velocity,

  /// Drag to draw a controller lane.
  lane,

  /// Drag to draw the bend; it snaps back to no bend near the middle.
  pitchBend,
}

/// What the pointer is over while editing, for picking a hint.
enum MidiHoverArea {
  none,
  empty,
  note,
  noteEdge,
  velocityLane,
  controllerLane,
  pitchBendLane,
}

/// The hint worth showing now, or null when there's nothing left to teach
/// here: the first not yet [learned] of those that fit — the lane or note
/// edge under the pointer first, then the tool in hand. [keyboard] false (a
/// phone) leaves out the hints about keys.
MidiEditHint? nextMidiEditHint({
  required bool pencil,
  required MidiHoverArea hover,
  required bool hasSelection,
  required Set<MidiEditHint> learned,
  bool keyboard = true,
}) {
  final fitting = switch (hover) {
    MidiHoverArea.velocityLane => const [MidiEditHint.velocity],
    MidiHoverArea.pitchBendLane => const [MidiEditHint.pitchBend],
    MidiHoverArea.controllerLane => const [MidiEditHint.lane],
    MidiHoverArea.noteEdge => const [MidiEditHint.resize],
    _ when pencil => [
        if (hover == MidiHoverArea.note) MidiEditHint.pencilErase,
        MidiEditHint.pencilDraw,
      ],
    _ => [
        if (hasSelection && keyboard) ...[
          MidiEditHint.transpose,
          MidiEditHint.altCopy,
        ],
        if (hover == MidiHoverArea.note && keyboard) MidiEditHint.ctrlFree,
        MidiEditHint.pencil,
        MidiEditHint.doubleClick,
        MidiEditHint.boxSelect,
      ],
  };
  for (final hint in fitting) {
    if (!learned.contains(hint)) return hint;
  }
  return null;
}

/// The hints a user has already learned, told to [onChanged] as they grow
/// so they can be remembered.
class MidiEditHints extends ChangeNotifier {
  MidiEditHints({Set<MidiEditHint> learned = const {}, this.onChanged})
      : _learned = {...learned};

  final Set<MidiEditHint> _learned;
  final ValueChanged<Set<MidiEditHint>>? onChanged;

  Set<MidiEditHint> get learned => Set.unmodifiable(_learned);

  /// [hint] was done, or dismissed: it won't be shown again.
  void learn(MidiEditHint hint) {
    if (!_learned.add(hint)) return;
    onChanged?.call(learned);
    notifyListeners();
  }
}

/// How learned hints are stored: their names, comma separated.
String encodeMidiEditHints(Set<MidiEditHint> hints) =>
    (hints.map((h) => h.name).toList()..sort()).join(',');

/// Reads [encodeMidiEditHints]'s text back; names this build doesn't know
/// (a hint since retired) are skipped.
Set<MidiEditHint> decodeMidiEditHints(String? text) {
  if (text == null || text.isEmpty) return {};
  final names = text.split(',').map((s) => s.trim()).toSet();
  return {
    for (final h in MidiEditHint.values)
      if (names.contains(h.name)) h,
  };
}
