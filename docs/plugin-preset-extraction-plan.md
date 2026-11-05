# Plan: extract plug-in presets from Cubase projects

Goal: on a Cubase project's page, show which preset each VST2 plug-in instance was using (for example "Sylenth1 — *LD Axe Lead Solo PROTO*, program 35 of 512"). Let the user save it as a standard `.fxp` or `.fxb`, one instance at a time or for the whole project, ready to load straight back into the plug-in.

Status: format verified against 156 real Cubase projects on one machine (Cubase SX 3 to 13). Nothing is implemented yet.

## What a `.cpr` holds (verified)

Every plug-in instance's state is an attribute named `audioComponent` inside the plug-in's object in an `ARCH` chunk, the same objects `CubaseProjectParser` already walks for `Plugin Name`:

```
"audioComponent" 00            key, NUL-terminated
00 02 00 07                    attribute kind, binary (constant in all 176,818 occurrences)
u32 BE length                  length of the blob that follows
blob
```

When the plug-in is a VST2 plug-in (wrapped by Cubase), the blob is:

```
"VstW"  u32 BE 8  u32 BE 1 (version)  u32 BE 0 (bypass)     16 bytes
CcnK…                                                        a complete .fxb or .fxp file
```

- The `CcnK` part *is* a standard VST2 bank or program file: `CcnK`, a u32 BE `byteSize` (the file is `byteSize + 8` bytes), magic `FBCh`/`FPCh`/`FxBk`/`FxCk`, version, a 4-char plug-in ID (`syl1` is Sylenth1), and so on. Writing those bytes to disk produces a file the plug-in loads directly. No re-encoding.
- `length == 16 + byteSize + 8` held for all 7,102 `VstW` blobs across 110 different VST2 plug-ins.
- Blobs that don't start with `VstW` are native VST3 states: opaque, in each plug-in's own format. They are out of scope for v1 (see phase 2).
- The same state can appear more than once in a file: 37 duplicates among 458 Sylenth1 copies. De-duplicate by content hash, and keep the copy that sits inside the instance's object.

### Reading which preset was selected (bank files)

A bank (`FBCh`) holds every program the plug-in had loaded. The plug-in decides what is inside the chunk, so "which program was in use" is plug-in-specific. For **Sylenth1** it's known exactly. Everything below is little-endian, inside the chunk that follows the `FBCh` header at file offset 160:

```
"1lys"  version  programCount  fieldsPerProgram  currentProgram     20 bytes
programCount x { float fields[fieldsPerProgram]; char name[36]; }   (names NUL-terminated)
```

- Version 3045: the chunk is `"1lys" version` followed by a **zlib** stream holding the 20-byte header and the records. `ZLibDecoder` from `dart:io` handles it.
- Versions 2011–3031: plain. Detect compression by checking whether the plain reading fits the chunk size, not by the version number.
- Real banks have 512 slots. Unused slots are named `Init`.
- In all 421 distinct Sylenth1 instances, `currentProgram` was in range and named a real preset.

The reference implementation, tested against 270 real files: `synleth1/scripts/sylenth_bank.py` (`parse_chunk`, `expand`) and `synleth1/src/sylenth/SylenthFormat.cpp`.

For other plug-ins v1 shows the plug-in ID, the program count (`FBCh` header `numPrograms`) and, for `FPCh`/`FxCk`, the 28-byte program name in the header. A decoder for one more plug-in's selected program can be added later, behind the same interface.

## Design

**Nothing new is stored.** Presets are read from the project file on demand, when the page opens or the user exports. One Sylenth1 bank is up to about 0.5 MB, and a project can hold dozens, so they don't belong in Hive, `ProjectStats`, Drive sync or the local backup. That makes the sync/backup question for new fields moot: there are none. If a later version wants to show the preset name in the table without opening the file, a small `pluginPresets` summary (names only) can go into `ProjectStats`, and that field gets the usual sync and backup evaluation.

```
lib/services/daw_parsers/cubase_project_parser.dart
    readPluginStates() -> List<CubasePluginState>      new, next to readTracks()/readPluginNames()

lib/services/plugin_presets/                           new folder, pure Dart, no Flutter
    vst2_state.dart          Vst2State.parse(Uint8List blob): VstW header, CcnK container, kind, plug-in ID, programs
    sylenth1_bank.dart       selected program + names for plug-in ID 'syl1' (zlib or plain)
    preset_decoders.dart     map plug-in ID -> decoder; unknown IDs fall back to the generic summary
    preset_export.dart       file names, de-duplication, writing .fxb/.fxp (bytes as stored)
```

