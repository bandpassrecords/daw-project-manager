import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_preferences.dart';
import '../models/music_project.dart';
import '../models/release.dart';
import '../utils/app_paths.dart';
import 'deadline_notification_plan.dart';
import 'linux_portal_notifier.dart';

/// Service for managing deadline notifications
/// Based on working implementation from Retro1 app
class DeadlineNotificationService {
  static final DeadlineNotificationService _instance = DeadlineNotificationService._internal();
  factory DeadlineNotificationService() => _instance;
  DeadlineNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Box<NotificationPreferences>? _preferencesBox;
  bool _isInitialized = false;
  bool _isDesktopInitialized = false;

  static const _workTimerNotifId = 9999;
  static const _simpleNotifId = 9998;

  /// Registers the AUMID and COM activator CLSID in the Windows registry so
  /// that WinRT toast notifications (flutter_local_notifications) display the
  /// correct app icon in the notification header row.
  ///
  /// Three keys are needed:
  ///   1. CLSID\{guid}  — names the COM activator class
  ///   2. CLSID\{guid}\LocalServer32 — exe path the activator resolves to
  ///   3. AppUserModelId\{aumid}     — ties icon, name and activator together
  void _registerWindowsAumid() {
    try {
      final exe = Platform.resolvedExecutable;
      final exeDir = File(exe).parent.path;
      // Build path with OS separator to avoid mixed-slash issues.
      final iconPath = '$exeDir${Platform.pathSeparator}data'
          '${Platform.pathSeparator}flutter_assets'
          '${Platform.pathSeparator}app_icon.png';

      const guid   = '{a3c9f2e1-4b87-4d6a-9e05-2c1d8f3b7a94}';
      const aumid  = 'BandPassRecords.DAWProjectManager';
      const clsid  = r'HKCU\Software\Classes\CLSID\' + guid;
      const aumKey = r'HKCU\Software\Classes\AppUserModelId\' + aumid;

      // 1. CLSID root — display name
      Process.run('reg', ['add', clsid, '/ve', '/t', 'REG_SZ', '/d', 'DAW Project Manager', '/f']);
      // 2. LocalServer32 — path to the executable
      Process.run('reg', ['add', '$clsid\\LocalServer32', '/ve', '/t', 'REG_SZ', '/d', exe, '/f']);
      // 3. AUMID — display name, icon, and pointer to the COM activator
      Process.run('reg', ['add', aumKey, '/v', 'DisplayName',     '/t', 'REG_SZ', '/d', 'DAW Project Manager', '/f']);
      Process.run('reg', ['add', aumKey, '/v', 'IconUri',         '/t', 'REG_SZ', '/d', iconPath, '/f']);
      Process.run('reg', ['add', aumKey, '/v', 'CustomActivator', '/t', 'REG_SZ', '/d', guid, '/f']);
    } catch (_) {}
  }

