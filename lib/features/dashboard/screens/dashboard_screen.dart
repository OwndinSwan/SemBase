import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/alarm_notification_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/services/app_update_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/connectivity_status_badge.dart';
import '../../archive/screens/archive_explorer_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../cor_parser/widgets/cor_upload_modal.dart';
import '../../subject_hub/screens/subject_detail_screen.dart';
import '../../update/widgets/force_update_dialog.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/hero_card.dart';
import '../widgets/morning_briefing_banner.dart';
import '../widgets/timeline_view.dart';
import '../widgets/urgent_tasks_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  static const List<String> days = ['M', 'T', 'W', 'TH', 'F', 'S'];

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  AppUpdateInfo? _availableUpdate;
  bool _showMorningBriefing = false;
  final ScrollController _dayScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkForAppUpdates();
    _checkMorningBriefing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = ref.read(databaseProvider);
      // syncAllClassAlarms also reschedules morning briefing notifications internally
      AlarmNotificationService.syncAllClassAlarms(db);
      _scrollToCurrentDay();
    });
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkMorningBriefing() async {
    final shouldShow = await AlarmNotificationService.shouldShowMorningBriefingToday();
    if (mounted) {
      setState(() => _showMorningBriefing = shouldShow);
    }
    await AlarmNotificationService.checkAndCatchUpTodayBriefingNotification();
  }

  void _scrollToCurrentDay() {
    if (!_dayScrollController.hasClients) return;
    final now = DateTime.now();
    final currentDayToken = TimeFormatter.getDayTokenFromWeekday(now.weekday);
    final index = DashboardScreen.days.indexOf(currentDayToken);
    if (index > 0) {
      final targetOffset = (index * 110.0) - 20.0;
      _dayScrollController.animateTo(
        targetOffset.clamp(0.0, _dayScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _checkForAppUpdates() async {
    final updateInfo = await AppUpdateService.checkForUpdates();
    if (mounted && updateInfo.hasUpdate) {
      setState(() => _availableUpdate = updateInfo);
      if (updateInfo.isMandatory) {
        ForceUpdateDialog.show(context, updateInfo);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileStreamProvider);
    final selectedDay = ref.watch(selectedDayTokenProvider);
    final schedulesForSelectedDay = ref.watch(schedulesForSelectedDayProvider).value ?? [];
    final todayActualSchedules = ref.watch(todayActualSchedulesProvider).value ?? [];
    final urgentTasks = ref.watch(urgentTasksStreamProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('SemBase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            const ConnectivityStatusBadge(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu_outlined, color: AppTheme.accentAmber),
            tooltip: 'Academic History & Archive',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ArchiveExplorerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.accentCyan),
            tooltip: 'Account & Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_to_photos_outlined, color: AppTheme.primaryGreenLight),
            tooltip: 'Import / Upload COR',
            onPressed: () => _openCorUpload(context),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              await _checkForAppUpdates();
              await _checkMorningBriefing();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. In-App Morning Briefing Banner
                  if (_showMorningBriefing) ...[
                    MorningBriefingBanner(
                      todaySchedules: todayActualSchedules,
                      dueTasks: urgentTasks,
                      onDismiss: () async {
                        setState(() => _showMorningBriefing = false);
                        await AlarmNotificationService.dismissTodayMorningBriefing();
                      },
                    ),
                  ],

                  // 2. Update Banner (if new release available)
                  if (_availableUpdate != null && _availableUpdate!.hasUpdate) ...[
                    _buildUpdateBanner(_availableUpdate!),
                  ],

                  // 3. Profile Header Bar
                  _buildProfileHeader(profile),
                  const SizedBox(height: 16),

                  // Day Token Quick Selector
                  SingleChildScrollView(
                    controller: _dayScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: DashboardScreen.days.map((d) {
                        final isSelected = selectedDay == d;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              '${TimeFormatter.getFullDayName(d)} ($d)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isSelected ? Colors.white : AppTheme.textSecondaryDark,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryGreen,
                            backgroundColor: AppTheme.cardDark,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.borderDark.withOpacity(0.4),
                            ),
                            onSelected: (_) {
                              ref.read(selectedDayTokenProvider.notifier).state = d;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Live Class Hero Card
                  const DashboardHeroCard(),
                  const SizedBox(height: 16),

                  // Pinned Urgent Tasks (Due next 48h)
                  const UrgentTasksCard(),

                  // Daily Timeline Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${TimeFormatter.getFullDayName(selectedDay)} Schedule',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                      Text(
                        'Auto-calculated free blocks',
                        style: TextStyle(fontSize: 11, color: AppTheme.accentIndigo.withOpacity(0.9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Vertical Chronological Feed
                  DailyTimelineView(
                    onCourseTap: (courseId) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubjectDetailScreen(courseId: courseId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.studentNo} • ${profile.section}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
                Text(
                  '${profile.semester} (A.Y. ${profile.schoolYear})',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentIndigo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${profile.totalUnits} Units',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentIndigo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file, size: 64, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Schedule / COR Uploaded Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Import your Certificate of Registration (PDF) or paste your weekly schedule text to unlock your real-time academic timetable and class count-downs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryDark, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openCorUpload(context),
              icon: const Icon(Icons.add),
              label: const Text('Import Schedule / COR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCorUpload(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CorUploadModal(),
    );
  }

  Widget _buildUpdateBanner(AppUpdateInfo update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentCyan.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_outlined, color: AppTheme.accentCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Version v${update.latestVersion} Available!',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap to view release notes and download APK.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => ForceUpdateDialog.show(context, update),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }
}
