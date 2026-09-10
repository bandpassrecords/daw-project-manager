import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_template.dart';
import 'package:daw_project_manager/providers/providers.dart';

ProjectTemplate _makeTemplate({
  required String id,
  String name = 'Song Template',
  String mainFileRelativePath = 'Song Template.als',
  String? musicalKey,
  bool hidden = false,
}) {
  return ProjectTemplate(
    id: id,
    name: name,
    sourceFolderPath: '/Users/artist/Templates/$name',
    mainFileRelativePath: mainFileRelativePath,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    musicalKey: musicalKey,
    hidden: hidden,
  );
}

ProviderContainer _makeContainer(List<ProjectTemplate> templates) {
  return ProviderContainer(
    overrides: [
      projectTemplatesProvider.overrideWith((ref) => Stream.value(templates)),
    ],
  );
}

/// Riverpod 3 pauses stream subscriptions when a provider has no active
/// listener (a bare `read()` call doesn't count) — same requirement as
/// projects_provider_test.dart's `_readProjects`. Holds an active
/// subscription on [projectTemplatesProvider] open until it emits, then
/// releases it so a plain `read` of a derived provider sees fresh data.
Future<T> _afterTemplatesLoaded<T>(
  ProviderContainer c,
  T Function() read,
) async {
  final completer = Completer<void>();
  final sub = c.listen<AsyncValue<List<ProjectTemplate>>>(
    projectTemplatesProvider,
    (_, next) {
      if (next.hasValue && !completer.isCompleted) completer.complete();
    },
    fireImmediately: true,
  );
  await completer.future;
  sub.close();
  return read();
}

