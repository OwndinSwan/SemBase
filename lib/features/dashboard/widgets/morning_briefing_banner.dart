import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_theme.dart';

/// In-App Morning Briefing Banner that appears at the top of the Dashboard
class MorningBriefingBanner extends StatefulWidget {
  final List<ScheduleWithCourse> todaySchedules;
  final List<TaskWithCourse> dueTasks;
  final VoidCallback onDismiss;

  const MorningBriefingBanner({
    super.key,
    required this.todaySchedules,
    required this.dueTasks,
    required this.onDismiss,
  });

  @override
  State<MorningBriefingBanner> createState() => _MorningBriefingBannerState();
}

class _MorningBriefingBannerState extends State<MorningBriefingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isSunday = now.weekday == DateTime.sunday;
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    // On Sunday, academic schedule is strictly empty (no classes)
    final effectiveTodaySchedules = isSunday ? <ScheduleWithCourse>[] : widget.todaySchedules;
    final totalClasses = effectiveTodaySchedules.length;
    final totalTasks = widget.dueTasks.length;

    // Find next upcoming class today (including subjects with TBA room)
    final currentMinutes = now.hour * 60 + now.minute;
    final upcomingClasses = effectiveTodaySchedules
        .where((s) => s.schedule.startMinutes < s.schedule.endMinutes && s.schedule.endMinutes > currentMinutes)
        .toList()
      ..sort((a, b) => a.schedule.startMinutes.compareTo(b.schedule.startMinutes));

    final nextClass = upcomingClasses.isNotEmpty ? upcomingClasses.first : null;

    // Dynamic greeting motivation
    String headline;
    if (totalClasses == 0 && totalTasks == 0) {
      headline = isSunday
          ? 'Happy Sunday! No classes today — enjoy your weekend rest!'
          : 'No classes today — perfect time to relax or get ahead!';
    } else if (totalClasses == 0) {
      headline = isSunday
          ? 'Happy Sunday! No classes today, but you have tasks coming up soon.'
          : 'No classes today, but you have tasks coming up soon.';
    } else if (totalTasks > 0) {
      headline = '$totalClasses ${totalClasses == 1 ? "class" : "classes"} and $totalTasks ${totalTasks == 1 ? "task" : "tasks"} scheduled.';
    } else {
      headline = '$totalClasses ${totalClasses == 1 ? "class" : "classes"} scheduled today. Have a productive day!';
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E2638), // Midnight slate
                Color(0xFF0F172A), // Deep obsidian
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.accentAmber.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentAmber.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle golden morning glow decoration at top-left
              Positioned(
                top: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentAmber.withOpacity(0.06),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentAmber.withOpacity(0.3),
                                AppTheme.accentAmber.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accentAmber.withOpacity(0.4),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentAmber.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.wb_sunny_rounded,
                            color: AppTheme.accentAmber,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Morning Briefing',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryDark,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentAmber.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '7:00 AM',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentAmber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Smooth Dismiss Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _handleDismiss,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppTheme.textMutedDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Motivational Summary Headline
                    Text(
                      headline,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryDark.withOpacity(0.9),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Summary Stats Grid
                    Row(
                      children: [
                        // Classes Stat Tile
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x18FFFFFF)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 15,
                                    color: AppTheme.primaryGreenLight,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$totalClasses ${totalClasses == 1 ? "Class" : "Classes"}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text(
                                        'Today\'s timetable',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondaryDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Tasks Due Stat Tile
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x18FFFFFF)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (totalTasks > 0 ? AppTheme.accentRose : AppTheme.accentCyan).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.assignment_turned_in_rounded,
                                    size: 15,
                                    color: totalTasks > 0 ? AppTheme.accentRose : AppTheme.accentCyan,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$totalTasks ${totalTasks == 1 ? "Task" : "Tasks"}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: totalTasks > 0 ? AppTheme.accentRose : AppTheme.textPrimaryDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text(
                                        'Due soon',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondaryDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Next Class Capsule (if any)
                    if (nextClass != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryGreenLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Up next: ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreenLight,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${nextClass.course.courseCode} at ${TimeFormatter.formatMinutesTo12Hour(nextClass.schedule.startMinutes)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' (${nextClass.schedule.roomCode.isEmpty ? "TBA" : nextClass.schedule.roomCode})',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

