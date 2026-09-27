import 'package:flutter/material.dart';

import '../../utils/project_tags.dart';

/// A project's tags as removable chips, plus a field that adds new ones
/// (#109).
///
/// Takes plain values and callbacks — no `Ref`, no Hive, no
/// `AppLocalizations` — so it is widget-testable; the page resolves strings
/// and does the saving. Enter adds exactly what was typed; picking a
/// suggestion adds that suggestion. Either way the caller is handed raw text
/// and is expected to run it through [canonicalTag], so "trap" typed on a
/// song lands as the library's existing "Trap".
class ProjectTagsEditor extends StatefulWidget {
  const ProjectTagsEditor({
    super.key,
    required this.tags,
    required this.suggestions,
    required this.hintText,
    required this.onAdd,
    required this.onRemove,
    required this.removeTooltip,
    this.helperText,
  });

  /// The project's tags, in their stored order.
  final List<String> tags;

  /// Every tag in use in the library. Tags the project already has are
  /// filtered out here, so the caller can pass the full list.
  final List<String> suggestions;

  final String hintText;
  final String? helperText;
  final String Function(String tag) removeTooltip;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  /// Most suggestions shown at once. The list is a nudge towards reusing a
  /// spelling, not a browser for the whole vocabulary.
  static const int maxSuggestions = 8;

  /// The suggestions offered for [query]: tags not already on the project
  /// that contain [query], ignoring case — ones that *start* with it first.
  /// Nothing for an empty query, so the field doesn't open a list on focus.
  static List<String> suggestionsFor({
    required String query,
    required List<String> suggestions,
    required List<String> current,
  }) {
    final q = tagKey(query.trim());
    if (q.isEmpty) return const [];
    final candidates = suggestions
        .where((s) => !containsTag(current, s) && tagKey(s).contains(q))
        .toList();
    candidates.sort((a, b) {
      final aStarts = tagKey(a).startsWith(q);
      final bStarts = tagKey(b).startsWith(q);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return 0; // Stable: keeps the library's alphabetical order.
    });
    return candidates.take(maxSuggestions).toList();
  }

  @override
  State<ProjectTagsEditor> createState() => _ProjectTagsEditorState();
}

class _ProjectTagsEditorState extends State<ProjectTagsEditor> {
  // Captured from Autocomplete's field builder: the field owns it, and this
  // is the only way to clear it after a tag goes in.
  TextEditingController? _fieldController;

  void _submit(String raw) {
    if (normalizeTag(raw) == null) return;
    widget.onAdd(raw);
    _fieldController?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in widget.tags)
                InputChip(
                  key: ValueKey('tag-chip-$tag'),
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                  onDeleted: () => widget.onRemove(tag),
                  deleteButtonTooltipMessage: widget.removeTooltip(tag),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Autocomplete<String>(
          optionsBuilder: (value) => ProjectTagsEditor.suggestionsFor(
            query: value.text,
            suggestions: widget.suggestions,
            current: widget.tags,
          ),
          onSelected: _submit,
          fieldViewBuilder: (context, controller, focusNode, _) {
            _fieldController = controller;
            return TextField(
              key: const ValueKey('tag-input'),
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                helperText: widget.helperText,
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.sell_outlined, size: 18),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLength: kMaxTagLength,
              // The counter is noise for a label this short; the limit is
              // there to stop a pasted paragraph, not to be watched.
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              textInputAction: TextInputAction.done,
              onSubmitted: (raw) {
                _submit(raw);
                // Keep typing tags without clicking back into the field.
                focusNode.requestFocus();
              },
            );
          },
        ),
      ],
    );
  }
}
