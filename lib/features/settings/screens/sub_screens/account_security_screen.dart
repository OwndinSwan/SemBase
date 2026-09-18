import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/notifications/alarm_notification_service.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../main.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/animated_confirm_dialog.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../../shared/widgets/pro_gate_dialog.dart';
import '../../../auth/screens/auth_screen.dart';
import '../../../auth/services/auth_keystore_service.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> with WidgetsBindingObserver {
  String? _userEmail;
  bool _isBiometricEnabled = false;
  bool _hasNotificationPermission = false;
  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = true;
  bool _isPreciseLocation = false;
  bool _isBatteryExempt = false;
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
    final isGuest = await AuthKeystoreService.isGuestMode();
    final email = isGuest ? null : await AuthKeystoreService.getUserEmail();
    final bio = await AuthKeystoreService.isBiometricEnabled();
    final notif = await AlarmNotificationService.checkNotificationPermission();
    final battery = await AlarmNotificationService.isIgnoringBatteryOptimizations();

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
        _userEmail = email;
        _isBiometricEnabled = bio;
        _hasNotificationPermission = notif;
        _hasLocationPermission = hasLoc;
        _isLocationServiceEnabled = isLocService;
        _isPreciseLocation = precise;
        _isBatteryExempt = battery;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileStreamProvider);
    final isGuest = _userEmail == null || _userEmail!.isEmpty;
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Security'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. Account Info Card
                _buildAccountInfoCard(profileAsync.value, isGuest),
                const SizedBox(height: 20),

                // 2. System Permissions & Hardware Sensors (Moved here!)
                _buildSectionHeader('System Permissions & Sensor Access', Icons.security_rounded),
                const SizedBox(height: 8),
                _buildSystemPermissionsCard(),
                const SizedBox(height: 20),

                // 3. Authentication & Biometrics
                _buildSectionHeader('Device Security & Biometrics', Icons.fingerprint_rounded),
                const SizedBox(height: 8),
                _buildBiometricsCard(isGuest, isPro),
                const SizedBox(height: 20),

                // 4. Password Management (For Cloud Users)
                if (!isGuest) ...[
                  _buildSectionHeader('Credentials & Login', Icons.password_rounded),
                  const SizedBox(height: 8),
                  _buildPasswordCard(),
                  const SizedBox(height: 20),
                ],

                // 5. Session Actions
                _buildSectionHeader('Session Management', Icons.logout_rounded),
                const SizedBox(height: 8),
                _buildSessionCard(isGuest),
                const SizedBox(height: 32),
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondaryDark,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoCard(AcademicProfile? profile, bool isGuest) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isGuest ? AppTheme.accentAmber.withOpacity(0.18) : AppTheme.primaryGreen.withOpacity(0.18),
            child: Icon(
              isGuest ? Icons.person_outline : Icons.person_rounded,
              color: isGuest ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGuest ? AppTheme.accentAmber.withOpacity(0.15) : AppTheme.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGuest ? 'Local Offline Mode' : 'Cloud Sync Active',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isGuest ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                        ),
                      ),
                    ),
                    if (profile != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        profile.section,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPermissionsCard() {
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
          // Row 1: System Notifications Permission
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hasNotificationPermission
                    ? AppTheme.primaryGreen.withOpacity(0.15)
                    : AppTheme.accentRose.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _hasNotificationPermission ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                color: _hasNotificationPermission ? AppTheme.primaryGreenLight : AppTheme.accentRose,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'System Notifications',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _hasNotificationPermission
                        ? AppTheme.primaryGreen.withOpacity(0.15)
                        : AppTheme.accentRose.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _hasNotificationPermission
                          ? AppTheme.primaryGreen.withOpacity(0.4)
                          : AppTheme.accentRose.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    _hasNotificationPermission ? 'ALLOWED' : 'DISABLED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _hasNotificationPermission ? AppTheme.primaryGreenLight : AppTheme.accentRose,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: const Text(
              'Required for pre-class reminders, morning academic briefings, and timetable notifications',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
            ),
            value: _hasNotificationPermission,
            activeThumbColor: AppTheme.primaryGreen,
            onChanged: (val) async {
              if (val) {
                final granted = await AlarmNotificationService.requestNotificationPermission();
                if (mounted) {
                  setState(() => _hasNotificationPermission = granted);
                  if (granted) {
                    AppToast.showSuccess(
                      context,
                      'Notification permission granted.',
                      icon: Icons.notifications_active_rounded,
                    );
                  } else {
                    AppToast.showWarning(
                      context,
                      'Please enable notifications in App Settings.',
                      icon: Icons.settings_rounded,
                    );
                    await Geolocator.openAppSettings();
                  }
                }
              } else {
                if (mounted) {
                  AppToast.showInfo(
                    context,
                    'To revoke notification permission, adjust permissions in App Settings.',
                    icon: Icons.tune_rounded,
                  );
                  await Geolocator.openAppSettings();
                }
              }
            },
          ),

          const Divider(color: AppTheme.borderDark, height: 20),

          // Row 2: Location Access Permission
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hasLocationPermission
                    ? AppTheme.primaryGreen.withOpacity(0.15)
                    : AppTheme.accentAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _hasLocationPermission ? Icons.location_on_rounded : Icons.location_off_rounded,
                color: _hasLocationPermission ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Location Access',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _hasLocationPermission
                        ? AppTheme.primaryGreen.withOpacity(0.15)
                        : AppTheme.accentAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _hasLocationPermission
                          ? AppTheme.primaryGreen.withOpacity(0.4)
                          : AppTheme.accentAmber.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    _hasLocationPermission ? 'GRANTED' : 'DENIED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _hasLocationPermission ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: const Text(
              'Powers campus map positioning, multi-modal commute routing, and room arrival alerts',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
            ),
            value: _hasLocationPermission,
            activeThumbColor: AppTheme.primaryGreen,
            onChanged: (val) async {
              if (val) {
                final perm = await Geolocator.requestPermission();
                if (perm == LocationPermission.deniedForever) {
                  if (mounted) {
                    AppToast.showWarning(
                      context,
                      'Location permission is permanently denied. Please enable it in App Settings.',
                      icon: Icons.settings_rounded,
                    );
                    await Geolocator.openAppSettings();
                  }
                } else if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
                  await _loadState();
                  if (mounted) {
                    AppToast.showSuccess(
                      context,
                      'Location access granted.',
                      icon: Icons.location_on_rounded,
                    );
                  }
                }
              } else {
                if (mounted) {
                  AppToast.showInfo(
                    context,
                    'To revoke location permission, adjust permissions in App Settings.',
                    icon: Icons.tune_rounded,
                  );
                  await Geolocator.openAppSettings();
                }
              }
            },
          ),

          const Divider(color: AppTheme.borderDark, height: 20),

          // Row 3: Precise Location (High Accuracy GNSS)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isPreciseLocation
                    ? AppTheme.accentCyan.withOpacity(0.15)
                    : AppTheme.borderDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isPreciseLocation ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                color: _isPreciseLocation ? AppTheme.accentCyan : AppTheme.textMutedDark,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Precise Location (GNSS)',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isPreciseLocation
                        ? AppTheme.accentCyan.withOpacity(0.15)
                        : AppTheme.borderDark.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isPreciseLocation
                          ? AppTheme.accentCyan.withOpacity(0.4)
                          : AppTheme.borderDark,
                    ),
                  ),
                  child: Text(
                    _isPreciseLocation ? 'PRECISE' : 'APPROXIMATE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _isPreciseLocation ? AppTheme.accentCyan : AppTheme.textMutedDark,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: const Text(
              'High-precision satellite positioning for room-level proximity triggers & live heading',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
            ),
            value: _isPreciseLocation && _hasLocationPermission,
            activeThumbColor: AppTheme.accentCyan,
            onChanged: _hasLocationPermission
                ? (val) async {
                    if (val && !_isPreciseLocation) {
                      AppToast.showInfo(
                        context,
                        'Please verify "Use Precise Location" is toggled ON in system location settings.',
                        icon: Icons.gps_fixed_rounded,
                        duration: const Duration(seconds: 4),
                      );
                      await Geolocator.openAppSettings();
                    } else if (!val) {
                      AppToast.showInfo(
                        context,
                        'Precise accuracy can be changed in device Location Settings.',
                        icon: Icons.tune_rounded,
                      );
                      await Geolocator.openAppSettings();
                    }
                  }
                : null,
          ),

          const Divider(color: AppTheme.borderDark, height: 20),

          // Row 4: Battery Saver / Doze Mode Exemption
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isBatteryExempt
                      ? AppTheme.primaryGreen.withOpacity(0.15)
                      : AppTheme.accentAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isBatteryExempt ? Icons.bolt_rounded : Icons.battery_alert_rounded,
                  color: _isBatteryExempt ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Battery Saver Exemption',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isBatteryExempt
                                ? AppTheme.primaryGreen.withOpacity(0.15)
                                : AppTheme.accentAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isBatteryExempt
                                  ? AppTheme.primaryGreen.withOpacity(0.4)
                                  : AppTheme.accentAmber.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            _isBatteryExempt ? 'EXEMPTED' : 'RESTRICTED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _isBatteryExempt ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isBatteryExempt
                          ? 'Push notifications can still deliver while device is idle'
                          : 'Android may delay background notifications in deep sleep',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!_isBatteryExempt) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AlarmNotificationService.openBatteryOptimizationSettings();
                  final exempt = await AlarmNotificationService.isIgnoringBatteryOptimizations();
                  setState(() => _isBatteryExempt = exempt);
                },
                icon: const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.accentAmber),
                label: const Text(
                  'Disable Battery Restrictions for SemBase',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.accentAmber, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accentAmber, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Row 5: Quick App Settings Link
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
              icon: const Icon(Icons.tune_rounded, size: 15, color: AppTheme.primaryGreenLight),
              label: const Text(
                'Open Device System App Settings',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreenLight),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.bgDarkElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppTheme.borderDark.withOpacity(0.6)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricsCard(bool isGuest, bool isPro) {
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
            color: AppTheme.accentCyan.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fingerprint_rounded, color: AppTheme.accentCyan, size: 20),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Biometric App Lock',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
              ),
            ),
            const SizedBox(width: 8),
            ProBadge(isProActive: isPro),
          ],
        ),
        subtitle: const Text(
          'Require fingerprint or face ID to open SemBase',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
        ),
        value: _isBiometricEnabled && isPro,
        activeThumbColor: AppTheme.primaryGreen,
        onChanged: (val) async {
          if (!isPro && val) {
            ProGateDialog.show(
              context,
              featureName: 'Biometric Privacy App Lock',
              featureDescription:
                  'Requiring Fingerprint or Face ID unlock to protect your academic schedule and grades requires SemBase Pro.',
              featureIcon: Icons.fingerprint_rounded,
            );
            return;
          }
          if (val) {
            final authenticated = await AuthKeystoreService.authenticateWithBiometrics();
            if (!authenticated) {
              if (mounted) {
                AppToast.showError(
                  context,
                  'Biometric authentication failed or cancelled',
                  icon: Icons.fingerprint_rounded,
                );
              }
              return;
            }
          }
          await AuthKeystoreService.setBiometricEnabled(val);
          setState(() => _isBiometricEnabled = val);
        },
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryGreenLight, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                ),
                SizedBox(height: 2),
                Text(
                  'Update account credentials or security password',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showChangePasswordDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bgDarkElevated,
              foregroundColor: AppTheme.primaryGreenLight,
              side: const BorderSide(color: AppTheme.borderDark),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(bool isGuest) {
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
          if (isGuest) ...[
            const Text(
              'Sign in with your student email or Google account to enable automatic cloud sync across devices.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToAuth,
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text('Sign In / Link Cloud Account', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Signing out preserves your offline SQLite schedule on this device. You can sign back in anytime to resume cloud sync.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.accentRose),
                label: const Text('Sign Out', style: TextStyle(color: AppTheme.accentRose, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.accentRose.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    final appMetadata = user?.appMetadata ?? {};
    final providers = (appMetadata['providers'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
    final String? singleProvider = appMetadata['provider']?.toString().toLowerCase();
    final bool hasEmailIdentity = user?.identities?.any((i) => i.provider.toLowerCase() == 'email') ?? false;

    final bool isPureGoogle = (singleProvider == 'google' || (providers.contains('google') && providers.length == 1)) && !hasEmailIdentity;
    final bool hasEmailPassword = !isPureGoogle && user?.email != null;

    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isProcessing = false;
    String? dialogError;

    showGeneralDialog(
      context: context,
      barrierDismissible: !isProcessing,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: StatefulBuilder(
              builder: (ctx, setDialogState) => Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 380,
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryGreenLight, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasEmailPassword ? 'Change Password' : 'Set Account Password',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasEmailPassword
                                          ? 'Verify current password and set a new one'
                                          : 'Create a password for your account',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryDark, size: 20),
                                onPressed: isProcessing ? null : () => Navigator.of(dialogCtx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (dialogError != null) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentRose.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.accentRose.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.accentRose),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dialogError!,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.accentRose, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (hasEmailPassword) ...[
                            const Text(
                              'Current Password *',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: currentPassCtrl,
                              obscureText: obscureCurrent,
                              style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter your current password',
                                hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18, color: AppTheme.accentCyan),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: AppTheme.textMutedDark,
                                  ),
                                  onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                                ),
                                filled: true,
                                fillColor: AppTheme.bgDark.withOpacity(0.6),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.borderDark),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          const Text(
                            'New Password *',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: newPassCtrl,
                            obscureText: obscureNew,
                            style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Minimum 6 characters',
                              hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.accentAmber),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppTheme.textMutedDark,
                                ),
                                onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                              ),
                              filled: true,
                              fillColor: AppTheme.bgDark.withOpacity(0.6),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.borderDark),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'Confirm New Password *',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: confirmPassCtrl,
                            obscureText: obscureConfirm,
                            style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Re-enter new password',
                              hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                              prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppTheme.accentCyan),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppTheme.textMutedDark,
                                ),
                                onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                              ),
                              filled: true,
                              fillColor: AppTheme.bgDark.withOpacity(0.6),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.borderDark),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isProcessing ? null : () => Navigator.of(dialogCtx).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.textSecondaryDark,
                                    side: const BorderSide(color: AppTheme.borderDark),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isProcessing
                                      ? null
                                      : () async {
                                          final newPass = newPassCtrl.text.trim();
                                          final confirmPass = confirmPassCtrl.text.trim();
                                          final currentPass = currentPassCtrl.text.trim();

                                          if (hasEmailPassword && currentPass.isEmpty) {
                                            setDialogState(() => dialogError = 'Please enter your current password.');
                                            return;
                                          }

                                          if (newPass.length < 6) {
                                            setDialogState(() => dialogError = 'New password must be at least 6 characters.');
                                            return;
                                          }

                                          if (newPass != confirmPass) {
                                            setDialogState(() => dialogError = 'Passwords do not match.');
                                            return;
                                          }

                                          setDialogState(() {
                                            isProcessing = true;
                                            dialogError = null;
                                          });

                                          try {
                                            if (hasEmailPassword && user?.email != null) {
                                              try {
                                                await Supabase.instance.client.auth.signInWithPassword(
                                                  email: user!.email!,
                                                  password: currentPass,
                                                );
                                              } catch (_) {
                                                if (ctx.mounted) {
                                                  setDialogState(() {
                                                    isProcessing = false;
                                                    dialogError = 'Incorrect current password. Please try again.';
                                                  });
                                                }
                                                return;
                                              }
                                            }

                                            await Supabase.instance.client.auth.updateUser(
                                              UserAttributes(password: newPass),
                                            );

                                            if (mounted) {
                                              Navigator.of(dialogCtx).pop();
                                              AppToast.showSuccess(
                                                context,
                                                'Password updated successfully!',
                                                icon: Icons.lock_outline_rounded,
                                              );
                                            }
                                          } catch (e) {
                                            if (ctx.mounted) {
                                              setDialogState(() {
                                                isProcessing = false;
                                                dialogError = 'Error updating password: $e';
                                              });
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: isProcessing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text(
                                          'Save Password',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await AnimatedConfirmDialog.show(
      context,
      title: 'Sign Out?',
      message: 'Your offline SQLite data will remain safe on your device. You can sign back in anytime.',
      confirmLabel: 'Sign Out',
      confirmColor: AppTheme.accentRose,
      icon: Icons.logout,
    );

    if (confirmed) {
      await AuthKeystoreService.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        SemBaseApp.signOut(context);
      }
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          onAuthenticated: () {
            Navigator.of(context).pop();
            _loadState();
          },
        ),
      ),
    );
  }
}
