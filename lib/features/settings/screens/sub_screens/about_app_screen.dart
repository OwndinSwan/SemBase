import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../update/widgets/force_update_dialog.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  int? _expandedFaqIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Features'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. App Logo & Version Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: AppTheme.primaryGreenLight, size: 44),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SemBase Academic Companion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDarkElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Text(
                    'Version v${AppConfig.appVersion}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreenLight),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The unified academic hub for students — timetable schedule grids, syllabus task checklist, class reminders, and offline cloud synchronization.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. OTA Software Update Checker Card
          _buildUpdateCheckerCard(context),
          const SizedBox(height: 24),

          // 3. Core App Functions & Features Section
          _buildSectionHeader('CORE FUNCTIONS & FEATURES', Icons.stars_rounded),
          const SizedBox(height: 10),
          _buildFeaturesList(),
          const SizedBox(height: 24),

          // 4. Frequently Asked Questions (FAQ)
          _buildSectionHeader('FREQUENTLY ASKED QUESTIONS', Icons.help_outline_rounded),
          const SizedBox(height: 10),
          _buildFaqSection(),
          const SizedBox(height: 24),

          // 5. System Specifications & Architecture
          _buildSectionHeader('TECHNICAL SPECIFICATIONS', Icons.memory_rounded),
          const SizedBox(height: 10),
          _buildArchitectureCard(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondaryDark,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCheckerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.system_update_rounded, color: AppTheme.accentCyan, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Software Updates',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Check GitHub repository for the latest release builds',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                AppToast.showInfo(
                  context,
                  'Checking GitHub for latest updates...',
                  icon: Icons.sync_rounded,
                  duration: const Duration(seconds: 1),
                );
                final update = await AppUpdateService.checkForUpdates();
                if (!context.mounted) return;

                if (update.hasUpdate) {
                  ForceUpdateDialog.show(context, update);
                } else {
                  AppToast.showSuccess(
                    context,
                    'You are using the latest version of SemBase!',
                    icon: Icons.check_circle_outline_rounded,
                  );
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Check for Updates Now', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      _FeatureInfo(
        icon: Icons.calendar_view_week_rounded,
        color: AppTheme.primaryGreenLight,
        title: 'Interactive Weekly Timetable Grid',
        description: 'Pinch-to-zoom schedule view with multi-touch panning, auto-hiding zoom buttons, LEC/LAB session tags, classroom locator, and side-by-side overlap clustering.',
      ),
      _FeatureInfo(
        icon: Icons.checklist_rounded,
        color: AppTheme.accentCyan,
        title: 'Subject Hub & Syllabus Task Manager',
        description: 'Complete course manager with syllabus tasks, quick +/- 1-week deadline shifters, instructor details, grading weight breakdown, and pinned urgent deadlines.',
      ),
      _FeatureInfo(
        icon: Icons.map_rounded,
        color: const Color(0xFF0284C7),
        title: 'Campus Map Hub & Room Pinning',
        description: 'Interactive campus map with classroom pinpoints, custom color-coded building markers, real-time GPS pathfinding routing, and simulated GPS mock positioning.',
      ),
      _FeatureInfo(
        icon: Icons.download_for_offline_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'Offline Map Pack & Arrival Geofence Alerts (Pro)',
        description: 'Download 100% offline map vector tiles and road networks for zero-data commute & campus navigation, plus real-time arrival alerts (50m–150m) when reaching your lecture halls.',
      ),
      _FeatureInfo(
        icon: Icons.notifications_active_rounded,
        color: AppTheme.accentAmber,
        title: 'Smart Class Reminders & 7:00 AM Briefing',
        description: 'High-priority notifications arriving before each class (customizable 5–60 mins) and a daily morning academic briefing heads-up summary of today\'s classes and due tasks.',
      ),
      _FeatureInfo(
        icon: Icons.cloud_sync_rounded,
        color: AppTheme.accentCyan,
        title: 'Offline-First Architecture & Cloud Sync',
        description: '100% functionality with local SQLite storage. Synchronizes with SemBase Cloud in the background using a transactional outbox queue with Last-Write-Wins conflict resolution.',
      ),
      _FeatureInfo(
        icon: Icons.folder_zip_rounded,
        color: AppTheme.primaryGreenLight,
        title: 'Personal Backups & Smart Timestamp Merge',
        description: 'One-tap JSON exports to share sheets. Intelligent Smart Merge ensures local task completions made after an export are never reverted when importing previous backups.',
      ),
      _FeatureInfo(
        icon: Icons.event_available_rounded,
        color: AppTheme.accentAmber,
        title: 'RFC 5545 iCalendar (.ics) Sync',
        description: 'Export semester timetables into standardized .ics files that can be imported directly into Google Calendar, Apple Calendar, or Microsoft Outlook.',
      ),
      _FeatureInfo(
        icon: Icons.archive_rounded,
        color: AppTheme.textSecondaryDark,
        title: 'Academic Term Archiving & History',
        description: 'Cleanly transition between semesters by archiving past terms, preserving past subject notes and tasks for future reference without cluttering your active grid.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        children: List.generate(features.length, (i) {
          final item = features[i];
          final isLast = i == features.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.description,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(color: Color(0x10FFFFFF), height: 1, indent: 52, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFaqSection() {
    final faqs = [
      _FaqItem(
        question: 'Does SemBase work completely offline without internet?',
        answer: 'Yes! SemBase is built with an offline-first architecture. All your courses, schedule slots, notes, and task checklists are stored directly on your phone in a high-performance SQLite database. You can view schedules and check off tasks anywhere, even without Wi-Fi or data. When you reconnect, changes sync to the cloud automatically.',
      ),
      _FaqItem(
        question: 'What is the difference between Smart Merge and Clean Restore?',
        answer: 'When importing a backup:\n• Smart Merge compares modification timestamps (Last-Write-Wins). If you checked off tasks or added new notes after the backup was made, your newer progress is preserved.\n• Clean Restore replaces your local database entirely with the backup contents, perfect for wiping and reverting to a known state.',
      ),
      _FaqItem(
        question: 'Why am I not receiving class reminder notifications?',
        answer: 'To ensure reliable notification delivery:\n1. Enable System Notifications in Settings > Notifications & Reminders.\n2. Tap "Disable Battery Restrictions" so Android does not delay background notifications during deep sleep (Doze mode).\n3. Check that your device\'s "Do Not Disturb" mode is not blocking SemBase alerts.',
      ),
      _FaqItem(
        question: 'How do I export my schedule to Google Calendar or Apple Calendar?',
        answer: 'Open the Subject Hub, tap the Calendar export icon on any subject, or use the calendar sync options to generate a universal RFC 5545 iCalendar (.ics) file. You can open this file in Google Calendar, Outlook, or iOS Calendar to add all your recurring classes automatically.',
      ),
      _FaqItem(
        question: 'Can I synchronize my academic data across multiple devices?',
        answer: 'Yes. Simply sign in with your email or Google account on any phone or tablet. All your registered courses, syllabi, and checklist items will sync automatically across all your logged-in devices in real time.',
      ),
      _FaqItem(
        question: 'How do Campus Room Pinning and Offline Maps work?',
        answer: 'You can pin your classrooms and buildings directly onto the Campus Map Hub from your Timetable or Subject Hub. All students can use the interactive online map, route navigation, and mock GPS simulation for free. Downloading 100% offline map packs for zero-data navigation and background arrival geofence alerts require SemBase Pro.',
      ),
      _FaqItem(
        question: 'What happens to my data when a semester ends?',
        answer: 'You can archive your current semester from the Subject Hub. Archiving preserves your grades, completed tasks, and notes safely on your device while giving you a fresh, clean timetable grid for the new school term.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        children: List.generate(faqs.length, (i) {
          final item = faqs[i];
          final isExpanded = _expandedFaqIndex == i;
          final isLast = i == faqs.length - 1;

          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: isLast && !isExpanded ? const Radius.circular(18) : Radius.zero,
                ),
                onTap: () {
                  setState(() {
                    _expandedFaqIndex = isExpanded ? null : i;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isExpanded ? AppTheme.primaryGreen.withOpacity(0.2) : AppTheme.bgDarkElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Q${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isExpanded ? AppTheme.primaryGreenLight : AppTheme.textSecondaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.question,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isExpanded ? AppTheme.primaryGreenLight : AppTheme.textPrimaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMutedDark, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgDark.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
                          ),
                          child: Text(
                            item.answer,
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryDark, height: 1.45),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              if (!isLast)
                const Divider(color: Color(0x10FFFFFF), height: 1, indent: 48, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildArchitectureCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Local Engine', 'SQLite + Drift 2.34 (Reactive ORM)'),
          _buildInfoRow('Cloud Backend', 'SemBase Cloud & Realtime Sync'),
          _buildInfoRow('Sync Protocol', 'Transactional Outbox with LWW'),
          _buildInfoRow('Notification Engine', 'Native Android Notification Channels'),
          _buildInfoRow('Calendar Engine', 'RFC 5545 iCalendar Engine'),
          _buildInfoRow('Framework', 'Flutter 3.x with Riverpod 2.6'),
          _buildInfoRow('Developer', 'SemBase Academic Engineering Team'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryDark)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  _FeatureInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({
    required this.question,
    required this.answer,
  });
}
