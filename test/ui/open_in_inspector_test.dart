import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/project_inspector_page.dart';
import 'package:daw_project_manager/utils/cloud_file.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

void main() {
  group('attributesSayCloudOnly', () {
    test('placeholders: recall on open, recall on data access, offline', () {
      expect(attributesSayCloudOnly(0x40000), isTrue);
      expect(attributesSayCloudOnly(0x400000 | 0x20), isTrue);
      expect(attributesSayCloudOnly(0x1000), isTrue);
    });

    test('a file that is here, pinned or not, is not', () {
      expect(attributesSayCloudOnly(0x20), isFalse, reason: 'archive');
      expect(attributesSayCloudOnly(0x80000 | 0x20), isFalse,
          reason: 'pinned: always kept on this computer');
      expect(attributesSayCloudOnly(0xFFFFFFFF), isFalse,
          reason: 'no attributes: the file is not there to download');
    });
  });

  group('openInInspector', () {
    late Directory dir;
    late String project;
    late String notAProject;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('open_in_inspector');
      project = p.join(dir.path, 'Song.cpr');
      File(project).writeAsBytesSync(List.filled(10, 0));
      notAProject = p.join(dir.path, 'notes.txt');
      File(notAProject).writeAsStringSync('hi');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    Future<(ProviderContainer, BuildContext, WidgetRef)> host(
        WidgetTester tester) async {
      late BuildContext context;
      late WidgetRef widgetRef;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(builder: (c, ref, _) {
              context = c;
              widgetRef = ref;
              return const SizedBox.expand();
            }),
          ),
        ),
      ));
      return (container, context, widgetRef);
    }

    testWidgets('a project opens with the size and time it has, and the tab '
        'is asked for', (tester) async {
      final (container, context, ref) = await host(tester);
      final requests = container.read(inspectorShowRequestProvider);

      final opened = await openInInspector(context, ref, project);

      expect(opened, isTrue);
      final file = container.read(inspectorFileProvider)!;
      final stat = File(project).statSync();
      expect(file, (
        path: project,
        size: 10,
        modifiedMs: stat.modified.millisecondsSinceEpoch,
      ));
      expect(container.read(inspectorShowRequestProvider), requests + 1);
    });

    testWidgets('a file that is no project is refused with a note',
        (tester) async {
      final (container, context, ref) = await host(tester);
      final opened = await openInInspector(context, ref, notAProject);
      await tester.pump();
      expect(opened, isFalse);
      expect(container.read(inspectorFileProvider), isNull);
      expect(find.textContaining('.txt'), findsOneWidget);
      // The snackbar times out on its own.
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('a project that is gone is refused too', (tester) async {
      final (container, context, ref) = await host(tester);
      final opened =
          await openInInspector(context, ref, p.join(dir.path, 'Gone.cpr'));
      expect(opened, isFalse);
      expect(container.read(inspectorFileProvider), isNull);
      await tester.pump(const Duration(seconds: 10));
    });
  });
}
