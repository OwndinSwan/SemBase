import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';
import '../database/app_database.dart';
import '../logging/app_log_service.dart';
import '../notifications/alarm_notification_service.dart';

class BackupSummary {
  final int profileCount;
  final int courseCount;
  final int scheduleCount;
  final int taskCount;
  final int metadataCount;
  final int pinCount;
  final String? studentNumber;
  final String? section;
  final String? semester;
  final String? schoolYear;
  final DateTime exportedAt;
  final String appVersion;

  BackupSummary({
    required this.profileCount,
    required this.courseCount,
    required this.scheduleCount,
    required this.taskCount,
    required this.metadataCount,
    this.pinCount = 0,
    this.studentNumber,
    this.section,
    this.semester,
    this.schoolYear,
    required this.exportedAt,
    required this.appVersion,
  });

  int get totalRecords => profileCount + courseCount + scheduleCount + taskCount + metadataCount + pinCount;
}

class BackupRestoreResult {
  final bool success;
  final String message;
  final int profilesRestored;
  final int coursesRestored;
  final int schedulesRestored;
  final int tasksRestored;
  final int metadataRestored;
  final int pinsRestored;

  BackupRestoreResult({
    required this.success,
    required this.message,
    this.profilesRestored = 0,
    this.coursesRestored = 0,
    this.schedulesRestored = 0,
    this.tasksRestored = 0,
    this.metadataRestored = 0,
    this.pinsRestored = 0,
  });
}

/// Local Data Backup & Restore Engine
/// Handles full export, validation, and merge/overwrite restoration of all local SQLite databases.
class LocalBackupService {
  static const String currentBackupVersion = '1.0.0';

  /// Serializes all local SQLite tables to a structured JSON payload
  static Future<Map<String, dynamic>> exportBackupData(AppDatabase db) async {
    final profiles = await db.select(db.academicProfiles).get();
    final courses = await db.select(db.courses).get();
    final schedules = await db.select(db.courseSchedules).get();
    final tasks = await db.select(db.courseTasks).get();
    final metadata = await db.select(db.courseMetadata).get();
    final pins = await db.select(db.campusPins).get();

    final now = DateTime.now();

    final payload = <String, dynamic>{
      'sembase_backup': true,
      'backup_version': currentBackupVersion,
      'app_version': AppConfig.appVersion,
      'exported_at': now.toIso8601String(),
      'summary': {
        'profile_count': profiles.length,
        'course_count': courses.length,
        'schedule_count': schedules.length,
        'task_count': tasks.length,
        'metadata_count': metadata.length,
        'pin_count': pins.length,
      },
      'data': {
        'academic_profiles': profiles.map((p) => {
          'id': p.id,
          'student_no': p.studentNo,
          'section': p.section,
          'school_year': p.schoolYear,
          'semester': p.semester,
          'total_units': p.totalUnits,
          'updated_at': p.updatedAt.toIso8601String(),
        }).toList(),
        'courses': courses.map((c) => {
          'id': c.id,
          'profile_id': c.profileId,
          'course_code': c.courseCode,
          'course_title': c.courseTitle,
          'lec_units': c.lecUnits,
          'lab_units': c.labUnits,
          'is_archived': c.isArchived,
        }).toList(),
        'course_schedules': schedules.map((s) => {
          'id': s.id,
          'course_id': s.courseId,
          'day_token': s.dayToken,
          'start_minutes': s.startMinutes,
          'end_minutes': s.endMinutes,
          'room_code': s.roomCode,
          'session_type': s.sessionType,
          'is_tba': s.isTba,
        }).toList(),
        'course_tasks': tasks.map((t) => {
          'id': t.id,
          'course_id': t.courseId,
          'title': t.title,
          'details': t.details,
          'task_type': t.taskType,
          'is_completed': t.isCompleted,
          'due_date': t.dueDate?.toIso8601String(),
          'updated_at': t.updatedAt.toIso8601String(),
        }).toList(),
        'course_metadata': metadata.map((m) => {
          'id': m.id,
          'course_id': m.courseId,
          'classroom_url': m.classroomUrl,
          'lms_url': m.lmsUrl,
          'prof_name': m.profName,
          'prof_email': m.profEmail,
          'consultation_hours': m.consultationHours,
        }).toList(),
        'campus_pins': pins.map((p) => {
          'id': p.id,
          'profile_id': p.profileId,
          'room_code': p.roomCode,
          'building_name': p.buildingName,
          'latitude': p.latitude,
          'longitude': p.longitude,
          'pin_color': p.pinColor,
          'created_at': p.createdAt.toIso8601String(),
          'updated_at': p.updatedAt.toIso8601String(),
        }).toList(),
      },
    };

    AppLogService.info(
      AppLogService.catAction,
      'Generated personal backup payload: ${courses.length} courses, ${schedules.length} schedules, ${tasks.length} tasks.',
    );

    return payload;
  }

