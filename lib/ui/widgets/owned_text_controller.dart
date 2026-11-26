import 'package:material_ui/material_ui.dart';

/// Builds [builder] with a [TextEditingController] it owns, disposed when it
/// leaves the tree.
///
/// For a text field in a dialog or a sheet. A controller made before
/// `showDialog` and disposed as soon as it returns is disposed while the
/// dialog's closing animation still draws the field, which then throws ("A
/// TextEditingController was used after being disposed") on every close.
class OwnedTextController extends StatefulWidget {
  const OwnedTextController({super.key, this.text = '', required this.builder});

  /// What the field starts with.
  final String text;
  final Widget Function(BuildContext context, TextEditingController controller)
  builder;

  @override
  State<OwnedTextController> createState() => _OwnedTextControllerState();
}

class _OwnedTextControllerState extends State<OwnedTextController> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
