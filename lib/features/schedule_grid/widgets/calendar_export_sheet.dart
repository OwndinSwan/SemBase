import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/utils/ics_generator.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/pro_gate_dialog.dart';

class CalendarExportSheet extends ConsumerWidget {
  final AcademicProfile? profile;
  final List<ScheduleWithCourse> schedules;

  const CalendarExportSheet({
    super.key,
    required this.profile,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navBarPadding = MediaQuery.of(context).padding.bottom;
    final isPro = ref.watch(isProProvider);

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: navBarPadding > 0 ? navBarPadding + 16 : 24,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Export Academic Schedule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Export to Google Calendar or share formatted text with classmates.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryDark),
          ),
          const SizedBox(height: 20),

          // ICS File Export Option
          _buildExportTile(
            context: context,
            icon: Icons.calendar_month,
            iconColor: AppTheme.accentAmber,
            title: 'Export RFC 5545 .ics File',
            subtitle: 'Import directly into Google Calendar, Outlook, or Apple Calendar with weekly recurring alerts.',
            badge: isPro ? 'PRO ACTIVE' : 'PRO',
            badgeColor: isPro ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
            onTap: () {
              if (!isPro) {
                Navigator.pop(context);
                ProGateDialog.show(
                  context,
                  featureName: 'Google & Apple Calendar Export (.ics)',
                  featureDescription:
                      'Exporting standardized RFC 5545 .ics calendar files for automatic recurring class alerts in Google Calendar, Apple Calendar, and Outlook requires SemBase Pro. Plain-text sharing is 100% free!',
                  featureIcon: Icons.calendar_month_rounded,
                );
                return;
              }
              _exportIcs(context);
            },
          ),
          const SizedBox(height: 12),

          // Plain Text Export Option
          _buildExportTile(
            context: context,
            icon: Icons.text_snippet_outlined,
            iconColor: AppTheme.accentCyan,
            title: 'Share Plain-Text Schedule',
            subtitle: 'Send formatted weekly schedule to Messenger, Discord, Telegram, or Notes.',
            badge: 'FREE',
            badgeColor: AppTheme.textSecondaryDark,
            onTap: () => _exportPlainText(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

  Widget _buildExportTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgDark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? AppTheme.accentAmber).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: badgeColor ?? AppTheme.accentAmber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMutedDark),
          ],
        ),
      ),
    );
  }

  Future<void> _exportIcs(BuildContext context) async {
    Navigator.of(context).pop();
    final exportable = schedules.map((s) => ExportableSchedule(
      courseCode: s.course.courseCode,
      courseTitle: s.course.courseTitle,
      dayToken: s.schedule.dayToken,
      startMinutes: s.schedule.startMinutes,
      endMinutes: s.schedule.endMinutes,
      roomCode: s.schedule.roomCode,
      sessionType: s.schedule.sessionType,
      profName: s.metadata?.profName,
    )).toList();

    final semName = profile != null ? '${profile!.semester} ${profile!.schoolYear}' : 'Current Term';
    final filePath = await IcsGenerator.exportIcsFile(
      semesterName: semName,
      schedules: exportable,
    );

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'SemBase Schedule ($semName)',
      subject: 'SemBase Academic Schedule .ics',
    );
  }

  Future<void> _exportPlainText(BuildContext context) async {
    Navigator.of(context).pop();
    final exportable = schedules.map((s) => ExportableSchedule(
      courseCode: s.course.courseCode,
      courseTitle: s.course.courseTitle,
      dayToken: s.schedule.dayToken,
      startMinutes: s.schedule.startMinutes,
      endMinutes: s.schedule.endMinutes,
      roomCode: s.schedule.roomCode,
      sessionType: s.schedule.sessionType,
      profName: s.metadata?.profName,
    )).toList();

    final text = IcsGenerator.formatPlainTextSchedule(
      studentNo: profile?.studentNo ?? '',
      section: profile?.section ?? '',
      semester: profile != null ? '${profile!.semester} (A.Y. ${profile!.schoolYear})' : 'SemBase Term',
      schedules: exportable,
    );

    await Share.share(
      text,
      subject: 'My SemBase Schedule',
    );
  }
}
