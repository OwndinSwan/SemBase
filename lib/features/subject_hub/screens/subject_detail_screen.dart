import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/notifications/alarm_notification_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_toast.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/animated_confirm_dialog.dart';
import '../../../shared/widgets/animated_task_checkbox.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const SubjectDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDetailsController = TextEditingController();
  String _selectedTaskType = 'requirement';
  DateTime? _selectedDueDate;
  String _taskFilter = 'all'; // 'all', 'pending', 'completed'
  bool _isScheduleAndFacultyExpanded = false;

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return StreamBuilder<CourseWithDetails?>(
      stream: db.watchCourseDetails(widget.courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Subject Details')),
            body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          );
        }

        final details = snapshot.data!;
        final course = details.course;
        final schedules = details.schedules;
        final metadata = details.metadata;
        final tasks = details.tasks;

        final completedTasksCount = tasks.where((t) => t.isCompleted).length;
        final pendingTasksCount = tasks.where((t) => !t.isCompleted).length;
        final taskProgress = tasks.isNotEmpty ? (completedTasksCount / tasks.length) : 0.0;
        final totalUnits = (course.lecUnits + course.labUnits).toInt();
        final primaryRoom = schedules.isNotEmpty ? schedules.first.roomCode : 'TBA';

        // Filter tasks based on selected tab
        final filteredTasks = tasks.where((t) {
          if (_taskFilter == 'pending') return !t.isCompleted;
          if (_taskFilter == 'completed') return t.isCompleted;
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              course.courseCode,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              _buildCircleActionButton(
                icon: Icons.edit_rounded,
                color: AppTheme.accentCyan,
                tooltip: 'Edit Subject Details',
                size: 36,
                iconSize: 18,
                onTap: () => _openEditSubjectDialog(context, course, metadata, schedules, db),
              ),
              const SizedBox(width: 8),
              _buildCircleActionButton(
                icon: Icons.delete_outline_rounded,
                color: AppTheme.accentRose,
                tooltip: 'Delete Subject',
                size: 36,
                iconSize: 18,
                onTap: () => _handleDeleteSubject(context, course, db),
              ),
              const SizedBox(width: 14),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1. HERO BANNER CARD
                // ==========================================
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF064E3B), // Deep Emerald
                        Color(0xFF0F172A), // Slate Obsidian
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative subtle green ambient circle
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Course Code & Units Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    course.courseCode,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.45), width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryGreen.withOpacity(0.15),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.school_rounded, size: 14, color: AppTheme.primaryGreenLight),
                                      const SizedBox(width: 5),
                                      Text(
                                        '$totalUnits Units',
                                        style: const TextStyle(
                                          color: AppTheme.primaryGreenLight,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Full Course Title
                            Text(
                              course.courseTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondaryDark.withOpacity(0.95),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Metadata Chips Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildBannerPill(
                                  icon: Icons.meeting_room_rounded,
                                  label: primaryRoom.isNotEmpty ? primaryRoom : 'TBA',
                                  color: AppTheme.accentCyan,
                                ),
                                _buildBannerPill(
                                  icon: Icons.layers_rounded,
                                  label: '${course.lecUnits.toInt()} Lec / ${course.labUnits.toInt()} Lab',
                                  color: AppTheme.primaryGreenLight,
                                ),
                                if (metadata?.profName != null && metadata!.profName!.trim().isNotEmpty)
                                  _buildBannerPill(
                                    icon: Icons.person_rounded,
                                    label: metadata!.profName!,
                                    color: AppTheme.accentAmber,
                                  ),
                                _buildBannerPill(
                                  icon: Icons.task_alt_rounded,
                                  label: '${(taskProgress * 100).toInt()}% Done',
                                  color: completedTasksCount == tasks.length && tasks.isNotEmpty
                                      ? AppTheme.primaryGreenLight
                                      : AppTheme.accentRose,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 2. UNIFIED SCHEDULE & FACULTY HUB DROPDOWN
                // ==========================================
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      // Dropdown Header
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _isScheduleAndFacultyExpanded = !_isScheduleAndFacultyExpanded),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: AppTheme.primaryGreenLight,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Schedule & Faculty Info',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${schedules.length} ${schedules.length == 1 ? "Slot" : "Slots"} • ${metadata?.profName ?? "Instructor Unassigned"}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedRotation(
                                turns: _isScheduleAndFacultyExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.textSecondaryDark,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expandable Body
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: _isScheduleAndFacultyExpanded
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(color: Color(0x15FFFFFF), height: 1),
                                    const SizedBox(height: 14),

                                    // A. Class Schedule Sub-Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Class Schedule',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryDark,
                                          ),
                                        ),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () => _openAddOrEditScheduleDialog(context, courseId: course.id, db: db),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Row(
                                              children: const [
                                                Icon(Icons.add_circle_outline_rounded, size: 15, color: AppTheme.primaryGreenLight),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Add Slot',
                                                  style: TextStyle(
                                                    color: AppTheme.primaryGreenLight,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Schedules List
                                    if (schedules.isEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgDark.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.borderDark.withOpacity(0.3)),
                                        ),
                                        child: Column(
                                          children: const [
                                            Icon(Icons.event_busy_rounded, size: 28, color: AppTheme.textMutedDark),
                                            SizedBox(height: 6),
                                            Text(
                                              'No scheduled class time slots yet.',
                                              style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: schedules.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final s = schedules[index];
                                          final durationMinutes = s.endMinutes - s.startMinutes;
                                          final durationHours = durationMinutes ~/ 60;
                                          final durationMins = durationMinutes % 60;
                                          final durationStr = durationHours > 0
                                              ? '${durationHours}h ${durationMins > 0 ? "${durationMins}m" : ""}'
                                              : '${durationMins}m';

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.bgDark.withOpacity(0.6),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.borderDark.withOpacity(0.35)),
                                            ),
                                            child: Row(
                                              children: [
                                                // Day Token Pill
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        AppTheme.primaryGreen.withOpacity(0.25),
                                                        AppTheme.primaryGreen.withOpacity(0.1),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.35)),
                                                  ),
                                                  child: Text(
                                                    s.dayToken,
                                                    style: const TextStyle(
                                                      color: AppTheme.primaryGreenLight,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),

                                                // Time & Room Details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            TimeFormatter.formatTimeRange(s.startMinutes, s.endMinutes),
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: AppTheme.textPrimaryDark,
                                                              fontSize: 12.5,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withOpacity(0.06),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              durationStr,
                                                              style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondaryDark),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            '📍 ${s.roomCode.isNotEmpty ? s.roomCode : "TBA"}',
                                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          SessionTypeBadge(sessionType: s.sessionType),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Actions
                                                _buildCircleActionButton(
                                                  icon: Icons.edit_rounded,
                                                  color: AppTheme.accentCyan,
                                                  tooltip: 'Edit Slot',
                                                  size: 30,
                                                  iconSize: 15,
                                                  onTap: () => _openAddOrEditScheduleDialog(
                                                    context,
                                                    courseId: course.id,
                                                    existingSchedule: s,
                                                    db: db,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                _buildCircleActionButton(
                                                  icon: Icons.delete_outline_rounded,
                                                  color: AppTheme.accentRose,
                                                  tooltip: 'Delete Slot',
                                                  size: 30,
                                                  iconSize: 15,
                                                  onTap: () => _handleDeleteSchedule(context, s, db),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    const SizedBox(height: 18),
                                    const Divider(color: Color(0x15FFFFFF), height: 1),
                                    const SizedBox(height: 14),

                                    // B. Quick Links & Faculty Hub Sub-Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Quick Links & Faculty Hub',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryDark,
                                          ),
                                        ),
                                        _buildCircleActionButton(
                                          icon: Icons.edit_note_rounded,
                                          color: AppTheme.accentCyan,
                                          tooltip: 'Edit Links & Faculty',
                                          size: 32,
                                          iconSize: 17,
                                          onTap: () => _openEditSubjectDialog(context, course, metadata, schedules, db),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Action Tiles Grid
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildActionTile(
                                            icon: Icons.school_rounded,
                                            title: 'Classroom',
                                            subtitle: metadata?.classroomUrl != null && metadata!.classroomUrl!.isNotEmpty ? 'Open' : 'Link',
                                            color: AppTheme.accentAmber,
                                            onTap: () => _launchURL(metadata?.classroomUrl),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildActionTile(
                                            icon: Icons.laptop_chromebook_rounded,
                                            title: 'LMS Portal',
                                            subtitle: metadata?.lmsUrl != null && metadata!.lmsUrl!.isNotEmpty ? 'Open LMS' : 'Link',
                                            color: AppTheme.accentCyan,
                                            onTap: () => _launchURL(metadata?.lmsUrl),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildActionTile(
                                            icon: Icons.email_rounded,
                                            title: 'Email Prof',
                                            subtitle: metadata?.profEmail != null && metadata!.profEmail!.isNotEmpty ? 'Send Email' : 'Set Email',
                                            color: AppTheme.primaryGreen,
                                            onTap: () => _launchEmail(metadata?.profEmail),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Faculty Info Card
                                    if (metadata?.profName != null || metadata?.consultationHours != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgDark.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.borderDark.withOpacity(0.35)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentAmber.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.person_rounded, size: 18, color: AppTheme.accentAmber),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    metadata?.profName ?? 'Instructor Unassigned',
                                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                                                  ),
                                                  if (metadata?.consultationHours != null && metadata!.consultationHours!.isNotEmpty)
                                                    Text(
                                                      'Consultation: ${metadata!.consultationHours}',
                                                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryDark),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 4. SYLLABUS & TASK CHECKLIST SECTION
                // ==========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Syllabus & Task Checklist',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                        ),
                        Text(
                          '$completedTasksCount of ${tasks.length} completed (${(taskProgress * 100).toInt()}%)',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openAddOrEditTaskDialog(context, courseId: course.id, db: db),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Task progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: taskProgress,
                    minHeight: 6,
                    backgroundColor: AppTheme.bgDark,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(height: 14),

                // Task Filter Segmented Chips
                Row(
                  children: [
                    _buildTaskFilterChip('All (${tasks.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildTaskFilterChip('Pending ($pendingTasksCount)', 'pending'),
                    const SizedBox(width: 8),
                    _buildTaskFilterChip('Completed ($completedTasksCount)', 'completed'),
                  ],
                ),
                const SizedBox(height: 12),

                // Tasks List
                if (filteredTasks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderDark.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.checklist_rtl_rounded, size: 40, color: AppTheme.textMutedDark),
                        const SizedBox(height: 8),
                        Text(
                          _taskFilter == 'completed'
                              ? 'No completed tasks yet.'
                              : _taskFilter == 'pending'
                                  ? 'All caught up! No pending tasks.'
                                  : 'No syllabus tasks added yet.',
                          style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
                        ),
                        if (_taskFilter == 'all') ...[
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => _openAddOrEditTaskDialog(context, courseId: course.id, db: db),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add First Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildTaskItem(context, task, db);
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
    double size = 32,
    double iconSize = 16,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskFilterChip(String label, String filterKey) {
    final isSelected = _taskFilter == filterKey;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _taskFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.2) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderDark.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primaryGreenLight : AppTheme.textSecondaryDark,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.9), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shiftTaskDeadline(
    BuildContext context,
    CourseTask task,
    int dayDelta,
    AppDatabase db,
  ) async {
    final baseDate = task.dueDate ?? DateTime.now();
    final newDate = baseDate.add(Duration(days: dayDelta));
    final normalized = TimeFormatter.normalizeDueDate(newDate);
    await db.updateTaskDueDate(task.id, normalized);
    AppLogService.info(
      AppLogService.catAction,
      'Shifted task deadline: "${task.title}" to ${TimeFormatter.formatDate(newDate)}',
    );
    if (context.mounted) {
      final direction = dayDelta > 0 ? '+${dayDelta ~/ 7}W' : '${dayDelta ~/ 7}W';
      AppToast.showInfo(
        context,
        'Deadline shifted ($direction) to ${TimeFormatter.formatDate(newDate)}',
        icon: Icons.event_repeat_rounded,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showTaskDeadlineOptionsModal(BuildContext context, CourseTask task, AppDatabase db) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final currentDue = task.dueDate;
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.schedule_rounded, color: AppTheme.accentCyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adjust Task Deadline',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                          ),
                          Text(
                            currentDue != null ? 'Current: ${TimeFormatter.formatDate(currentDue)}' : 'No deadline set',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.borderDark, height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bgDarkElevated,
                          foregroundColor: AppTheme.accentCyan,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.borderDark),
                          ),
                        ),
                        icon: const Icon(Icons.replay_rounded, size: 16),
                        label: const Text('- 1 Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _shiftTaskDeadline(context, task, -7, db);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                          foregroundColor: AppTheme.primaryGreenLight,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
                          ),
                        ),
                        icon: const Icon(Icons.forward_rounded, size: 16),
                        label: const Text('+ 1 Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _shiftTaskDeadline(context, task, 7, db);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppTheme.borderDark),
                        ),
                        icon: const Icon(Icons.today_rounded, size: 16, color: AppTheme.accentAmber),
                        label: const Text('Set to Today', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final today = TimeFormatter.normalizeDueDate(DateTime.now());
                          await db.updateTaskDueDate(task.id, today);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppTheme.borderDark),
                        ),
                        icon: const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.accentCyan),
                        label: const Text('Custom Date...', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: task.dueDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            final normalized = TimeFormatter.normalizeDueDate(picked);
                            await db.updateTaskDueDate(task.id, normalized);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (currentDue != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentRose,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      label: const Text('Remove Deadline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await db.updateTaskDueDate(task.id, null);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, CourseTask task, AppDatabase db) {
    Color typeColor;
    switch (task.taskType.toLowerCase()) {
      case 'assignment':
        typeColor = AppTheme.accentCyan;
        break;
      case 'exam':
        typeColor = AppTheme.accentRose;
        break;
      default:
        typeColor = AppTheme.accentAmber;
        break;
    }

    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1))) &&
        !task.isCompleted;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openTaskDetailsSheet(context, task, db),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            AnimatedTaskCheckbox(
              isCompleted: task.isCompleted,
              onChanged: (val) async {
                await db.updateTaskStatus(task.id, val);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: AppTheme.textMutedDark,
                      color: task.isCompleted ? AppTheme.textMutedDark : AppTheme.textPrimaryDark,
                    ),
                    child: Text(task.title),
                  ),
                  if (task.details != null && task.details!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.details!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: typeColor.withOpacity(0.35), width: 1),
                        ),
                        child: Text(
                          task.taskType.toUpperCase(),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      // Interactive Due Date Stepper Badge
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _showTaskDeadlineOptionsModal(context, task, db),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? AppTheme.accentRose.withOpacity(0.15)
                                : task.dueDate != null
                                    ? AppTheme.accentCyan.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isOverdue
                                  ? AppTheme.accentRose.withOpacity(0.4)
                                  : task.dueDate != null
                                      ? AppTheme.accentCyan.withOpacity(0.3)
                                      : AppTheme.borderDark,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                task.dueDate != null ? Icons.schedule_rounded : Icons.add_alarm_rounded,
                                size: 11,
                                color: isOverdue
                                    ? AppTheme.accentRose
                                    : task.dueDate != null
                                        ? AppTheme.accentCyan
                                        : AppTheme.textMutedDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.dueDate != null ? 'Due: ${TimeFormatter.formatDate(task.dueDate!)}' : '+ Deadline',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.w600,
                                  color: isOverdue
                                      ? AppTheme.accentRose
                                      : task.dueDate != null
                                          ? AppTheme.textPrimaryDark
                                          : AppTheme.textMutedDark,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.arrow_drop_down, size: 12, color: AppTheme.textSecondaryDark),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCircleActionButton(
                  icon: Icons.event_repeat_rounded,
                  color: AppTheme.accentCyan,
                  tooltip: 'Reschedule (+/- 1 Week)',
                  size: 28,
                  iconSize: 14,
                  onTap: () => _showTaskDeadlineOptionsModal(context, task, db),
                ),
                const SizedBox(width: 4),
                _buildCircleActionButton(
                  icon: Icons.edit_rounded,
                  color: AppTheme.accentAmber,
                  tooltip: 'Edit Task',
                  size: 28,
                  iconSize: 14,
                  onTap: () => _openAddOrEditTaskDialog(context, courseId: task.courseId, existingTask: task, db: db),
                ),
                const SizedBox(width: 4),
                _buildCircleActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppTheme.accentRose,
                  tooltip: 'Delete Task',
                  size: 28,
                  iconSize: 14,
                  onTap: () => _handleDeleteTask(context, task, db),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TASK DETAILS BOTTOM SHEET
  // ==========================================

  void _openTaskDetailsSheet(BuildContext context, CourseTask task, AppDatabase db) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final navBarPadding = MediaQuery.of(ctx).padding.bottom;
        return SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: navBarPadding > 0 ? navBarPadding + 16 : 24,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                    ),
                    _buildCircleActionButton(
                      icon: Icons.edit_rounded,
                      color: AppTheme.accentCyan,
                      tooltip: 'Edit Task',
                      size: 36,
                      iconSize: 18,
                      onTap: () {
                        Navigator.pop(ctx);
                        _openAddOrEditTaskDialog(context, courseId: task.courseId, existingTask: task, db: db);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.taskType.toUpperCase(),
                        style: const TextStyle(color: AppTheme.primaryGreenLight, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDarkElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderDark.withOpacity(0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_rounded, size: 16, color: AppTheme.accentCyan),
                          const SizedBox(width: 6),
                          Text(
                            task.dueDate != null
                                ? 'Deadline: ${TimeFormatter.formatDate(task.dueDate!)}'
                                : 'No Deadline Configured',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                side: const BorderSide(color: AppTheme.borderDark),
                              ),
                              icon: const Icon(Icons.replay_rounded, size: 14, color: AppTheme.accentCyan),
                              label: const Text('- 1 Week', style: TextStyle(fontSize: 11, color: AppTheme.textPrimaryDark)),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _shiftTaskDeadline(context, task, -7, db);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                                foregroundColor: AppTheme.primaryGreenLight,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
                                ),
                              ),
                              icon: const Icon(Icons.forward_rounded, size: 14),
                              label: const Text('+ 1 Week', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _shiftTaskDeadline(context, task, 7, db);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.textSecondaryDark),
                            tooltip: 'Pick Date',
                            onPressed: () => _showTaskDeadlineOptionsModal(context, task, db),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Text(
                  'Task Details & Notes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
                  ),
                  child: Text(
                    task.details != null && task.details!.trim().isNotEmpty
                        ? task.details!
                        : 'No additional details provided. Tap edit to add instructions, links, or reviewer notes.',
                    style: TextStyle(
                      fontSize: 13,
                      color: task.details != null && task.details!.trim().isNotEmpty
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textMutedDark,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: task.isCompleted ? AppTheme.bgDarkElevated : AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: task.isCompleted ? const BorderSide(color: AppTheme.borderDark) : BorderSide.none,
                          ),
                        ),
                        icon: Icon(task.isCompleted ? Icons.undo : Icons.check_circle_outline, size: 18),
                        label: Text(task.isCompleted ? 'Mark as Incomplete' : 'Mark as Done'),
                        onPressed: () async {
                          await db.updateTaskStatus(task.id, !task.isCompleted);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddOrEditTaskDialog(
    BuildContext context, {
    required String courseId,
    CourseTask? existingTask,
    required AppDatabase db,
  }) {
    _taskTitleController.text = existingTask?.title ?? '';
    _taskDetailsController.text = existingTask?.details ?? '';
    _selectedTaskType = existingTask?.taskType ?? 'requirement';
    _selectedDueDate = existingTask?.dueDate;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 360,
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.35), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    existingTask != null ? Icons.edit_note_rounded : Icons.add_task_rounded,
                                    color: AppTheme.primaryGreenLight,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        existingTask != null ? 'Edit Task' : 'Add Syllabus Task',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryDark,
                                        ),
                                      ),
                                      const Text(
                                        'Set title, category, and deadline',
                                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryDark, size: 20),
                                  onPressed: () => Navigator.of(dialogCtx).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Task Category',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildCategoryChip('requirement', 'Requirement', AppTheme.accentAmber, setModalState),
                                const SizedBox(width: 6),
                                _buildCategoryChip('assignment', 'Assignment', AppTheme.accentCyan, setModalState),
                                const SizedBox(width: 6),
                                _buildCategoryChip('exam', 'Exam', AppTheme.accentRose, setModalState),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _taskTitleController,
                              autofocus: existingTask == null,
                              style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Task Title *',
                                labelStyle: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
                                hintText: 'e.g. Midterm Project, Lab Manual',
                                hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                                prefixIcon: const Icon(Icons.title_rounded, size: 18, color: AppTheme.accentCyan),
                                filled: true,
                                fillColor: AppTheme.bgDark.withOpacity(0.6),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.borderDark),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _taskDetailsController,
                              maxLines: 2,
                              style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Instructions / Notes',
                                labelStyle: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
                                hintText: 'Optional notes, reviewer topics...',
                                hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                                prefixIcon: const Icon(Icons.notes_rounded, size: 18, color: AppTheme.textSecondaryDark),
                                filled: true,
                                fillColor: AppTheme.bgDark.withOpacity(0.6),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.borderDark),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.bgDarkElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.event_rounded, size: 16, color: AppTheme.primaryGreenLight),
                                          const SizedBox(width: 6),
                                          Text(
                                            _selectedDueDate == null
                                                ? 'No Deadline'
                                                : TimeFormatter.formatDate(_selectedDueDate!),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedDueDate == null ? AppTheme.textMutedDark : AppTheme.textPrimaryDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_selectedDueDate != null)
                                        InkWell(
                                          onTap: () => setModalState(() => _selectedDueDate = null),
                                          child: const Text('Clear', style: TextStyle(fontSize: 11, color: AppTheme.accentRose, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildDatePresetChip('Today', () {
                                        setModalState(() => _selectedDueDate = TimeFormatter.normalizeDueDate(DateTime.now()));
                                      }),
                                      _buildDatePresetChip('- 1 Week', () {
                                        final base = _selectedDueDate ?? DateTime.now();
                                        setModalState(() => _selectedDueDate = TimeFormatter.normalizeDueDate(base.subtract(const Duration(days: 7))));
                                      }),
                                      _buildDatePresetChip('+ 1 Week', () {
                                        final base = _selectedDueDate ?? DateTime.now();
                                        setModalState(() => _selectedDueDate = TimeFormatter.normalizeDueDate(base.add(const Duration(days: 7))));
                                      }),
                                      _buildDatePresetChip('📅 Custom...', () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDueDate ?? DateTime.now(),
                                          firstDate: DateTime.now().subtract(const Duration(days: 60)),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null) {
                                          setModalState(() => _selectedDueDate = TimeFormatter.normalizeDueDate(picked));
                                        }
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(color: AppTheme.borderDark),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => Navigator.of(dialogCtx).pop(),
                                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryDark, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    onPressed: () async {
                                      final title = _taskTitleController.text.trim();
                                      if (title.isEmpty) return;

                                      if (existingTask != null) {
                                        await db.updateTaskFull(
                                          CourseTasksCompanion(
                                            id: drift.Value(existingTask.id),
                                            courseId: drift.Value(courseId),
                                            title: drift.Value(title),
                                            details: drift.Value(_taskDetailsController.text.trim()),
                                            taskType: drift.Value(_selectedTaskType),
                                            isCompleted: drift.Value(existingTask.isCompleted),
                                            dueDate: drift.Value(_selectedDueDate),
                                            updatedAt: drift.Value(DateTime.now()),
                                          ),
                                        );
                                        AppLogService.info(AppLogService.catAction, 'Updated task: "$title"');
                                      } else {
                                        await db.insertTask(
                                          CourseTasksCompanion.insert(
                                            id: const Uuid().v4(),
                                            courseId: courseId,
                                            title: title,
                                            details: drift.Value(_taskDetailsController.text.trim()),
                                            taskType: _selectedTaskType,
                                            dueDate: drift.Value(_selectedDueDate),
                                          ),
                                        );
                                        AppLogService.info(AppLogService.catAction, 'Added new task: "$title"');
                                      }

                                      if (mounted) Navigator.of(dialogCtx).pop();
                                    },
                                    child: Text(
                                      existingTask != null ? 'Save Changes' : 'Add Task',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String type, String label, Color color, StateSetter setModalState) {
    final isSelected = _selectedTaskType == type;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setModalState(() => _selectedTaskType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppTheme.bgDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderDark,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppTheme.textSecondaryDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePresetChip(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _openAddOrEditScheduleDialog(
    BuildContext context, {
    required String courseId,
    CourseSchedule? existingSchedule,
    required AppDatabase db,
  }) {
    String selectedDay = existingSchedule?.dayToken ?? 'M';
    int startMinutes = existingSchedule?.startMinutes ?? 480;
    int endMinutes = existingSchedule?.endMinutes ?? 600;
    final roomCtrl = TextEditingController(text: existingSchedule?.roomCode ?? 'TBA');
    String sessionType = existingSchedule?.sessionType ?? 'lecture';

    final days = ['M', 'T', 'W', 'TH', 'F', 'S', 'SUN'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final durationMin = endMinutes - startMinutes;
                final durationHours = durationMin ~/ 60;
                final durationRemainder = durationMin % 60;
                final durationStr = durationHours > 0
                    ? '${durationHours}h ${durationRemainder > 0 ? "${durationRemainder}m" : ""}'
                    : '${durationRemainder}m';

                return Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 360,
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.35), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentCyan.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    existingSchedule != null ? Icons.edit_calendar_rounded : Icons.alarm_add_rounded,
                                    color: AppTheme.accentCyan,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        existingSchedule != null ? 'Edit Schedule Slot' : 'Add Schedule Slot',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryDark,
                                        ),
                                      ),
                                      const Text(
                                        'Configure day, time window & room',
                                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryDark, size: 20),
                                  onPressed: () => Navigator.of(dialogCtx).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Day of the Week',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: days.map((day) {
                                  final isSelected = selectedDay == day;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => setModalState(() => selectedDay = day),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppTheme.accentCyan : AppTheme.bgDarkElevated,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? AppTheme.accentCyan : AppTheme.borderDark,
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Text(
                                          day,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.black : AppTheme.textPrimaryDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final initial = TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60);
                                      final picked = await showTimePicker(context: context, initialTime: initial);
                                      if (picked != null) {
                                        setModalState(() {
                                          startMinutes = picked.hour * 60 + picked.minute;
                                          if (endMinutes <= startMinutes) endMinutes = startMinutes + 90;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgDarkElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.borderDark),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.access_time, size: 14, color: AppTheme.primaryGreenLight),
                                              SizedBox(width: 4),
                                              Text('Start Time', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            TimeFormatter.formatMinutesTo12Hour(startMinutes),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final initial = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
                                      final picked = await showTimePicker(context: context, initialTime: initial);
                                      if (picked != null) {
                                        setModalState(() => endMinutes = picked.hour * 60 + picked.minute);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgDarkElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.borderDark),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.access_time_filled, size: 14, color: AppTheme.accentCyan),
                                              SizedBox(width: 4),
                                              Text('End Time', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            TimeFormatter.formatMinutesTo12Hour(endMinutes),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentCyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, size: 13, color: AppTheme.accentCyan),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Duration: $durationStr',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Session Type',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => setModalState(() => sessionType = 'lecture'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: sessionType == 'lecture' ? AppTheme.accentCyan.withOpacity(0.2) : AppTheme.bgDarkElevated,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: sessionType == 'lecture' ? AppTheme.accentCyan : AppTheme.borderDark,
                                          width: sessionType == 'lecture' ? 1.5 : 1,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text('Lecture (LEC)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryDark)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => setModalState(() => sessionType = 'lab'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: sessionType == 'lab' ? AppTheme.accentAmber.withOpacity(0.2) : AppTheme.bgDarkElevated,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: sessionType == 'lab' ? AppTheme.accentAmber : AppTheme.borderDark,
                                          width: sessionType == 'lab' ? 1.5 : 1,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text('Laboratory (LAB)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryDark)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: roomCtrl,
                              style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Room Code / Building',
                                labelStyle: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
                                hintText: 'e.g. CL1, ICT-202, TBA',
                                hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                                prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18, color: AppTheme.accentCyan),
                                filled: true,
                                fillColor: AppTheme.bgDark.withOpacity(0.6),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.borderDark),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.accentCyan, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(color: AppTheme.borderDark),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => Navigator.of(dialogCtx).pop(),
                                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryDark, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentCyan,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    onPressed: () async {
                                      final room = roomCtrl.text.trim().isEmpty ? 'TBA' : roomCtrl.text.trim();

                                      if (existingSchedule != null) {
                                        await db.updateSchedule(
                                          CourseSchedulesCompanion(
                                            id: drift.Value(existingSchedule.id),
                                            courseId: drift.Value(courseId),
                                            dayToken: drift.Value(selectedDay),
                                            startMinutes: drift.Value(startMinutes),
                                            endMinutes: drift.Value(endMinutes),
                                            roomCode: drift.Value(room),
                                            sessionType: drift.Value(sessionType),
                                            isTba: drift.Value(room == 'TBA'),
                                          ),
                                        );
                                        AppLogService.info(
                                          AppLogService.catAction,
                                          'Updated schedule slot: $selectedDay ${TimeFormatter.formatTimeRange(startMinutes, endMinutes)} ($room)',
                                        );
                                      } else {
                                        await db.insertSchedule(
                                          CourseSchedulesCompanion.insert(
                                            id: const Uuid().v4(),
                                            courseId: courseId,
                                            dayToken: selectedDay,
                                            startMinutes: startMinutes,
                                            endMinutes: endMinutes,
                                            roomCode: room,
                                            sessionType: sessionType,
                                            isTba: drift.Value(room == 'TBA'),
                                          ),
                                        );
                                        AppLogService.info(
                                          AppLogService.catAction,
                                          'Added new schedule slot: $selectedDay ${TimeFormatter.formatTimeRange(startMinutes, endMinutes)} ($room)',
                                        );
                                      }

                                      Navigator.of(dialogCtx).pop();
                                      AlarmNotificationService.syncAllClassAlarms(db);
                                    },
                                    child: Text(
                                      existingSchedule != null ? 'Update Slot' : 'Add Slot',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteSchedule(BuildContext context, CourseSchedule schedule, AppDatabase db) async {
    final confirmed = await AnimatedConfirmDialog.show(
      context,
      title: 'Delete Schedule Slot?',
      message: 'Remove ${schedule.dayToken} (${TimeFormatter.formatTimeRange(schedule.startMinutes, schedule.endMinutes)}) from this course?',
      confirmLabel: 'Delete Slot',
      confirmColor: AppTheme.accentRose,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed) {
      await db.deleteSchedule(schedule.id);
      AppLogService.info(
        AppLogService.catAction,
        'Deleted schedule slot: ${schedule.dayToken} ${TimeFormatter.formatTimeRange(schedule.startMinutes, schedule.endMinutes)}',
      );
      await AlarmNotificationService.syncAllClassAlarms(db);
    }
  }

  // ==========================================
  // DELETE TASK HANDLER
  // ==========================================

  Future<void> _handleDeleteTask(BuildContext context, CourseTask task, AppDatabase db) async {
    final confirmed = await AnimatedConfirmDialog.show(
      context,
      title: 'Delete Task',
      message: 'Are you sure you want to remove "${task.title}"?',
      confirmLabel: 'Delete',
      confirmColor: AppTheme.accentRose,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed) {
      await db.deleteTask(task.id);
      AppLogService.info(AppLogService.catAction, 'Deleted task: "${task.title}"');
    }
  }

  // ==========================================
  // EDIT SUBJECT DETAILS MODAL (ANIMATED SPRING DIALOG)
  // ==========================================

  void _openEditSubjectDialog(
    BuildContext context,
    Course course,
    CourseMetadataEntry? metadata,
    List<CourseSchedule> schedules,
    AppDatabase db,
  ) {
    final codeCtrl = TextEditingController(text: course.courseCode);
    final titleCtrl = TextEditingController(text: course.courseTitle);
    final lecCtrl = TextEditingController(text: course.lecUnits.toString());
    final labCtrl = TextEditingController(text: course.labUnits.toString());
    final lmsCtrl = TextEditingController(text: metadata?.lmsUrl ?? '');
    final classCtrl = TextEditingController(text: metadata?.classroomUrl ?? '');
    final profNameCtrl = TextEditingController(text: metadata?.profName ?? '');
    final profEmailCtrl = TextEditingController(text: metadata?.profEmail ?? '');
    final consultCtrl = TextEditingController(text: metadata?.consultationHours ?? '');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 380,
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school_rounded, color: AppTheme.primaryGreenLight, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Edit Subject Details',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryDark,
                                    ),
                                  ),
                                  Text(
                                    course.courseCode,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreenLight, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryDark, size: 20),
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader('1. Course Information', Icons.menu_book_rounded),
                        const SizedBox(height: 8),
                        TextField(
                          controller: codeCtrl,
                          style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Course Code *',
                            prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppTheme.accentCyan),
                            filled: true,
                            fillColor: AppTheme.bgDark.withOpacity(0.6),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleCtrl,
                          style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Course Title *',
                            prefixIcon: const Icon(Icons.auto_stories_outlined, size: 18, color: AppTheme.accentCyan),
                            filled: true,
                            fillColor: AppTheme.bgDark.withOpacity(0.6),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: lecCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Lec Units',
                                  filled: true,
                                  fillColor: AppTheme.bgDark.withOpacity(0.6),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: labCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Lab Units',
                                  filled: true,
                                  fillColor: AppTheme.bgDark.withOpacity(0.6),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader('2. Faculty & Office Hours', Icons.person_outline_rounded),
                        const SizedBox(height: 8),
                        TextField(
                          controller: profNameCtrl,
                          style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Instructor Name',
                            prefixIcon: const Icon(Icons.person_pin_outlined, size: 18, color: AppTheme.accentAmber),
                            filled: true,
                            fillColor: AppTheme.bgDark.withOpacity(0.6),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: profEmailCtrl,
                          style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Instructor Email',
                            prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppTheme.accentAmber),
                            filled: true,
                            fillColor: AppTheme.bgDark.withOpacity(0.6),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: consultCtrl,
                          style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Consultation Hours',
                            prefixIcon: const Icon(Icons.schedule_outlined, size: 18, color: AppTheme.accentAmber),
                            filled: true,
                            fillColor: AppTheme.bgDark.withOpacity(0.6),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader('3. Digital Classroom & LMS', Icons.link_rounded),
                        const SizedBox(height: 8),
                        TextField(
                          controller: classCtrl,
                          style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Google Classroom URL',
                            prefixIcon: const Icon(Icons.cast_for_education_rounded, size: 18, color: AppTheme.accentCyan),
                            filled: true,
                            fillColor: AppTheme.bgDark.withOpacity(0.6),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: lmsCtrl,
                          style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'LMS Portal URL',
                            prefixIcon: const Icon(Icons.language_rounded, size: 18, color: AppTheme.accentCyan),
                            filled: true,
                            fillColor: AppTheme.bgDark.withOpacity(0.6),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: AppTheme.borderDark),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryDark, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  final newCode = codeCtrl.text.trim();
                                  final newTitle = titleCtrl.text.trim();
                                  if (newCode.isEmpty || newTitle.isEmpty) return;

                                  final parsedLec = double.tryParse(lecCtrl.text.trim()) ?? course.lecUnits;
                                  final parsedLab = double.tryParse(labCtrl.text.trim()) ?? course.labUnits;

                                  await db.updateCourse(
                                    CoursesCompanion(
                                      id: drift.Value(course.id),
                                      courseCode: drift.Value(newCode),
                                      courseTitle: drift.Value(newTitle),
                                      lecUnits: drift.Value(parsedLec),
                                      labUnits: drift.Value(parsedLab),
                                    ),
                                  );

                                  await db.upsertCourseMetadata(
                                    CourseMetadataCompanion(
                                      id: drift.Value(metadata?.id ?? const Uuid().v4()),
                                      courseId: drift.Value(course.id),
                                      classroomUrl: drift.Value(classCtrl.text.trim().isEmpty ? null : classCtrl.text.trim()),
                                      lmsUrl: drift.Value(lmsCtrl.text.trim().isEmpty ? null : lmsCtrl.text.trim()),
                                      profName: drift.Value(profNameCtrl.text.trim().isEmpty ? null : profNameCtrl.text.trim()),
                                      profEmail: drift.Value(profEmailCtrl.text.trim().isEmpty ? null : profEmailCtrl.text.trim()),
                                      consultationHours: drift.Value(consultCtrl.text.trim().isEmpty ? null : consultCtrl.text.trim()),
                                    ),
                                  );

                                  AppLogService.info(
                                    AppLogService.catAction,
                                    'Updated course details: $newCode - $newTitle',
                                  );

                                  if (mounted) Navigator.of(dialogCtx).pop();
                                },
                                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.accentCyan),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
        ),
      ],
    );
  }

  Future<void> _handleDeleteSubject(BuildContext context, Course course, AppDatabase db) async {
    final confirmed = await AnimatedConfirmDialog.show(
      context,
      title: 'Delete Subject',
      message: 'Are you sure you want to delete "${course.courseCode} - ${course.courseTitle}"? All associated tasks and schedules will be removed.',
      confirmLabel: 'Delete Subject',
      confirmColor: AppTheme.accentRose,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed) {
      await db.deleteCourse(course.id);
      AppLogService.info(
        AppLogService.catAction,
        'Deleted course: ${course.courseCode} - ${course.courseTitle}',
      );
      await AlarmNotificationService.syncAllClassAlarms(db);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _launchURL(String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty) {
      AppToast.showWarning(context, 'No URL configured for this resource.');
      return;
    }
    final uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        AppToast.showError(context, 'Could not open $urlStr');
      }
    }
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.isEmpty) {
      AppToast.showWarning(context, 'No email address configured for this instructor.');
      return;
    }
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
