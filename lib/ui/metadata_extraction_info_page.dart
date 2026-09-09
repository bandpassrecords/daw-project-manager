import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../utils/daw_logo.dart';
import '../utils/mobile_utils.dart';
import 'widgets/desktop_title_bar.dart';

/// Which fields [MetadataExtractor.extractMetadata] can pull automatically
/// from each DAW's project file today. DAWs not listed here (or listed with
/// every field false) still show up on the Dashboard and can be scanned —
/// BPM/key/notes just have to be entered manually, since nobody has reverse
/// engineered that file format's binary/XML layout yet.
class _DawExtractionInfo {
  final String name;
  final bool bpm;
  final bool key;
  final bool version;
  final bool notes;

  /// Timeline markers and regions (#91). Only Reaper writes them somewhere
  /// readable so far — every other format either has no equivalent or keeps
  /// it in a binary blob nobody has reverse engineered yet.
  final bool markers;

  const _DawExtractionInfo(
    this.name, {
    required this.bpm,
    required this.key,
    required this.version,
    required this.notes,
    this.markers = false,
  });
}

const _dawExtractionInfo = [
  _DawExtractionInfo('Ableton Live', bpm: true, key: true, version: true, notes: false),
  _DawExtractionInfo('ACID Pro', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Adobe Audition', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Ardour', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Audacity', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Bitwig Studio', bpm: true, key: true, version: true, notes: false),
  _DawExtractionInfo('Cakewalk / Sonar', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Cubase', bpm: true, key: true, version: true, notes: true),
  _DawExtractionInfo('Digital Performer', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('FL Studio', bpm: true, key: false, version: true, notes: false),
  _DawExtractionInfo('GarageBand', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('LMMS', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Logic Pro', bpm: true, key: true, version: true, notes: false),
  _DawExtractionInfo('MAGDA', bpm: true, key: true, version: true, notes: false),
  _DawExtractionInfo('Maschine', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Mixcraft', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Nuendo', bpm: true, key: true, version: true, notes: true),
  _DawExtractionInfo('Pro Tools', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Qtractor', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Reaper', bpm: true, key: true, version: true, notes: true, markers: true),
  _DawExtractionInfo('Reason', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Renoise', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Rosegarden', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Samplitude / Sequoia', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Studio One', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Tracktion Waveform', bpm: false, key: false, version: false, notes: false),
  _DawExtractionInfo('Universal Audio LUNA', bpm: false, key: false, version: false, notes: false),
];

class MetadataExtractionInfoPage extends StatelessWidget {
  const MetadataExtractionInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDesktop = !kIsWeb && MobileUtils.isDesktop();

    Widget statusIcon(bool supported) => Icon(
          supported ? Icons.check_circle : Icons.remove_circle_outline,
          size: 18,
          color: supported
              ? Colors.green
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        );

    Widget dawNameCell(String name) {
      final logoPath = getDawLogoPath(name);
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (logoPath == null)
            Icon(Icons.piano, size: 16, color: theme.colorScheme.onSurfaceVariant)
          else
            Image.asset(
              logoPath,
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.piano,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 8),
          Text(name),
        ],
      );
    }

    return Scaffold(
      body: Column(
        children: [
          DesktopTitleBar(title: l10n.metadataExtractionTitle, showBack: true),
          if (!isDesktop)
            AppBar(
              title: Text(l10n.metadataExtractionTitle),
              leading: const BackButton(),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.metadataExtractionIntro,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text(l10n.daw)),
                                DataColumn(label: Text(l10n.bpm)),
                                DataColumn(label: Text(l10n.metadataFieldKey)),
                                DataColumn(label: Text(l10n.metadataFieldVersion)),
                                DataColumn(label: Text(l10n.notes)),
                                DataColumn(label: Text(l10n.projectMarkers)),
                              ],
                              rows: [
                                for (final daw in _dawExtractionInfo)
                                  DataRow(
                                    cells: [
                                      DataCell(dawNameCell(daw.name)),
                                      DataCell(statusIcon(daw.bpm)),
                                      DataCell(statusIcon(daw.key)),
                                      DataCell(statusIcon(daw.version)),
                                      DataCell(statusIcon(daw.notes)),
                                      DataCell(statusIcon(daw.markers)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.metadataExtractionManualNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
