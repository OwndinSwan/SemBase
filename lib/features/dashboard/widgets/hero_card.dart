import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../map/screens/map_hub_screen.dart';
import '../providers/dashboard_providers.dart';

class DashboardHeroCard extends ConsumerWidget {
  const DashboardHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroState = ref.watch(dashboardHeroStateProvider);

    if (heroState.currentClass == null && heroState.upNextClass == null) {
      return _buildNoActiveClassesCard(context);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF064E3B), // Deep Emerald
            Color(0xFF0F172A), // Slate 900
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Status Badge & Countdown
          if (heroState.isClassInProgress && heroState.currentClass != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'CLASS IN PROGRESS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  TimeFormatter.formatRemainingTime(heroState.currentRemaining),
                  style: const TextStyle(
                    color: AppTheme.primaryGreenLight,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Course Title & Code
            Text(
              heroState.currentClass!.course.courseCode,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              heroState.currentClass!.course.courseTitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 16),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: heroState.currentProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreenLight),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TimeFormatter.formatMinutesTo12Hour(heroState.currentClass!.schedule.startMinutes),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMutedDark),
                    ),
                    Text(
                      '${(heroState.currentProgress * 100).toInt()}% Elapsed',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      TimeFormatter.formatMinutesTo12Hour(heroState.currentClass!.schedule.endMinutes),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMutedDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metadata row: Room & Session Type & Navigate Shortcut
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MapHubScreen(
                          initialTargetRoomCode: heroState.currentClass!.schedule.roomCode,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreenLight.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation_rounded, size: 14, color: AppTheme.primaryGreenLight),
                        const SizedBox(width: 6),
                        Text(
                          heroState.currentClass!.schedule.roomCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SessionTypeBadge(sessionType: heroState.currentClass!.schedule.sessionType),
                if (heroState.currentClass!.metadata?.profName != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Prof: ${heroState.currentClass!.metadata!.profName}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ] else if (heroState.hasUpNext && heroState.upNextClass != null) ...[
            // Up Next Hero Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentCyan.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'UP NEXT',
                    style: TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  'Starts in ${TimeFormatter.formatRemainingTime(heroState.upNextRemaining)}',
                  style: const TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              heroState.upNextClass!.course.courseCode,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              heroState.upNextClass!.course.courseTitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  TimeFormatter.formatTimeRange(
                    heroState.upNextClass!.schedule.startMinutes,
                    heroState.upNextClass!.schedule.endMinutes,
                  ),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MapHubScreen(
                          initialTargetRoomCode: heroState.upNextClass!.schedule.roomCode,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation_rounded, size: 12, color: AppTheme.accentCyan),
                        const SizedBox(width: 4),
                        Text(
                          heroState.upNextClass!.schedule.roomCode,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoActiveClassesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: AppTheme.primaryGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'No Active Classes Right Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enjoy your free study break or review your syllabus checklists.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
