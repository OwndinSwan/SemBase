import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_outbox_worker.dart';
import '../../cor_parser/models/parsed_cor.dart';
import '../models/cor_diff_result.dart';

class SyncDiffService {
  final AppDatabase db;

  SyncDiffService(this.db);

  /// Computes granular diff between existing database and parsed COR data
  Future<CorDiffSummary> computeDiff(ParsedCorData incoming) async {
    final existingProfile = await db.getActiveProfile();
    final List<CourseDiffItem> diffItems = [];
    bool isNewSemester = false;

    if (existingProfile == null) {
      isNewSemester = true;
      for (final course in incoming.courses) {
        diffItems.add(CourseDiffItem(
          courseCode: course.courseCode,
          newCourse: course,
          diffType: DiffType.added,
          changeDetails: ['New course (${course.schedules.length} slots)'],
        ));
      }
    } else {
      if (existingProfile.schoolYear != incoming.schoolYear ||
          existingProfile.semester != incoming.semester) {
        isNewSemester = true;
      }

      final existingCourses = await db.getCoursesForProfile(existingProfile.id, includeArchived: false);
      final existingCodeMap = {for (final c in existingCourses) c.courseCode.toUpperCase(): c};
      final incomingCodeMap = {for (final c in incoming.courses) c.courseCode.toUpperCase(): c};

      // 1. Detect additions and modifications
      for (final incomingCourse in incoming.courses) {
        final code = incomingCourse.courseCode.toUpperCase();
        if (!existingCodeMap.containsKey(code)) {
          diffItems.add(CourseDiffItem(
            courseCode: incomingCourse.courseCode,
            newCourse: incomingCourse,
            diffType: DiffType.added,
            changeDetails: ['Course added in incoming COR'],
          ));
        } else {
          final existingCourse = existingCodeMap[code]!;
          final details = await db.getCourseDetails(existingCourse.id);
          final existingSchedules = details?.schedules ?? [];

          final List<String> changes = [];
          if (existingSchedules.length != incomingCourse.schedules.length) {
            changes.add('Schedule slot count changed from ${existingSchedules.length} to ${incomingCourse.schedules.length}');
          } else {
            for (int i = 0; i < incomingCourse.schedules.length; i++) {
              final incS = incomingCourse.schedules[i];
              final match = existingSchedules.any((exS) =>
                  exS.dayToken == incS.dayToken &&
                  exS.startMinutes == incS.startMinutes &&
                  exS.endMinutes == incS.endMinutes &&
                  exS.roomCode == incS.roomCode);
              if (!match) {
                changes.add('Schedule timing or room updated');
                break;
              }
            }
          }

          if (existingCourse.courseTitle != incomingCourse.courseTitle) {
            changes.add('Title changed');
          }
          if (existingCourse.lecUnits != incomingCourse.lecUnits ||
              existingCourse.labUnits != incomingCourse.labUnits) {
            changes.add('Units updated');
          }

          if (changes.isNotEmpty) {
            diffItems.add(CourseDiffItem(
              courseCode: incomingCourse.courseCode,
              existingCourse: existingCourse,
              newCourse: incomingCourse,
              diffType: DiffType.modified,
              changeDetails: changes,
            ));
          } else {
            diffItems.add(CourseDiffItem(
              courseCode: incomingCourse.courseCode,
              existingCourse: existingCourse,
              newCourse: incomingCourse,
              diffType: DiffType.unchanged,
              changeDetails: ['Unchanged'],
            ));
          }
        }
      }

      // 2. Detect deletions / dropped courses
      for (final existingCourse in existingCourses) {
        final code = existingCourse.courseCode.toUpperCase();
        if (!incomingCodeMap.containsKey(code)) {
          diffItems.add(CourseDiffItem(
            courseCode: existingCourse.courseCode,
            existingCourse: existingCourse,
            diffType: DiffType.dropped,
            changeDetails: ['Course missing in incoming COR (archived)'],
          ));
        }
      }
    }

    return CorDiffSummary(
      incomingData: incoming,
      existingProfile: existingProfile,
      diffItems: diffItems,
      isNewSemester: isNewSemester,
    );
  }

