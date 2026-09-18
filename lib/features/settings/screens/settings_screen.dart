import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/notifications/alarm_notification_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/sync/sync_outbox_worker.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/connectivity_status_badge.dart';
import '../../auth/services/auth_keystore_service.dart';
import '../../map/screens/offline_map_pack_screen.dart';
import 'activity_logs_screen.dart';
import 'sub_screens/about_app_screen.dart';
import 'sub_screens/account_security_screen.dart';
import 'sub_screens/cloud_sync_settings_screen.dart';
import 'sub_screens/danger_zone_screen.dart';
import 'sub_screens/notifications_settings_screen.dart';
import 'sub_screens/personal_backup_screen.dart';
import 'sub_screens/subscription_plans_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  String? _userEmail;
  bool _isBiometricEnabled = false;
  int _alarmOffsetMinutes = 15;
  int _pendingMutationsCount = 0;
  int _logCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userEmail = AuthKeystoreService.cachedEmail;
    _alarmOffsetMinutes = AlarmNotificationService.cachedOffsetMinutes;
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadState();
    }
  }

  Future<void> _loadState() async {
    final isGuest = await AuthKeystoreService.isGuestMode();
    final email = isGuest ? null : await AuthKeystoreService.getUserEmail();
    final bio = await AuthKeystoreService.isBiometricEnabled();
    final offset = await AlarmNotificationService.getAlarmOffsetMinutes();
    final logCount = await AppLogService.getLogCount();
    final db = ref.read(databaseProvider);
    final pending = await db.getPendingMutations();

    if (mounted) {
      setState(() {
        _userEmail = email;
        _isBiometricEnabled = bio;
        _alarmOffsetMinutes = offset;
        _logCount = logCount;
        _pendingMutationsCount = pending.length;
      });
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadState());
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileStreamProvider);
    final isGuest = _userEmail == null || _userEmail!.isEmpty;

    final subInfo = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: ConnectivityStatusBadge()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. User Profile Hero Card
          _buildProfileHeroCard(profileAsync.value, isGuest),
          const SizedBox(height: 14),

          // 2. Subscription Status Banner (Tap to view Plans)
          _buildSubscriptionTierBanner(subInfo),
          const SizedBox(height: 24),

          // 3. Section: Security & Preferences
          _buildSectionTitle('SECURITY & PREFERENCES'),
          const SizedBox(height: 8),
          _buildSettingsGroup([
            _SettingsItem(
              icon: Icons.diamond_outlined,
              iconColor: AppTheme.accentAmber,
              iconBgColor: AppTheme.accentAmber.withOpacity(0.15),
              title: 'Plans & Subscription',
              subtitle: subInfo.isPro ? subInfo.planDisplayName : 'Upgrade to Pro for Cloud Vault, Auto-Sync & Briefings',
              badge: subInfo.isPro ? 'PRO ACTIVE' : 'FREE',
              badgeColor: subInfo.isPro ? AppTheme.primaryGreenLight : AppTheme.textSecondaryDark,
              onTap: () => _navigateTo(const SubscriptionPlansScreen()),
            ),
            _SettingsItem(
              icon: Icons.shield_outlined,
              iconColor: AppTheme.primaryGreenLight,
              iconBgColor: AppTheme.primaryGreen.withOpacity(0.15),
              title: 'Account & Security',
              subtitle: isGuest
                  ? 'Sign in, biometric lock & system permissions'
                  : (_isBiometricEnabled
                      ? 'Biometrics, passwords & system permissions'
                      : 'Credentials, security & system permissions'),
              badge: isGuest ? 'Guest' : null,
              badgeColor: AppTheme.accentAmber,
              onTap: () => _navigateTo(const AccountSecurityScreen()),
            ),
            _SettingsItem(
              icon: Icons.notifications_none_rounded,
              iconColor: AppTheme.accentAmber,
              iconBgColor: AppTheme.accentAmber.withOpacity(0.15),
              title: 'Notifications & Reminders',
              subtitle: 'Class reminders • $_alarmOffsetMinutes mins before',
              badge: '$_alarmOffsetMinutes mins',
              badgeColor: AppTheme.primaryGreen,
              onTap: () => _navigateTo(const NotificationsSettingsScreen()),
            ),
          ]),
          const SizedBox(height: 24),

          // 4. Section: Data & Storage
          _buildSectionTitle('DATA & STORAGE'),
          const SizedBox(height: 8),
          _buildSettingsGroup([
            _SettingsItem(
              icon: Icons.map_outlined,
              iconColor: AppTheme.primaryGreenLight,
              iconBgColor: AppTheme.primaryGreen.withOpacity(0.15),
              title: 'Offline Map Pack & Territory',
              subtitle: 'Calibrate territory • Download tiles (~15–30 MB)',
              badge: 'OFFLINE',
              badgeColor: AppTheme.primaryGreenLight,
              onTap: () => _navigateTo(const OfflineMapPackScreen()),
            ),
            _SettingsItem(
              icon: Icons.cloud_outlined,
              iconColor: AppTheme.accentCyan,
              iconBgColor: AppTheme.accentCyan.withOpacity(0.15),
              title: 'Cloud Sync & Data Vault',
              subtitle: isGuest
                  ? 'Local offline storage'
                  : (_pendingMutationsCount > 0 ? '$_pendingMutationsCount pending changes' : 'Vault fully synchronized'),
              badge: subInfo.isPro ? 'PRO ACTIVE' : 'PRO',
              badgeColor: subInfo.isPro ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
              onTap: () => _navigateTo(const CloudSyncSettingsScreen()),
            ),
            _SettingsItem(
              icon: Icons.folder_zip_outlined,
              iconColor: AppTheme.primaryGreenLight,
              iconBgColor: AppTheme.primaryGreen.withOpacity(0.15),
              title: 'Personal Data Backup',
              subtitle: 'Export & import JSON archives',
              badge: 'JSON',
              badgeColor: AppTheme.accentCyan,
              onTap: () => _navigateTo(const PersonalBackupScreen()),
            ),
          ]),
          const SizedBox(height: 24),

          // 5. Section: System & Diagnostics
          _buildSectionTitle('SYSTEM & INFORMATION'),
          const SizedBox(height: 8),
          _buildSettingsGroup([
            _SettingsItem(
              icon: Icons.receipt_long_outlined,
              iconColor: AppTheme.accentAmber,
              iconBgColor: AppTheme.accentAmber.withOpacity(0.15),
              title: 'Diagnostics & Activity Logs',
              subtitle: 'Audit trail • $_logCount recorded events',
              badge: '$_logCount logs',
              badgeColor: AppTheme.accentAmber,
              onTap: () => _navigateTo(const ActivityLogsScreen()),
            ),
            _SettingsItem(
              icon: Icons.info_outline_rounded,
              iconColor: AppTheme.accentCyan,
              iconBgColor: AppTheme.accentCyan.withOpacity(0.15),
              title: 'About & App Updates',
              subtitle: 'SemBase v${AppConfig.appVersion} • Check updates',
              badge: 'v${AppConfig.appVersion}',
              badgeColor: AppTheme.accentCyan,
              onTap: () => _navigateTo(const AboutAppScreen()),
            ),
            _SettingsItem(
              icon: Icons.warning_amber_rounded,
              iconColor: AppTheme.accentRose,
              iconBgColor: AppTheme.accentRose.withOpacity(0.15),
              title: 'Danger Zone',
              subtitle: 'Re-index cache • Account deletion',
              onTap: () => _navigateTo(const DangerZoneScreen()),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondaryDark,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard(AcademicProfile? profile, bool isGuest) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _navigateTo(const AccountSecurityScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isGuest ? AppTheme.accentAmber.withOpacity(0.18) : AppTheme.primaryGreen.withOpacity(0.18),
              child: Icon(
                isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                color: isGuest ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGuest ? 'Guest Student' : (_userEmail ?? 'Authenticated User'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile != null
                        ? '${profile.section} • ${profile.studentNo.isNotEmpty ? profile.studentNo : "No Student ID"}'
                        : (isGuest ? 'Tap to link cloud account' : 'SemBase Student Account'),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedDark, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTierBanner(SubscriptionInfo subInfo) {
    final isPro = subInfo.isPro;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _navigateTo(const SubscriptionPlansScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPro ? AppTheme.accentAmber.withOpacity(0.1) : AppTheme.primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPro ? AppTheme.accentAmber.withOpacity(0.4) : AppTheme.primaryGreen.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isPro ? AppTheme.accentAmber.withOpacity(0.18) : AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPro ? Icons.diamond_rounded : Icons.verified_rounded,
                color: isPro ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isPro ? '💎 ${subInfo.planDisplayName}' : 'SemBase Free Academic Edition',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPro ? AppTheme.accentAmber : AppTheme.textPrimaryDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPro ? AppTheme.accentAmber.withOpacity(0.2) : AppTheme.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPro ? 'PRO ACTIVE' : 'UPGRADE',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: isPro ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMutedDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: isLast ? const Radius.circular(18) : Radius.zero,
                ),
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.iconBgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (item.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.badge!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.badgeColor,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedDark, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(color: Color(0x10FFFFFF), height: 1, indent: 56, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color badgeColor;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor = AppTheme.primaryGreen,
    required this.onTap,
  });
}
