import '../../../models/project_anatomy.dart';
import '../../../utils/csv.dart';

/// Lists inside one cell are joined with this: commas belong to the CSV.
const _join = '; ';

String _db(double? db) => db == null
    ? ''
    : db.isInfinite
    ? '-inf'
    : db.toStringAsFixed(1);

/// The Inspector's track list as CSV (#224): every channel in project
/// order with its kind, folder, output, fader, pan, mute and solo, its
/// instrument, inserts (slot. plug-in), strip modules and sends. English,
/// like every CSV the app writes. Empty when the DAW's channels aren't read.
String anatomyTracksCsv(ProjectAnatomy anatomy) => csvTable(
  const [
    'channel',
    'kind',
    'folder',
    'output',
    'volume_db',
    'fader_position',
    'pan',
    'muted',
    'soloed',
    'instrument',
    'instrument_preset',
    'inserts',
    'strip',
    'sends',
    'eq_bands_on',
  ],
  [
    for (final c in anatomy.channels ?? const <AnatomyChannel>[])
      [
        c.name,
        c.kind.name,
        c.folder,
        c.output,
        _db(c.volumeDb),
        c.faderPosition?.toStringAsFixed(3),
        c.pan?.toStringAsFixed(2),
        c.muted,
        c.soloed,
        c.instrument,
        c.instrumentPreset,
        [
          for (final i in c.inserts)
            '${i.slot + 1}. ${i.plugin}${i.deactivated == true ? ' (off)' : ''}',
        ].join(_join),
        [
          for (final m in c.stripModules)
            '${m.kind?.name ?? 'module'}: ${m.plugin}'
                '${m.deactivated == true ? ' (off)' : ''}',
        ].join(_join),
        [
          for (final s in c.sends)
            [
              s.sideChainOf != null
                  ? 'side-chain ${s.sideChainOf}'
                  : s.destination ?? '?',
              if (s.levelDb != null) '${_db(s.levelDb)} dB',
              if (s.preFader) 'pre',
              if (!s.on) 'off',
            ].join(' '),
        ].join(_join),
        c.eqBandsOn,
      ],
  ],
);

/// Every plug-in the project uses as CSV (#224): name, maker, format, role,
/// stock or not, how many instances and on which channels — what is known
/// for this DAW; the rest left empty.
String anatomyPluginsCsv(ProjectAnatomy anatomy) => csvTable(
  const [
    'plugin',
    'vendor',
    'format',
    'role',
    'stock',
    'instances',
    'channels',
  ],
  [
    for (final pl in anatomy.plugins)
      [
        pl.name,
        pl.vendor,
        pl.format,
        pl.role?.name,
        pl.stock,
        pl.instances,
        pl.channels.join(_join),
      ],
  ],
);
