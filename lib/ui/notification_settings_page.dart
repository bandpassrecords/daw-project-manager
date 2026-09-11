import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/notification_preferences.dart';
import '../services/deadline_notification_service.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import 'widgets/desktop_title_bar.dart';

/// Page for configuring deadline notification preferences
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  final _notificationService = DeadlineNotificationService();
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkPermissions();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _notificationService.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = prefs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _notificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() => _hasPermission = hasPermission);
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestPermissions();
    if (mounted) {
      setState(() => _hasPermission = granted);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.notificationPermissionDenied),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.settings,
              onPressed: () {
                // Open app settings
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    try {
      await _notificationService.savePreferences(_preferences!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notificationSettingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingSettings)),
        );
      }
    }
  }

  bool get _isMobile => MobileUtils.isMobile();

  @override
  Widget build(BuildContext context) {
    if (_isLoading && Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.notificationSettings),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final listView = ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
          // ── Work Session Reminders (desktop only) ───────────────────────
          if (!Platform.isAndroid && !Platform.isIOS)
            WorkTimerSection(l10n: l10n),

          if (Platform.isAndroid) ...[
          const Divider(height: 32),
          // Permission status
          if (!_hasPermission)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: Text(AppLocalizations.of(context)!.notificationPermissionRequired),
                subtitle: Text(AppLocalizations.of(context)!.notificationPermissionDescription),
                trailing: ElevatedButton(
                  onPressed: _requestPermissions,
                  child: Text(AppLocalizations.of(context)!.enable),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Enable/Disable notifications
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.enableDeadlineNotifications),
            subtitle: Text(AppLocalizations.of(context)!.receiveRemindersForDeadlines),
            value: _preferences?.enabled ?? true,
            onChanged: _hasPermission
                ? (value) {
                    setState(() {
                      _preferences = _preferences?.copyWith(enabled: value) ??
                          NotificationPreferences(enabled: value);
                    });
                  }
                : null,
          ),

          const Divider(),

          // Notification time
          ListTile(
            title: Text(AppLocalizations.of(context)!.notificationTime),
            subtitle: Text(
              AppLocalizations.of(context)!.timeToReceiveNotifications,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(_preferences?.notificationHour ?? 9).toString().padLeft(2, '0')}:${(_preferences?.notificationMinute ?? 0).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: (_hasPermission && (_preferences?.enabled ?? true))
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (_hasPermission && (_preferences?.enabled ?? true))
                  Icon(
                    Icons.access_time,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            enabled: _hasPermission && (_preferences?.enabled ?? true),
            onTap: (_hasPermission && (_preferences?.enabled ?? true))
                ? () => _showTimePicker(context)
                : null,
          ),

          const Divider(),

          // Reminder days
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.reminderDays,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.selectDaysBeforeDeadline,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildReminderChip(1),
                    _buildReminderChip(3),
                    _buildReminderChip(7),
                    _buildReminderChip(14),
                    _buildReminderChip(30),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Notify on deadline day
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.notifyOnDeadlineDay),
            subtitle: Text(AppLocalizations.of(context)!.receiveNotificationOnDeadlineDay),
            value: _preferences?.notifyOnDeadlineDay ?? true,
            onChanged: _hasPermission && (_preferences?.enabled ?? true)
                ? (value) {
                    setState(() {
                      _preferences = _preferences?.copyWith(notifyOnDeadlineDay: value) ??
                          NotificationPreferences(notifyOnDeadlineDay: value);
                    });
                  }
                : null,
          ),

          const SizedBox(height: 32),

          // Help text
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.howItWorks,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.deadlineNotificationsHelp,
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
          ),

          // Debug section (only visible in debug mode)
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '🧪 Debug Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.notificationTestTitle,
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.notifications_active),
                            label: Text(AppLocalizations.of(context)!.notificationSendNow),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _hasPermission
                                ? () async {
                                    try {
                                      await _notificationService.sendTestNotification();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.notificationTestSent),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.notificationTestError(e.toString())),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.schedule),
                            label: Text(AppLocalizations.of(context)!.notificationSchedule30s),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _hasPermission
                                ? () async {
                                    try {
                                      await _notificationService.scheduleTestNotification(secondsFromNow: 30);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.notificationTestScheduled),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.notificationTestError(e.toString())),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.info_outline),
                            label: Text(AppLocalizations.of(context)!.notificationShowDebugInfo),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade500,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final pending = await _notificationService.getPendingNotifications();
                              final enabled = await _notificationService.areNotificationsEnabled();
                              
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.notificationDebugTitle),
                                    content: SingleChildScrollView(
                                      child: SelectableText(
                                        '📊 Notification System Status\n'
                                        '══════════════════════════════════\n'
                                        '✓ Notifications enabled: $enabled\n'
                                        '📬 Pending notifications: ${pending.length}\n\n'
                                        'Pending notifications:\n'
                                        '${pending.isEmpty ? "No notifications scheduled" : pending.map((n) => "• ${n.title}\n  ${n.body}").join("\n\n")}',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(AppLocalizations.of(context)!.close),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLocalizations.of(context)!.notificationRescheduleAll),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _hasPermission
                                ? () async {
                                    try {
                                      if (kDebugMode) {
                                        print('\n🔄 Re-scheduling all notifications...');
                                      }
                                      
                                      final projectRepo = await ref.read(repositoryProvider.future);
                                      final projects = projectRepo.getAllProjects();
                                      
                                      if (kDebugMode) {
                                        print('📦 Total projects: ${projects.length}');
                                      }
                                      
                                      await _notificationService.scheduleAllDeadlineNotifications(
                                        projects: projects,
                                        releases: projectRepo.getAllReleases(),
                                      );
                                      
                                      final pending = await _notificationService.getPendingNotifications();
                                      
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('✅ Scheduled ${pending.length} notifications (check console for details)'),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (kDebugMode) {
                                        print('❌ Error re-scheduling: $e');
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.notificationTestError(e.toString())),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '⚠️ EMULATOR WARNING',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scheduled notifications often DON\'T WORK on Android emulators!\n\n'
                            '✅ TEST ON A REAL DEVICE for accurate results!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '📋 Check console logs for detailed information.\n'
                      '⚡ Disable battery optimization for best results.\n'
                      '🔔 Ensure notifications are enabled in settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ], // closes if (Platform.isAndroid)
        ],
    );
    return Scaffold(
      appBar: _isMobile ? AppBar(
        title: Text(l10n.notificationSettings),
        actions: [
          if (Platform.isAndroid)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePreferences,
              tooltip: l10n.save,
            ),
        ],
      ) : null,
      body: Column(
        children: [
          DesktopTitleBar(title: l10n.notificationSettings, showBack: true),
          Expanded(child: listView),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final currentHour = _preferences?.notificationHour ?? 9;
    final currentMinute = _preferences?.notificationMinute ?? 0;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _preferences = _preferences?.copyWith(
          notificationHour: picked.hour,
          notificationMinute: picked.minute,
        ) ?? NotificationPreferences(
          notificationHour: picked.hour,
          notificationMinute: picked.minute,
        );
      });
    }
  }

  Widget _buildReminderChip(int days) {
    // ignore: dead_code — this method is only called from the Android branch
    final isSelected = _preferences?.reminderDays.contains(days) ?? false;
    final isEnabled = _hasPermission && (_preferences?.enabled ?? true);
    final l10n = AppLocalizations.of(context)!;

    return FilterChip(
      label: Text(days == 1 ? l10n.oneDay : l10n.xDays(days)),
      selected: isSelected,
      onSelected: isEnabled
          ? (selected) {
              setState(() {
                final currentDays = List<int>.from(_preferences?.reminderDays ?? [1, 3, 7, 14]);
                if (selected) {
                  currentDays.add(days);
                } else {
                  currentDays.remove(days);
                }
                currentDays.sort();
                _preferences = _preferences?.copyWith(reminderDays: currentDays) ??
                    NotificationPreferences(reminderDays: currentDays);
              });
            }
          : null,
    );
  }
}