  /// Writes JSON backup payload to a temporary file and returns file path
  static Future<String> exportBackupToFile(AppDatabase db) async {
    final payload = await exportBackupData(db);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'SemBase_Personal_Backup_$timestamp.json';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(jsonStr);
    return file.path;
  }

  /// Exports and invokes system share sheet for personal backup file
  static Future<void> shareBackupFile(AppDatabase db) async {
    final filePath = await exportBackupToFile(db);
    final xFile = XFile(filePath, mimeType: 'application/json');

    await Share.shareXFiles(
      [xFile],
      text: 'SemBase Personal Academic Backup (.json)',
      subject: 'SemBase Local Data Backup',
    );
  }

  /// Parses and validates JSON backup content, returning summary statistics
  static BackupSummary parseAndValidateBackup(String jsonContent) {
    final dynamic decoded = jsonDecode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup file format: Root is not a JSON object.');
    }

    if (decoded['sembase_backup'] != true || decoded['data'] is! Map<String, dynamic>) {
      throw const FormatException('File is not a valid SemBase backup archive.');
    }

    final data = decoded['data'] as Map<String, dynamic>;
    final profiles = (data['academic_profiles'] as List<dynamic>?) ?? [];
    final courses = (data['courses'] as List<dynamic>?) ?? [];
    final schedules = (data['course_schedules'] as List<dynamic>?) ?? [];
    final tasks = (data['course_tasks'] as List<dynamic>?) ?? [];
    final metadata = (data['course_metadata'] as List<dynamic>?) ?? [];
    final pins = (data['campus_pins'] as List<dynamic>?) ?? [];

    String? studentNo;
    String? section;
    String? semester;
    String? schoolYear;

    if (profiles.isNotEmpty && profiles.first is Map<String, dynamic>) {
      final p = profiles.first as Map<String, dynamic>;
      studentNo = p['student_no']?.toString();
      section = p['section']?.toString();
      semester = p['semester']?.toString();
      schoolYear = p['school_year']?.toString();
    }

    final exportedAtStr = decoded['exported_at']?.toString();
    final exportedAt = exportedAtStr != null ? DateTime.tryParse(exportedAtStr) ?? DateTime.now() : DateTime.now();

