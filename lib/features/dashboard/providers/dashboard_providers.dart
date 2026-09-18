import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/vacant_period_service.dart';
import '../../../core/utils/time_formatter.dart';
import '../models/timeline_item.dart';

/// 1-second ticking timer stream provider for live hero countdowns and progress bars
final tickerStreamProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  controller.add(DateTime.now());

  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (!controller.isClosed) {
      controller.add(DateTime.now());
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Watches changes in user custom vacant period edits or deletions
final vacantChangeProvider = StreamProvider<int>((ref) {
  final controller = StreamController<int>();
  void listener() => controller.add(VacantPeriodService.changeNotifier.value);
  VacantPeriodService.changeNotifier.addListener(listener);
  ref.onDispose(() {
    VacantPeriodService.changeNotifier.removeListener(listener);
    controller.close();
  });
  return controller.stream;
});

/// Day token currently selected in Dashboard (defaults to current weekday)
final selectedDayTokenProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  final day = TimeFormatter.getDayTokenFromWeekday(now.weekday);
  return day.isNotEmpty ? day : 'M';
});

/// Schedules for the selected day
final schedulesForSelectedDayProvider = StreamProvider<List<ScheduleWithCourse>>((ref) {
  final db = ref.watch(databaseProvider);
  final profileAsync = ref.watch(activeProfileStreamProvider);
  final dayToken = ref.watch(selectedDayTokenProvider);

  return profileAsync.when(
    data: (profile) {
      if (profile == null) return Stream.value([]);
      return db.watchSchedulesForDay(profile.id, dayToken);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Schedules strictly for TODAY (based on actual DateTime.now(), immune to UI day-tab switching and strictly empty on Sundays)
final todayActualSchedulesProvider = StreamProvider<List<ScheduleWithCourse>>((ref) {
  final db = ref.watch(databaseProvider);
  final profileAsync = ref.watch(activeProfileStreamProvider);
  final now = DateTime.now();
  final todayToken = TimeFormatter.getDayTokenFromWeekday(now.weekday);

  return profileAsync.when(
    data: (profile) {
      if (profile == null || todayToken.isEmpty || now.weekday == DateTime.sunday) {
        return Stream.value([]);
      }
      return db.watchSchedulesForDay(profile.id, todayToken);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Urgent tasks due within 48 hours for active profile
final urgentTasksStreamProvider = StreamProvider<List<TaskWithCourse>>((ref) {
  final db = ref.watch(databaseProvider);
  final profileAsync = ref.watch(activeProfileStreamProvider);

  return profileAsync.when(
    data: (profile) {
      if (profile == null) return Stream.value([]);
      return db.watchPendingTasksDueWithinHours(profile.id, AppConfig.deadlineAlertWindowHours);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Hero State Model for the live countdown, up-next class, and daily timeline
class DashboardHeroState {
  final ScheduleWithCourse? currentClass;
  final double currentProgress; // 0.0 to 1.0
  final Duration currentRemaining;
  final ScheduleWithCourse? upNextClass;
  final Duration upNextRemaining;
  final List<TimelineItem> timelineItems;
  final bool isClassInProgress;
  final bool hasUpNext;
  final int currentMinuteOfDay;

  const DashboardHeroState({
    this.currentClass,
    this.currentProgress = 0.0,
    this.currentRemaining = Duration.zero,
    this.upNextClass,
    this.upNextRemaining = Duration.zero,
    this.timelineItems = const [],
    this.isClassInProgress = false,
    this.hasUpNext = false,
    this.currentMinuteOfDay = 0,
  });
}

/// Unified Dashboard State Provider
final dashboardHeroStateProvider = Provider<DashboardHeroState>((ref) {
  final schedulesAsync = ref.watch(schedulesForSelectedDayProvider);
  final selectedDay = ref.watch(selectedDayTokenProvider);
  ref.watch(vacantChangeProvider);
  final tickerTime = ref.watch(tickerStreamProvider).value ?? DateTime.now();

  final items = schedulesAsync.value ?? [];
  final currentWeekdayToken = TimeFormatter.getDayTokenFromWeekday(tickerTime.weekday);
  final isToday = currentWeekdayToken.isNotEmpty &&
      tickerTime.weekday != DateTime.sunday &&
      selectedDay.toUpperCase() == currentWeekdayToken.toUpperCase();

  final currentMinuteOfDay = tickerTime.hour * 60 + tickerTime.minute;
  final currentSecondOfMinute = tickerTime.second;

  // Filter schedules matching the selected day
  final sortedSchedules = List<ScheduleWithCourse>.from(items);

  // Sort by start time
  sortedSchedules.sort((a, b) => a.schedule.startMinutes.compareTo(b.schedule.startMinutes));

  ScheduleWithCourse? activeSchedule;
  double activeProgress = 0.0;
  Duration activeRemaining = Duration.zero;

  ScheduleWithCourse? nextSchedule;
  Duration nextRemaining = Duration.zero;

  if (isToday) {
    for (final item in sortedSchedules) {
      final startMin = item.schedule.startMinutes;
      final endMin = item.schedule.endMinutes;

      // Skip untimed/invalid intervals (e.g., 0 duration)
      if (startMin >= endMin) continue;

      if (currentMinuteOfDay >= startMin && currentMinuteOfDay < endMin) {
        // Active class in progress
        activeSchedule = item;
        final totalSeconds = (endMin - startMin) * 60;
        final elapsedSeconds = ((currentMinuteOfDay - startMin) * 60) + currentSecondOfMinute;
        activeProgress = totalSeconds > 0 ? (elapsedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
        final remainingSeconds = totalSeconds - elapsedSeconds;
        activeRemaining = Duration(seconds: remainingSeconds > 0 ? remainingSeconds : 0);

        // Find up-next class after this one
        final laterSchedules = sortedSchedules
            .where((s) => s.schedule.startMinutes >= endMin && s.schedule.startMinutes < s.schedule.endMinutes)
            .toList();
        if (laterSchedules.isNotEmpty) {
          nextSchedule = laterSchedules.first;
          final secondsUntilNext = ((nextSchedule.schedule.startMinutes - currentMinuteOfDay) * 60) - currentSecondOfMinute;
          nextRemaining = Duration(seconds: secondsUntilNext > 0 ? secondsUntilNext : 0);
        }
        break;
      } else if (currentMinuteOfDay < startMin) {
        // First upcoming class
        if (nextSchedule == null) {
          nextSchedule = item;
          final secondsUntilNext = ((startMin - currentMinuteOfDay) * 60) - currentSecondOfMinute;
          nextRemaining = Duration(seconds: secondsUntilNext > 0 ? secondsUntilNext : 0);
        }
      }
    }
  }

  // 2. Build Daily Chronological Timeline with accurate Vacant Periods / Free Blocks
  final List<TimelineItem> timeline = [];

  // Group and sort valid timed intervals to calculate true gap spaces (including TBA room subjects)
  final timedSchedules = sortedSchedules.where((s) => s.schedule.startMinutes < s.schedule.endMinutes).toList();
  timedSchedules.sort((a, b) => a.schedule.startMinutes.compareTo(b.schedule.startMinutes));

  // Merge overlapping and contiguous class intervals (handles multiple concurrent/split classes)
  final List<({int start, int end})> mergedIntervals = [];
  for (final s in timedSchedules) {
    final start = s.schedule.startMinutes;
    final end = s.schedule.endMinutes;
    if (mergedIntervals.isEmpty) {
      mergedIntervals.add((start: start, end: end));
    } else {
      final last = mergedIntervals.last;
      if (start <= last.end) {
        if (end > last.end) {
          mergedIntervals[mergedIntervals.length - 1] = (start: last.start, end: end);
        }
      } else {
        mergedIntervals.add((start: start, end: end));
      }
    }
  }

  // Calculate vacant gaps between merged intervals
  final hiddenBlocks = VacantPeriodService.cachedHidden;
  final customLabels = VacantPeriodService.cachedLabels;
  final customRanges = VacantPeriodService.cachedRanges;

  for (int i = 0; i < mergedIntervals.length - 1; i++) {
    final gapStart = mergedIntervals[i].end;
    final gapEnd = mergedIntervals[i + 1].start;
    if (gapEnd - gapStart >= 15) {
      final blockId = '${selectedDay}_${gapStart}_$gapEnd';
      if (!hiddenBlocks.contains(blockId)) {
        int finalStart = gapStart;
        int finalEnd = gapEnd;
        if (customRanges.containsKey(blockId)) {
          finalStart = customRanges[blockId]!['start'] ?? gapStart;
          finalEnd = customRanges[blockId]!['end'] ?? gapEnd;
        }

        timeline.add(TimelineItem(
          type: TimelineItemType.freeBlock,
          startMinutes: finalStart,
          endMinutes: finalEnd,
          blockId: blockId,
          customLabel: customLabels[blockId],
        ));
      }
    }
  }

  // Add all scheduled classes (and untimed TBA)
  for (final current in sortedSchedules) {
    if (current.schedule.startMinutes >= current.schedule.endMinutes) {
      timeline.add(TimelineItem(
        type: TimelineItemType.tbaSession,
        startMinutes: current.schedule.startMinutes,
        endMinutes: current.schedule.endMinutes,
        scheduleWithCourse: current,
      ));
      continue;
    }

    final isCurrent = activeSchedule?.schedule.id == current.schedule.id;
    final isUpNext = nextSchedule?.schedule.id == current.schedule.id && !isCurrent;

    timeline.add(TimelineItem(
      type: TimelineItemType.classSession,
      startMinutes: current.schedule.startMinutes,
      endMinutes: current.schedule.endMinutes,
      scheduleWithCourse: current,
      isCurrent: isCurrent,
      isUpNext: isUpNext,
      progressPercent: isCurrent ? activeProgress : 0.0,
      remainingDuration: isCurrent ? activeRemaining : (isUpNext ? nextRemaining : Duration.zero),
    ));
  }

  // Sort complete chronological timeline by startMinutes
  timeline.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  return DashboardHeroState(
    currentClass: activeSchedule,
    currentProgress: activeProgress,
    currentRemaining: activeRemaining,
    upNextClass: nextSchedule,
    upNextRemaining: nextRemaining,
    timelineItems: timeline,
    isClassInProgress: activeSchedule != null,
    hasUpNext: nextSchedule != null,
    currentMinuteOfDay: currentMinuteOfDay,
  );
});
