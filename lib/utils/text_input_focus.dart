import 'package:flutter/material.dart';

/// Whether any text input (TextField / EditableText) currently has focus.
///
/// Every keyboard handler that binds bare keys — Space to play/pause, arrows
/// to seek — has to check this first, or typing a space into a rename field
/// pauses the music instead of writing a space.
///
/// Walks up from the focused widget's context rather than inspecting the
/// focus node: the inner [Focus] widget an [EditableText] creates is a
/// descendant of it, so [EditableText] is reliably findable as an ancestor
/// from there, whereas the node itself carries nothing that identifies it as
/// a text field.
bool isTextInputFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return context.findAncestorWidgetOfExactType<EditableText>() != null;
}
