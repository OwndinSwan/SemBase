import '../../../core/database/app_database.dart';

enum TimelineItemType {
  classSession,
  freeBlock,
  tbaSession,
}

/// Represents an item in the daily chronological timeline
class TimelineItem {
  final TimelineItemType type;
  final int startMinutes;
  final int endMinutes;
  final ScheduleWithCourse? scheduleWithCourse;
  final bool isCurrent;
  final bool isUpNext;
  final double progressPercent; // 0.0 to 1.0 for current class
  final Duration remainingDuration;
  final String? blockId;
  final String? customLabel;

  const TimelineItem({
    required this.type,
    required this.startMinutes,
    required this.endMinutes,
    this.scheduleWithCourse,
    this.isCurrent = false,
    this.isUpNext = false,
    this.progressPercent = 0.0,
    this.remainingDuration = Duration.zero,
    this.blockId,
    this.customLabel,
  });

  int get durationMinutes => endMinutes - startMinutes;
  String get displayLabel => customLabel ?? 'Vacant Period';
}