void main() {
  // Same three modes as the dashboard's showHiddenProjectsProvider:
  // 0 = visible only (default), 1 = all, 2 = hidden only.
  group('filteredProjectTemplatesProvider — hidden templates', () {
    test('hides hidden templates by default', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'visible'),
        _makeTemplate(id: 'gone', hidden: true),
      ]);
      addTearDown(c.dispose);

      final ids = await _afterTemplatesLoaded(
        c,
        () =>
            c.read(filteredProjectTemplatesProvider).map((t) => t.id).toList(),
      );
      expect(ids, ['visible']);
    });

    test('show-all mode (1) returns both', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'visible'),
        _makeTemplate(id: 'gone', hidden: true),
      ]);
      addTearDown(c.dispose);
      c.read(showHiddenTemplatesProvider.notifier).setShowAll(true);

      final ids = await _afterTemplatesLoaded(
        c,
        () =>
            c.read(filteredProjectTemplatesProvider).map((t) => t.id).toList(),
      );
      expect(ids, ['visible', 'gone']);
    });

    test('hidden-only mode (2) returns just the hidden ones', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'visible'),
        _makeTemplate(id: 'gone', hidden: true),
      ]);
      addTearDown(c.dispose);
      c.read(showHiddenTemplatesProvider.notifier).setShowOnlyHidden(true);

      final ids = await _afterTemplatesLoaded(
        c,
        () =>
            c.read(filteredProjectTemplatesProvider).map((t) => t.id).toList(),
      );
      expect(ids, ['gone']);
    });

    test('search still applies on top of the hidden filter', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'a', name: 'Bass Session', hidden: true),
        _makeTemplate(id: 'b', name: 'Drum Loop', hidden: true),
      ]);
      addTearDown(c.dispose);
      c.read(showHiddenTemplatesProvider.notifier).setShowOnlyHidden(true);
      c.read(templateSearchProvider.notifier).setSearchText('bass');

      final ids = await _afterTemplatesLoaded(
        c,
        () =>
            c.read(filteredProjectTemplatesProvider).map((t) => t.id).toList(),
      );
      expect(ids, ['a']);
    });
  });

  // What the create-project dialog picks from. Kept separate from the
  // templates page's show-hidden mode on purpose: switching that page to
  // "show all" must not start offering put-away templates when creating a
  // project.
  group('visibleProjectTemplatesProvider', () {
    test('excludes hidden templates', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'visible'),
        _makeTemplate(id: 'gone', hidden: true),
      ]);
      addTearDown(c.dispose);

      final ids = await _afterTemplatesLoaded(
        c,
        () => c.read(visibleProjectTemplatesProvider).map((t) => t.id).toList(),
      );
      expect(ids, ['visible']);
    });

    test('is unaffected by the templates page show-hidden mode', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'visible'),
        _makeTemplate(id: 'gone', hidden: true),
      ]);
      addTearDown(c.dispose);
      c.read(showHiddenTemplatesProvider.notifier).setShowAll(true);

      final ids = await _afterTemplatesLoaded(
        c,
        () => c.read(visibleProjectTemplatesProvider).map((t) => t.id).toList(),
      );
      expect(ids, ['visible']);
    });
  });

  group('filteredProjectTemplatesProvider — search text', () {
    test('filters by template name, case-insensitively', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'a', name: 'Bass Session'),
        _makeTemplate(id: 'b', name: 'Drum Loop'),
      ]);
      addTearDown(c.dispose);
      c.read(templateSearchProvider.notifier).setSearchText('bass');

      final ids = await _afterTemplatesLoaded(
        c,
        () =>
            c.read(filteredProjectTemplatesProvider).map((t) => t.id).toList(),
      );
      expect(ids, ['a']);
    });

    test('empty search text returns every template', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'a'),
        _makeTemplate(id: 'b'),
      ]);
      addTearDown(c.dispose);

      final ids = await _afterTemplatesLoaded(
        c,
        () =>
            c.read(filteredProjectTemplatesProvider).map((t) => t.id).toList(),
      );
      expect(ids, ['a', 'b']);
    });
  });

  group('filteredProjectTemplatesProvider — DAW filter', () {
    test('null DAW filter shows every template', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'a', mainFileRelativePath: 'Song.als'),
        _makeTemplate(id: 'b', mainFileRelativePath: 'Song.flp'),
      ]);
      addTearDown(c.dispose);

      final templates = await _afterTemplatesLoaded(
        c,
        () => c.read(filteredProjectTemplatesProvider),
      );
      expect(templates.length, 2);
    });

    test(
      'setting DAW filter = FL Studio returns only .flp templates',
      () async {
        final c = _makeContainer([
          _makeTemplate(id: 'a', mainFileRelativePath: 'Song.als'),
          _makeTemplate(id: 'b', mainFileRelativePath: 'Song.flp'),
          _makeTemplate(id: 'c', mainFileRelativePath: 'Other.flp'),
        ]);
        addTearDown(c.dispose);
        c.read(templateDawFilterProvider.notifier).setDaw('FL Studio');

        final ids = await _afterTemplatesLoaded(
          c,
          () =>
              c.read(filteredProjectTemplatesProvider).map((t) => t.id).toSet(),
        );
        expect(ids, {'b', 'c'});
      },
    );

    test('clear() resets the DAW filter back to showing all', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'a', mainFileRelativePath: 'Song.als'),
        _makeTemplate(id: 'b', mainFileRelativePath: 'Song.flp'),
      ]);
      addTearDown(c.dispose);
      c.read(templateDawFilterProvider.notifier).setDaw('FL Studio');
      expect(
        (await _afterTemplatesLoaded(
          c,
          () => c.read(filteredProjectTemplatesProvider),
        )).length,
        1,
      );

      c.read(templateDawFilterProvider.notifier).clear();
      expect(
        (await _afterTemplatesLoaded(
          c,
          () => c.read(filteredProjectTemplatesProvider),
        )).length,
        2,
      );
    });
  });

  group('filteredProjectTemplatesProvider — Key filter', () {
    test(
      'setting key filter returns only templates with a matching key',
      () async {
        final c = _makeContainer([
          _makeTemplate(id: 'a', musicalKey: 'C#m'),
          _makeTemplate(id: 'b', musicalKey: 'F major'),
        ]);
        addTearDown(c.dispose);
        c.read(templateKeyFilterProvider.notifier).setKey('F major');

        final ids = await _afterTemplatesLoaded(
          c,
          () => c
              .read(filteredProjectTemplatesProvider)
              .map((t) => t.id)
              .toList(),
        );
        expect(ids, ['b']);
      },
    );
  });

  group('filteredProjectTemplatesProvider — combined filters', () {
    test('search text and DAW filter apply together', () async {
      final c = _makeContainer([
        _makeTemplate(
          id: 'a',
          name: 'Bass Idea',
          mainFileRelativePath: 'Bass Idea.als',
        ),
        _makeTemplate(
          id: 'b',
          name: 'Bass Idea',
          mainFileRelativePath: 'Bass Idea.flp',
        ),
        _makeTemplate(
          id: 'c',
          name: 'Drum Idea',
          mainFileRelativePath: 'Drum Idea.als',
        ),
      ]);
      addTearDown(c.dispose);
      c.read(templateSearchProvider.notifier).setSearchText('bass');
      c.read(templateDawFilterProvider.notifier).setDaw('Ableton Live');

      final ids = await _afterTemplatesLoaded(
        c,
        () =>
            c.read(filteredProjectTemplatesProvider).map((t) => t.id).toList(),
      );
      expect(ids, ['a']);
    });
  });

  group('availableTemplateDawsProvider', () {
    test(
      'returns distinct, alphabetically sorted DAW types derived from the main file extension',
      () async {
        final c = _makeContainer([
          _makeTemplate(id: 'a', mainFileRelativePath: 'Song.flp'),
          _makeTemplate(id: 'b', mainFileRelativePath: 'Song.als'),
          _makeTemplate(id: 'c', mainFileRelativePath: 'Other.flp'),
        ]);
        addTearDown(c.dispose);

        final daws = await _afterTemplatesLoaded(
          c,
          () => c.read(availableTemplateDawsProvider),
        );
        expect(daws, ['Ableton Live', 'FL Studio']);
      },
    );

    test('unrecognized extensions are omitted', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'a', mainFileRelativePath: 'Song.als'),
        _makeTemplate(id: 'b', mainFileRelativePath: 'Notes.txt'),
      ]);
      addTearDown(c.dispose);

      final daws = await _afterTemplatesLoaded(
        c,
        () => c.read(availableTemplateDawsProvider),
      );
      expect(daws, ['Ableton Live']);
    });

    test('empty template list returns an empty DAW list', () async {
      final c = _makeContainer([]);
      addTearDown(c.dispose);

      final daws = await _afterTemplatesLoaded(
        c,
        () => c.read(availableTemplateDawsProvider),
      );
      expect(daws, isEmpty);
    });
  });

  group('availableTemplateKeysProvider', () {
    test('returns distinct, alphabetically sorted keys', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'a', musicalKey: 'F major'),
        _makeTemplate(id: 'b', musicalKey: 'C#m'),
        _makeTemplate(id: 'c', musicalKey: 'F major'),
      ]);
      addTearDown(c.dispose);

      final keys = await _afterTemplatesLoaded(
        c,
        () => c.read(availableTemplateKeysProvider),
      );
      expect(keys, ['C#m', 'F major']);
    });

    test('ignores null and empty key values', () async {
      final c = _makeContainer([
        _makeTemplate(id: 'a', musicalKey: 'C#m'),
        _makeTemplate(id: 'b'),
        _makeTemplate(id: 'c', musicalKey: ''),
      ]);
      addTearDown(c.dispose);

      final keys = await _afterTemplatesLoaded(
        c,
        () => c.read(availableTemplateKeysProvider),
      );
      expect(keys, ['C#m']);
    });
  });

  group('TemplateSearchNotifier', () {
    test('setSearchText updates state and clear() resets it', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(templateSearchProvider.notifier).setSearchText('bass');
      expect(c.read(templateSearchProvider), 'bass');

      c.read(templateSearchProvider.notifier).clear();
      expect(c.read(templateSearchProvider), '');
    });
  });
}
