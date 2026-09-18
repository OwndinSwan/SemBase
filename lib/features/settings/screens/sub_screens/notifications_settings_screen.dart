import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/notifications/alarm_notification_service.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../../shared/widgets/pro_gate_dialog.dart';
import 'account_security_screen.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends ConsumerState<NotificationsSettingsScreen> with WidgetsBindingObserver {
  bool _hasNotificationPermission = false;
  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = true;
  bool _isPreciseLocation = false;
  bool _isBatteryExempt = false;
  int _alarmOffsetMinutes = 15;
  bool _morningBriefing = true;
  bool _proximityAlerts = true;
  int _proximityRadius = 75;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final notif = await AlarmNotificationService.checkNotificationPermission();
    final battery = await AlarmNotificationService.isIgnoringBatteryOptimizations();
    final offset = await AlarmNotificationService.getAlarmOffsetMinutes();
    final briefing = await AlarmNotificationService.isMorningBriefingEnabled();
    final proxEnabled = await AlarmNotificationService.isProximityAlertsEnabled();
    final proxRadius = await AlarmNotificationService.getProximityRadiusMeters();

    // Location & Precision Status
    bool hasLoc = false;
    bool isLocService = true;
    bool precise = false;

    try {
      isLocService = await Geolocator.isLocationServiceEnabled();
      final locPerm = await Geolocator.checkPermission();
      hasLoc = locPerm == LocationPermission.whileInUse || locPerm == LocationPermission.always;
      if (hasLoc) {
        final accuracy = await Geolocator.getLocationAccuracy();
        precise = (accuracy == LocationAccuracyStatus.precise);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _hasNotificationPermission = notif;
        _hasLocationPermission = hasLoc;
        _isLocationServiceEnabled = isLocService;
        _isPreciseLocation = precise;
        _isBatteryExempt = battery;
        _alarmOffsetMinutes = offset;
        _morningBriefing = briefing;
        _proximityAlerts = proxEnabled;
        _proximityRadius = proxRadius;
        _isLoading = false;
      });
    }
  }

  void _navigateToAccountSecurity() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AccountSecurityScreen()))
        .then((_) => _loadState());
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);

    final hasMissingPermissions =
        !_hasNotificationPermission || !_hasLocationPermission || !_isBatteryExempt || !_isLocationServiceEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Reminders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. Permission Warning Tags / Status Overview
                _buildPermissionTagsSection(hasMissingPermissions),
                const SizedBox(height: 20),

                // 2. Class Reminders Timing (Rich Aesthetic!)
                _buildSectionHeader(
                  'Class Reminder Lead Time',
                  Icons.notifications_active_rounded,
                  isGated: !_hasNotificationPermission,
                ),
                const SizedBox(height: 8),
                _buildPermissionGated(child: _buildReminderOffsetCard(isPro)),
                const SizedBox(height: 20),

                // 3. Daily Academic Briefing
                _buildSectionHeader(
                  'Daily Academic Briefing',
                  Icons.wb_sunny_rounded,
                  isGated: !_hasNotificationPermission,
                ),
                const SizedBox(height: 8),
                _buildPermissionGated(child: _buildMorningBriefingCard(isPro)),
                const SizedBox(height: 20),

                // 4. Campus & Commuter Arrival Alerts
                _buildSectionHeader(
                  'Campus & Commuter Arrival Alerts',
                  Icons.near_me_rounded,
                  isGated: !_hasNotificationPermission,
                ),
                const SizedBox(height: 8),
                _buildPermissionGated(child: _buildProximityAlertsCard(isPro)),
                const SizedBox(height: 20),

                // 5. Diagnostics & Testing
                _buildSectionHeader(
                  'Diagnostics & Testing',
                  Icons.notifications_active_rounded,
                  isGated: !_hasNotificationPermission,
                ),
                const SizedBox(height: 8),
                _buildPermissionGated(child: _buildTestNotificationCard()),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildPermissionGated({required Widget child}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _hasNotificationPermission ? 1.0 : 0.42,
      child: IgnorePointer(
        ignoring: !_hasNotificationPermission,
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool isGated = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isGated ? AppTheme.textMutedDark : AppTheme.textSecondaryDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isGated ? AppTheme.textMutedDark : AppTheme.textSecondaryDark,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (isGated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentRose.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Permission Required',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.accentRose),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionTagsSection(bool hasMissingPermissions) {
    if (!hasMissingPermissions) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppTheme.primaryGreenLight, size: 16),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All System Permissions Active',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                  ),
                  Text(
                    'Managed in Account & Security tab',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryDark),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _navigateToAccountSecurity,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgDarkElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Manage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreenLight)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.primaryGreenLight),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notification Missing Tag
        if (!_hasNotificationPermission)
          _buildWarningTag(
            icon: Icons.notifications_off_rounded,
            title: 'Notifications Disabled in Account & Security',
            subtitle: 'Class reminders and morning briefings cannot ring without notification permission.',
            badgeText: 'NOTIFICATIONS BLOCKED',
            accentColor: AppTheme.accentRose,
            onTap: _navigateToAccountSecurity,
          ),

        // Location Missing Tag
        if (!_hasLocationPermission || !_isLocationServiceEnabled) ...[
          if (!_hasNotificationPermission) const SizedBox(height: 8),
          _buildWarningTag(
            icon: Icons.location_off_rounded,
            title: !_isLocationServiceEnabled ? 'Device GPS Is Turned OFF' : 'Location Permission Disabled',
            subtitle: 'Campus and room arrival proximity alerts require active location permission.',
            badgeText: 'LOCATION DISABLED',
            accentColor: AppTheme.accentAmber,
            onTap: _navigateToAccountSecurity,
          ),
        ],

        // Battery Restriction Tag
        if (_hasNotificationPermission && !_isBatteryExempt) ...[
          const SizedBox(height: 8),
          _buildWarningTag(
            icon: Icons.battery_alert_rounded,
            title: 'Battery Saver Active for SemBase',
            subtitle: 'Android Doze mode may delay background reminders. Exempt in Account & Security.',
            badgeText: 'BATTERY RESTRICTED',
            accentColor: AppTheme.accentAmber,
            onTap: _navigateToAccountSecurity,
          ),
        ],
      ],
    );
  }

  Widget _buildWarningTag({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: accentColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderOffsetCard(bool isPro) {
    final db = ref.read(databaseProvider);

    final offsetOptions = [
      (minutes: 5, label: '5 mins', sub: 'Instant buffer', icon: Icons.bolt_rounded),
      (minutes: 10, label: '10 mins', sub: 'Quick prep', icon: Icons.directions_walk_rounded),
      (minutes: 15, label: '15 mins', sub: 'Standard Free', icon: Icons.schedule_rounded),
      (minutes: 30, label: '30 mins', sub: 'Commute buffer', icon: Icons.directions_bus_rounded),
      (minutes: 45, label: '45 mins', sub: 'Early headstart', icon: Icons.explore_rounded),
      (minutes: 60, label: '60 mins', sub: '1 hour alert', icon: Icons.menu_book_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasNotificationPermission
              ? AppTheme.primaryGreen.withOpacity(0.25)
              : AppTheme.borderDark.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Icon and Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen.withOpacity(0.25),
                      AppTheme.primaryGreen.withOpacity(0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryGreenLight, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pre-Class Notification',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Notifies ${_alarmOffsetMinutes} minutes before each class',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreenLight, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (!isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '15m Free • Pro',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Select how early SemBase sends a push notification before your scheduled subject starts:',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryDark, height: 1.3),
          ),
          const SizedBox(height: 14),

          // Options Grid (2 Columns for rich aesthetic presentation)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offsetOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.35,
            ),
            itemBuilder: (context, index) {
              final opt = offsetOptions[index];
              final isSelected = _alarmOffsetMinutes == opt.minutes;
              final isFree = opt.minutes == 15;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  if (!isFree && !isPro) {
                    ProGateDialog.show(
                      context,
                      featureName: 'Custom Reminder Timing',
                      featureDescription:
                          'Customizable pre-class alert buffers (${opt.minutes} mins) require SemBase Pro. Free users get fixed 15-minute alerts.',
                      featureIcon: Icons.timer_rounded,
                    );
                    return;
                  }
                  await AlarmNotificationService.setAlarmOffsetMinutes(opt.minutes, db);
                  setState(() => _alarmOffsetMinutes = opt.minutes);
                  if (mounted) {
                    AppToast.showSuccess(
                      context,
                      'Class reminders set to ${opt.minutes} minutes before classes.',
                      icon: Icons.timer_rounded,
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryGreen.withOpacity(0.18) : AppTheme.bgDarkElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.borderDark.withOpacity(0.7),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen.withOpacity(0.25)
                              : AppTheme.cardDark.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isSelected ? Icons.check_circle_rounded : opt.icon,
                          size: 16,
                          color: isSelected ? AppTheme.primaryGreenLight : AppTheme.textSecondaryDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? AppTheme.primaryGreenLight : AppTheme.textPrimaryDark,
                                  ),
                                ),
                                if (!isFree && !isPro) ...[
                                  const SizedBox(width: 4),
                                  const ProBadge(
                                    fontSize: 7.0,
                                    padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              opt.sub,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isSelected ? AppTheme.primaryGreenLight.withOpacity(0.8) : AppTheme.textMutedDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // Offline Note Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.bgDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: AppTheme.primaryGreenLight, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Push notifications are scheduled ahead of time and will vibrate + notify even without an active internet connection.',
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryDark, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMorningBriefingCard(bool isPro) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentAmber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.wb_sunny_outlined, color: AppTheme.accentAmber, size: 20),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Daily Morning Briefing (07:00 AM)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
              ),
            ),
            const SizedBox(width: 8),
            ProBadge(isProActive: isPro),
          ],
        ),
        subtitle: const Text(
          'Get a summary notification of today\'s subjects & pending tasks',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
        ),
        value: _morningBriefing && isPro,
        activeThumbColor: AppTheme.primaryGreen,
        onChanged: (val) async {
          if (!isPro) {
            ProGateDialog.show(
              context,
              featureName: '7:00 AM Morning Academic Briefing',
              featureDescription:
                  'Automated daily 7:00 AM briefing notifications summarizing today\'s class schedule and pending deadlines require SemBase Pro.',
              featureIcon: Icons.wb_sunny_rounded,
            );
            return;
          }
          await AlarmNotificationService.setMorningBriefingEnabled(val);
          setState(() => _morningBriefing = val);
          if (mounted) {
            if (val) {
              AppToast.showSuccess(
                context,
                'Daily 7:00 AM morning academic briefing enabled.',
                icon: Icons.wb_sunny_rounded,
                duration: const Duration(seconds: 2),
              );
            } else {
              AppToast.showInfo(
                context,
                'Daily morning briefing disabled.',
                icon: Icons.wb_sunny_outlined,
                duration: const Duration(seconds: 2),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildProximityAlertsCard(bool isPro) {
    const radiuses = [50, 75, 100, 150];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text(
                    'Campus & Room Arrival Alerts',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                  ),
                ),
                const SizedBox(width: 8),
                ProBadge(isProActive: isPro),
              ],
            ),
            subtitle: const Text(
              'Get a heads-up notification and vibration when you physically arrive near your pinned classroom or destination',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
            ),
            value: _proximityAlerts && isPro,
            activeThumbColor: AppTheme.primaryGreen,
            onChanged: (val) async {
              if (!isPro) {
                ProGateDialog.show(
                  context,
                  featureName: 'Campus & Room Arrival Alerts',
                  featureDescription:
                      'Automated real-time geofence proximity alerts notifying you when arriving near your pinned classrooms require SemBase Pro.',
                  featureIcon: Icons.near_me_rounded,
                );
                return;
              }
              await AlarmNotificationService.setProximityAlertsEnabled(val);
              setState(() => _proximityAlerts = val);
              if (mounted) {
                if (val) {
                  AppToast.showArrival(
                    context,
                    'Campus & room arrival alerts enabled ($_proximityRadius m radius).',
                    icon: Icons.near_me_rounded,
                    duration: const Duration(seconds: 2),
                  );
                } else {
                  AppToast.showInfo(
                    context,
                    'Campus & room arrival alerts disabled.',
                    icon: Icons.location_off_rounded,
                    duration: const Duration(seconds: 2),
                  );
                }
              }
            },
          ),
          if (_proximityAlerts && isPro) ...[
            const Divider(color: AppTheme.borderDark, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Geofence Arrival Trigger Radius:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showCustomRadiusInputDialog(isPro),
                  icon: const Icon(Icons.tune_rounded, size: 14, color: AppTheme.primaryGreenLight),
                  label: Text(
                    'Custom: ${_proximityRadius}m',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreenLight),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...radiuses.map((radius) {
                  final isSelected = _proximityRadius == radius;
                  final label = radius == 50
                      ? '50m (Precise)'
                      : radius == 75
                          ? '75m (Balanced)'
                          : radius == 100
                              ? '100m (Standard)'
                              : '150m (Early)';

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      if (!isPro) {
                        ProGateDialog.show(
                          context,
                          featureName: 'Campus & Room Arrival Alerts',
                          featureDescription:
                              'Automated real-time geofence proximity alerts notifying you when arriving near your pinned classrooms require SemBase Pro.',
                          featureIcon: Icons.near_me_rounded,
                        );
                        return;
                      }
                      await AlarmNotificationService.setProximityRadiusMeters(radius);
                      setState(() => _proximityRadius = radius);
                      if (mounted) {
                        AppToast.showArrival(
                          context,
                          'Arrival alerts will trigger within $radius meters of pinned rooms.',
                          icon: Icons.near_me_rounded,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryGreen.withOpacity(0.2) : AppTheme.bgDarkElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryGreen : AppTheme.borderDark,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryGreenLight : AppTheme.textSecondaryDark,
                        ),
                      ),
                    ),
                  );
                }),
                // Custom Meter Chip
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showCustomRadiusInputDialog(isPro),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: !radiuses.contains(_proximityRadius)
                          ? AppTheme.primaryGreen.withOpacity(0.2)
                          : AppTheme.bgDarkElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !radiuses.contains(_proximityRadius)
                            ? AppTheme.primaryGreen
                            : AppTheme.borderDark,
                        width: !radiuses.contains(_proximityRadius) ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 13,
                          color: !radiuses.contains(_proximityRadius)
                              ? AppTheme.primaryGreenLight
                              : AppTheme.textSecondaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          !radiuses.contains(_proximityRadius)
                              ? 'Custom: ${_proximityRadius}m'
                              : 'Custom Input...',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: !radiuses.contains(_proximityRadius) ? FontWeight.bold : FontWeight.normal,
                            color: !radiuses.contains(_proximityRadius)
                                ? AppTheme.primaryGreenLight
                                : AppTheme.textSecondaryDark,
                          ),
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

  Future<void> _showCustomRadiusInputDialog(bool isPro) async {
    if (!isPro) {
      ProGateDialog.show(
        context,
        featureName: 'Custom Arrival Trigger Radius',
        featureDescription:
            'Configuring custom meter arrival geofence radiuses requires SemBase Pro.',
        featureIcon: Icons.near_me_rounded,
      );
      return;
    }

    final controller = TextEditingController(text: _proximityRadius.toString());
    int tempRadius = _proximityRadius;

    await showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_location_alt_rounded, color: AppTheme.primaryGreenLight, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Custom Trigger Radius',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specify the exact distance in meters from your pinned classroom/building to fire the arrival alert.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Trigger Radius (Meters)',
                      labelStyle: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
                      suffixText: 'meters',
                      suffixStyle: const TextStyle(color: AppTheme.primaryGreenLight, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: AppTheme.bgDarkElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setDialogState(() => tempRadius = parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Quick Step Adjusters
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          final current = int.tryParse(controller.text) ?? tempRadius;
                          final next = (current - 25).clamp(15, 2000);
                          controller.text = next.toString();
                          setDialogState(() => tempRadius = next);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: AppTheme.borderDark),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('-25m', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          final current = int.tryParse(controller.text) ?? tempRadius;
                          final next = (current + 25).clamp(15, 2000);
                          controller.text = next.toString();
                          setDialogState(() => tempRadius = next);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: AppTheme.borderDark),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('+25m', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          final current = int.tryParse(controller.text) ?? tempRadius;
                          final next = (current + 100).clamp(15, 2000);
                          controller.text = next.toString();
                          setDialogState(() => tempRadius = next);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: AppTheme.borderDark),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('+100m', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Min: 15m • Max: 2,000m (Recommended: 30m–200m)',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textMutedDark),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryDark)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final parsed = int.tryParse(controller.text);
                    if (parsed == null || parsed < 15 || parsed > 2000) {
                      AppToast.showWarning(
                        context,
                        'Please enter a radius between 15m and 2,000m.',
                        icon: Icons.warning_amber_rounded,
                      );
                      return;
                    }
                    Navigator.of(ctx).pop(parsed);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Radius', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    ).then((newRadius) async {
      if (newRadius != null && mounted) {
        await AlarmNotificationService.setProximityRadiusMeters(newRadius);
        setState(() => _proximityRadius = newRadius);
        if (mounted) {
          AppToast.showArrival(
            context,
            'Arrival trigger radius set to $newRadius meters.',
            icon: Icons.near_me_rounded,
            duration: const Duration(seconds: 2),
          );
        }
      }
    });
  }

  Widget _buildTestNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trigger an immediate high-priority test notification to verify your device\'s vibration, sound, and heads-up banner channels.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await AlarmNotificationService.showTestNotification();
                if (mounted) {
                  AppToast.showSuccess(
                    context,
                    'Test notification sent! Check your notification shade.',
                    icon: Icons.notifications_active_rounded,
                  );
                }
              },
              icon: const Icon(Icons.vibration_rounded, size: 18),
              label: const Text('Send Test Notification', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bgDarkElevated,
                foregroundColor: AppTheme.primaryGreenLight,
                side: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

