import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/sync/sync_outbox_worker.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_toast.dart';
import '../services/auth_keystore_service.dart';

class AuthSettingsDialog extends ConsumerStatefulWidget {
  const AuthSettingsDialog({super.key});

  @override
  ConsumerState<AuthSettingsDialog> createState() => _AuthSettingsDialogState();
}

class _AuthSettingsDialogState extends ConsumerState<AuthSettingsDialog> {
  bool _isBiometricEnabled = false;
  bool _isLoading = false;
  int _pendingQueueCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bio = await AuthKeystoreService.isBiometricEnabled();
    final db = ref.read(databaseProvider);
    final pending = await db.getPendingMutations();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = bio;
        _pendingQueueCount = pending.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppTheme.accentCyan),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Security & Cloud Sync',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMutedDark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hardware Keystore & Biometrics
            const Text(
              'Local Keystore & Biometrics',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMutedDark),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint, color: AppTheme.primaryGreenLight),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Biometric App Lock', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark)),
                        Text('Fingerprint / PIN unlock via Android Keystore', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isBiometricEnabled,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) async {
                      if (val) {
                        final authOk = await AuthKeystoreService.authenticateWithBiometrics();
                        if (!authOk) return;
                      }
                      await AuthKeystoreService.setBiometricEnabled(val);
                      setState(() => _isBiometricEnabled = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cloud Sync Section
            const Text(
              'SemBase Encrypted Cloud Hub',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMutedDark),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync_outlined, color: AppTheme.accentIndigo),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Transactional Outbox Queue',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentIndigo.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_pendingQueueCount Pending',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentIndigo),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mutations are queued locally in Drift and synchronized with Last-Write-Wins (LWW) resolution when connected.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _triggerSyncWorker(db),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Process Outbox Sync Now'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentIndigo,
                        side: const BorderSide(color: AppTheme.accentIndigo),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerSyncWorker(AppDatabase db) async {
    setState(() => _isLoading = true);
    final worker = SyncOutboxWorker(db);
    await worker.processPendingMutations();
    await _loadSettings();
    if (mounted) {
      setState(() => _isLoading = false);
      AppToast.showSuccess(context, 'Outbox queue processed.');
    }
  }
}
