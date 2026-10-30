import '../../../models/project_anatomy.dart';
import '../../../utils/csv.dart';
import 'anatomy_diff.dart';

/// Every change in [diff] as CSV, a row each: what it is about, the channel
/// (A's name, then B's when renamed), the change and its values as read.
/// The header and values are English, like every CSV the app writes: a
/// file for a spreadsheet, not a sentence for a person.
String anatomyDiffCsv(AnatomyDiff diff) {
  String value(Object? v, bool position) => switch (v) {
    null => '',
    final double d when position => d.toStringAsFixed(3),
    final double d when d.isInfinite => '-inf',
    final double d => d.toStringAsFixed(2),
    final AnatomyChannelKind k => k.name,
    _ => '$v',
  };
  List<Object?> row(AnatomyChange c, ChannelComparison? ch) => [
    c.area.name,
    ch?.a?.name,
    ch?.b?.name,
    c.kind.name,
    c.subject,
    c.slot == null ? null : c.slot! + 1,
    value(c.before, c.position),
    value(c.after, c.position),
    c.position
        ? 'position'
        : c.kind == AnatomyChangeKind.volume ||
              c.kind == AnatomyChangeKind.sendLevel
        ? 'dB'
        : null,
  ];
  return csvTable(
    const [
      'area',
      'channel_a',
      'channel_b',
      'change',
      'subject',
      'slot',
      'before',
      'after',
      'unit',
    ],
    [
      for (final c in diff.projectChanges) row(c, null),
      for (final ch in diff.channels)
        for (final c in ch.changes) row(c, ch),
    ],
  );
}