/// Work timer notification settings — shown on all platforms. Also embedded
/// directly as the "Notifications" section of the desktop SettingsPage.
class WorkTimerSection extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  const WorkTimerSection({super.key, required this.l10n});

  @override
  ConsumerState<WorkTimerSection> createState() => _WorkTimerSectionState();
}

class _WorkTimerSectionState extends ConsumerState<WorkTimerSection> {
  static const _intervalSeconds = [900, 1800, 2700, 3600, 5400, 7200];
  static const _customSentinel = -1;

  AppLocalizations get l10n => widget.l10n;

  String _label(int seconds) {
    final m = seconds ~/ 60;
    return '$m ${l10n.minutes}';
  }

  Future<void> _showCustomDialog(int currentInterval) async {
    final isCurrentCustom = !_intervalSeconds.contains(currentInterval);
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => _CustomIntervalDialog(
        initialMinutes: isCurrentCustom ? currentInterval ~/ 60 : 0,
        l10n: l10n,
      ),
    );
    if (result != null && mounted) {
      ref.read(workTimerNotifIntervalProvider.notifier).set(result);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await DeadlineNotificationService().showWorkTimerNotification(
        l10n.testNotificationTitle,
        l10n.testNotificationBody,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationTestSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationTestError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionModeOn = ref.watch(sessionModeProvider);
    final enabled = ref.watch(workTimerNotifEnabledProvider);
    final interval = ref.watch(workTimerNotifIntervalProvider);
    final isCustom = !_intervalSeconds.contains(interval);
    final dropdownValue = isCustom ? _customSentinel : interval;
    final controlsEnabled = sessionModeOn && enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.timer_outlined),
          title: Text(l10n.workTimerSection,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            sessionModeOn ? l10n.workTimerSectionDesc : l10n.workTimerRequiresSessionMode,
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: sessionModeOn ? 1.0 : 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.workTimerEnabled),
                value: enabled,
                onChanged: sessionModeOn
                    ? (v) => ref.read(workTimerNotifEnabledProvider.notifier).set(v)
                    : null,
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: controlsEnabled ? 1.0 : 0.4,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.workTimerIntervalLabel),
                  trailing: DropdownButton<int>(
                    value: dropdownValue,
                    underline: const SizedBox.shrink(),
                    selectedItemBuilder: (_) => [
                      ..._intervalSeconds.map(
                        (s) => Align(alignment: Alignment.centerLeft, child: Text(_label(s))),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(isCustom ? _label(interval) : l10n.customInterval),
                      ),
                    ],
                    items: [
                      ..._intervalSeconds.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(_label(s)),
                          )),
                      DropdownMenuItem(
                        value: _customSentinel,
                        child: Text(l10n.customInterval),
                      ),
                    ],
                    onChanged: controlsEnabled
                        ? (v) {
                            if (v == _customSentinel) {
                              _showCustomDialog(interval);
                            } else if (v != null) {
                              ref.read(workTimerNotifIntervalProvider.notifier).set(v);
                            }
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _sendTestNotification,
            icon: const Icon(Icons.notifications_active_outlined, size: 16),
            label: Text(l10n.sendTestNotification),
          ),
        ),
      ],
    );
  }
}

class _CustomIntervalDialog extends StatefulWidget {
  final int initialMinutes;
  final AppLocalizations l10n;

  const _CustomIntervalDialog({required this.initialMinutes, required this.l10n});

  @override
  State<_CustomIntervalDialog> createState() => _CustomIntervalDialogState();
}

class _CustomIntervalDialogState extends State<_CustomIntervalDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialMinutes > 0 ? widget.initialMinutes.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.customInterval),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.minutes,
          suffixText: l10n.minutes,
        ),
        autofocus: true,
        onSubmitted: (_) {
          final m = int.tryParse(_controller.text.trim());
          if (m != null && m > 0) Navigator.of(context).pop(m * 60);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final m = int.tryParse(_controller.text.trim());
            if (m != null && m > 0) Navigator.of(context).pop(m * 60);
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