  /// Initialize notifications on desktop (Windows/macOS/Linux).
  /// Safe to call multiple times — no-ops after first success.
  Future<void> initializeDesktop() async {
    if (_isDesktopInitialized || Platform.isAndroid || Platform.isIOS) return;

    // Linux shows notifications via LinuxPortalNotifier (org.freedesktop.
    // portal.Notification) instead of this plugin — see
    // showWorkTimerNotification/showSimpleNotification below — so there's
    // nothing of this plugin's to initialize here. Its Linux backend talks
    // to org.freedesktop.Notifications directly, bypassing the portal.
    if (Platform.isLinux) {
      _isDesktopInitialized = true;
      return;
    }

    try {
      if (Platform.isWindows) _registerWindowsAumid();

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: 'DAW Project Manager',
        appUserModelId: 'BandPassRecords.DAWProjectManager',
        guid: 'a3c9f2e1-4b87-4d6a-9e05-2c1d8f3b7a94',
      );
      const initSettings = InitializationSettings(
        macOS: darwinSettings,
        windows: windowsSettings,
      );
      await _notifications.initialize(settings: initSettings);
      _isDesktopInitialized = true;

      if (Platform.isMacOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: false, sound: false);
      }
    } catch (e) {
      if (kDebugMode) print('[DeadlineNotification] Desktop init failed: $e');
    }
  }

  /// Show a work-session reminder notification on any platform.
  /// [body] is the pre-localised notification body string.
  Future<void> showWorkTimerNotification(String projectName, String body) async {
    if (Platform.isLinux) {
      await LinuxPortalNotifier.show(title: projectName, body: body);
      return;
    }
    if (!Platform.isAndroid && !_isDesktopInitialized) {
      await initializeDesktop();
    }
    try {
      const androidDetails = AndroidNotificationDetails(
        'work_timer',
        'Work Timer',
        channelDescription: 'Work session time reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );
      // No custom image — the header icon comes from the AUMID registry entry
      // registered in _registerWindowsAumid() at startup.
      const windowsDetails = WindowsNotificationDetails();
      final notifDetails = NotificationDetails(
        android: androidDetails,
        macOS: darwinDetails,
        iOS: darwinDetails,
        windows: windowsDetails,
      );
      await _notifications.show(
        id: _workTimerNotifId,
        title: projectName,
        body: body,
        notificationDetails: notifDetails,
      );
    } catch (e) {
      if (kDebugMode) print('[DeadlineNotification] Work timer notification failed: $e');
    }
  }

  /// Show a plain one-off notification on any platform (title + body, no
  /// tap payload). Used e.g. for the one-time "still running in the tray"
  /// notice. Kept separate from the work-timer notification so they don't
  /// overwrite each other (distinct notification ids/channels).
  Future<void> showSimpleNotification(String title, String body) async {
    if (Platform.isLinux) {
      await LinuxPortalNotifier.show(title: title, body: body);
      return;
    }
    if (!Platform.isAndroid && !_isDesktopInitialized) {
      await initializeDesktop();
    }
    try {
      const androidDetails = AndroidNotificationDetails(
        'general',
        'General',
        channelDescription: 'General app notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );
      // No custom image — the header icon comes from the AUMID registry entry
      // registered in _registerWindowsAumid() at startup.
      const windowsDetails = WindowsNotificationDetails();
      final notifDetails = NotificationDetails(
        android: androidDetails,
        macOS: darwinDetails,
        iOS: darwinDetails,
        windows: windowsDetails,
      );
      await _notifications.show(
        id: _simpleNotifId,
        title: title,
        body: body,
        notificationDetails: notifDetails,
      );
    } catch (e) {
      if (kDebugMode) print('[DeadlineNotification] Simple notification failed: $e');
    }
  }

  /// Callback for when notification is tapped
  Function(String projectId)? _onNotificationTapCallback;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!Platform.isAndroid) {
      if (kDebugMode) print('[DeadlineNotification] Not on Android, skipping initialization');
      return;
    }

    try {
      if (kDebugMode) print('[DeadlineNotification] Initializing...');
      
      // 1. Initialize timezones first
      tz.initializeTimeZones();
      
      // 2. Configure local system timezone
      await _configureTimezone();
      
      // 3. Configure plugin initialization (Android only)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      final initialized = await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      if (kDebugMode) print('[DeadlineNotification] Plugin initialized: $initialized');

      if (initialized != true) {
        if (kDebugMode) print('[DeadlineNotification] WARNING: Plugin initialization failed');
        return;
      }

      // 4. Request permissions
      await _requestPermissions();

      // 5. Initialize preferences storage
      await ensureHiveInitialized();
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(NotificationPreferencesAdapter());
      }
      _preferencesBox = await Hive.openBox<NotificationPreferences>('notification_preferences');

      _isInitialized = true;
      if (kDebugMode) print('[DeadlineNotification] Initialization complete');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DeadlineNotification] ERROR initializing: $e');
        print('[DeadlineNotification] Stack trace: $stackTrace');
      }
    }
  }

  /// Configure timezone based on system offset
  Future<void> _configureTimezone() async {
    try {
      // Get system offset
      final systemOffset = DateTime.now().timeZoneOffset;
      final offsetHours = systemOffset.inHours;
      final offsetMinutes = systemOffset.inMinutes % 60;
      
      if (kDebugMode) {
        print('[DeadlineNotification] System timezone offset: $systemOffset (${offsetHours >= 0 ? '+' : ''}$offsetHours:${offsetMinutes.toString().padLeft(2, '0')})');
      }
      
      // Map offset to real IANA timezone (better DST support than Etc/GMT)
      final timezoneMap = {
        0: 'UTC',
        1: 'Europe/Paris',      // UTC+1 (CET/CEST)
        -1: 'Atlantic/Azores',   // UTC-1
        2: 'Europe/Berlin',      // UTC+2 (CEST)
        -2: 'Atlantic/South_Georgia', // UTC-2
        3: 'Europe/Moscow',      // UTC+3
        -3: 'America/Sao_Paulo', // UTC-3 (BRT)
        4: 'Asia/Dubai',         // UTC+4
        -4: 'America/New_York',  // UTC-4 (EDT) or UTC-5 (EST)
        5: 'Asia/Karachi',       // UTC+5
        -5: 'America/Chicago',   // UTC-5 (CDT) or UTC-6 (CST)
        -6: 'America/Denver',    // UTC-6 (MDT) or UTC-7 (MST)
        -7: 'America/Los_Angeles', // UTC-7 (PDT) or UTC-8 (PST)
        8: 'Asia/Shanghai',      // UTC+8
        -8: 'Pacific/Pitcairn',  // UTC-8
        9: 'Asia/Tokyo',         // UTC+9
        -9: 'Pacific/Gambier',   // UTC-9
        10: 'Australia/Sydney',  // UTC+10 (AEDT) or UTC+11 (AEST)
        -10: 'Pacific/Honolulu', // UTC-10
      };
      
      // Try to use timezone based on offset
      final suggestedTimezone = timezoneMap[offsetHours];
      if (suggestedTimezone != null) {
        try {
          final suggestedLocation = tz.getLocation(suggestedTimezone);
          tz.setLocalLocation(suggestedLocation);
          final suggestedOffset = suggestedLocation.currentTimeZone.offset;
          final suggestedOffsetHours = suggestedOffset.inHours;
          if (kDebugMode) {
            print('[DeadlineNotification] Set timezone to: $suggestedTimezone (offset: $suggestedOffset seconds, $suggestedOffsetHours hours)');
          }
        } catch (e) {
          if (kDebugMode) print('[DeadlineNotification] Could not set suggested timezone $suggestedTimezone: $e');
          _setTimezoneByOffset(offsetHours);
        }
      } else {
        // If no mapping, use Etc/GMT based on offset
        _setTimezoneByOffset(offsetHours);
      }
      
      // Verify timezone was configured correctly
      final localLocation = tz.local;
      final locationOffset = localLocation.currentTimeZone.offset;
      final locationOffsetHours = locationOffset.inHours;
      
      if (kDebugMode) {
        print('[DeadlineNotification] Configured timezone: ${localLocation.name}');
        print('[DeadlineNotification] Configured timezone offset: $locationOffset seconds ($locationOffsetHours hours)');
      }
      
      // Check if offset matches system (allow 1 hour difference for DST)
      final offsetDiff = (locationOffsetHours - offsetHours).abs();
      if (offsetDiff > 1) {
        if (kDebugMode) {
          print('[DeadlineNotification] WARNING: Timezone offset mismatch! System: $offsetHours, Configured: $locationOffsetHours');
          print('[DeadlineNotification] Attempting to fix...');
        }
        _setTimezoneByOffset(offsetHours);
        
        // Check again after correction
        final correctedLocation = tz.local;
        final correctedOffset = correctedLocation.currentTimeZone.offset;
        final correctedOffsetHours = correctedOffset ~/ 3600;
        if (kDebugMode) {
          print('[DeadlineNotification] After correction - Timezone: ${correctedLocation.name}, Offset: $correctedOffset seconds ($correctedOffsetHours hours)');
        }
      } else {
        if (kDebugMode) {
          print('[DeadlineNotification] Timezone configured correctly (offset difference: $offsetDiff hours, may be due to DST)');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[DeadlineNotification] WARNING: Could not configure local timezone: $e');
      // Fallback to UTC if cannot detect
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
        if (kDebugMode) print('[DeadlineNotification] Fallback to UTC timezone');
      } catch (e2) {
        if (kDebugMode) print('[DeadlineNotification] ERROR setting UTC timezone: $e2');
      }
    }
  }

  /// Helper to configure timezone based on offset
  void _setTimezoneByOffset(int offsetHours) {
    try {
      // Etc/GMT uses inverted sign: GMT+1 = Etc/GMT-1
      String timezoneName;
      if (offsetHours == 0) {
        timezoneName = 'UTC';
      } else if (offsetHours > 0) {
        timezoneName = 'Etc/GMT-$offsetHours';
      } else {
        timezoneName = 'Etc/GMT+${-offsetHours}';
      }
      
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      if (kDebugMode) print('[DeadlineNotification] Set timezone to: $timezoneName (offset: $offsetHours)');
    } catch (e) {
      if (kDebugMode) print('[DeadlineNotification] ERROR setting timezone by offset: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Request notification permission (Android 13+)
        final notificationPermission = await androidPlugin.requestNotificationsPermission();
        if (kDebugMode) print('[DeadlineNotification] Notification permission granted: $notificationPermission');
        
        // Check if notifications are enabled
        final areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
        if (kDebugMode) print('[DeadlineNotification] Are notifications enabled: $areNotificationsEnabled');
        
        if (areNotificationsEnabled == false) {
          if (kDebugMode) print('[DeadlineNotification] WARNING: Notifications are disabled in system settings');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[DeadlineNotification] ERROR requesting permissions: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) print('[DeadlineNotification] Notification tapped: ${response.payload}');
    if (response.payload != null && _onNotificationTapCallback != null) {
      _onNotificationTapCallback!(response.payload!);
    }
  }

  /// Set callback for notification taps
  void setOnNotificationTapCallback(Function(String projectId) callback) {
    _onNotificationTapCallback = callback;
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    if (_preferencesBox == null) {
      await initialize();
    }
    
    if (_preferencesBox != null && _preferencesBox!.isNotEmpty) {
      return _preferencesBox!.values.first;
    }
    
    return NotificationPreferences.getDefault();
  }

  /// Save notification preferences
  Future<void> savePreferences(NotificationPreferences preferences) async {
    if (_preferencesBox == null) {
      await initialize();
    }
    
    if (_preferencesBox != null) {
      await _preferencesBox!.clear();
      await _preferencesBox!.add(preferences);
      
      if (kDebugMode) print('[DeadlineNotification] Notification preferences saved');
    }
  }

  /// Schedule all deadline notifications — project deadlines and per-todo due
  /// dates alike, both driven by the one set of notification preferences.
  ///
  /// What gets scheduled is decided by the pure [planDeadlineNotifications];
  /// this method only turns that plan into platform calls.
  Future<void> scheduleAllDeadlineNotifications({
    List<MusicProject>? projects,
    List<Release>? releases,
  }) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      if (kDebugMode) print('[DeadlineNotification] Scheduling deadline notifications...');

      final preferences = await getPreferences();
      if (!preferences.enabled) {
        await _notifications.cancelAll();
        if (kDebugMode) print('[DeadlineNotification] Notifications disabled, cancelled all');
        return;
      }

      // Cancel existing notifications first
      await _notifications.cancelAll();

      if ((projects == null || projects.isEmpty) &&
          (releases == null || releases.isEmpty)) {
        if (kDebugMode) print('[DeadlineNotification] No projects provided');
        return;
      }

      // Get current time in local timezone
      final systemNow = DateTime.now();
      final now = tz.TZDateTime.now(tz.local);

      if (kDebugMode) {
        print('[DeadlineNotification] System time: $systemNow (offset: ${systemNow.timeZoneOffset})');
        print('[DeadlineNotification] Local timezone time: $now');
        print('[DeadlineNotification] Local timezone: ${tz.local.name}');
        final localOffset = tz.local.currentTimeZone.offset;
        final localOffsetHours = localOffset ~/ 3600;
        print('[DeadlineNotification] Local timezone offset: $localOffset seconds ($localOffsetHours hours)');
      }

      final occurrences = planDeadlineNotifications(
        preferences: preferences,
        now: systemNow,
        projects: projects ?? const [],
        releases: releases ?? const [],
      );

      int scheduledCount = 0;

      for (final occurrence in occurrences) {
        // The plan is wall-clock; anchor it in the local zone here.
        final scheduledDate = tz.TZDateTime(
          tz.local,
          occurrence.scheduledDate.year,
          occurrence.scheduledDate.month,
          occurrence.scheduledDate.day,
          occurrence.scheduledDate.hour,
          occurrence.scheduledDate.minute,
        );
        if (!scheduledDate.isAfter(now)) continue;

        await _scheduleOccurrence(
          occurrence: occurrence,
          scheduledDate: scheduledDate,
        );
        scheduledCount++;
      }

      // Verify pending notifications after scheduling
      await Future.delayed(const Duration(milliseconds: 500));
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      
      if (kDebugMode) {
        print('[DeadlineNotification] Total notifications scheduled: $scheduledCount');
        print('[DeadlineNotification] Total pending notifications: ${pendingNotifications.length}');
        for (var notif in pendingNotifications) {
          print('[DeadlineNotification]   - ID: ${notif.id}, Title: ${notif.title}');
        }
        print('[DeadlineNotification] Notifications scheduled successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DeadlineNotification] ERROR scheduling notifications: $e');
        print('[DeadlineNotification] Stack trace: $stackTrace');
      }
    }
  }

  /// Schedule one planned occurrence — a project deadline or a todo due date.
  Future<void> _scheduleOccurrence({
    required DeadlineNotificationOccurrence occurrence,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
      final notificationId = occurrence.notificationId;
      final title = notificationTitleFor(occurrence);
      final body = notificationBodyFor(occurrence);

      if (kDebugMode) {
        print('[DeadlineNotification] Scheduling notification for ${occurrence.ownerName}: $scheduledDate (day offset: ${occurrence.daysRemaining})');
      }

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        'deadline_reminders',
        'Deadline Reminders',
        channelDescription: 'Notifications for project deadlines',
        icon: 'ic_notification',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      final details = NotificationDetails(android: androidDetails);

      // Schedule notification (inexact - no special permission required)
      await _notifications.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: occurrence.ownerId,
      );

      if (kDebugMode) {
        print('[DeadlineNotification] Notification scheduled successfully for day ${occurrence.daysRemaining}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DeadlineNotification] ERROR scheduling notification: $e');
        print('[DeadlineNotification] Stack trace: $stackTrace');
      }
    }
  }

  /// Send a test notification immediately
  Future<void> sendTestNotification() async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      if (kDebugMode) print('[DeadlineNotification] Sending test notification...');
      
      final androidDetails = AndroidNotificationDetails(
        'deadline_reminders',
        'Deadline Reminders',
        channelDescription: 'Notifications for project deadlines',
        icon: 'ic_notification',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      final details = NotificationDetails(android: androidDetails);

      await _notifications.show(
        id: 999999,
        title: '🧪 Test Notification',
        body: 'If you\'re seeing this, notifications are working!',
        notificationDetails: details,
      );
      
      if (kDebugMode) print('[DeadlineNotification] Test notification sent successfully');
    } catch (e) {
      if (kDebugMode) print('[DeadlineNotification] ERROR sending test notification: $e');
      rethrow;
    }
  }

  /// Schedule a test notification in the future
  Future<void> scheduleTestNotification({int secondsFromNow = 30}) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(Duration(seconds: secondsFromNow));
      
      if (kDebugMode) {
        print('[DeadlineNotification] Scheduling test notification...');
        print('[DeadlineNotification] Current time: $now');
        print('[DeadlineNotification] Scheduled for: $scheduledTime');
        print('[DeadlineNotification] In $secondsFromNow seconds');
      }

      final androidDetails = AndroidNotificationDetails(
        'deadline_reminders',
        'Deadline Reminders',
        channelDescription: 'Notifications for project deadlines',
        icon: 'ic_notification',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      final details = NotificationDetails(android: androidDetails);

      await _notifications.zonedSchedule(
        id: 999998,
        title: '🧪 Test Notification ($secondsFromNow sec)',
        body: 'If you see this, notifications are working! Scheduled at ${now.hour}:${now.minute}:${now.second}',
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'test',
      );

      if (kDebugMode) {
        print('[DeadlineNotification] Test notification scheduled successfully!');
        print('[DeadlineNotification] ID: 999998');
        print('[DeadlineNotification] Scheduled for: $scheduledTime');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DeadlineNotification] ERROR scheduling test notification: $e');
        print('[DeadlineNotification] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!Platform.isAndroid || !_isInitialized) return;
    
    if (kDebugMode) print('[DeadlineNotification] Cancelling all notifications...');
    await _notifications.cancelAll();
    if (kDebugMode) print('[DeadlineNotification] All notifications cancelled');
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!Platform.isAndroid || !_isInitialized) return [];
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final enabled = await androidImpl.areNotificationsEnabled();
        return enabled ?? false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('[DeadlineNotification] Error checking notification status: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('[DeadlineNotification] Error requesting notification permissions: $e');
      return false;
    }
  }
}
