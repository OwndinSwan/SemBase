import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../config/app_config.dart';
import '../database/app_database.dart';
import '../logging/app_log_service.dart';

/// Service managing native Android notification-based class reminders and daily morning briefings
class AlarmNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static const _offsetPrefKey = 'sembase_pre_class_offset_minutes';
  static const _briefingPrefKey = 'sembase_morning_briefing_enabled';
  static const _proximityAlertsPrefKey = 'sembase_proximity_alerts_enabled';
  static const _proximityRadiusPrefKey = 'sembase_proximity_radius_meters';
  static const _lastDismissedBriefingDateKey = 'sembase_last_dismissed_briefing_date';
  static const _lastNotifiedBriefingDateKey = 'sembase_last_notified_briefing_date';

  static const int morningBriefingNotificationId = 99999;
  static const int testNotificationId = 77777;
  static const int proximityNotificationId = 66666;

  // In-memory cache for instant synchronous UI binding
  static int _cachedOffsetMinutes = 15;
  static bool _cachedMorningBriefing = true;
  static bool _cachedProximityAlerts = true;
  static int _cachedProximityRadiusMeters = 75;

  static int get cachedOffsetMinutes => _cachedOffsetMinutes;
  static bool get cachedMorningBriefing => _cachedMorningBriefing;
  static bool get cachedProximityAlerts => _cachedProximityAlerts;
  static int get cachedProximityRadiusMeters => _cachedProximityRadiusMeters;

  /// Returns true if the in-app morning briefing banner should be displayed today.
  /// Conditions:
  /// 1. Morning briefing setting is enabled by the user.
  /// 2. Current time is 7:00 AM or later today.
  /// 3. User has NOT already dismissed today's morning briefing.
  static Future<bool> shouldShowMorningBriefingToday() async {
    if (!_cachedMorningBriefing) return false;
    final now = DateTime.now();

    // Briefing is active from 7:00 AM onwards for the current day
    final today7am = DateTime(now.year, now.month, now.day, AppConfig.morningBriefingHour, AppConfig.morningBriefingMinute);
    if (now.isBefore(today7am)) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lastDismissed = prefs.getString(_lastDismissedBriefingDateKey);

      if (lastDismissed == todayKey) {
        return false; // Already dismissed by user today
      }
    } catch (_) {}

    return true;
  }

  /// Persists that the user dismissed today's morning briefing banner so it stays dismissed until tomorrow.
  static Future<void> dismissTodayMorningBriefing() async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastDismissedBriefingDateKey, todayKey);
      AppLogService.info(
        AppLogService.catAlarm,
        'Morning briefing banner dismissed for today ($todayKey)',
      );
    } catch (e) {
      debugPrint('Error saving briefing dismissal: $e');
    }
  }

  /// Verifies that today's 7:00 AM briefing was active/notified; logs status cleanly
  static Future<void> checkAndCatchUpTodayBriefingNotification() async {
    if (kIsWeb) return;
    if (!_cachedMorningBriefing) return;
    final hasPerm = await checkNotificationPermission();
    if (!hasPerm) return;

    final now = DateTime.now();
    final today7am = DateTime(now.year, now.month, now.day, AppConfig.morningBriefingHour, AppConfig.morningBriefingMinute);
    if (now.isBefore(today7am)) return;

    try {
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getString(_lastNotifiedBriefingDateKey);

      if (lastNotified != todayKey) {
        await prefs.setString(_lastNotifiedBriefingDateKey, todayKey);
        AppLogService.info(
          AppLogService.catAlarm,
          'Morning briefing active for today ($todayKey)',
        );
      }
    } catch (_) {}
  }

  /// Initializes notification channels, Android permissions, and TimeZone data
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize TimeZones with bulletproof device offset matching
      tz_data.initializeTimeZones();
      _setupLocalTimeZone();

      // 2. Load cached preferences from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _cachedOffsetMinutes = prefs.getInt(_offsetPrefKey) ?? AppConfig.preClassAlarmOffset.inMinutes;
      _cachedMorningBriefing = prefs.getBool(_briefingPrefKey) ?? AppConfig.enableMorningScheduleBriefing;
      _cachedProximityAlerts = prefs.getBool(_proximityAlertsPrefKey) ?? true;
      _cachedProximityRadiusMeters = prefs.getInt(_proximityRadiusPrefKey) ?? 75;

      // 3. Initialize Flutter Local Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
          AppLogService.info(
            AppLogService.catAlarm,
            'User opened notification',
            details: 'Payload: ${details.payload}',
          );
        },
      );

      // 4. Create standard notification channels (pure notification based, NOT phone alarms)
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // Delete old channels if upgrading
        await android.deleteNotificationChannel('sembase_class_alarms');
        await android.deleteNotificationChannel('sembase_class_alerts');
        await android.deleteNotificationChannel('sembase_briefings');

        // Notification channel for pre-class reminders (high importance heads-up banner)
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'sembase_class_alerts',
            'Class Reminders',
            description: 'Notification alerts sent before your classes start',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

        // Notification channel for 7:00 AM daily morning briefings
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'sembase_briefings',
            'Daily Morning Briefings',
            description: '7:00 AM daily overview of classes and due tasks',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

        // Notification channel for Proximity & Campus Arrival Alerts
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'sembase_proximity_alerts',
            'Campus & Room Arrival Alerts',
            description: 'Heads-up notification alerts when you arrive near your pinned classroom or campus building',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );
      }

      _isInitialized = true;
      AppLogService.success(
        AppLogService.catAlarm,
        'Notification engine initialized (Notification-based)',
        details: 'Timezone: ${tz.local.name}, Pre-class offset: $_cachedOffsetMinutes mins',
      );
    } catch (e, st) {
      AppLogService.error(
        AppLogService.catAlarm,
        'Failed to initialize notification engine',
        details: '$e\n$st',
      );
    }
  }

  static void _setupLocalTimeZone() {
    final now = DateTime.now();
    final offsetMs = now.timeZoneOffset.inMilliseconds;
    tz.Location? matchedLocation;

    for (final key in tz.timeZoneDatabase.locations.keys) {
      final loc = tz.timeZoneDatabase.locations[key];
      if (loc != null && loc.currentTimeZone.offset == offsetMs) {
        matchedLocation = loc;
        break;
      }
    }

    if (matchedLocation != null) {
      tz.setLocalLocation(matchedLocation);
    } else {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Manila'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  /// Checks if system notifications are currently enabled on device
  static Future<bool> checkNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final android = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final enabled = await android.areNotificationsEnabled();
        return enabled ?? false;
      }
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
    }
    return true;
  }

  /// Requests notification permission from the OS (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final android = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        final isGranted = granted ?? false;
        if (isGranted) {
          AppLogService.success(AppLogService.catPermission, 'POST_NOTIFICATIONS granted by user');
        } else {
          AppLogService.warning(AppLogService.catPermission, 'POST_NOTIFICATIONS denied by user');
        }
        return isGranted;
      }
    } catch (e) {
      AppLogService.error(AppLogService.catPermission, 'Error requesting notification permission', details: '$e');
    }
    return true;
  }

  /// Gets the user-configured pre-class alarm offset in minutes (defaults to 15)
  static Future<int> getAlarmOffsetMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedOffsetMinutes = prefs.getInt(_offsetPrefKey) ?? _cachedOffsetMinutes;
    } catch (_) {}
    return _cachedOffsetMinutes;
  }

  /// Saves the pre-class alarm offset and reschedules all active alarms
  static Future<void> setAlarmOffsetMinutes(int minutes, AppDatabase db) async {
    _cachedOffsetMinutes = minutes;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_offsetPrefKey, minutes);
      AppLogService.info(
        AppLogService.catAlarm,
        'Pre-class alert offset changed to $minutes minutes',
      );
    } catch (e) {
      debugPrint('Error saving alarm offset: $e');
    }
    await syncAllClassAlarms(db);
  }

  /// Checks if 7:00 AM Morning Briefing is enabled (defaults to true)
  static Future<bool> isMorningBriefingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedMorningBriefing = prefs.getBool(_briefingPrefKey) ?? _cachedMorningBriefing;
    } catch (_) {}
    return _cachedMorningBriefing;
  }

  /// Toggles 7:00 AM Morning Briefing
  static Future<void> setMorningBriefingEnabled(bool enabled) async {
    _cachedMorningBriefing = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_briefingPrefKey, enabled);
      AppLogService.info(
        AppLogService.catAlarm,
        '7:00 AM Morning Briefing ${enabled ? "enabled" : "disabled"}',
      );
    } catch (e) {
      debugPrint('Error saving briefing setting: $e');
    }

    if (enabled) {
      await scheduleMorningBriefing();
    } else {
      // Cancel all 30 morning briefing slots
      for (int i = 0; i < 30; i++) {
        await _notificationsPlugin.cancel(morningBriefingNotificationId + i);
      }
      AppLogService.info(AppLogService.catAlarm, 'Cancelled all 30 scheduled morning briefings');
    }
  }

  /// Checks if Proximity Arrival Alerts are enabled
  static Future<bool> isProximityAlertsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedProximityAlerts = prefs.getBool(_proximityAlertsPrefKey) ?? _cachedProximityAlerts;
    } catch (_) {}
    return _cachedProximityAlerts;
  }

  /// Gets Proximity Arrival radius in meters
  static Future<int> getProximityRadiusMeters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedProximityRadiusMeters = prefs.getInt(_proximityRadiusPrefKey) ?? _cachedProximityRadiusMeters;
    } catch (_) {}
    return _cachedProximityRadiusMeters;
  }

  /// Sends an immediate test notification to verify sound, banner, and vibration
  static Future<void> showTestNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'sembase_class_alerts',
      'Class Reminders',
      channelDescription: 'Notification alerts sent before your classes start',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      testNotificationId,
      '🔔 SemBase Notification Test',
      'Class alerts and task reminders are active and working perfectly!',
      platformDetails,
    );

    AppLogService.success(
      AppLogService.catAlarm,
      'Test notification triggered immediately',
      details: 'Channel: sembase_class_alerts (Importance.high)',
    );
  }

  /// Schedules daily morning briefing heads-up notification at 07:00 AM.
  /// Must be called AFTER notification permission is confirmed (not at app startup).
  static Future<void> scheduleMorningBriefing() async {
    if (kIsWeb) return;
    await initialize();

    final isEnabled = await isMorningBriefingEnabled();
    if (!isEnabled) return;

    // Gate on notification permission
    final hasNotifPerm = await checkNotificationPermission();
    if (!hasNotifPerm) {
      AppLogService.warning(
        AppLogService.catAlarm,
        'Morning briefing skipped — POST_NOTIFICATIONS not granted',
      );
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    const androidDetails = AndroidNotificationDetails(
      'sembase_briefings',
      'Daily Morning Briefings',
      channelDescription: '7:00 AM daily overview of classes and due tasks',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    int scheduledDays = 0;
    // Schedule 7:00 AM briefing for each of the next 30 days (1 full month)
    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final briefingTime = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        AppConfig.morningBriefingHour,
        AppConfig.morningBriefingMinute,
        0,
      );

      if (briefingTime.isBefore(now)) continue;

      final notifId = morningBriefingNotificationId + dayOffset;
      await _zonedScheduleWithFallback(
        id: notifId,
        title: '🌅 Good Morning! Today\'s Schedule',
        body: 'Tap to review your class timetable and upcoming tasks for today.',
        triggerTime: briefingTime,
        details: platformDetails,
        debugLabel: 'MorningBriefing+$dayOffset',
      );
      scheduledDays++;
    }

    AppLogService.info(
      AppLogService.catAlarm,
      'Scheduled 7:00 AM daily morning briefings',
      details: 'Total discrete days scheduled: $scheduledDays days ahead',
    );
  }

  /// Synchronizes pre-class notification alerts for all enrolled course schedules.
  static Future<void> syncAllClassAlarms(AppDatabase db) async {
    if (kIsWeb) return;
    await initialize();

    // Gate on notification permission — nothing works without it
    final hasNotifPerm = await checkNotificationPermission();
    if (!hasNotifPerm) {
      AppLogService.warning(
        AppLogService.catAlarm,
        'Class alerts synchronization skipped — POST_NOTIFICATIONS not granted',
      );
      return;
    }

    final offsetMinutes = await getAlarmOffsetMinutes();
    final profile = await db.watchActiveProfile().first;
    if (profile == null) {
      AppLogService.info(AppLogService.catAlarm, 'Alert sync skipped: No active academic profile');
      return;
    }

    final schedules = await db.getAllActiveSchedules(profile.id);

    // Cancel all previously scheduled notifications cleanly
    await _notificationsPlugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final currentMinuteOfDay = now.hour * 60 + now.minute;

    const androidDetails = AndroidNotificationDetails(
      'sembase_class_alerts',
      'Class Reminders',
      channelDescription: 'Notification alerts sent before your classes start',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    int totalAlertsScheduled = 0;
    final scheduledCourses = <String>{};

    for (final item in schedules) {
      if (item.schedule.startMinutes >= item.schedule.endMinutes) continue;

      final targetWeekday = _dayTokenToWeekday(item.schedule.dayToken);
      final classStartMin = item.schedule.startMinutes;

      // Compute exact alert minute before class
      var alertMinuteOfDay = classStartMin - offsetMinutes;
      var weekdayAdjustment = 0;
      if (alertMinuteOfDay < 0) {
        alertMinuteOfDay += 24 * 60;
        weekdayAdjustment = -1;
      }

      final alertHour = (alertMinuteOfDay ~/ 60) % 24;
      final alertMinute = alertMinuteOfDay % 60;

      // Find the next occurrence of target weekday
      int targetDay = targetWeekday + weekdayAdjustment;
      int baseDaysUntil = (targetDay - now.weekday) % 7;
      if (baseDaysUntil < 0) baseDaysUntil += 7;

      // If scheduled day is today, check if alert minute today has already passed
      if (baseDaysUntil == 0 && alertMinuteOfDay <= currentMinuteOfDay) {
        baseDaysUntil = 7;
      }

      final roomStr = item.schedule.roomCode.isNotEmpty ? item.schedule.roomCode : 'TBA';
      final sessionType = item.schedule.sessionType.toUpperCase();

      // Schedule notification alerts for each of the next 4 weeks
      for (int week = 0; week < 4; week++) {
        final daysUntil = baseDaysUntil + (week * 7);
        final targetDate = now.add(Duration(days: daysUntil));
        final triggerTime = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          alertHour,
          alertMinute,
          0,
        );

        if (triggerTime.isBefore(now)) continue;

        // Deterministic ID per (courseId, dayToken, weekIndex)
        final deterministicId = 10000 +
            ((item.schedule.courseId.hashCode ^
                        item.schedule.dayToken.hashCode ^
                        week)
                    .abs() %
                5000);

        await _zonedScheduleWithFallback(
          id: deterministicId,
          title: '🔔 ${item.course.courseCode} in $offsetMinutes mins',
          body: '${item.course.courseTitle}\n📍 Room: $roomStr [$sessionType]',
          triggerTime: triggerTime,
          details: platformDetails,
          debugLabel: item.course.courseCode,
        );
        totalAlertsScheduled++;
        scheduledCourses.add(item.course.courseCode);
      }
    }

    AppLogService.success(
      AppLogService.catAlarm,
      'Pre-class notification alerts synchronized',
      details: 'Scheduled $totalAlertsScheduled discrete notifications across 30 days for: ${scheduledCourses.join(", ")} (Offset: $offsetMinutes mins)',
    );

    // Reschedule morning briefing — cancelAll() above wiped those slots too
    await scheduleMorningBriefing();
  }

  /// Schedules a notification using standard notification scheduling with graceful fallback
  static Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime triggerTime,
    required NotificationDetails details,
    String? debugLabel,
  }) async {
    // Try exact notification first
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        triggerTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[ExactNotification] ${debugLabel ?? id} @ $triggerTime (id: $id)');
      return;
    } catch (_) {}

    // Fallback 1: inexactAllowWhileIdle
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        triggerTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[InexactAllowWhileIdle] ${debugLabel ?? id} @ $triggerTime (id: $id)');
      return;
    } catch (_) {}

    // Fallback 2: inexact standard background notification
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        triggerTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[Inexact] ${debugLabel ?? id} @ $triggerTime (id: $id)');
    } catch (e) {
      AppLogService.error(
        AppLogService.catAlarm,
        'Failed to schedule notification for ${debugLabel ?? id}',
        details: 'Trigger: $triggerTime, Error: $e',
      );
    }
  }

  static int _dayTokenToWeekday(String dayToken) {
    switch (dayToken.toUpperCase()) {
      case 'M':
        return DateTime.monday;
      case 'T':
        return DateTime.tuesday;
      case 'W':
        return DateTime.wednesday;
      case 'TH':
        return DateTime.thursday;
      case 'F':
        return DateTime.friday;
      case 'S':
        return DateTime.saturday;
      default:
        return DateTime.monday;
    }
  }

  static const MethodChannel _settingsChannel = MethodChannel('com.classbase.sembase/settings');

  /// Checks if the app is currently exempt from battery optimizations
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final bool? isIgnoring = await _settingsChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return isIgnoring ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system Battery Optimization / App Settings page
  static Future<void> openBatteryOptimizationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      AppLogService.info(AppLogService.catPermission, 'Opening Android Battery Optimization settings');
      await _settingsChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      AppLogService.error(
        AppLogService.catPermission,
        'Failed to open battery optimization settings',
        details: '$e',
      );
    }
  }

  /// Sets whether proximity arrival alerts are enabled
  static Future<void> setProximityAlertsEnabled(bool enabled) async {
    _cachedProximityAlerts = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_proximityAlertsPrefKey, enabled);
      AppLogService.info(
        AppLogService.catAlarm,
        'Proximity arrival alerts ${enabled ? "enabled" : "disabled"}',
      );
    } catch (_) {}
  }

  /// Sets proximity arrival alert trigger radius (meters)
  static Future<void> setProximityRadiusMeters(int radiusMeters) async {
    _cachedProximityRadiusMeters = radiusMeters;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_proximityRadiusPrefKey, radiusMeters);
      AppLogService.info(
        AppLogService.catAlarm,
        'Proximity arrival radius set to $radiusMeters meters',
      );
    } catch (_) {}
  }

  /// Displays an instant high-priority arrival notification for campus / classroom geofence
  static Future<void> showProximityArrivalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_cachedProximityAlerts) return;
    final hasPerm = await checkNotificationPermission();
    if (!hasPerm) return;

    const androidDetails = AndroidNotificationDetails(
      'sembase_proximity_alerts',
      'Campus & Room Arrival Alerts',
      channelDescription: 'Heads-up notification alerts when you arrive near your pinned classroom or campus building',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.locationSharing,
      visibility: NotificationVisibility.public,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        proximityNotificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      AppLogService.success(
        AppLogService.catAlarm,
        'Fired proximity arrival alert',
        details: '$title - $body',
      );
    } catch (e) {
      AppLogService.error(
        AppLogService.catAlarm,
        'Failed to show proximity arrival alert',
        details: '$e',
      );
    }
  }
}

