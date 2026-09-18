import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_toast.dart';
import '../../subject_hub/screens/subject_detail_screen.dart';

/// Comprehensive task & deadline details modal for Pinned Deadlines,
/// matching the exact design and modals from Subject Hub.
class TaskDeadlineModal extends StatefulWidget {
  final TaskWithCourse item;
  final AppDatabase db;

  const TaskDeadlineModal({
    super.key,
    required this.item,
    required this.db,
  });

  static Future<void> show(
    BuildContext context, {
    required TaskWithCourse item,
    required AppDatabase db,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDeadlineModal(item: item, db: db),
    );
  }

  @override
  State<TaskDeadlineModal> createState() => _TaskDeadlineModalState();
}

class _TaskDeadlineModalState extends State<TaskDeadlineModal> {
  late CourseTask _task;
  late Course _course;
  late CourseMetadataEntry? _metadata;

  // Controllers for Add/Edit Dialog
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDetailsController = TextEditingController();
  String _selectedTaskType = 'requirement';
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _task = widget.item.task;
    _course = widget.item.course;
    _metadata = widget.item.metadata;
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDetailsController.dispose();
    super.dispose();
  }

  Future<void> _refreshTask() async {
    final updated = await (widget.db.select(widget.db.courseTasks)
          ..where((t) => t.id.equals(_task.id)))
        .getSingleOrNull();
    if (updated != null && mounted) {
      setState(() {
        _task = updated;
      });
    }
  }

  Future<void> _toggleCompletion() async {
    final nextStatus = !_task.isCompleted;
    await widget.db.updateTaskStatus(_task.id, nextStatus);
    await _refreshTask();
  }

  Future<void> _shiftTaskDeadline(int dayDelta) async {
    final baseDate = _task.dueDate ?? DateTime.now();
    final newDate = baseDate.add(Duration(days: dayDelta));
    final normalized = TimeFormatter.normalizeDueDate(newDate);
    await widget.db.updateTaskDueDate(_task.id, normalized);
    await _refreshTask();
    if (mounted) {
      final direction = dayDelta > 0 ? '+${dayDelta ~/ 7}W' : '${dayDelta ~/ 7}W';
      AppToast.showInfo(
        context,
        'Deadline shifted ($direction) to ${TimeFormatter.formatDate(newDate)}',
        icon: Icons.event_repeat_rounded,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ==========================================
  // ADJUST DEADLINE OPTIONS MODAL (from Subject Hub)
  // ==========================================
  void _showTaskDeadlineOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final currentDue = _task.dueDate;
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
                          _shiftTaskDeadline(-7);
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
                          _shiftTaskDeadline(7);
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
                          await widget.db.updateTaskDueDate(_task.id, today);
                          await _refreshTask();
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
                            initialDate: _task.dueDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            final normalized = TimeFormatter.normalizeDueDate(picked);
                            await widget.db.updateTaskDueDate(_task.id, normalized);
                            await _refreshTask();
                          }
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

  // ==========================================
  // EDIT TASK DIALOG (from Subject Hub)
  // ==========================================
  void _openEditTaskDialog(BuildContext context) {
    _taskTitleController.text = _task.title;
    _taskDetailsController.text = _task.details ?? '';
    _selectedTaskType = _task.taskType;
    _selectedDueDate = _task.dueDate;

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
                                  child: const Icon(
                                    Icons.edit_note_rounded,
                                    color: AppTheme.primaryGreenLight,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Edit Task',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryDark,
                                        ),
                                      ),
                                      Text(
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
                              autofocus: false,
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

                                      await widget.db.updateTaskFull(
                                        CourseTasksCompanion(
                                          id: drift.Value(_task.id),
                                          courseId: drift.Value(_task.courseId),
                                          title: drift.Value(title),
                                          details: drift.Value(_taskDetailsController.text.trim().isEmpty ? null : _taskDetailsController.text.trim()),
                                          taskType: drift.Value(_selectedTaskType),
                                          isCompleted: drift.Value(_task.isCompleted),
                                          dueDate: drift.Value(_selectedDueDate),
                                          updatedAt: drift.Value(DateTime.now()),
                                        ),
                                      );
                                      await _refreshTask();
                                      if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // DELETE TASK CONFIRMATION DIALOG (from Subject Hub)
  // ==========================================
  void _openDeleteTaskDialog(BuildContext context) {
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
                  width: 340,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.accentRose.withOpacity(0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accentRose.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRose, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delete Task',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryDark,
                                  ),
                                ),
                                Text(
                                  'Remove this task permanently',
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
                      Text(
                        'Are you sure you want to delete "${_task.title}"? This cannot be undone.',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryDark, height: 1.4),
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
                                backgroundColor: AppTheme.accentRose,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                Navigator.of(dialogCtx).pop();
                                await widget.db.deleteTask(_task.id);
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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
        );
      },
    );
  }

  Widget _buildCategoryChip(String type, String label, Color color, StateSetter setModalState) {
    final isSelected = _selectedTaskType == type;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setModalState(() => _selectedTaskType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppTheme.bgDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderDark.withOpacity(0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppTheme.textSecondaryDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePresetChip(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderDark.withOpacity(0.7)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimaryDark)),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    double size = 36,
    double iconSize = 18,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBarPadding = MediaQuery.of(context).padding.bottom;

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
            // Drag Handle
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

            // Task Title + Action Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCircleActionButton(
                      icon: Icons.edit_rounded,
                      color: AppTheme.accentCyan,
                      tooltip: 'Edit Task',
                      onTap: () => _openEditTaskDialog(context),
                    ),
                    const SizedBox(width: 8),
                    _buildCircleActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: AppTheme.accentRose,
                      tooltip: 'Delete Task',
                      onTap: () => _openDeleteTaskDialog(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Subject Badge + Task Category Chips
            Row(
              children: [
                // Subject Code Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                  ),
                  child: Text(
                    _course.courseCode,
                    style: const TextStyle(
                      color: AppTheme.primaryGreenLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Task Type Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _task.taskType.toUpperCase(),
                    style: const TextStyle(color: AppTheme.primaryGreenLight, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                // View Subject Hub Link
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SubjectDetailScreen(courseId: _course.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      children: const [
                        Text(
                          'View Hub',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreenLight,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.primaryGreenLight),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deadline Section Box
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
                      Expanded(
                        child: Text(
                          _task.dueDate != null
                              ? 'Deadline: ${TimeFormatter.formatDate(_task.dueDate!)}'
                              : 'No Deadline Configured',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                          onPressed: () => _shiftTaskDeadline(-7),
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
                          onPressed: () => _shiftTaskDeadline(7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.textSecondaryDark),
                        tooltip: 'Pick Date',
                        onPressed: () => _showTaskDeadlineOptionsModal(context),
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
                _task.details != null && _task.details!.trim().isNotEmpty
                    ? _task.details!
                    : 'No additional details provided. Tap edit to add instructions, links, or reviewer notes.',
                style: TextStyle(
                  fontSize: 13,
                  color: _task.details != null && _task.details!.trim().isNotEmpty
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
                      backgroundColor: _task.isCompleted ? AppTheme.bgDarkElevated : AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: _task.isCompleted ? const BorderSide(color: AppTheme.borderDark) : BorderSide.none,
                      ),
                    ),
                    icon: Icon(_task.isCompleted ? Icons.undo : Icons.check_circle_outline, size: 18),
                    label: Text(_task.isCompleted ? 'Mark as Incomplete' : 'Mark as Done'),
                    onPressed: () async {
                      await _toggleCompletion();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
