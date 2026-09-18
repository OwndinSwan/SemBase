import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../models/timeline_item.dart';
import '../providers/dashboard_providers.dart';
import 'vacant_edit_modal.dart';

class DailyTimelineView extends ConsumerWidget {
  final Function(String courseId)? onCourseTap;

  const DailyTimelineView({super.key, this.onCourseTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroState = ref.watch(dashboardHeroStateProvider);
    final selectedDay = ref.watch(selectedDayTokenProvider);
    final items = heroState.timelineItems;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          children: const [
            Icon(Icons.event_busy, size: 40, color: AppTheme.textMutedDark),
            SizedBox(height: 12),
            Text(
              'No scheduled classes for this day',
              style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item.type == TimelineItemType.freeBlock) {
          return _buildFreeBlockTile(context, item, selectedDay);
        }

        return _buildClassTimelineTile(context, item);
      },
    );
  }

  Widget _buildFreeBlockTile(BuildContext context, TimelineItem item, String dayToken) {
    final durationHours = item.durationMinutes ~/ 60;
    final durationMins = item.durationMinutes % 60;
    final durationStr = durationHours > 0
        ? '${durationHours}h ${durationMins > 0 ? '${durationMins}m' : ''}'
        : '${durationMins}m';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentIndigo.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentIndigo.withOpacity(0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => VacantEditModal.show(context, item, dayToken),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.coffee_outlined, size: 16, color: AppTheme.accentIndigo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${item.displayLabel} • $durationStr free block',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentIndigo,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  TimeFormatter.formatTimeRange(item.startMinutes, item.endMinutes),
                  style: TextStyle(fontSize: 11, color: AppTheme.accentIndigo.withOpacity(0.8)),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_outlined, size: 14, color: AppTheme.accentIndigo.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassTimelineTile(BuildContext context, TimelineItem item) {
    final data = item.scheduleWithCourse;
    if (data == null) return const SizedBox.shrink();

    final isCurrent = item.isCurrent;
    final isUpNext = item.isUpNext;

    Color borderColor = AppTheme.borderDark.withOpacity(0.3);
    Color bgColor = AppTheme.cardDark;

    if (isCurrent) {
      borderColor = AppTheme.primaryGreen;
      bgColor = AppTheme.primaryGreen.withOpacity(0.12);
    } else if (isUpNext) {
      borderColor = AppTheme.accentCyan;
      bgColor = AppTheme.accentCyan.withOpacity(0.08);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: (isCurrent || isUpNext) ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onCourseTap?.call(data.course.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TimeFormatter.formatMinutesTo12Hour(item.startMinutes),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? AppTheme.primaryGreenLight : AppTheme.textPrimaryDark,
                      ),
                    ),
                    Text(
                      TimeFormatter.formatMinutesTo12Hour(item.endMinutes),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMutedDark),
                    ),
                    const SizedBox(height: 6),
                    SessionTypeBadge(sessionType: data.schedule.sessionType),
                  ],
                ),
                const SizedBox(width: 16),

                // Vertical Divider Line
                Container(
                  width: 2,
                  height: 60,
                  color: isCurrent ? AppTheme.primaryGreen : AppTheme.borderDark.withOpacity(0.5),
                ),
                const SizedBox(width: 16),

                // Course Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.course.courseCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryDark,
                              ),
                            ),
                          ),
                          if (data.schedule.isTba)
                            const TbaBadge()
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '📍 ${data.schedule.roomCode}',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.course.courseTitle,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (data.metadata?.profName != null && data.metadata!.profName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 13, color: AppTheme.textMutedDark),
                            const SizedBox(width: 4),
                            Text(
                              data.metadata!.profName!,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMutedDark),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
