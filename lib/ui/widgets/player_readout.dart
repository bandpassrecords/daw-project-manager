import 'package:material_ui/material_ui.dart';

/// A player's readout — its clock, its file details — in a slot whose width
/// never changes: as wide as the widest of [templates] in [style].
///
/// Until [text] is known (null) the slot holds a placeholder bar the size of
/// the first template, so nothing beside it moves when the data arrives. A
/// readout sized to its text grew the moment a file's details or length
/// loaded, shoving the track name next to it sideways — a blink on every play.
/// Text longer than every template is cut with an ellipsis rather than
/// widening the slot.
class PlayerReadout extends StatelessWidget {
  final String? text;

  /// The widest texts this readout can show. The slot is the widest of them.
  final List<String> templates;
  final TextStyle? style;

  /// Where the text and the placeholder sit inside the slot.
  final AlignmentGeometry alignment;

  /// Read out by a screen reader while [text] is null.
  final String loadingLabel;

  const PlayerReadout({
    super.key,
    required this.text,
    required this.templates,
    required this.loadingLabel,
    this.style,
    this.alignment = AlignmentDirectional.centerEnd,
  });

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    Size measure(String s) {
      final painter = TextPainter(
        text: TextSpan(text: s, style: effective),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final sizes = templates.map(measure).toList();
    final width = sizes.fold<double>(0, (w, s) => s.width > w ? s.width : w);
    final height = sizes.isEmpty ? 0.0 : sizes.first.height;
    final current = text;

    return SizedBox(
      width: width.ceilToDouble(),
      height: height.ceilToDouble(),
      child: Align(
        alignment: alignment,
        child: current != null
            ? Text(
                current,
                style: style,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              )
            : Semantics(
                label: loadingLabel,
                child: Container(
                  key: const ValueKey('playerReadoutPlaceholder'),
                  width: sizes.isEmpty ? 0 : sizes.first.width,
                  height: height * 0.6,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
      ),
    );
  }
}
