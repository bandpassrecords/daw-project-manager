import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/windows_install.dart';

void main() {
  group('isMsixExecutablePath', () {
    test('the Store / .msix install lives under WindowsApps in its own folder',
        () {
      expect(
        isMsixExecutablePath(
          r'C:\Program Files\WindowsApps\BandPassRecords.DAWProjectManager_2.9.2.0_x64__abc123\daw_project_manager.exe',
        ),
        isTrue,
      );
    });

    test("the .exe installer's copy is not packaged", () {
      expect(
        isMsixExecutablePath(
          r'C:\Program Files\DAW Project Manager\daw_project_manager.exe',
        ),
        isFalse,
      );
    });

    test('another package under WindowsApps is not this app', () {
      expect(
        isMsixExecutablePath(
          r'C:\Program Files\WindowsApps\SomeoneElse.App_1.0.0.0_x64__xyz\app.exe',
        ),
        isFalse,
      );
    });
  });

  test('the package name is the one pubspec.yaml packages the app as', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('identity_name: $kMsixPackageName'));
  });

  group('windowsInstallerDownloadUrl', () {
    test('points at the release asset of that version', () {
      expect(
        windowsInstallerDownloadUrl(
          owner: 'bandpassrecords',
          repo: 'daw-project-manager',
          version: '2.9.2',
        ).toString(),
        'https://github.com/bandpassrecords/daw-project-manager/releases/'
        'download/v2.9.2/DAW_Project_Manager_Installer_v2.9.2.exe',
      );
    });

    test('matches the name release.yml uploads the installer as', () {
      // Tags are "v<version>", so the asset is named after "v<version>" too.
      final workflow =
          File('.github/workflows/release.yml').readAsStringSync();
      expect(
        workflow,
        contains(
          r'asset_name: DAW_Project_Manager_Installer_${{ github.ref_name }}.exe',
        ),
      );
    });
  });
}
