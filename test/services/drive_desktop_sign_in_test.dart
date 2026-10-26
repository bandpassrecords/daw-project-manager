import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';

/// The desktop loopback sign-in, with the browser stood in for: these never
/// reach Google, only the local server the browser redirects back to.
void main() {
  final port = GoogleDriveSyncService.loopbackPort;

  Future<String> redirectBack(Map<String, String> query) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.http('127.0.0.1:$port', '/', query),
      );
      final response = await request.close();
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  test('cancelling while the browser is open returns null and frees the port',
      () async {
    // The bug: nothing could stop the wait, so closing the browser tab left
    // the sync page spinning with every button disabled.
    final service = GoogleDriveSyncService();
    final signIn = service.signInDesktopWithLoopback(openBrowser: (_) async {
      return true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(service.isWaitingForBrowser, isTrue);

    service.cancelDesktopSignIn();

    expect(await signIn, isNull);
    expect(service.isWaitingForBrowser, isFalse);
    // The port is free again for the next try.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    await server.close();
  });

  test('gives up after the timeout', () async {
    final service = GoogleDriveSyncService();
    await expectLater(
      service.signInDesktopWithLoopback(
        timeout: const Duration(milliseconds: 100),
        openBrowser: (_) async => true,
      ),
      throwsA(isA<DesktopSignInException>().having(
        (e) => e.failure,
        'failure',
        DesktopSignInFailure.timedOut,
      )),
    );
  });

  test('says so when the port is taken', () async {
    // Used to come back as a bare "cancelled or failed".
    final blocker = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    try {
      await expectLater(
        GoogleDriveSyncService().signInDesktopWithLoopback(
          openBrowser: (_) async => true,
        ),
        throwsA(isA<DesktopSignInException>().having(
          (e) => e.failure,
          'failure',
          DesktopSignInFailure.portInUse,
        )),
      );
    } finally {
      await blocker.close();
    }
  });

  test('says so when no browser opens', () async {
    await expectLater(
      GoogleDriveSyncService().signInDesktopWithLoopback(
        openBrowser: (_) async => false,
      ),
      throwsA(isA<DesktopSignInException>().having(
        (e) => e.failure,
        'failure',
        DesktopSignInFailure.browserUnavailable,
      )),
    );
  });

  test('a refusal in the browser returns null and shows the page in the '
      "user's language", () async {
    final opened = Completer<Uri>();
    final signIn = GoogleDriveSyncService().signInDesktopWithLoopback(
      pageTexts: const LoopbackPageTexts(
        successHeading: 'Anmeldung erfolgreich',
        successMessage: '-',
        cancelledHeading: 'Anmeldung abgebrochen',
        cancelledMessage: '-',
        errorHeading: 'Etwas ist schiefgelaufen',
        errorMessage: '-',
      ),
      openBrowser: (url) async {
        opened.complete(url);
        return true;
      },
    );
    final authUrl = await opened.future;
    expect(authUrl.queryParameters['redirect_uri'], 'http://127.0.0.1:$port/');

    final page = await redirectBack({
      'error': 'access_denied',
      'state': authUrl.queryParameters['state']!,
    });

    expect(page, contains('Anmeldung abgebrochen'));
    expect(await signIn, isNull);
  });

  // Any web page can send the browser to the loopback port. A code or an
  // error that doesn't carry this sign-in's state is not Google's answer:
  // ending the wait on it let any page cancel a sign-in.
  for (final forged in [
    {'code': 'attacker-code', 'state': 'guessed'},
    {'error': 'access_denied', 'state': 'guessed'},
    {'code': 'attacker-code'},
  ]) {
    test('a callback with the wrong state ($forged) is turned away and the wait goes on',
        () async {
      final service = GoogleDriveSyncService();
      final signIn = service.signInDesktopWithLoopback(openBrowser: (_) async => true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await redirectBack(forged);

      expect(service.isWaitingForBrowser, isTrue);
      service.cancelDesktopSignIn();
      expect(await signIn, isNull);
    });
  }

  // Randomness itself can't be asserted; that it comes from Random.secure
  // rather than the clock is read in _generateState.
  test('each sign-in has a state of its own', () async {
    Future<String> stateOfOneSignIn() async {
      final opened = Completer<Uri>();
      final service = GoogleDriveSyncService();
      final signIn = service.signInDesktopWithLoopback(openBrowser: (url) async {
        opened.complete(url);
        return true;
      });
      final state = (await opened.future).queryParameters['state']!;
      service.cancelDesktopSignIn();
      await signIn;
      return state;
    }

    final first = await stateOfOneSignIn();
    final second = await stateOfOneSignIn();
    expect(first, isNot(second));
    // 32 bytes, base64url without padding.
    expect(first.length, 43);
  });

  test('a stray request (a favicon) does not end the wait', () async {
    final service = GoogleDriveSyncService();
    final signIn = service.signInDesktopWithLoopback(
      openBrowser: (_) async => true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/favicon.ico'),
    );
    await (await request.close()).drain<void>();
    client.close();

    expect(service.isWaitingForBrowser, isTrue);
    service.cancelDesktopSignIn();
    expect(await signIn, isNull);
  });
}
