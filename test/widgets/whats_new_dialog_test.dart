import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/services/changelog_service.dart';
import 'package:daw_project_manager/ui/widgets/whats_new_dialog.dart';

ChangelogRelease _release(
  String version,
  List<String> en, {
  Map<String, List<String>> extra = const {},
}) =>
    ChangelogRelease(
      version: version,
      date: DateTime(2026, 9, 22),
      highlightsByLocale: {'en': en, ...extra},
    );

/// Pumps the view directly — no Hive, no asset bundle, no providers. The
/// "which entries does this launch show" half lives in
/// `changelog_service_test.dart`; what matters here is what reaches the
/// screen and which button did what.
Future<void> _pumpView(
  WidgetTester tester, {
  required List<ChangelogRelease> releases,
  String localeCode = 'en',
  Locale? locale,
  VoidCallback? onClose,
  VoidCallback? onViewFullChangelog,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: WhatsNewView(
        releases: releases,
        localeCode: localeCode,
        onClose: onClose ?? () {},
        onViewFullChangelog: onViewFullChangelog,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every highlight of the one release', (tester) async {
    await _pumpView(
      tester,
      releases: [
        _release('2.9.0', ['First thing changed', 'Second thing changed']),
      ],
    );

    expect(find.text('First thing changed'), findsOneWidget);
    expect(find.text('Second thing changed'), findsOneWidget);
  });

  testWidgets('puts the version in the title for a single release',
      (tester) async {
    await _pumpView(tester, releases: [_release('2.9.0', ['A change'])]);

    expect(find.textContaining('2.9.0'), findsOneWidget);
  });

  testWidgets('shows a heading per version when several were skipped',
      (tester) async {
    // Someone who skipped a version should be able to tell what arrived when,
    // rather than getting one undifferentiated list.
    await _pumpView(
      tester,
      releases: [
        _release('2.9.0', ['Newest change']),
        _release('2.8.0', ['Older change']),
      ],
    );

    expect(find.textContaining('2.9.0'), findsOneWidget);
    expect(find.textContaining('2.8.0'), findsOneWidget);
    expect(find.text('Newest change'), findsOneWidget);
    expect(find.text('Older change'), findsOneWidget);
  });

  testWidgets('shows the requested locale\'s highlight text', (tester) async {
    await _pumpView(
      tester,
      localeCode: 'pt',
      releases: [
        _release('2.9.0', ['English line'], extra: {
          'pt': ['Linha em português'],
        }),
      ],
    );

    expect(find.text('Linha em português'), findsOneWidget);
    expect(find.text('English line'), findsNothing);
  });

  testWidgets('falls back to English for an untranslated locale',
      (tester) async {
    await _pumpView(
      tester,
      localeCode: 'ja',
      releases: [_release('2.9.0', ['English line'])],
    );

    expect(find.text('English line'), findsOneWidget);
  });

  testWidgets('the dismiss button calls onClose', (tester) async {
    var closed = false;
    await _pumpView(
      tester,
      releases: [_release('2.9.0', ['A change'])],
      onClose: () => closed = true,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('offers the full changelog when a callback is given',
      (tester) async {
    var opened = false;
    await _pumpView(
      tester,
      releases: [_release('2.9.0', ['A change'])],
      onViewFullChangelog: () => opened = true,
    );

    await tester.tap(find.byType(TextButton));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('hides the full-changelog button when there is nowhere to go',
      (tester) async {
    await _pumpView(tester, releases: [_release('2.9.0', ['A change'])]);

    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('renders in a non-English UI locale without overflowing',
      (tester) async {
    // The chrome is localized even though the highlight text is data; this
    // catches a missing ARB key in one locale.
    await _pumpView(
      tester,
      locale: const Locale('pt'),
      localeCode: 'pt',
      releases: [
        _release('2.9.0', ['English'], extra: {
          'pt': ['Uma mudança'],
        }),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Uma mudança'), findsOneWidget);
  });
}
