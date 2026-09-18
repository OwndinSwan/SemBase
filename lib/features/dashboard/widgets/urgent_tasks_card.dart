import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/animated_task_checkbox.dart';
import '../providers/dashboard_providers.dart';
import 'task_deadline_modal.dart';

class UrgentTasksCard extends ConsumerStatefulWidget {
  const UrgentTasksCard({super.key});

  @override
  ConsumerState<UrgentTasksCard> createState() => _UrgentTasksCardState();
}

class _UrgentTasksCardState extends ConsumerState<UrgentTasksCard> {
  bool _isExpanded = false;

  String _getRelativeUrgency(DateTime? due) {
    if (due == null) return 'Soon';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(due.year, due.month, due.day);
    final diffDays = dueDate.difference(today).inDays;

    if (diffDays < 0) {
      return 'Overdue';
    } else if (diffDays == 0) {
      return 'Today';
    } else if (diffDays == 1) {
      return 'Tomorrow';
    } else {
      return 'In $diffDays d';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgentTasksAsync = ref.watch(urgentTasksStreamProvider);

    return urgentTasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();

        final pendingCount = tasks.where((t) => !t.task.isCompleted).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.accentRose.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentRose.withOpacity(0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown Header
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRose.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.alarm_on_rounded, color: AppTheme.accentRose, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Pinned Deadlines (Next 48 Hours)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentRose,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRose.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentRose.withOpacity(0.4)),
                          ),
                          child: Text(
                            '$pendingCount Due Soon',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentRose),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubic,
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.accentRose,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expandable Task List
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: _isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(color: Color(0x15FFFFFF), height: 1),
                              const SizedBox(height: 4),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: tasks.length > 5 ? 240 : double.infinity,
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: tasks.length > 5
                                      ? const BouncingScrollPhysics()
                                      : const NeverScrollableScrollPhysics(),
                                  itemCount: tasks.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                                  itemBuilder: (context, index) {
                                    final item = tasks[index];
                                    final task = item.task;
                                    final course = item.course;
                                    final urgencyTag = _getRelativeUrgency(task.dueDate);
                                    final hasDetails = task.details != null && task.details!.trim().isNotEmpty;
                                    final isOverdue = urgencyTag == 'Overdue';

                                    return Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          final db = ref.read(databaseProvider);
                                          TaskDeadlineModal.show(context, item: item, db: db);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              AnimatedTaskCheckbox(
                                                isCompleted: task.isCompleted,
                                                onChanged: (val) async {
                                                  final db = ref.read(databaseProvider);
                                                  await db.updateTaskStatus(task.id, val);
                                                },
                                              ),
                                              const SizedBox(width: 6),
                                              // Subject Code Chip
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryGreen.withOpacity(0.18),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  course.courseCode,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryGreenLight,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Task Title + Inline Paper Icon
                                              Expanded(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: AnimatedDefaultTextStyle(
                                                        duration: const Duration(milliseconds: 200),
                                                        style: TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.w600,
                                                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                                          decorationColor: AppTheme.textMutedDark,
                                                          color: task.isCompleted ? AppTheme.textMutedDark : AppTheme.textPrimaryDark,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                        child: Text(task.title),
                                                      ),
                                                    ),
                                                    if (hasDetails) ...[
                                                      const SizedBox(width: 4),
                                                      const Icon(
                                                        Icons.description_outlined,
                                                        size: 13,
                                                        color: AppTheme.textMutedDark,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Urgency Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: isOverdue
                                                      ? AppTheme.accentRose.withOpacity(0.2)
                                                      : AppTheme.accentAmber.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: isOverdue
                                                        ? AppTheme.accentRose.withOpacity(0.4)
                                                        : AppTheme.accentAmber.withOpacity(0.35),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Text(
                                                  urgencyTag,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isOverdue ? AppTheme.accentRose : AppTheme.accentAmber,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                size: 14,
                                                color: AppTheme.textMutedDark,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

