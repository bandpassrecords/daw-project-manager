/// Whether connecting to Google Drive for the first time leaves automatic
/// sync off.
///
/// "Sync when the app starts" is on unless turned off, which suits a device
/// that has been syncing but not one that has just connected: the next launch
/// would upload a library the user has not yet looked at. So a device that
/// has never synced and has no stored choice starts manual; the first-sync
/// dialog then offers automatic sync, unchecked.
///
/// A device that has synced before, or whose user has chosen either way, is
/// left alone.
bool firstConnectionStaysManual({
  required bool syncedBefore,
  required bool startupChoiceStored,
}) => !syncedBefore && !startupChoiceStored;
