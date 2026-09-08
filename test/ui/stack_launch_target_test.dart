import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/session_actions.dart';

import '../helpers/test_factories.dart';

/// Which version of a stack "Launch in DAW" opens (#94).
///
/// A stack has no file of its own, so a launch has to be redirected to one of
/// its versions before anything touches `filePath`. Null means "ask".
void main() {
  MusicProject member(String id) => TestFactories.makeProject(id: id);

  test('opens the nominated default without asking', () {
    expect(
      resolveStackLaunchTarget(
        defaultLaunchMemberId: 'v2',
        members: [member('v1'), member('v2'), member('v3')],
      )?.id,
      'v2',
    );
  });

  test('asks when no default has been nominated', () {
    expect(
      resolveStackLaunchTarget(
        defaultLaunchMemberId: null,
        members: [member('v1'), member('v2')],
      ),
      isNull,
    );
  });

  test('asks when the nominated default is no longer a member', () {
    // A nominated member can be removed from the stack or deleted outright.
    // Opening a stale id would open the wrong version, or nothing at all.
    expect(
      resolveStackLaunchTarget(
        defaultLaunchMemberId: 'deleted',
        members: [member('v1'), member('v2')],
      ),
      isNull,
    );
  });

  test('a lone surviving version opens without a pointless prompt', () {
    expect(
      resolveStackLaunchTarget(
        defaultLaunchMemberId: 'deleted',
        members: [member('v1')],
      )?.id,
      'v1',
    );
  });

  test('an empty stack has nothing to open', () {
    expect(
      resolveStackLaunchTarget(defaultLaunchMemberId: 'v1', members: []),
      isNull,
    );
  });
}
