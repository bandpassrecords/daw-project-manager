import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart' show camelotCodeForKey;
import '../models/project_template.dart';
import '../providers/providers.dart';
import '../services/metadata_extractor.dart';
import '../utils/daw_logo.dart';
import '../utils/file_launcher.dart';
import '../utils/mobile_utils.dart';
import 'dialogs/create_project_dialog.dart';
import 'dialogs/duplicate_template_dialog.dart';
import 'project_detail_page.dart';
import 'widgets/desktop_title_bar.dart';

/// A trimmed-down counterpart to `ProjectDetailPage`, scoped to what a
/// [ProjectTemplate] actually has: name/BPM/key/DAW/notes fields and basic
/// file info — no preview player, todos, session history or stats, none of
/// which have a template equivalent.
class TemplateDetailPage extends ConsumerStatefulWidget {
  final String templateId;

  const TemplateDetailPage({super.key, required this.templateId});

  @override
  ConsumerState<TemplateDetailPage> createState() => _TemplateDetailPageState();
}

class _TemplateDetailPageState extends ConsumerState<TemplateDetailPage> {
  final _nameCtrl = TextEditingController();
  final _bpmCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _bpmFocusNode = FocusNode();
  final _keyFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();
  Timer? _autoSaveTimer;
  bool _initialized = false;
  bool _extractingMetadata = false;

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameCtrl.dispose();
    _bpmCtrl.dispose();
    _keyCtrl.dispose();
    _notesCtrl.dispose();
    _nameFocusNode.dispose();
    _bpmFocusNode.dispose();
    _keyFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Widget _buildDawPrefixIcon(String? dawType, Color color) {
    final logoPath = getDawLogoPath(dawType);
    if (logoPath == null) {
      return Icon(Icons.piano, color: color);
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        logoPath,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.piano, color: color),
      ),
    );
  }

  void _scheduleAutoSave(ProjectTemplate template) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(milliseconds: 400),
      () => _doAutoSave(template),
    );
  }

  void _doAutoSave(ProjectTemplate template) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final bpmText = _bpmCtrl.text.trim();
    final keyText = _keyCtrl.text.trim();
    final notesText = _notesCtrl.text.trim();
    ref
        .read(projectTemplatesNotifierProvider.notifier)
        .updateTemplate(
          template.copyWith(
            name: name,
            bpm: bpmText.isEmpty ? null : double.tryParse(bpmText),
            clearBpm: bpmText.isEmpty,
            musicalKey: keyText.isEmpty ? null : keyText,
            clearMusicalKey: keyText.isEmpty,
            notes: notesText.isEmpty ? null : notesText,
            clearNotes: notesText.isEmpty,
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// Hides or unhides this template, mirroring the templates table's own
  /// hide action. Leaving the record in place is what keeps a template-folder
  /// refresh from re-importing it as a brand new template.
  Future<void> _setHidden(ProjectTemplate template, bool hidden) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(projectTemplatesNotifierProvider.notifier)
        .setTemplatesHidden([template.id], hidden);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hidden
                ? l10n.templatesHidden(1, '')
                : l10n.templatesUnhidden(1, ''),
          ),
        ),
      );
    }
  }

  Future<void> _deleteTemplate(ProjectTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteTemplate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteTemplateConfirm(template.name)),
            const SizedBox(height: 12),
            Text(
              l10n.deleteTemplateFolderKept(template.sourceFolderPath),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(projectTemplatesNotifierProvider.notifier)
        .deleteTemplate(template.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _useTemplate(ProjectTemplate template) {
    showDialog(
      context: context,
      builder: (_) => CreateProjectDialog(initialTemplate: template),
    );
  }

  void _duplicateTemplate(ProjectTemplate template) {
    showDialog(
      context: context,
      builder: (_) => DuplicateTemplateDialog(template: template),
    );
  }

  Future<void> _extractMetadata(ProjectTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _extractingMetadata = true);
    try {
      await ref
          .read(projectTemplatesNotifierProvider.notifier)
          .extractMetadataForTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.metadataExtractedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToExtractMetadata(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _extractingMetadata = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(projectTemplatesProvider);
    final templates = templatesAsync.value ?? const <ProjectTemplate>[];
    ProjectTemplate? template;
    for (final t in templates) {
      if (t.id == widget.templateId) {
        template = t;
        break;
      }
    }

    final isMobile = MobileUtils.isMobile();

    if (template == null) {
      return Scaffold(
        appBar: isMobile
            ? AppBar(
                title: Text(l10n.templateDetailTitle),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        body: Column(
          children: [
            DesktopTitleBar(title: l10n.templateDetailTitle, showBack: true),
            Expanded(child: Center(child: Text(l10n.templateNotFound))),
          ],
        ),
      );
    }
    final currentTemplate = template;

    if (!_initialized) {
      _nameCtrl.text = currentTemplate.name;
      _bpmCtrl.text = currentTemplate.bpm?.toString() ?? '';
      _keyCtrl.text = currentTemplate.musicalKey ?? '';
      _notesCtrl.text = currentTemplate.notes ?? '';
      _initialized = true;
    }

    final mainFile = File(
      p.join(
        currentTemplate.sourceFolderPath,
        currentTemplate.mainFileRelativePath,
      ),
    );
    final sourceExists = mainFile.existsSync();
    final extractionSupported = MetadataExtractor.supportsFullExtraction(
      mainFile.path,
    );
    final dawType = MetadataExtractor.getDawTypeFromExtension(
      p.extension(currentTemplate.mainFileRelativePath),
    );
    final camelotCode = camelotCodeForKey(currentTemplate.musicalKey);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final projectsFromTemplate =
        (ref.watch(allProjectsStreamProvider).value ?? const [])
            .where((p) => p.sourceTemplateId == currentTemplate.id)
            .toList();

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(currentTemplate.name),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(title: currentTemplate.name, showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!sourceExists)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l10n.templateSourceMissing)),
                        ],
                      ),
                    ),
                  Text(
                    '${l10n.dateCreatedColumn}: ${dateFormat.format(currentTemplate.createdAt)}   '
                    '${l10n.dateModifiedColumn}: ${dateFormat.format(currentTemplate.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: sourceExists
                            ? () => FileLauncher.openFolder(
                                currentTemplate.sourceFolderPath,
                              )
                            : null,
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: Text(l10n.openFolder),
                      ),
                      OutlinedButton.icon(
                        onPressed: sourceExists
                            ? () => _useTemplate(currentTemplate)
                            : null,
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: Text(l10n.useTemplate),
                      ),
                      OutlinedButton.icon(
                        onPressed: sourceExists
                            ? () => _duplicateTemplate(currentTemplate)
                            : null,
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        label: Text(l10n.duplicateTemplate),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _setHidden(
                          currentTemplate,
                          !currentTemplate.hidden,
                        ),
                        icon: Icon(
                          currentTemplate.hidden
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                          size: 16,
                        ),
                        label: Text(
                          currentTemplate.hidden ? l10n.unhide : l10n.hide,
                        ),
                      ),
                      // Deleting is offered only once the main file is gone —
                      // otherwise hiding is the durable answer, since a
                      // template-folder refresh would re-import a deleted
                      // template as a brand new one.
                      if (!sourceExists)
                        OutlinedButton.icon(
                          onPressed: () => _deleteTemplate(currentTemplate),
                          icon: const Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.red,
                          ),
                          label: Text(l10n.delete),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    focusNode: _nameFocusNode,
                    decoration: InputDecoration(labelText: l10n.templateName),
                    onChanged: (_) => _scheduleAutoSave(currentTemplate),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bpmCtrl,
                          focusNode: _bpmFocusNode,
                          decoration: InputDecoration(labelText: l10n.bpm),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => _scheduleAutoSave(currentTemplate),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _keyCtrl,
                          focusNode: _keyFocusNode,
                          decoration: InputDecoration(labelText: l10n.key),
                          onChanged: (_) {
                            setState(() {});
                            _scheduleAutoSave(currentTemplate);
                          },
                        ),
                      ),
                      if (camelotCode != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            enabled: false,
                            initialValue: camelotCode,
                            decoration: InputDecoration(
                              labelText: l10n.camelotCode,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                      if (dawType != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            enabled: false,
                            initialValue:
                                currentTemplate.dawVersion?.isNotEmpty == true
                                ? '$dawType ${currentTemplate.dawVersion}'
                                : dawType,
                            decoration: InputDecoration(
                              labelText: l10n.daw,
                              border: const OutlineInputBorder(),
                              prefixIcon: _buildDawPrefixIcon(
                                dawType,
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Tooltip(
                        message: !sourceExists
                            ? l10n.sourceFileNotFoundOnThisMachine
                            : !extractionSupported
                            ? l10n.metadataExtractionNotSupportedForDaw
                            : '',
                        child: ElevatedButton.icon(
                          onPressed:
                              _extractingMetadata ||
                                  !sourceExists ||
                                  !extractionSupported
                              ? null
                              : () => _extractMetadata(currentTemplate),
                          icon: _extractingMetadata
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search, size: 18),
                          label: Text(
                            _extractingMetadata
                                ? l10n.extracting
                                : l10n.extract,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    focusNode: _notesFocusNode,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: l10n.notes,
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => _scheduleAutoSave(currentTemplate),
                  ),
                  if (currentTemplate.projectNotes?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      enabled: false,
                      initialValue: currentTemplate.projectNotes,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: l10n.projectNotesFromDaw,
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    l10n.fileInfo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (sourceExists)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.fileSize}: ${_formatFileSize(mainFile.lengthSync())}',
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              '${l10n.filePath}: ${mainFile.path}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.fileModified}: ${dateFormat.format(mainFile.lastModifiedSync())}',
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      l10n.templateSourceMissing,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.projectsFromThisTemplate(projectsFromTemplate.length),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (projectsFromTemplate.isEmpty)
                    Text(
                      l10n.noProjectsFromThisTemplate,
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Column(
                      children: [
                        for (final project in projectsFromTemplate)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(project.displayName),
                              subtitle: Text(
                                dateFormat.format(project.createdAt),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 18,
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProjectDetailPage(projectId: project.id),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
