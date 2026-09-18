import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../logging/app_log_service.dart';
import '../services/subscription_service.dart';
import '../utils/time_formatter.dart';

enum SyncEventType { pushed, pulled, error }

class SyncNotificationEvent {
  final SyncEventType type;
  final String message;
  final int recordCount;
  final DateTime timestamp;

  SyncNotificationEvent({
    required this.type,
    required this.message,
    this.recordCount = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Transactional Outbox Sync Worker
/// Processes local mutations in strict FIFO order with immediate debounced triggers,
/// multi-device bidirectional sync (including deletions and LWW conflict resolution),
/// schema sanitization, dead-letter cleanup, and local archive isolation.
class SyncOutboxWorker {
  final AppDatabase db;
  bool _isProcessing = false;
  bool _wasOffline = true;
  Timer? _pollingTimer;
  Timer? _debounceTimer;
  RealtimeChannel? _realtimeChannel;

  static SyncOutboxWorker? instance;
  static const _autoSyncPrefKey = 'sembase_auto_sync_mode_enabled';
  static bool _cachedAutoSync = true;

  /// Global broadcast stream for sync notifications across the app
  static final StreamController<SyncNotificationEvent> syncEvents = StreamController<SyncNotificationEvent>.broadcast();

  /// Real-time connectivity and sync status notifiers
  static final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isAutoSyncEnabledNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<DateTime?> lastSyncedAtNotifier = ValueNotifier<DateTime?>(null);
  static final ValueNotifier<String> syncStatusTextNotifier = ValueNotifier<String>('Idle');

  SyncOutboxWorker(this.db) {
    instance = this;
    AppDatabase.onMutationEnqueued = triggerDebouncedSync;
  }

  /// Proactively flushes pending mutations within 400ms when Auto Sync is on
  void triggerDebouncedSync() {
    if (!_cachedAutoSync) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      processPendingMutations();
    });
  }

  /// Checks if active internet is reachable
  static Future<bool> hasInternetConnection() async {
    try {
      final res = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      final online = res.isNotEmpty && res[0].rawAddress.isNotEmpty;
      isOnlineNotifier.value = online;
      return online;
    } catch (_) {
      isOnlineNotifier.value = false;
      return false;
    }
  }

  /// Checks whether Auto Sync mode is enabled (defaults to true)
  static Future<bool> isAutoSyncEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedAutoSync = prefs.getBool(_autoSyncPrefKey) ?? true;
      isAutoSyncEnabledNotifier.value = _cachedAutoSync;
    } catch (_) {}
    return _cachedAutoSync;
  }

  /// Toggles Auto Sync vs Manual Mode
  static Future<void> setAutoSyncEnabled(bool enabled) async {
    _cachedAutoSync = enabled;
    isAutoSyncEnabledNotifier.value = enabled;
    syncStatusTextNotifier.value = enabled ? 'Auto Sync Mode' : 'Manual Mode';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoSyncPrefKey, enabled);
      AppLogService.info(
        AppLogService.catSync,
        'Cloud sync mode updated: ${enabled ? "Auto Sync (Real-time)" : "Manual Mode (Push/Pull)"}',
      );
      if (enabled) {
        instance?.processPendingMutations();
      }
    } catch (_) {}
  }

  /// Starts the background sync listener with auto internet reconnection detection & Realtime WebSockets
  void start() {
    _pollingTimer?.cancel();
    
    // Check mode and process pending outbox mutations on startup if auto-sync is on
    isAutoSyncEnabled().then((autoSync) {
      if (autoSync) {
        processPendingMutations().then((_) {
          _initRealtimeIfAuthenticated();
        });
      }
    });
    
    // Initial connectivity check
    hasInternetConnection();

    // Polls every 15 seconds: flushes pending mutations when online AND auto-sync is enabled
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!_cachedAutoSync) return; // In manual mode, do not auto-poll or auto-push in background
      final isOnline = await hasInternetConnection();
      if (isOnline) {
        if (_wasOffline) {
          _wasOffline = false;
          await processPendingMutations();
          _initRealtimeIfAuthenticated();
        } else {
          await processPendingMutations();
        }
      } else {
        _wasOffline = true;
      }
    });
  }

  void _initRealtimeIfAuthenticated() async {
    if (!_cachedAutoSync) return;
    try {
      final isPro = await SubscriptionService.isPro();
      if (!isPro) {
        _realtimeChannel?.unsubscribe();
        return;
      }
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user.id.isNotEmpty) {
        _subscribeToRealtimeChanges(session.user.id);
      }
    } catch (_) {}
  }

  void _subscribeToRealtimeChanges(String userId) {
    if (!_cachedAutoSync) return;
    try {
      final supabase = Supabase.instance.client;
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = supabase.channel('public:multi-device-$userId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'course_tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!_cachedAutoSync) return;
            debugPrint('⚡ Realtime task update: ${payload.eventType}');
            pullCloudDataToLocalDatabase(force: false);
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'course_schedules',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!_cachedAutoSync) return;
            debugPrint('⚡ Realtime schedule update: ${payload.eventType}');
            pullCloudDataToLocalDatabase(force: false);
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'courses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!_cachedAutoSync) return;
            debugPrint('⚡ Realtime course update: ${payload.eventType}');
            pullCloudDataToLocalDatabase(force: false);
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'course_metadata',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!_cachedAutoSync) return;
            debugPrint('⚡ Realtime faculty/metadata update: ${payload.eventType}');
            pullCloudDataToLocalDatabase(force: false);
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'academic_profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!_cachedAutoSync) return;
            debugPrint('⚡ Realtime profile update: ${payload.eventType}');
            pullCloudDataToLocalDatabase(force: false);
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'campus_pins',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!_cachedAutoSync) return;
            debugPrint('⚡ Realtime campus pin update: ${payload.eventType}');
            pullCloudDataToLocalDatabase(force: false);
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('Realtime subscription error: $e');
    }
  }

  void stop() {
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _realtimeChannel?.unsubscribe();
  }

  /// Processes pending mutations with immediate execution, schema sanitization, and dead-letter cleanup
  Future<void> processPendingMutations() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final isPro = await SubscriptionService.isPro();
      if (!isPro) {
        // Free plan / Guest: Cloud sync is strictly disabled
        _realtimeChannel?.unsubscribe();
        isSyncingNotifier.value = false;
        syncStatusTextNotifier.value = 'Offline Vault (Free)';
        return;
      }

      final pendingList = await db.getPendingMutations(limit: 50);
      if (pendingList.isEmpty) {
        if (syncStatusTextNotifier.value == 'Syncing...' || syncStatusTextNotifier.value == 'Idle') {
          syncStatusTextNotifier.value = 'Up to date';
        }
        return;
      }

      isSyncingNotifier.value = true;
      syncStatusTextNotifier.value = 'Syncing...';

      // Check if Supabase client is initialized and user is authenticated
      final SupabaseClient supabase;
      final Session? session;
      try {
        supabase = Supabase.instance.client;
        session = supabase.auth.currentSession;
      } catch (_) {
        return;
      }

      if (session == null || session.user.id.isEmpty) {
        // Guest user: skip cloud sync entirely
        return;
      }

      final userId = session.user.id;
      int pushedCount = 0;

      for (final mutation in pendingList) {
        bool success = false;
        try {
          final payload = jsonDecode(mutation.payload) as Map<String, dynamic>;
          // Inject authenticated user_id for Row Level Security
          payload['user_id'] = userId;

          // Schema Sanitization (removes unsupported schema columns like courses on academic_profiles)
          if (mutation.targetTable == 'academic_profiles') {
            payload.remove('courses');
            payload.remove('courseList');
          }

          switch (mutation.operation.toUpperCase()) {
            case 'INSERT':
            case 'UPDATE':
            case 'UPSERT':
              await supabase
                  .from(mutation.targetTable)
                  .upsert(payload);
              success = true;
              break;
            case 'DELETE':
              if (payload.containsKey('id')) {
                await supabase
                    .from(mutation.targetTable)
                    .delete()
                    .eq('id', payload['id']);
                success = true;
              }
              break;
          }
        } catch (e) {
          debugPrint('Sync mutation error for queue ID ${mutation.queueId}: $e');
          AppLogService.error(
            AppLogService.catSync,
            'Failed to push mutation (${mutation.operation} on ${mutation.targetTable})',
            details: 'Queue ID: ${mutation.queueId}, Error: $e',
          );
          // If the mutation has failed 3+ times or is an unrecoverable schema mismatch, discard dead letter
          if (mutation.retryCount >= 3 || e.toString().contains('PGRST204') || e.toString().contains('PGRST200')) {
            await db.removeMutation(mutation.queueId);
            AppLogService.warning(
              AppLogService.catSync,
              'Discarded unprocessable mutation from queue ID ${mutation.queueId}',
            );
          } else {
            await db.incrementRetryCount(mutation.queueId);
          }
        }

        if (success) {
          await db.removeMutation(mutation.queueId);
          pushedCount++;
        }
      }

      if (pushedCount > 0) {
        AppLogService.success(
          AppLogService.catSync,
          'Pushed $pushedCount outbox mutations to cloud',
        );
        lastSyncedAtNotifier.value = DateTime.now();
        syncStatusTextNotifier.value = 'Synced with Cloud';
        syncEvents.add(SyncNotificationEvent(
          type: SyncEventType.pushed,
          message: 'Auto synced $pushedCount updates to cloud',
          recordCount: pushedCount,
        ));
      } else {
        syncStatusTextNotifier.value = 'Up to date';
      }
    } catch (e) {
      AppLogService.error(
        AppLogService.catSync,
        'Outbox worker synchronization exception',
        details: '$e',
      );
      syncStatusTextNotifier.value = 'Sync Error';
    } finally {
      _isProcessing = false;
      isSyncingNotifier.value = false;
    }
  }

  /// Pushes all active (unarchived) local academic data to Supabase
  /// Archived past schedules remain safely local on device and are never pushed.
  Future<int> syncAllLocalDataToCloud() async {
    isSyncingNotifier.value = true;
    syncStatusTextNotifier.value = 'Pushing to Cloud...';

    try {
      // 1. Process any pending mutations in the queue first
      await processPendingMutations();

      final isPro = await SubscriptionService.isPro();
      if (!isPro) {
        isSyncingNotifier.value = false;
        syncStatusTextNotifier.value = 'Free Plan (Cloud Sync Pro Feature)';
        AppLogService.warning(AppLogService.catSync, 'Cloud push blocked: Pro subscription required.');
        return 0;
      }

      final SupabaseClient supabase;
      final Session? session;
      try {
        supabase = Supabase.instance.client;
        session = supabase.auth.currentSession;
      } catch (_) {
        isSyncingNotifier.value = false;
        syncStatusTextNotifier.value = 'Cloud Unavailable';
        return 0;
      }

      if (session == null || session.user.id.isEmpty) {
        isSyncingNotifier.value = false;
        syncStatusTextNotifier.value = 'Guest Mode (No Cloud)';
        return 0;
      }

      final userId = session.user.id;
      int syncedCount = 0;

      // 1. Sync Active Academic Profile Only
      final activeProfile = await db.watchActiveProfile().first;
      if (activeProfile == null) {
        isSyncingNotifier.value = false;
        syncStatusTextNotifier.value = 'No Active Profile';
        return 0;
      }

      await supabase.from('academic_profiles').upsert({
        'id': activeProfile.id,
        'user_id': userId,
        'student_no': activeProfile.studentNo,
        'section': activeProfile.section,
        'school_year': activeProfile.schoolYear,
        'semester': activeProfile.semester,
        'total_units': activeProfile.totalUnits,
        'updated_at': activeProfile.updatedAt.toIso8601String(),
      });
      syncedCount++;

      // 2. Sync Active Courses Only (exclude archived)
      final allCourses = await db.getCoursesForProfile(activeProfile.id, includeArchived: false);
      final activeCourseIds = allCourses.map((c) => c.id).toSet();

      for (final c in allCourses) {
        await supabase.from('courses').upsert({
          'id': c.id,
          'profile_id': c.profileId,
          'user_id': userId,
          'course_code': c.courseCode,
          'course_title': c.courseTitle,
          'lec_units': c.lecUnits,
          'lab_units': c.labUnits,
          'is_archived': false,
        });
        syncedCount++;
      }

      // 3. Sync Active Course Schedules
      final schedules = await db.getAllActiveSchedules(activeProfile.id);
      for (final s in schedules) {
        await supabase.from('course_schedules').upsert({
          'id': s.schedule.id,
          'course_id': s.schedule.courseId,
          'user_id': userId,
          'day_token': s.schedule.dayToken,
          'start_minutes': s.schedule.startMinutes,
          'end_minutes': s.schedule.endMinutes,
          'room_code': s.schedule.roomCode,
          'session_type': s.schedule.sessionType,
          'is_tba': s.schedule.isTba,
        });
        syncedCount++;
      }

      // 4. Sync Course Tasks for active courses
      final allTasks = await db.getAllTasksList();
      final activeTasks = allTasks.where((t) => activeCourseIds.contains(t.courseId));
      for (final t in activeTasks) {
        await supabase.from('course_tasks').upsert({
          'id': t.id,
          'course_id': t.courseId,
          'user_id': userId,
          'title': t.title,
          'details': t.details,
          'task_type': t.taskType,
          'is_completed': t.isCompleted,
          'due_date': t.dueDate != null ? TimeFormatter.normalizeDueDate(t.dueDate)?.toIso8601String() : null,
          'updated_at': t.updatedAt.toIso8601String(),
        });
        syncedCount++;
      }

      // 5. Sync Course Metadata for active courses
      final allMetadata = await db.getAllMetadataList();
      final activeMetadata = allMetadata.where((m) => activeCourseIds.contains(m.courseId));
      for (final m in activeMetadata) {
        await supabase.from('course_metadata').upsert({
          'id': m.id,
          'course_id': m.courseId,
          'user_id': userId,
          'classroom_url': m.classroomUrl,
          'lms_url': m.lmsUrl,
          'prof_name': m.profName,
          'prof_email': m.profEmail,
          'consultation_hours': m.consultationHours,
        });
        syncedCount++;
      }

      // 6. Sync Campus Building / Room POI Pins
      final allPins = await db.getCampusPins(activeProfile.id);
      for (final p in allPins) {
        await supabase.from('campus_pins').upsert({
          'id': p.id,
          'profile_id': p.profileId,
          'user_id': userId,
          'room_code': p.roomCode,
          'building_name': p.buildingName,
          'latitude': p.latitude,
          'longitude': p.longitude,
          'pin_color': p.pinColor,
          'created_at': p.createdAt.toIso8601String(),
          'updated_at': p.updatedAt.toIso8601String(),
        });
        syncedCount++;
      }

      lastSyncedAtNotifier.value = DateTime.now();
      syncStatusTextNotifier.value = 'Push Complete ($syncedCount items)';

      if (syncedCount > 0) {
        AppLogService.success(
          AppLogService.catSync,
          'Local active schedule pushed to cloud ($syncedCount records)',
        );
        syncEvents.add(SyncNotificationEvent(
          type: SyncEventType.pushed,
          message: 'Saved $syncedCount active schedule records to cloud',
          recordCount: syncedCount,
        ));
      }

      return syncedCount;
    } catch (e) {
      AppLogService.error(
        AppLogService.catSync,
        'Manual cloud push failed',
        details: '$e',
      );
      syncStatusTextNotifier.value = 'Push Error';
      rethrow;
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// Pulls remote cloud data into local SQLite database with bidirectional conflict & deletion handling
  Future<int> pullCloudDataToLocalDatabase({bool force = false}) async {
    final isPro = await SubscriptionService.isPro();
    if (!isPro) {
      isSyncingNotifier.value = false;
      syncStatusTextNotifier.value = 'Free Plan (Cloud Sync Pro Feature)';
      AppLogService.warning(AppLogService.catSync, 'Cloud pull blocked: Pro subscription required.');
      return 0;
    }

    isSyncingNotifier.value = true;
    syncStatusTextNotifier.value = 'Checking Cloud Updates...';

    final SupabaseClient supabase;
    final Session? session;
    try {
      supabase = Supabase.instance.client;
      session = supabase.auth.currentSession;
    } catch (_) {
      isSyncingNotifier.value = false;
      syncStatusTextNotifier.value = 'Cloud Unavailable';
      return 0;
    }

    if (session == null || session.user.id.isEmpty) {
      isSyncingNotifier.value = false;
      syncStatusTextNotifier.value = 'Guest Mode (No Cloud)';
      return 0;
    }

    final userId = session.user.id;
    int pulledCount = 0;

    try {
      // 1. Check local pending mutations
      final pendingMutations = await db.getPendingMutations();
      if (pendingMutations.isNotEmpty && !force) {
        AppLogService.info(
          AppLogService.catSync,
          'Pending local changes detected (${pendingMutations.length}). Flushing outbox before pulling...',
        );
        await processPendingMutations();
      }

      // 2. Fetch remote cloud records matching authenticated user ID (UUID)
      final results = await Future.wait([
        supabase.from('academic_profiles').select().eq('user_id', userId).order('updated_at', ascending: false).limit(1),
        supabase.from('courses').select().eq('user_id', userId),
        supabase.from('course_schedules').select().eq('user_id', userId),
        supabase.from('course_tasks').select().eq('user_id', userId),
        supabase.from('course_metadata').select().eq('user_id', userId),
        supabase.from('campus_pins').select().eq('user_id', userId),
      ]);

      final profileRows = results[0] as List;
      final courseRows = results[1] as List;
      final scheduleRows = results[2] as List;
      final taskRows = results[3] as List;
      final metaRows = results[4] as List;
      final pinRows = results[5] as List;

      if (profileRows.isEmpty && courseRows.isEmpty && pinRows.isEmpty) {
        syncStatusTextNotifier.value = 'No Cloud Data Found';
        isSyncingNotifier.value = false;
        return 0;
      }

      final Map<String, dynamic> remoteProfile;
      if (profileRows.isNotEmpty) {
        remoteProfile = profileRows.first as Map<String, dynamic>;
      } else {
        final synthProfileId = courseRows.first['profile_id'] as String? ?? 'PROFILE-DEFAULT';
        remoteProfile = <String, dynamic>{
          'id': synthProfileId,
          'student_no': '',
          'section': '',
          'school_year': 'Academic Year',
          'semester': 'Active Term',
          'total_units': 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }

      final remoteUpdatedAt = remoteProfile['updated_at'] != null
          ? DateTime.parse(remoteProfile['updated_at'] as String)
          : DateTime.now();

      final localActiveProfile = await db.watchActiveProfile().first;
      final localCourses = localActiveProfile != null
          ? await db.getCoursesForProfile(localActiveProfile.id, includeArchived: true)
          : [];

      // Smart conflict check: if local data has courses and newer updates than cloud and not forcing, keep local data
      if (localActiveProfile != null && !force && localCourses.isNotEmpty) {
        if (localActiveProfile.updatedAt.isAfter(remoteUpdatedAt)) {
          AppLogService.info(
            AppLogService.catSync,
            'Local active schedule is newer than cloud. Preserving local changes.',
            details: 'Local: ${localActiveProfile.updatedAt}, Cloud: $remoteUpdatedAt',
          );
          syncStatusTextNotifier.value = 'Local is Up to Date';
          isSyncingNotifier.value = false;
          return 0;
        }
      }

      final cloudProfileId = remoteProfile['id'] as String;
      final remoteCourseIds = courseRows.map((r) => r['id'] as String).toSet();
      final remoteScheduleIds = scheduleRows.map((r) => r['id'] as String).toSet();
      final remoteTaskIds = taskRows.map((r) => r['id'] as String).toSet();
      final remoteMetaIds = metaRows.map((r) => r['id'] as String).toSet();

      // Atomic batch update of active cloud data
      await db.transaction(() async {
        // 1. Pull Academic Profile (ensuring it is set as active profile)
        await db.insertOrUpdateProfile(AcademicProfilesCompanion(
          id: drift.Value(cloudProfileId),
          studentNo: drift.Value(remoteProfile['student_no'] as String? ?? ''),
          section: drift.Value(remoteProfile['section'] as String? ?? ''),
          schoolYear: drift.Value(remoteProfile['school_year'] as String? ?? ''),
          semester: drift.Value(remoteProfile['semester'] as String? ?? ''),
          totalUnits: drift.Value((remoteProfile['total_units'] as num?)?.toDouble() ?? 0.0),
          updatedAt: drift.Value(DateTime.now()),
        ));
        await db.setActiveProfile(cloudProfileId);
        pulledCount++;

        // 2. Pull Courses (and prune active courses deleted on cloud ONLY IF cloud has courses)
        if (courseRows.isNotEmpty) {
          final localActiveCourses = await db.getCoursesForProfile(cloudProfileId, includeArchived: true);
          for (final localC in localActiveCourses) {
            if (!remoteCourseIds.contains(localC.id)) {
              final hasRemoteWithSameCode = courseRows.any((r) => r['course_code'] == localC.courseCode);
              if (!hasRemoteWithSameCode) {
                await (db.delete(db.courses)..where((c) => c.id.equals(localC.id))).go();
              }
            }
          }
        }

        for (final row in courseRows) {
          final courseId = row['id'] as String;
          final courseCode = row['course_code'] as String;

          // Find any existing courses with the same code under this profile to avoid UNIQUE constraint crash
          final existingWithSameCodeList = await (db.select(db.courses)
                ..where((c) => c.profileId.equals(cloudProfileId) & c.courseCode.equals(courseCode)))
              .get();

          for (final existingWithSameCode in existingWithSameCodeList) {
            if (existingWithSameCode.id != courseId) {
              // Re-point child tasks, schedules, and metadata to incoming courseId
              await (db.update(db.courseTasks)..where((t) => t.courseId.equals(existingWithSameCode.id))).write(
                CourseTasksCompanion(courseId: drift.Value(courseId)),
              );
              await (db.update(db.courseSchedules)..where((s) => s.courseId.equals(existingWithSameCode.id))).write(
                CourseSchedulesCompanion(courseId: drift.Value(courseId)),
              );
              await (db.update(db.courseMetadata)..where((m) => m.courseId.equals(existingWithSameCode.id))).write(
                CourseMetadataCompanion(courseId: drift.Value(courseId)),
              );
              // Delete old duplicate row so unique (profileId, courseCode) index is not violated
              await (db.delete(db.courses)..where((c) => c.id.equals(existingWithSameCode.id))).go();
            }
          }

          await (db.into(db.courses)).insertOnConflictUpdate(CoursesCompanion(
            id: drift.Value(courseId),
            profileId: drift.Value(cloudProfileId),
            courseCode: drift.Value(courseCode),
            courseTitle: drift.Value(row['course_title'] as String),
            lecUnits: drift.Value((row['lec_units'] as num?)?.toDouble() ?? 3.0),
            labUnits: drift.Value((row['lab_units'] as num?)?.toDouble() ?? 0.0),
            isArchived: const drift.Value(false),
          ));
          pulledCount++;
        }

        // 3. Pull Course Schedules (and prune schedules deleted on cloud for active courses)
        for (final courseId in remoteCourseIds) {
          final localSchedules = await (db.select(db.courseSchedules)..where((s) => s.courseId.equals(courseId))).get();
          for (final localS in localSchedules) {
            if (!remoteScheduleIds.contains(localS.id)) {
              await (db.delete(db.courseSchedules)..where((s) => s.id.equals(localS.id))).go();
            }
          }
        }

        for (final row in scheduleRows) {
          await (db.into(db.courseSchedules)).insertOnConflictUpdate(CourseSchedulesCompanion(
            id: drift.Value(row['id'] as String),
            courseId: drift.Value(row['course_id'] as String),
            dayToken: drift.Value(row['day_token'] as String),
            startMinutes: drift.Value(row['start_minutes'] as int),
            endMinutes: drift.Value(row['end_minutes'] as int),
            roomCode: drift.Value(row['room_code'] as String? ?? 'TBA'),
            sessionType: drift.Value(row['session_type'] as String? ?? 'lecture'),
            isTba: drift.Value(row['is_tba'] as bool? ?? false),
          ));
          pulledCount++;
        }

        // 4. Pull Course Tasks (with Last-Write-Wins and prune tasks deleted on cloud)
        for (final courseId in remoteCourseIds) {
          final localTasks = await (db.select(db.courseTasks)..where((t) => t.courseId.equals(courseId))).get();
          for (final localT in localTasks) {
            if (!remoteTaskIds.contains(localT.id)) {
              await (db.delete(db.courseTasks)..where((t) => t.id.equals(localT.id))).go();
            }
          }
        }

        for (final row in taskRows) {
          final taskId = row['id'] as String;
          final cloudTaskUpdatedAt = row['updated_at'] != null ? DateTime.parse(row['updated_at'] as String) : DateTime.now();
          final localTaskList = await (db.select(db.courseTasks)..where((t) => t.id.equals(taskId))..limit(1)).get();
          final localTask = localTaskList.firstOrNull;
          if (localTask == null || cloudTaskUpdatedAt.isAfter(localTask.updatedAt) || cloudTaskUpdatedAt.isAtSameMomentAs(localTask.updatedAt)) {
            await (db.into(db.courseTasks)).insertOnConflictUpdate(CourseTasksCompanion(
              id: drift.Value(taskId),
              courseId: drift.Value(row['course_id'] as String),
              title: drift.Value(row['title'] as String),
              details: drift.Value(row['details'] as String?),
              taskType: drift.Value(row['task_type'] as String? ?? 'assignment'),
              isCompleted: drift.Value(row['is_completed'] as bool? ?? false),
              dueDate: drift.Value(TimeFormatter.normalizeDueDate(row['due_date'])),
              updatedAt: drift.Value(cloudTaskUpdatedAt),
            ));
          }
          pulledCount++;
        }

        // 5. Pull Course Metadata (and prune metadata deleted on cloud)
        for (final courseId in remoteCourseIds) {
          final localMetaList = await (db.select(db.courseMetadata)..where((m) => m.courseId.equals(courseId))).get();
          for (final localMeta in localMetaList) {
            if (!remoteMetaIds.contains(localMeta.id)) {
              await (db.delete(db.courseMetadata)..where((m) => m.id.equals(localMeta.id))).go();
            }
          }
        }

        for (final row in metaRows) {
          await (db.into(db.courseMetadata)).insertOnConflictUpdate(CourseMetadataCompanion(
            id: drift.Value(row['id'] as String),
            courseId: drift.Value(row['course_id'] as String),
            classroomUrl: drift.Value(row['classroom_url'] as String?),
            lmsUrl: drift.Value(row['lms_url'] as String?),
            profName: drift.Value(row['prof_name'] as String?),
            profEmail: drift.Value(row['prof_email'] as String?),
            consultationHours: drift.Value(row['consultation_hours'] as String?),
          ));
          pulledCount++;
        }

        // 6. Pull Campus Building / Room POI Pins
        for (final row in pinRows) {
          final pinId = row['id'] as String;
          final roomCode = row['room_code'] as String;
          final lat = (row['latitude'] as num).toDouble();
          final lng = (row['longitude'] as num).toDouble();
          final buildingName = row['building_name'] as String?;
          final pinColor = row['pin_color'] as String?;
          final createdAt = row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : DateTime.now();
          final updatedAt = row['updated_at'] != null ? DateTime.parse(row['updated_at'] as String) : DateTime.now();

          await db.into(db.campusPins).insertOnConflictUpdate(CampusPinsCompanion(
            id: drift.Value(pinId),
            profileId: drift.Value(cloudProfileId),
            roomCode: drift.Value(roomCode),
            buildingName: drift.Value(buildingName),
            latitude: drift.Value(lat),
            longitude: drift.Value(lng),
            pinColor: drift.Value(pinColor),
            createdAt: drift.Value(createdAt),
            updatedAt: drift.Value(updatedAt),
          ));
          pulledCount++;
        }
      });

      lastSyncedAtNotifier.value = DateTime.now();
      syncStatusTextNotifier.value = 'Pulled ($pulledCount items)';

      if (pulledCount > 0) {
        AppLogService.success(
          AppLogService.catSync,
          'Downloaded and merged cloud data ($pulledCount records)',
        );
        syncEvents.add(SyncNotificationEvent(
          type: SyncEventType.pulled,
          message: 'Synced $pulledCount records from cloud',
          recordCount: pulledCount,
        ));
      }
    } catch (e) {
      AppLogService.error(
        AppLogService.catSync,
        'Error pulling remote cloud data',
        details: '$e',
      );
      syncStatusTextNotifier.value = 'Pull Error';
    } finally {
      isSyncingNotifier.value = false;
    }

    return pulledCount;
  }
}
