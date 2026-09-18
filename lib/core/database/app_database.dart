import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'connection/native.dart' if (dart.library.html) 'connection/unsupported.dart';
import '../config/app_config.dart';
import '../logging/app_log_service.dart';
import '../utils/time_formatter.dart';

part 'app_database.g.dart';

/// 1. Academic Profiles Table
@DataClassName('AcademicProfile')
class AcademicProfiles extends Table {
  TextColumn get id => text()(); // UUID PK
  TextColumn get studentNo => text()();
  TextColumn get section => text()();
  TextColumn get schoolYear => text()();
  TextColumn get semester => text()();
  RealColumn get totalUnits => real()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 2. Courses Table
@DataClassName('Course')
@TableIndex(name: 'idx_courses_profile_code', columns: {#profileId, #courseCode}, unique: true)
class Courses extends Table {
  TextColumn get id => text()(); // UUID PK
  TextColumn get profileId => text().references(AcademicProfiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get courseCode => text()();
  TextColumn get courseTitle => text()();
  RealColumn get lecUnits => real().withDefault(const Constant(0.0))();
  RealColumn get labUnits => real().withDefault(const Constant(0.0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 3. Course Schedules Table
@DataClassName('CourseSchedule')
class CourseSchedules extends Table {
  TextColumn get id => text()(); // UUID PK
  TextColumn get courseId => text().references(Courses, #id, onDelete: KeyAction.cascade)();
  TextColumn get dayToken => text()(); // 'M'|'T'|'W'|'TH'|'F'|'S'
  IntColumn get startMinutes => integer()(); // Minutes from midnight
  IntColumn get endMinutes => integer()();
  TextColumn get roomCode => text()();
  TextColumn get sessionType => text()(); // 'lecture' | 'lab'
  BoolColumn get isTba => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 4. Course Tasks Table
@DataClassName('CourseTask')
class CourseTasks extends Table {
  TextColumn get id => text()(); // UUID PK
  TextColumn get courseId => text().references(Courses, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get details => text().nullable()(); // Rich details / notes
  TextColumn get taskType => text()(); // 'requirement'|'assignment'|'exam'
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 5. Course Metadata Table
@DataClassName('CourseMetadataEntry')
class CourseMetadata extends Table {
  TextColumn get id => text()(); // UUID PK
  TextColumn get courseId => text().references(Courses, #id, onDelete: KeyAction.cascade)();
  TextColumn get classroomUrl => text().nullable()();
  TextColumn get lmsUrl => text().nullable()();
  TextColumn get profName => text().nullable()();
  TextColumn get profEmail => text().nullable()();
  TextColumn get consultationHours => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 6. Transactional Outbox Sync Queue Table
@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  IntColumn get queueId => integer().autoIncrement()();
  TextColumn get mutationId => text()();
  TextColumn get targetTable => text().named('table_name')();
  TextColumn get operation => text()(); // 'INSERT'|'UPDATE'|'DELETE'
  TextColumn get payload => text()(); // JSON String
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

/// Helper model representing full course with schedule, metadata, and tasks
class CourseWithDetails {
  final Course course;
  final List<CourseSchedule> schedules;
  final CourseMetadataEntry? metadata;
  final List<CourseTask> tasks;

  CourseWithDetails({
    required this.course,
    required this.schedules,
    this.metadata,
    required this.tasks,
  });
}

/// Helper model for schedule item combined with course data
class ScheduleWithCourse {
  final CourseSchedule schedule;
  final Course course;
  final CourseMetadataEntry? metadata;

  ScheduleWithCourse({
    required this.schedule,
    required this.course,
    this.metadata,
  });
}

/// Helper model for task item combined with its parent course and metadata
class TaskWithCourse {
  final CourseTask task;
  final Course course;
  final CourseMetadataEntry? metadata;

  TaskWithCourse({
    required this.task,
    required this.course,
    this.metadata,
  });
}

/// 7. Campus Pins Table (Campus Building POIs & Bound Room Codes)
@DataClassName('CampusPin')
class CampusPins extends Table {
  TextColumn get id => text()(); // UUID PK
  TextColumn get profileId => text().references(AcademicProfiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get roomCode => text()(); // e.g. 'CL1', 'RM.5', 'COMP LAB 1'
  TextColumn get buildingName => text().nullable()(); // optional custom building label
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get pinColor => text().nullable()(); // Hex color e.g. '#10B981'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  AcademicProfiles,
  Courses,
  CourseSchedules,
  CourseTasks,
  CourseMetadata,
  SyncQueue,
  CampusPins,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? openConnection());

  @override
  int get schemaVersion => AppConfig.driftDbSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(campusPins);
      }
    },
  );

  // ==========================================
  // PROFILE QUERIES
  // ==========================================

  Stream<AcademicProfile?> watchActiveProfile() {
    return (select(academicProfiles)
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<AcademicProfile?> getActiveProfile() {
    return (select(academicProfiles)
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertOrUpdateProfile(AcademicProfilesCompanion profile) {
    return into(academicProfiles).insertOnConflictUpdate(profile);
  }

  Future<void> setActiveProfile(String profileId) async {
    await restoreTerm(profileId);
  }

  // ==========================================
  // COURSE & SCHEDULE QUERIES
  // ==========================================

  Stream<List<Course>> watchCoursesForProfile(String profileId, {bool includeArchived = false}) {
    final query = select(courses)..where((t) => t.profileId.equals(profileId));
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.courseCode)]);
    return query.watch();
  }

  Future<List<Course>> getCoursesForProfile(String profileId, {bool includeArchived = false}) {
    final query = select(courses)..where((t) => t.profileId.equals(profileId));
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.courseCode)]);
    return query.get();
  }

  Stream<List<ScheduleWithCourse>> watchSchedulesForDay(String profileId, String dayToken) {
    final query = select(courseSchedules).join([
      innerJoin(courses, courses.id.equalsExp(courseSchedules.courseId)),
      leftOuterJoin(courseMetadata, courseMetadata.courseId.equalsExp(courses.id)),
    ])
      ..where(courses.profileId.equals(profileId) &
          courses.isArchived.equals(false) &
          courseSchedules.dayToken.equals(dayToken))
      ..orderBy([OrderingTerm(expression: courseSchedules.startMinutes)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ScheduleWithCourse(
          schedule: row.readTable(courseSchedules),
          course: row.readTable(courses),
          metadata: row.readTableOrNull(courseMetadata),
        );
      }).toList();
    });
  }

  Stream<List<ScheduleWithCourse>> watchAllActiveSchedules(String profileId) {
    final query = select(courseSchedules).join([
      innerJoin(courses, courses.id.equalsExp(courseSchedules.courseId)),
      leftOuterJoin(courseMetadata, courseMetadata.courseId.equalsExp(courses.id)),
    ])
      ..where(courses.profileId.equals(profileId) & courses.isArchived.equals(false))
      ..orderBy([
        OrderingTerm(expression: courseSchedules.dayToken),
        OrderingTerm(expression: courseSchedules.startMinutes),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ScheduleWithCourse(
          schedule: row.readTable(courseSchedules),
          course: row.readTable(courses),
          metadata: row.readTableOrNull(courseMetadata),
        );
      }).toList();
    });
  }

  Future<List<ScheduleWithCourse>> getAllActiveSchedules(String profileId) {
    final query = select(courseSchedules).join([
      innerJoin(courses, courses.id.equalsExp(courseSchedules.courseId)),
      leftOuterJoin(courseMetadata, courseMetadata.courseId.equalsExp(courses.id)),
    ])
      ..where(courses.profileId.equals(profileId) & courses.isArchived.equals(false))
      ..orderBy([
        OrderingTerm(expression: courseSchedules.startMinutes),
      ]);

    return query.get().then((rows) {
      return rows.map((row) {
        return ScheduleWithCourse(
          schedule: row.readTable(courseSchedules),
          course: row.readTable(courses),
          metadata: row.readTableOrNull(courseMetadata),
        );
      }).toList();
    });
  }

  Future<CourseWithDetails?> getCourseDetails(String courseId) async {
    final courseList = await (select(courses)..where((t) => t.id.equals(courseId))..limit(1)).get();
    if (courseList.isEmpty) return null;
    final course = courseList.first;

    final schedules = await (select(courseSchedules)..where((t) => t.courseId.equals(courseId))).get();
    final metadataList = await (select(courseMetadata)..where((t) => t.courseId.equals(courseId))..limit(1)).get();
    final metadata = metadataList.firstOrNull;
    final tasks = await (select(courseTasks)..where((t) => t.courseId.equals(courseId))).get();

    return CourseWithDetails(
      course: course,
      schedules: schedules,
      metadata: metadata,
      tasks: tasks,
    );
  }

  Stream<List<CourseWithDetails>> watchAllCoursesWithDetailsForProfile(String profileId) {
    return customSelect(
      'SELECT id FROM courses WHERE profile_id = ? AND is_archived = 0 ORDER BY course_code',
      variables: [Variable.withString(profileId)],
      readsFrom: {courses, courseSchedules, courseMetadata, courseTasks},
    ).watch().asyncMap((rows) async {
      final List<CourseWithDetails> results = [];
      for (final row in rows) {
        final courseId = row.read<String>('id');
        final details = await getCourseDetails(courseId);
        if (details != null) {
          results.add(details);
        }
      }
      return results;
    });
  }

  Stream<CourseWithDetails?> watchCourseDetails(String courseId) {
    return customSelect(
      'SELECT id FROM courses WHERE id = ?',
      variables: [Variable.withString(courseId)],
      readsFrom: {courses, courseSchedules, courseMetadata, courseTasks},
    ).watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      return getCourseDetails(courseId);
    });
  }

  // ==========================================
  // TASK QUERIES
  // ==========================================

  Stream<List<CourseTask>> watchTasksForCourse(String courseId) {
    return (select(courseTasks)
          ..where((t) => t.courseId.equals(courseId))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<TaskWithCourse>> watchPendingTasksDueWithinHours(String profileId, int hours) {
    final cutoff = DateTime.now().add(Duration(hours: hours));
    final query = select(courseTasks).join([
      innerJoin(courses, courses.id.equalsExp(courseTasks.courseId)),
      leftOuterJoin(courseMetadata, courseMetadata.courseId.equalsExp(courses.id)),
    ])
      ..where(courses.profileId.equals(profileId) &
          courses.isArchived.equals(false) &
          courseTasks.isCompleted.equals(false) &
          courseTasks.dueDate.isNotNull() &
          courseTasks.dueDate.isSmallerOrEqualValue(cutoff))
      ..orderBy([OrderingTerm(expression: courseTasks.dueDate)]);

    return query.watch().map((rows) => rows.map((r) => TaskWithCourse(
          task: r.readTable(courseTasks),
          course: r.readTable(courses),
          metadata: r.readTableOrNull(courseMetadata),
        )).toList());
  }

  static const _uuid = Uuid();

  Future<int> insertTask(CourseTasksCompanion task) async {
    final res = await into(courseTasks).insert(task);
    try {
      final taskId = task.id.present ? task.id.value : null;
      if (taskId != null) {
        final currentTask = await (select(courseTasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
        if (currentTask != null) {
          await enqueueMutation(
            mutationId: _uuid.v4(),
            tableName: 'course_tasks',
            operation: 'INSERT',
            payloadJson: jsonEncode({
              'id': currentTask.id,
              'course_id': currentTask.courseId,
              'title': currentTask.title,
              'details': currentTask.details,
              'task_type': currentTask.taskType,
              'is_completed': currentTask.isCompleted,
              'due_date': currentTask.dueDate != null ? TimeFormatter.normalizeDueDate(currentTask.dueDate)?.toIso8601String() : null,
              'updated_at': currentTask.updatedAt.toIso8601String(),
            }),
          );
        }
      }
    } catch (e) {
      AppLogService.error(AppLogService.catSync, 'Failed to enqueue task insert mutation', details: '$e');
    }
    return res;
  }

  Future<bool> updateTaskStatus(String taskId, bool isCompleted) async {
    final now = DateTime.now();
    final count = await (update(courseTasks)..where((t) => t.id.equals(taskId)))
        .write(CourseTasksCompanion(
          isCompleted: Value(isCompleted),
          updatedAt: Value(now),
        ));
    if (count > 0) {
      try {
        final currentTask = await (select(courseTasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
        if (currentTask != null) {
          await enqueueMutation(
            mutationId: _uuid.v4(),
            tableName: 'course_tasks',
            operation: 'UPDATE',
            payloadJson: jsonEncode({
              'id': currentTask.id,
              'course_id': currentTask.courseId,
              'title': currentTask.title,
              'details': currentTask.details,
              'task_type': currentTask.taskType,
              'is_completed': currentTask.isCompleted,
              'due_date': currentTask.dueDate != null ? TimeFormatter.normalizeDueDate(currentTask.dueDate)?.toIso8601String() : null,
              'updated_at': currentTask.updatedAt.toIso8601String(),
            }),
          );
        }
      } catch (e) {
        AppLogService.error(AppLogService.catSync, 'Failed to enqueue task status update mutation', details: '$e');
      }
    }
    return count > 0;
  }

  Future<bool> updateTaskDueDate(String taskId, DateTime? newDueDate) async {
    final normalized = TimeFormatter.normalizeDueDate(newDueDate);
    final now = DateTime.now();
    final count = await (update(courseTasks)..where((t) => t.id.equals(taskId)))
        .write(CourseTasksCompanion(
          dueDate: Value(normalized),
          updatedAt: Value(now),
        ));
    if (count > 0) {
      try {
        final currentTask = await (select(courseTasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
        if (currentTask != null) {
          await enqueueMutation(
            mutationId: _uuid.v4(),
            tableName: 'course_tasks',
            operation: 'UPDATE',
            payloadJson: jsonEncode({
              'id': currentTask.id,
              'course_id': currentTask.courseId,
              'title': currentTask.title,
              'details': currentTask.details,
              'task_type': currentTask.taskType,
              'is_completed': currentTask.isCompleted,
              'due_date': currentTask.dueDate != null ? TimeFormatter.normalizeDueDate(currentTask.dueDate)?.toIso8601String() : null,
              'updated_at': currentTask.updatedAt.toIso8601String(),
            }),
          );
        }
      } catch (e) {
        AppLogService.error(AppLogService.catSync, 'Failed to enqueue task dueDate update mutation', details: '$e');
      }
    }
    return count > 0;
  }

  Future<bool> updateTaskFull(CourseTasksCompanion task) async {
    final taskId = task.id.present ? task.id.value : null;
    if (taskId == null) return false;
    final count = await (update(courseTasks)..where((t) => t.id.equals(taskId))).write(task);
    if (count > 0) {
      try {
        final currentTask = await (select(courseTasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
        if (currentTask != null) {
          await enqueueMutation(
            mutationId: _uuid.v4(),
            tableName: 'course_tasks',
            operation: 'UPDATE',
            payloadJson: jsonEncode({
              'id': currentTask.id,
              'course_id': currentTask.courseId,
              'title': currentTask.title,
              'details': currentTask.details,
              'task_type': currentTask.taskType,
              'is_completed': currentTask.isCompleted,
              'due_date': currentTask.dueDate != null ? TimeFormatter.normalizeDueDate(currentTask.dueDate)?.toIso8601String() : null,
              'updated_at': currentTask.updatedAt.toIso8601String(),
            }),
          );
        }
      } catch (e) {
        AppLogService.error(AppLogService.catSync, 'Failed to enqueue task update mutation', details: '$e');
      }
    }
    return count > 0;
  }

  Future<int> deleteTask(String taskId) async {
    final res = await (delete(courseTasks)..where((t) => t.id.equals(taskId))).go();
    if (res > 0) {
      try {
        await enqueueMutation(
          mutationId: _uuid.v4(),
          tableName: 'course_tasks',
          operation: 'DELETE',
          payloadJson: jsonEncode({'id': taskId}),
        );
      } catch (e) {
        AppLogService.error(AppLogService.catSync, 'Failed to enqueue task delete mutation', details: '$e');
      }
    }
    return res;
  }

  // ==========================================
  // COURSE SCHEDULE CRUD QUERIES
  // ==========================================

  Future<int> insertSchedule(CourseSchedulesCompanion schedule) async {
    final res = await into(courseSchedules).insert(schedule);
    try {
      final scheduleId = schedule.id.present ? schedule.id.value : null;
      if (scheduleId != null) {
        final currentSchedule = await (select(courseSchedules)..where((s) => s.id.equals(scheduleId))).getSingleOrNull();
        if (currentSchedule != null) {
          await enqueueMutation(
            mutationId: _uuid.v4(),
            tableName: 'course_schedules',
            operation: 'INSERT',
            payloadJson: jsonEncode({
              'id': currentSchedule.id,
              'course_id': currentSchedule.courseId,
              'day_token': currentSchedule.dayToken,
              'start_minutes': currentSchedule.startMinutes,
              'end_minutes': currentSchedule.endMinutes,
              'room_code': currentSchedule.roomCode,
              'session_type': currentSchedule.sessionType,
              'is_tba': currentSchedule.isTba,
            }),
          );
        }
      }
    } catch (e) {
      AppLogService.error(AppLogService.catSync, 'Failed to enqueue schedule insert mutation', details: '$e');
    }
    return res;
  }

  Future<bool> updateSchedule(CourseSchedulesCompanion schedule) async {
    final scheduleId = schedule.id.present ? schedule.id.value : null;
    if (scheduleId == null) return false;
    final count = await (update(courseSchedules)..where((t) => t.id.equals(scheduleId))).write(schedule);
    if (count > 0) {
      try {
        final currentSchedule = await (select(courseSchedules)..where((s) => s.id.equals(scheduleId))).getSingleOrNull();
        if (currentSchedule != null) {
          await enqueueMutation(
            mutationId: _uuid.v4(),
            tableName: 'course_schedules',
            operation: 'UPDATE',
            payloadJson: jsonEncode({
              'id': currentSchedule.id,
              'course_id': currentSchedule.courseId,
              'day_token': currentSchedule.dayToken,
              'start_minutes': currentSchedule.startMinutes,
              'end_minutes': currentSchedule.endMinutes,
              'room_code': currentSchedule.roomCode,
              'session_type': currentSchedule.sessionType,
              'is_tba': currentSchedule.isTba,
            }),
          );
        }
      } catch (e) {
        AppLogService.error(AppLogService.catSync, 'Failed to enqueue schedule update mutation', details: '$e');
      }
    }
    return count > 0;
  }

  Future<int> deleteSchedule(String scheduleId) async {
    final res = await (delete(courseSchedules)..where((t) => t.id.equals(scheduleId))).go();
    if (res > 0) {
      try {
        await enqueueMutation(
          mutationId: _uuid.v4(),
          tableName: 'course_schedules',
          operation: 'DELETE',
          payloadJson: jsonEncode({'id': scheduleId}),
        );
      } catch (e) {
        AppLogService.error(AppLogService.catSync, 'Failed to enqueue schedule delete mutation', details: '$e');
      }
    }
    return res;
  }

  // ==========================================
  // COURSE MODIFICATION & ARCHIVE QUERIES
  // ==========================================

  Future<bool> updateCourse(CoursesCompanion course) async {
    final courseId = course.id.present ? course.id.value : null;
    if (courseId == null) return false;
    final count = await (update(courses)..where((t) => t.id.equals(courseId))).write(course);
    if (count > 0) {
      try {
        final currentCourse = await (select(courses)..where((t) => t.id.equals(courseId))).getSingleOrNull();
        if (currentCourse != null) {
          await enqueueMutation(
            mutationId: _uuid.v4(),
            tableName: 'courses',
            operation: 'UPDATE',
            payloadJson: jsonEncode({
              'id': currentCourse.id,
              'profile_id': currentCourse.profileId,
              'course_code': currentCourse.courseCode,
              'course_title': currentCourse.courseTitle,
              'lec_units': currentCourse.lecUnits,
              'lab_units': currentCourse.labUnits,
              'is_archived': currentCourse.isArchived,
            }),
          );
        }
      } catch (e) {
        AppLogService.error(AppLogService.catSync, 'Failed to enqueue course update mutation', details: '$e');
      }
    }
    return count > 0;
  }

  Future<void> deleteCourse(String courseId) async {
    await transaction(() async {
      await (delete(courseTasks)..where((t) => t.courseId.equals(courseId))).go();
      await (delete(courseMetadata)..where((t) => t.courseId.equals(courseId))).go();
      await (delete(courseSchedules)..where((t) => t.courseId.equals(courseId))).go();
      await (delete(courses)..where((t) => t.id.equals(courseId))).go();
    });
    try {
      await enqueueMutation(
        mutationId: _uuid.v4(),
        tableName: 'courses',
        operation: 'DELETE',
        payloadJson: jsonEncode({'id': courseId}),
      );
    } catch (e) {
      AppLogService.error(AppLogService.catSync, 'Failed to enqueue course delete mutation', details: '$e');
    }
  }

  Stream<List<AcademicProfile>> watchAllProfiles() {
    return (select(academicProfiles)..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])).watch();
  }

  Future<void> restoreTerm(String profileId) async {
    await transaction(() async {
      // 1. Archive all courses belonging to other profiles
      await (update(courses)..where((t) => t.profileId.isNotValue(profileId)))
          .write(const CoursesCompanion(isArchived: Value(true)));

      // 2. Unarchive all courses for this restored profile
      await (update(courses)..where((t) => t.profileId.equals(profileId)))
          .write(const CoursesCompanion(isArchived: Value(false)));

      // 3. Update updatedAt to now so watchActiveProfile() picks this profile
      await (update(academicProfiles)..where((t) => t.id.equals(profileId)))
          .write(AcademicProfilesCompanion(updatedAt: Value(DateTime.now())));
    });
  }

  // ==========================================
  // METADATA QUERIES
  // ==========================================

  Future<int> upsertCourseMetadata(CourseMetadataCompanion metadataCompanion) async {
    final res = await into(courseMetadata).insertOnConflictUpdate(metadataCompanion);
    try {
      final metaId = metadataCompanion.id.present ? metadataCompanion.id.value : null;
      if (metaId != null) {
        final currentMeta = await (select(courseMetadata)..where((m) => m.id.equals(metaId))).getSingleOrNull();
        if (currentMeta != null) {
          await enqueueMutation(
            mutationId: _uuid.v4(),
            tableName: 'course_metadata',
            operation: 'UPSERT',
            payloadJson: jsonEncode({
              'id': currentMeta.id,
              'course_id': currentMeta.courseId,
              'classroom_url': currentMeta.classroomUrl,
              'lms_url': currentMeta.lmsUrl,
              'prof_name': currentMeta.profName,
              'prof_email': currentMeta.profEmail,
              'consultation_hours': currentMeta.consultationHours,
            }),
          );
        }
      }
    } catch (e) {
      AppLogService.error(AppLogService.catSync, 'Failed to enqueue metadata upsert mutation', details: '$e');
    }
    return res;
  }

  // ==========================================
  // BULK EXPORT / FULL CLOUD SYNC QUERIES
  // ==========================================

  Future<List<AcademicProfile>> getAllProfilesList() => select(academicProfiles).get();
  Future<List<Course>> getAllCoursesList() => select(courses).get();
  Future<List<CourseSchedule>> getAllSchedulesList() => select(courseSchedules).get();
  Future<List<CourseTask>> getAllTasksList() => select(courseTasks).get();
  Future<List<CourseMetadataEntry>> getAllMetadataList() => select(courseMetadata).get();

  // ==========================================
  // SYNC QUEUE QUERIES
  // ==========================================
  /// Callback triggered whenever a local mutation is enqueued into the outbox
  static void Function()? onMutationEnqueued;

  Future<int> enqueueMutation({
    required String mutationId,
    required String tableName,
    required String operation,
    required String payloadJson,
  }) async {
    final res = await into(syncQueue).insert(
      SyncQueueCompanion.insert(
        mutationId: mutationId,
        targetTable: tableName,
        operation: operation,
        payload: payloadJson,
      ),
    );
    AppLogService.info(
      AppLogService.catSync,
      'Enqueued $operation on $tableName',
    );
    onMutationEnqueued?.call();
    return res;
  }

  Stream<List<SyncQueueEntry>> watchPendingMutations() {
    return (select(syncQueue)..orderBy([(t) => OrderingTerm(expression: t.queueId)])).watch();
  }

  Future<List<SyncQueueEntry>> getPendingMutations({int limit = 50}) {
    return (select(syncQueue)
          ..orderBy([(t) => OrderingTerm(expression: t.queueId)])
          ..limit(limit))
        .get();
  }

  Future<int> removeMutation(int queueId) {
    return (delete(syncQueue)..where((t) => t.queueId.equals(queueId))).go();
  }

  Future<int> incrementRetryCount(int queueId) async {
    final entry = await (select(syncQueue)..where((t) => t.queueId.equals(queueId))).getSingleOrNull();
    if (entry == null) return 0;
    return (update(syncQueue)..where((t) => t.queueId.equals(queueId))).write(
      SyncQueueCompanion(retryCount: Value(entry.retryCount + 1)),
    );
  }

  // ==========================================
  // CAMPUS PINS & POI CALIBRATION QUERIES
  // ==========================================
  Stream<List<CampusPin>> watchCampusPins(String profileId) {
    return (select(campusPins)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm(expression: t.roomCode)]))
        .watch();
  }

  Future<List<CampusPin>> getCampusPins(String profileId) {
    return (select(campusPins)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm(expression: t.roomCode)]))
        .get();
  }

  Future<CampusPin?> getCampusPinForRoom(String profileId, String roomCode) {
    return (select(campusPins)
          ..where((t) => t.profileId.equals(profileId) & t.roomCode.equals(roomCode))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertOrUpdateCampusPin(CampusPinsCompanion pin) async {
    final res = await into(campusPins).insertOnConflictUpdate(pin);
    try {
      final pinId = pin.id.present ? pin.id.value : null;
      if (pinId != null) {
        final currentPin = await (select(campusPins)..where((t) => t.id.equals(pinId))).getSingleOrNull();
        if (currentPin != null) {
          await enqueueMutation(
            mutationId: _uuid.v4(),
            tableName: 'campus_pins',
            operation: 'UPSERT',
            payloadJson: jsonEncode({
              'id': currentPin.id,
              'profile_id': currentPin.profileId,
              'room_code': currentPin.roomCode,
              'building_name': currentPin.buildingName,
              'latitude': currentPin.latitude,
              'longitude': currentPin.longitude,
              'pin_color': currentPin.pinColor,
              'created_at': currentPin.createdAt.toIso8601String(),
              'updated_at': currentPin.updatedAt.toIso8601String(),
            }),
          );
        }
      }
    } catch (e) {
      AppLogService.error(AppLogService.catSync, 'Failed to enqueue campus pin upsert mutation', details: '$e');
    }
    return res;
  }

  Future<int> deleteCampusPin(String pinId) async {
    final res = await (delete(campusPins)..where((t) => t.id.equals(pinId))).go();
    if (res > 0) {
      try {
        await enqueueMutation(
          mutationId: _uuid.v4(),
          tableName: 'campus_pins',
          operation: 'DELETE',
          payloadJson: jsonEncode({'id': pinId}),
        );
      } catch (e) {
        AppLogService.error(AppLogService.catSync, 'Failed to enqueue campus pin delete mutation', details: '$e');
      }
    }
    return res;
  }

  /// Get distinct room codes from all enrolled courses in the active term
  Future<List<String>> getDistinctScheduleRoomCodes(String profileId) async {
    final query = select(courses).join([
      innerJoin(courseSchedules, courseSchedules.courseId.equalsExp(courses.id)),
    ])..where(courses.profileId.equals(profileId) & courses.isArchived.equals(false));

    final rows = await query.get();
    final roomCodes = <String>{};
    for (final row in rows) {
      final s = row.readTable(courseSchedules);
      final room = s.roomCode.trim();
      if (room.isNotEmpty && room.toUpperCase() != 'TBA' && !s.isTba) {
        roomCodes.add(room);
      }
    }
    final sorted = roomCodes.toList()..sort();
    return sorted;
  }

  // Clear all data for clean testing/reset
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(campusPins).go();
      await delete(syncQueue).go();
      await delete(courseTasks).go();
      await delete(courseMetadata).go();
      await delete(courseSchedules).go();
      await delete(courses).go();
      await delete(academicProfiles).go();
    });
  }
}
