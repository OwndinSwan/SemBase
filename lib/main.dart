import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/logging/app_log_service.dart';
import 'core/notifications/alarm_notification_service.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'core/services/vacant_period_service.dart';
import 'core/sync/sync_outbox_worker.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/services/account_login_detector.dart';
import 'features/auth/services/auth_keystore_service.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/map/screens/map_hub_screen.dart';
import 'features/schedule_grid/screens/schedule_view_screen.dart';
import 'features/subject_hub/screens/subject_detail_screen.dart';
import 'features/subject_hub/screens/subject_hub_list_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/utils/app_toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Local Diagnostic Activity Logger & prune 30d+ old logs
  await AppLogService.init();
  AppLogService.info(AppLogService.catApp, 'Application cold boot started');

  // 2. Initialize Local Notifications, Background Alarm Daemon & Vacant Period Service
  await AlarmNotificationService.initialize();
  // NOTE: scheduleMorningBriefing() is called from DashboardScreen.initState()
  // after POST_NOTIFICATIONS permission is confirmed — NOT here at cold start.
  await VacantPeriodService.init();

  // 2. Optional Supabase Backend Initialization (Graceful failure if offline or placeholders)
  try {
    if (!AppConfig.supabaseUrl.contains('your-project')) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    }
  } catch (e) {
    debugPrint('Supabase cloud init skipped/offline: $e');
  }

  runApp(
    ProviderScope(
      child: SemBaseApp(key: SemBaseApp.appKey),
    ),
  );
}

class SemBaseApp extends ConsumerStatefulWidget {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<_SemBaseAppState> appKey = GlobalKey<_SemBaseAppState>();

  static void signOut(BuildContext context) {
    appKey.currentState?.handleSignOut();
  }

  const SemBaseApp({super.key});

  @override
  ConsumerState<SemBaseApp> createState() => _SemBaseAppState();
}

class _SemBaseAppState extends ConsumerState<SemBaseApp> {
  bool _hasSession = false;
  bool _isUnlocked = false;
  bool _isCheckingAuth = true;
  StreamSubscription<SyncNotificationEvent>? _syncSub;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
    _startSyncWorker();
    _listenToSyncEvents();
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  void _listenToSyncEvents() {
    _syncSub = SyncOutboxWorker.syncEvents.stream.listen((event) {
      final color = event.type == SyncEventType.pushed ? AppTheme.primaryGreen : AppTheme.accentCyan;
      final icon = event.type == SyncEventType.pushed ? Icons.cloud_upload_outlined : Icons.cloud_download_outlined;

      AppToast.showWithMessenger(
        SemBaseApp.scaffoldMessengerKey.currentState,
        message: event.message,
        color: color,
        icon: icon,
      );
    });
  }

  void _startSyncWorker() {
    final db = ref.read(databaseProvider);
    final worker = SyncOutboxWorker(db);
    worker.start();
  }

  Future<void> _checkInitialAuth() async {
    final hasActiveSession = await AuthKeystoreService.isSessionActive();
    final bioEnabled = await AuthKeystoreService.isBiometricEnabled();

    if (!hasActiveSession) {
      if (mounted) {
        setState(() {
          _hasSession = false;
          _isUnlocked = false;
          _isCheckingAuth = false;
        });
      }
      return;
    }

    _hasSession = true;

    // Detect Pro subscription status and check cloud records immediately
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      AccountLoginDetector.onUserSignedIn(context, ref, userId: currentUser.id, showPrompt: true);
    } else {
      ref.read(subscriptionProvider.notifier).loadSubscription(syncCloud: true);
    }

    if (bioEnabled) {
      final authenticated = await AuthKeystoreService.authenticateWithBiometrics();
      if (mounted) {
        setState(() {
          _isUnlocked = authenticated;
          _isCheckingAuth = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isUnlocked = true;
          _isCheckingAuth = false;
        });
      }
    }
  }

  void handleSignOut() {
    ref.read(subscriptionProvider.notifier).resetToFree();
    setState(() {
      _hasSession = false;
      _isUnlocked = false;
      _isCheckingAuth = false;
    });
  }

  void handleSignIn() {
    ref.read(subscriptionProvider.notifier).loadSubscription(syncCloud: true);
    setState(() {
      _hasSession = true;
      _isUnlocked = true;
      _isCheckingAuth = false;
    });
  }

  Future<void> _checkBiometricLock() async {
    final authenticated = await AuthKeystoreService.authenticateWithBiometrics();
    if (mounted) {
      setState(() {
        _isUnlocked = authenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SemBaseApp.navigatorKey,
      scaffoldMessengerKey: SemBaseApp.scaffoldMessengerKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: _isCheckingAuth
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            )
          : (!_hasSession
              ? AuthScreen(
                  onAuthenticated: () {
                    ref.read(subscriptionProvider.notifier).loadSubscription(syncCloud: true);
                    setState(() {
                      _hasSession = true;
                      _isUnlocked = true;
                    });
                  },
                )
              : (!_isUnlocked
                  ? _buildLockedScreen()
                  : const MainNavigationShell())),
    );
  }

  Widget _buildLockedScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 56, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 24),
              const Text(
                'SemBase Vault Locked',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authenticate with your fingerprint or device PIN to access your academic schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryDark),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkBiometricLock,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Unlock with Fingerprint / PIN'),
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
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  void _navigateToCourse(String courseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubjectDetailScreen(courseId: courseId),
      ),
    );
  }

  void _handleBackPress() {
    // If not on Dashboard tab, switch to Dashboard tab first
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    // If on Dashboard tab, require double tap within 2s to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      AppToast.showInfo(
        context,
        'Press back again to exit SemBase',
        icon: Icons.exit_to_app_rounded,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Exits app
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      ScheduleViewScreen(onCourseTap: _navigateToCourse),
      const SubjectHubListScreen(),
      const MapHubScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryGreenLight),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: AppTheme.primaryGreenLight),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book, color: AppTheme.primaryGreenLight),
              label: 'Subjects',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: AppTheme.primaryGreenLight),
              label: 'Map Hub',
            ),
          ],
        ),
      ),
    );
  }
}
