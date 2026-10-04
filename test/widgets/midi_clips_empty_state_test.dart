import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/midi_clips_section.dart';

void main() {
  group('midiClipsEmptyState', () {
    test('nothing read yet speaks for all of Project Contents', () {
      expect(
          midiClipsEmptyState(contentsRead: false, canReadFile: true),
          MidiClipsEmptyState.readContents);
      expect(
          midiClipsEmptyState(contentsRead: false, canReadFile: false),
          MidiClipsEmptyState.nothingReadYet);
    });

    test('contents read but no clips stored is about the clips', () {
      expect(midiClipsEmptyState(contentsRead: true, canReadFile: true),
          MidiClipsEmptyState.loadClips);
      expect(midiClipsEmptyState(contentsRead: true, canReadFile: false),
          MidiClipsEmptyState.noClipsStored);
    });
  });

  test('the "MIDI clips" heading shows once anything has been read', () {
    expect(showsMidiClipsHeading(clipsStored: false, contentsRead: false),
        isFalse,
        reason: 'the empty state is about tracks and plug-ins too');
    expect(showsMidiClipsHeading(clipsStored: false, contentsRead: true), isTrue);
    expect(showsMidiClipsHeading(clipsStored: true, contentsRead: false), isTrue);
    expect(showsMidiClipsHeading(clipsStored: true, contentsRead: true), isTrue);
  });

  test('every language has the general Project Contents wording', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final text in [
        l10n.projectContentsRead,
        l10n.projectContentsReadHint,
        l10n.projectContentsNoneRead,
      ]) {
        expect(text.trim(), isNotEmpty, reason: '$locale');
      }
      if (locale != const Locale('en')) {
        final en = await AppLocalizations.delegate.load(const Locale('en'));
        expect(l10n.projectContentsReadHint, isNot(en.projectContentsReadHint),
            reason: '$locale is translated, not the English placeholder');
      }
    }
  });
}
