import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/sync/sync_outbox_worker.dart';
import '../../../main.dart';
import '../../../shared/theme/app_theme.dart';
import '../../settings/screens/sub_screens/subscription_plans_screen.dart';

/// Detector that executes immediately upon user sign-in to:
/// 1. Synchronize Pro account status in background
/// 2. Scan cloud database for saved records (e.g. from previous expired Pro plan) and prompt Free accounts
class AccountLoginDetector {
  /// Runs immediately after authentication to sync tier and check for locked cloud data
  static Future<void> onUserSignedIn(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    bool showPrompt = true,
  }) async {
    // 1. Launch Pro status sync immediately in background & update Riverpod state
    AppLogService.info(
      AppLogService.catAuth,
      'Executing background Pro account status detection for $userId',
    );

    final subInfo = await SubscriptionService.syncCloudSubscription();
    await ref.read(subscriptionProvider.notifier).loadSubscription(syncCloud: false);

    // 2. If user is on Pro plan, start pulling remote cloud data immediately
    if (subInfo.isPro) {
      AppLogService.success(
        AppLogService.catSync,
        'Pro account active on sign-in. Initializing cloud pull & realtime sync.',
      );
      final db = ref.read(databaseProvider);
      final worker = SyncOutboxWorker(db);
      await worker.pullCloudDataToLocalDatabase(force: true);
      return;
    }

    // 3. If account is on Free plan, scan if there are saved cloud records in Supabase
    if (!showPrompt) return;

    try {
      if (!AppConfig.supabaseUrl.contains('your-project')) {
        final client = Supabase.instance.client;
        final response = await client
            .from('courses')
            .select('id')
            .eq('user_id', userId)
            .limit(1)
            .timeout(const Duration(seconds: 5));

        if (response.isNotEmpty) {
          AppLogService.info(
            AppLogService.catAuth,
            'Saved cloud data detected for Free account ($userId). Prompting user.',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentIsPro = ref.read(isProProvider);
            if (currentIsPro) return;

            final activeCtx = SemBaseApp.navigatorKey.currentContext ?? (context.mounted ? context : null);
            if (activeCtx != null && activeCtx.mounted) {
              _showCloudDataDetectedDialog(activeCtx);
            }
          });
        }
      }
    } catch (e) {
      AppLogService.warning(AppLogService.catAuth, 'Notice scanning cloud database records: $e');
    }
  }

  static void _showCloudDataDetectedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: AppTheme.accentCyan, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cloud Data Detected ☁️',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We found existing academic schedules and tasks saved in your cloud data vault from a previous session.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryDark, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'However, your account is currently on the Free Academic Plan, so cloud sync & automatic restore are locked.',
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w600, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Would you like to renew / upgrade to Pro to pull all your saved cloud data, or continue with Free (start fresh or import your backup in Settings)?',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Continue with Free', style: TextStyle(color: AppTheme.textSecondaryDark)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              final navState = SemBaseApp.navigatorKey.currentState;
              if (navState != null) {
                navState.push(
                  MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                );
              } else if (context.mounted) {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                );
              }
            },
            icon: const Icon(Icons.workspace_premium_rounded, size: 16),
            label: const Text('Renew / Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
