enum AutoBackupInterval {
  off,
  every30min,
  hourly,
  every6hours,
  daily;

  Duration? get duration {
    switch (this) {
      case AutoBackupInterval.off:
        return null;
      case AutoBackupInterval.every30min:
        return const Duration(minutes: 30);
      case AutoBackupInterval.hourly:
        return const Duration(hours: 1);
      case AutoBackupInterval.every6hours:
        return const Duration(hours: 6);
      case AutoBackupInterval.daily:
        return const Duration(hours: 24);
    }
  }

  static AutoBackupInterval fromStorageKey(String? key) {
    return AutoBackupInterval.values.firstWhere(
      (e) => e.name == key,
      orElse: () => AutoBackupInterval.off,
    );
  }

  /// Whether the interval says to sync now: never when off, otherwise once
  /// it has passed since [lastSync].
  bool isDue({required DateTime? lastSync, required DateTime now}) {
    final every = duration;
    if (every == null) return false;
    if (lastSync == null) return true;
    return now.difference(lastSync) >= every;
  }

  /// Whether automatic sync should run now. At launch, "sync when the app
  /// starts" decides on its own — it is independent of the interval — and a
  /// due interval still counts, as it would on the timer's first tick.
  bool shouldSyncNow({
    required DateTime? lastSync,
    required DateTime now,
    required bool syncOnStartup,
    bool atLaunch = false,
  }) =>
      (atLaunch && syncOnStartup) || isDue(lastSync: lastSync, now: now);

  /// Whether the sync [shouldSyncNow] asks for runs only because the app
  /// started — and so merges only when Drive holds something this device
  /// hasn't seen (`syncDatabase(mergeOnlyIfNewer:)`). A due interval merges
  /// as Sync now does. Every launch used to run the whole sync.
  bool syncsOnlyForLaunch({
    required DateTime? lastSync,
    required DateTime now,
    required bool syncOnStartup,
    bool atLaunch = false,
  }) =>
      atLaunch && syncOnStartup && !isDue(lastSync: lastSync, now: now);

  /// Whether this device syncs on its own at all.
  bool syncsAutomatically({required bool syncOnStartup}) =>
      syncOnStartup || duration != null;
}
