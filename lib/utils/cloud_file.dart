import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;

/// Windows file attributes a cloud provider (OneDrive, Proton Drive, Google
/// Drive for desktop…) sets on a file that is only a placeholder here: its
/// contents come down the moment something reads them.
const _recallOnOpen = 0x40000;
const _recallOnDataAccess = 0x400000;
const _offline = 0x1000;
const _invalidAttributes = 0xFFFFFFFF;

/// Whether these attributes mark a cloud placeholder.
bool attributesSayCloudOnly(int attributes) =>
    attributes != _invalidAttributes &&
    attributes & (_recallOnOpen | _recallOnDataAccess | _offline) != 0;

/// Whether [path] is a cloud placeholder whose contents aren't on this
/// computer — reading it would download all of it. Asked of the file's
/// attributes only, which never downloads anything. Windows only: false
/// elsewhere, where a read just happens.
bool isCloudOnlyFile(String path) {
  if (!Platform.isWindows) return false;
  final native = path.toNativeUtf16();
  try {
    return attributesSayCloudOnly(
      win32.GetFileAttributes(win32.PCWSTR(native)).value,
    );
  } finally {
    calloc.free(native);
  }
}