`CubasePluginState`:
- track index or name, and the slot (VST Instrument, insert N) taken from the enclosing object;
- plug-in name (`Plugin Name`);
- the blob, as an offset and length into the file;
- the decoded `Vst2State`, or null when the blob isn't VST2.

To tie a blob to its track and slot, find the `_ArchiveIndex` instance whose byte range contains the `audioComponent` key, the same way `_channelKey` / `_pluginNameKey` are already resolved for inserts in `readTracks()`. An instance found nowhere else (for example on a disabled track) still gets listed, with track "unknown".

## Steps

1. **Fixtures first.** Make a small project of our own in Cubase 13. The repo's rule is "no commercial audio", and that applies just as much to presets from commercial packs.
   - Two instrument tracks with Sylenth1, each on a preset you make yourself and rename (one bank, one changed program).
   - One Sylenth1 used on a disabled track.
   - One VST2 effect insert, and one native VST3 plug-in, which must not be listed as VST2.
   - Add it with `scripts/add_test_fixture.ps1` and record its `.expected.json` with `UPDATE_FIXTURES=1`, then read the diff.
   - Also save the same project from an older Cubase version if you have one, so you get a plain (non-zlib) Sylenth1 chunk.
2. **`vst2_state.dart` and its unit tests.** Use byte fixtures cut from the project above, plus synthetic cases: wrong length, truncated `CcnK`, non-`VstW` blob, `FxBk` with programs inside, zero-length name.
3. **`sylenth1_bank.dart` and its tests.** Cover the zlib and plain variants, `currentProgram` in and out of range, 242/243/244 fields, and a name followed by stale bytes after the NUL (Sylenth1 doesn't clear its name buffer).
4. **`readPluginStates()` in the Cubase parser.** Extend `project_corpus_test.dart` so `.expected.json` records each instance: track, slot, plug-in, ID, kind, selected program name. Re-record every Cubase fixture and read the diff; projects without VST2 plug-ins should only gain an empty list.
5. **`preset_export.dart`.** It writes `<project>/<track> - <plugin> - <program>.fxb` (or `.fxp`), with the existing filename sanitiser, and de-duplicates by hash. "Export all" writes into a folder the user picks.
   - Build the work as plain functions, split from the folder dialog, so a flow test can drive it. CLAUDE.md asks for exactly that split.
   - Add a `test/flows/preset_export_flow_test.dart` that exports from the fixture copy and re-reads every file with `Vst2State.parse`.
6. **UI on the project page.**
   - Under the plug-in list (`ProjectStatsSection`), add a "Presets" section for Cubase projects: one row per VST2 instance, showing track, plug-in, and the selected program when a decoder knows it.
   - Each row gets "Save preset (.fxp)" and "Save bank (.fxb)"; the section gets "Save all presets…".
   - Every string goes in `app_en.arb` plus all 8 other locales (`app_pt.arb` is Brazilian Portuguese), then run `flutter gen-l10n`.
   - Reading runs off the UI thread (an isolate, or `compute`), because projects reach 30+ MB.
7. **Sample pack (optional).** Add a "Plug-in presets" checkbox to the sample pack export (`sample_pack_exporter.dart`). It puts each project's exported presets in a `Presets/` folder of the pack, next to its samples and MIDI.
8. `flutter test` on Windows, then CI on all three OSes.

## Phase 2 (not verified yet)

- **Native VST3 presets.** A `.vstpreset` is the `VST3` header, the plug-in's class ID (32 hex characters), and chunks `Comp` (component state, which is this blob) and `Cont` (controller state). It needs the class ID and the controller blob from the same instance. Look for neighbouring attributes in a Cubase 13 fixture before promising it.
- **Other DAWs.** These are unverified until checked against the corpus:
  - Ableton keeps VST2 state as a base64 `Buffer` (the raw chunk, without `CcnK`) next to the plug-in ID, so `.fxb` export would wrap it in a header.
  - REAPER keeps base64 state in the `.rpp` text.
  - Studio One's `.song` is a zip with preset files.

## Risks and checks

- **Edits made in the project.** Does the selected slot hold the sound as tweaked in the project, or the bank's stored preset? Probably the tweaked sound, since VST2 bank state usually stores the edited program, but it isn't verified. Test: in the fixture, turn a knob, save, export, load the `.fxb` in Sylenth1 and compare.
- **Memory.** Read the file once, and keep offsets rather than copies, until the user exports.
- **Content.** Presets from commercial packs inside third-party projects are for the user's own use. The UI offers "save" and nothing that shares or uploads.
