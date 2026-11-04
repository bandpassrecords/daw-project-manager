import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/todo_template.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/todo_templates_page.dart';
import 'package:daw_project_manager/ui/widgets/desktop_title_bar.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUp(() => DesktopTitleBar.debugMacOSOverride = false);
  tearDown(() => DesktopTitleBar.debugMacOSOverride = null);

  testWidgets('the page has the same title bar as the others, and a place '
      'in the breadcrumb trail', (tester) async {
    final container = ProviderContainer(
      overrides: [
        todoTemplatesProvider.overrideWith(
          (ref) => Stream.value(<TodoTemplate>[]),
        ),
      ],
    );
    addTearDown(container.dispose);

    late BuildContext ctx;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Scaffold(
                body: DesktopTitleBar(title: 'Root'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const TodoTemplatesPage()),
    );
    await tester.pumpAndSettle();

    // The page underneath is offstage and not counted.
    expect(find.byType(DesktopTitleBar), findsOneWidget);
    expect(find.byType(AppBar), findsNothing, reason: 'desktop: no AppBar');
    final labels = container
        .read(breadcrumbTrailProvider)
        .map((c) => c.label)
        .toList();
    expect(labels.length, 2);
    expect(labels.first, 'Root');
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
  });
}