    return BackupSummary(
      profileCount: profiles.length,
      courseCount: courses.length,
      scheduleCount: schedules.length,
      taskCount: tasks.length,
      metadataCount: metadata.length,
      pinCount: pins.length,
      studentNumber: studentNo,
      section: section,
      semester: semester,
      schoolYear: schoolYear,
      exportedAt: exportedAt,
      appVersion: decoded['app_version']?.toString() ?? AppConfig.appVersion,
    );
  }

  /// Restores local backup into SQLite database with optional overwrite or merge mode
  static Future<BackupRestoreResult> restoreBackupData(
    AppDatabase db,
    Map<String, dynamic> backupData, {
    required bool overwrite,
  }) async {
    try {
      final data = backupData['data'] as Map<String, dynamic>;
      final profiles = (data['academic_profiles'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final courses = (data['courses'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final schedules = (data['course_schedules'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final tasks = (data['course_tasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final metadata = (data['course_metadata'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final pins = (data['campus_pins'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      if (profiles.isEmpty && courses.isEmpty && pins.isEmpty) {
        return BackupRestoreResult(
          success: false,
          message: 'No profile, course, or campus pin records found in this backup file.',
        );
      }

      await db.transaction(() async {
        if (overwrite) {
          // Clear all existing course data
          await db.delete(db.campusPins).go();
          await db.delete(db.syncQueue).go();
          await db.delete(db.courseMetadata).go();
          await db.delete(db.courseTasks).go();
          await db.delete(db.courseSchedules).go();
          await db.delete(db.courses).go();
          await db.delete(db.academicProfiles).go();
        }

        // 1. Insert / Upsert Profiles with Timestamp Protection
        for (final p in profiles) {
          final profileId = p['id']?.toString() ?? '';
          if (profileId.isEmpty) continue;

          final incomingUpdatedAt = DateTime.tryParse(p['updated_at']?.toString() ?? '') ?? DateTime.now();

          if (!overwrite) {
            final existingProf = await (db.select(db.academicProfiles)..where((tbl) => tbl.id.equals(profileId))).getSingleOrNull();
            if (existingProf != null && existingProf.updatedAt.isAfter(incomingUpdatedAt)) {
              // Local profile is newer, preserve it
              continue;
            }
          }

          await db.into(db.academicProfiles).insertOnConflictUpdate(
            AcademicProfilesCompanion(
              id: Value(profileId),
              studentNo: Value(p['student_no']?.toString() ?? ''),
              section: Value(p['section']?.toString() ?? ''),
              schoolYear: Value(p['school_year']?.toString() ?? ''),
              semester: Value(p['semester']?.toString() ?? ''),
              totalUnits: Value((p['total_units'] as num?)?.toDouble() ?? 0.0),
              updatedAt: Value(incomingUpdatedAt),
            ),
          );

          await db.enqueueMutation(
            mutationId: 'restore_prof_$profileId',
            tableName: 'academic_profiles',
            operation: 'INSERT',
            payloadJson: jsonEncode({
              'id': profileId,
              'student_no': p['student_no'],
              'section': p['section'],
              'school_year': p['school_year'],
              'semester': p['semester'],
              'total_units': p['total_units'],
            }),
          );
        }

        // 2. Insert / Upsert Courses
        for (final c in courses) {
          final courseId = c['id']?.toString() ?? '';
          final profileId = c['profile_id']?.toString() ?? '';
          if (courseId.isEmpty || profileId.isEmpty) continue;

          if (!overwrite) {
            final existingCourse = await (db.select(db.courses)..where((tbl) => tbl.id.equals(courseId))).getSingleOrNull();
            if (existingCourse != null) {
              // Course already exists locally, preserve existing
              continue;
            }
          }

          await db.into(db.courses).insertOnConflictUpdate(
            CoursesCompanion(
              id: Value(courseId),
              profileId: Value(profileId),
              courseCode: Value(c['course_code']?.toString() ?? ''),
              courseTitle: Value(c['course_title']?.toString() ?? ''),
              lecUnits: Value((c['lec_units'] as num?)?.toDouble() ?? 0.0),
              labUnits: Value((c['lab_units'] as num?)?.toDouble() ?? 0.0),
              isArchived: Value(c['is_archived'] == true),
            ),
          );

          await db.enqueueMutation(
            mutationId: 'restore_course_$courseId',
            tableName: 'courses',
            operation: 'INSERT',
            payloadJson: jsonEncode({
              'id': courseId,
              'profile_id': profileId,
              'course_code': c['course_code'],
              'course_title': c['course_title'],
              'lec_units': c['lec_units'],
              'lab_units': c['lab_units'],
              'is_archived': c['is_archived'] ?? false,
            }),
          );
        }

        // 3. Insert / Upsert Schedules
        for (final s in schedules) {
          final schedId = s['id']?.toString() ?? '';
          final courseId = s['course_id']?.toString() ?? '';
          if (schedId.isEmpty || courseId.isEmpty) continue;

          if (!overwrite) {
            final existingSched = await (db.select(db.courseSchedules)..where((tbl) => tbl.id.equals(schedId))).getSingleOrNull();
            if (existingSched != null) {
              // Schedule slot already exists locally, preserve existing
              continue;
            }
          }

          await db.into(db.courseSchedules).insertOnConflictUpdate(
            CourseSchedulesCompanion(
              id: Value(schedId),
              courseId: Value(courseId),
              dayToken: Value(s['day_token']?.toString() ?? 'M'),
              startMinutes: Value((s['start_minutes'] as num?)?.toInt() ?? 480),
              endMinutes: Value((s['end_minutes'] as num?)?.toInt() ?? 600),
              roomCode: Value(s['room_code']?.toString() ?? 'TBA'),
              sessionType: Value(s['session_type']?.toString() ?? 'lecture'),
              isTba: Value(s['is_tba'] == true),
            ),
          );

          await db.enqueueMutation(
            mutationId: 'restore_sched_$schedId',
            tableName: 'course_schedules',
            operation: 'INSERT',
            payloadJson: jsonEncode({
              'id': schedId,
              'course_id': courseId,
              'day_token': s['day_token'],
              'start_minutes': s['start_minutes'],
              'end_minutes': s['end_minutes'],
              'room_code': s['room_code'],
              'session_type': s['session_type'],
              'is_tba': s['is_tba'] ?? false,
            }),
          );
        }

        // 4. Insert / Upsert Tasks with Smart Timestamp Merge
        for (final t in tasks) {
          final taskId = t['id']?.toString() ?? '';
          final courseId = t['course_id']?.toString() ?? '';
          if (taskId.isEmpty || courseId.isEmpty) continue;

          final dueStr = t['due_date']?.toString();
          final dueDate = dueStr != null ? DateTime.tryParse(dueStr) : null;
          final incomingUpdatedAt = DateTime.tryParse(t['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

          if (!overwrite) {
            final existingTask = await (db.select(db.courseTasks)..where((tbl) => tbl.id.equals(taskId))).getSingleOrNull();
            if (existingTask != null && existingTask.updatedAt.isAfter(incomingUpdatedAt)) {
              // Local task is newer (e.g. user checked/edited the task after the export was made) -> PRESERVE LOCAL STATE!
              AppLogService.info(
                AppLogService.catAction,
                'Smart Merge preserved newer local task "$taskId" (local: ${existingTask.updatedAt} > backup: $incomingUpdatedAt).',
              );
              continue;
            }
          }

          await db.into(db.courseTasks).insertOnConflictUpdate(
            CourseTasksCompanion(
              id: Value(taskId),
              courseId: Value(courseId),
              title: Value(t['title']?.toString() ?? ''),
              details: Value(t['details']?.toString()),
              taskType: Value(t['task_type']?.toString() ?? 'requirement'),
              isCompleted: Value(t['is_completed'] == true),
              dueDate: Value(dueDate),
              updatedAt: Value(incomingUpdatedAt),
            ),
          );

          await db.enqueueMutation(
            mutationId: 'restore_task_$taskId',
            tableName: 'course_tasks',
            operation: 'INSERT',
            payloadJson: jsonEncode({
              'id': taskId,
              'course_id': courseId,
              'title': t['title'],
              'details': t['details'],
              'task_type': t['task_type'],
              'is_completed': t['is_completed'] ?? false,
              'due_date': dueStr,
            }),
          );
        }

        // 5. Insert / Upsert Metadata
        for (final m in metadata) {
          final metaId = m['id']?.toString() ?? '';
          final courseId = m['course_id']?.toString() ?? '';
          if (metaId.isEmpty || courseId.isEmpty) continue;

          if (!overwrite) {
            final existingMeta = await (db.select(db.courseMetadata)..where((tbl) => tbl.id.equals(metaId))).getSingleOrNull();
            if (existingMeta != null) {
              // Metadata already exists locally, preserve existing
              continue;
            }
          }

          await db.into(db.courseMetadata).insertOnConflictUpdate(
            CourseMetadataCompanion(
              id: Value(metaId),
              courseId: Value(courseId),
              classroomUrl: Value(m['classroom_url']?.toString()),
              lmsUrl: Value(m['lms_url']?.toString()),
              profName: Value(m['prof_name']?.toString()),
              profEmail: Value(m['prof_email']?.toString()),
              consultationHours: Value(m['consultation_hours']?.toString()),
            ),
          );

          await db.enqueueMutation(
            mutationId: 'restore_meta_$metaId',
            tableName: 'course_metadata',
            operation: 'INSERT',
            payloadJson: jsonEncode({
              'id': metaId,
              'course_id': courseId,
              'classroom_url': m['classroom_url'],
              'lms_url': m['lms_url'],
              'prof_name': m['prof_name'],
              'prof_email': m['prof_email'],
              'consultation_hours': m['consultation_hours'],
            }),
          );
        }

        // 6. Insert / Upsert Campus Building / Room POI Pins
        for (final p in pins) {
          final pinId = p['id']?.toString() ?? '';
          final profileId = p['profile_id']?.toString() ?? '';
          if (pinId.isEmpty || profileId.isEmpty) continue;

          final lat = (p['latitude'] as num?)?.toDouble() ?? 0.0;
          final lng = (p['longitude'] as num?)?.toDouble() ?? 0.0;
          final roomCode = p['room_code']?.toString() ?? 'TBA';
          final buildingName = p['building_name']?.toString();
          final pinColor = p['pin_color']?.toString();
          final createdAt = DateTime.tryParse(p['created_at']?.toString() ?? '') ?? DateTime.now();
          final updatedAt = DateTime.tryParse(p['updated_at']?.toString() ?? '') ?? DateTime.now();

          await db.into(db.campusPins).insertOnConflictUpdate(
            CampusPinsCompanion(
              id: Value(pinId),
              profileId: Value(profileId),
              roomCode: Value(roomCode),
              buildingName: Value(buildingName),
              latitude: Value(lat),
              longitude: Value(lng),
              pinColor: Value(pinColor),
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

          await db.enqueueMutation(
            mutationId: 'restore_pin_$pinId',
            tableName: 'campus_pins',
            operation: 'UPSERT',
            payloadJson: jsonEncode({
              'id': pinId,
              'profile_id': profileId,
              'room_code': roomCode,
              'building_name': buildingName,
              'latitude': lat,
              'longitude': lng,
              'pin_color': pinColor,
              'created_at': createdAt.toIso8601String(),
              'updated_at': updatedAt.toIso8601String(),
            }),
          );
        }
      });

      // Synchronize alarms with new schedule data
      try {
        await AlarmNotificationService.syncAllClassAlarms(db);
      } catch (alarmError) {
        AppLogService.warning(AppLogService.catAlarm, 'Alarm sync skipped or unavailable: $alarmError');
      }

      AppLogService.info(
        AppLogService.catAction,
        'Personal backup restored successfully: ${courses.length} courses, ${schedules.length} schedules, ${tasks.length} tasks, ${pins.length} campus pins (${overwrite ? "Clean Overwrite" : "Merge"}).',
      );

      return BackupRestoreResult(
        success: true,
        message: 'Personal backup restored successfully!',
        profilesRestored: profiles.length,
        coursesRestored: courses.length,
        schedulesRestored: schedules.length,
        tasksRestored: tasks.length,
        metadataRestored: metadata.length,
        pinsRestored: pins.length,
      );
    } catch (e, stack) {
      AppLogService.error(AppLogService.catAction, 'Failed to restore personal backup: $e', details: stack.toString());
      return BackupRestoreResult(
        success: false,
        message: 'Failed to restore backup: $e',
      );
    }
  }
}