  /// Applies diff into Drift SQLite database with atomic transaction & preservation of tasks/metadata
  Future<void> applyDiff(CorDiffSummary summary, {bool archivePreviousSemester = true}) async {
    final uuid = const Uuid();
    final now = DateTime.now();

    final isSameTerm = summary.existingProfile != null &&
        summary.existingProfile!.schoolYear == summary.incomingData.schoolYear &&
        summary.existingProfile!.semester == summary.incomingData.semester;

    // Use existing profile ID if same term (preventing duplicate rows), else generate new UUID for new semester term
    final profileId = isSameTerm ? summary.existingProfile!.id : uuid.v4();

    await db.transaction(() async {
      // Map to preserve existing tasks and metadata by course code
      final Map<String, List<CourseTask>> preservedTasks = {};
      final Map<String, CourseMetadataEntry> preservedMetadata = {};

      if (summary.existingProfile != null) {
        final oldCourses = await db.getCoursesForProfile(summary.existingProfile!.id, includeArchived: true);
        for (final oldC in oldCourses) {
          final details = await db.getCourseDetails(oldC.id);
          if (details != null) {
            if (details.tasks.isNotEmpty) {
              preservedTasks[oldC.courseCode.toUpperCase()] = details.tasks;
            }
            if (details.metadata != null) {
              preservedMetadata[oldC.courseCode.toUpperCase()] = details.metadata!;
            }
          }
        }

        if (isSameTerm) {
          // Re-importing same term: archive prior courses under this profile before inserting new ones
          for (final c in oldCourses) {
            await (db.delete(db.courses)..where((t) => t.id.equals(c.id))).go();
          }
        } else {
          // New term: archive previous term's courses so they are preserved in Academic History
          for (final c in oldCourses) {
            await (db.update(db.courses)..where((t) => t.id.equals(c.id))).write(
              const CoursesCompanion(isArchived: Value(true)),
            );
          }
        }
      }

      // 1. Create or Update Academic Profile
      await db.insertOrUpdateProfile(
        AcademicProfilesCompanion(
          id: Value(profileId),
          studentNo: Value(summary.incomingData.studentNo),
          section: Value(summary.incomingData.section),
          schoolYear: Value(summary.incomingData.schoolYear),
          semester: Value(summary.incomingData.semester),
          totalUnits: Value(summary.incomingData.totalUnits),
          updatedAt: Value(now),
        ),
      );

      // Record profile mutation in sync queue
      await db.enqueueMutation(
        mutationId: uuid.v4(),
        tableName: 'academic_profiles',
        operation: 'UPSERT',
        payloadJson: jsonEncode({
          'id': profileId,
          'student_no': summary.incomingData.studentNo,
          'section': summary.incomingData.section,
          'school_year': summary.incomingData.schoolYear,
          'semester': summary.incomingData.semester,
          'total_units': summary.incomingData.totalUnits,
          'updated_at': now.toIso8601String(),
        }),
      );

      // 2. Insert all incoming courses and schedules
      for (final parsedCourse in summary.incomingData.courses) {
        final courseId = uuid.v4();

        await db.into(db.courses).insert(
          CoursesCompanion(
            id: Value(courseId),
            profileId: Value(profileId),
            courseCode: Value(parsedCourse.courseCode),
            courseTitle: Value(parsedCourse.courseTitle),
            lecUnits: Value(parsedCourse.lecUnits),
            labUnits: Value(parsedCourse.labUnits),
            isArchived: const Value(false),
          ),
        );

        // Enqueue Course mutation
        await db.enqueueMutation(
          mutationId: uuid.v4(),
          tableName: 'courses',
          operation: 'UPSERT',
          payloadJson: jsonEncode({
            'id': courseId,
            'profile_id': profileId,
            'course_code': parsedCourse.courseCode,
            'course_title': parsedCourse.courseTitle,
            'lec_units': parsedCourse.lecUnits,
            'lab_units': parsedCourse.labUnits,
            'is_archived': false,
          }),
        );

        // Insert Schedules
        for (final s in parsedCourse.schedules) {
          final scheduleId = uuid.v4();
          await db.into(db.courseSchedules).insert(
            CourseSchedulesCompanion(
              id: Value(scheduleId),
              courseId: Value(courseId),
              dayToken: Value(s.dayToken),
              startMinutes: Value(s.startMinutes),
              endMinutes: Value(s.endMinutes),
              roomCode: Value(s.roomCode),
              sessionType: Value(s.sessionType),
              isTba: Value(s.isTba),
            ),
          );

          // Enqueue Schedule mutation
          await db.enqueueMutation(
            mutationId: uuid.v4(),
            tableName: 'course_schedules',
            operation: 'UPSERT',
            payloadJson: jsonEncode({
              'id': scheduleId,
              'course_id': courseId,
              'day_token': s.dayToken,
              'start_minutes': s.startMinutes,
              'end_minutes': s.endMinutes,
              'room_code': s.roomCode,
              'session_type': s.sessionType,
              'is_tba': s.isTba,
            }),
          );
        }

        final codeUpper = parsedCourse.courseCode.toUpperCase();

        // Restore preserved metadata or save newly detected instructor name
        final detectedProf = parsedCourse.instructorName;
        final hasOldMeta = preservedMetadata.containsKey(codeUpper);

        if (detectedProf != null || hasOldMeta) {
          final oldMeta = hasOldMeta ? preservedMetadata[codeUpper] : null;
          final metaId = uuid.v4();
          final profNameValue = detectedProf ?? oldMeta?.profName;

          await db.into(db.courseMetadata).insert(
            CourseMetadataCompanion(
              id: Value(metaId),
              courseId: Value(courseId),
              classroomUrl: Value(oldMeta?.classroomUrl),
              lmsUrl: Value(oldMeta?.lmsUrl),
              profName: Value(profNameValue),
              profEmail: Value(oldMeta?.profEmail),
              consultationHours: Value(oldMeta?.consultationHours),
            ),
          );

          await db.enqueueMutation(
            mutationId: uuid.v4(),
            tableName: 'course_metadata',
            operation: 'UPSERT',
            payloadJson: jsonEncode({
              'id': metaId,
              'course_id': courseId,
              'classroom_url': oldMeta?.classroomUrl,
              'lms_url': oldMeta?.lmsUrl,
              'prof_name': profNameValue,
              'prof_email': oldMeta?.profEmail,
              'consultation_hours': oldMeta?.consultationHours,
            }),
          );
        }

        // Restore preserved syllabus tasks if existed
        if (preservedTasks.containsKey(codeUpper)) {
          for (final task in preservedTasks[codeUpper]!) {
            final taskId = uuid.v4();
            await db.into(db.courseTasks).insert(
              CourseTasksCompanion(
                id: Value(taskId),
                courseId: Value(courseId),
                title: Value(task.title),
                details: Value(task.details),
                taskType: Value(task.taskType),
                isCompleted: Value(task.isCompleted),
                dueDate: Value(task.dueDate),
                updatedAt: Value(now),
              ),
            );

            await db.enqueueMutation(
              mutationId: uuid.v4(),
              tableName: 'course_tasks',
              operation: 'UPSERT',
              payloadJson: jsonEncode({
                'id': taskId,
                'course_id': courseId,
                'title': task.title,
                'details': task.details,
                'task_type': task.taskType,
                'is_completed': task.isCompleted,
                'due_date': task.dueDate?.toIso8601String(),
                'updated_at': now.toIso8601String(),
              }),
            );
          }
        }
      }
    });

    // Proactively push all imported data to Supabase in background
    SyncOutboxWorker.instance?.triggerDebouncedSync();
  }
}
