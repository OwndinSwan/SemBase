import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_log_service.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../core/sync/sync_outbox_worker.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/connectivity_status_badge.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../../shared/widgets/pro_gate_dialog.dart';
import '../../../auth/services/auth_keystore_service.dart';

class CloudSyncSettingsScreen extends ConsumerStatefulWidget {
  const CloudSyncSettingsScreen({super.key});

  @override
  ConsumerState<CloudSyncSettingsScreen> createState() => _CloudSyncSettingsScreenState();
}

class _CloudSyncSettingsScreenState extends ConsumerState<CloudSyncSettingsScreen> {
  bool _isAutoSync = true;
  bool _isPushing = false;
  bool _isPulling = false;
  int _pendingMutationsCount = 0;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final autoSync = await SyncOutboxWorker.isAutoSyncEnabled();
    final db = ref.read(databaseProvider);
    final pending = await db.getPendingMutations();
    final email = await AuthKeystoreService.getUserEmail();

    if (mounted) {
      setState(() {
        _isAutoSync = autoSync;
        _pendingMutationsCount = pending.length;
        _userEmail = email;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _userEmail == null || _userEmail!.isEmpty;
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync & Data Vault'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: ConnectivityStatusBadge()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. Vault Sync Status Card
                _buildSyncStatusCard(isGuest),
                const SizedBox(height: 20),

                // 2. Synchronization Settings
                _buildSectionHeader('Automatic Background Sync', Icons.sync_rounded),
                const SizedBox(height: 8),
                _buildAutoSyncCard(isGuest, isPro),
                const SizedBox(height: 20),

                // 3. Manual Cloud Operations
                _buildSectionHeader('Manual Cloud Controls', Icons.cloud_done_rounded),
                const SizedBox(height: 8),
                _buildManualOperationsCard(isGuest, isPro),
                const SizedBox(height: 20),

                // 4. Outbox Queue Status
                _buildSectionHeader('Transactional Outbox Queue', Icons.queue_rounded),
                const SizedBox(height: 8),
                _buildOutboxInfoCard(),
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

  Widget _buildSyncStatusCard(bool isGuest) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGuest
                  ? AppTheme.accentAmber.withOpacity(0.15)
                  : (_pendingMutationsCount > 0
                      ? AppTheme.accentCyan.withOpacity(0.15)
                      : AppTheme.primaryGreen.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isGuest
                  ? Icons.cloud_off_rounded
                  : (_pendingMutationsCount > 0 ? Icons.sync_problem_rounded : Icons.cloud_done_rounded),
              color: isGuest
                  ? AppTheme.accentAmber
                  : (_pendingMutationsCount > 0 ? AppTheme.accentCyan : AppTheme.primaryGreenLight),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest
                      ? 'Offline Vault Mode'
                      : (_pendingMutationsCount > 0
                          ? '$_pendingMutationsCount Unsynced Change(s)'
                          : 'Vault Up to Date'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                ),
                const SizedBox(height: 2),
                Text(
                  isGuest
                      ? 'Local SQLite data is stored safely on this phone'
                      : (_pendingMutationsCount > 0
                          ? 'Changes queued locally and syncing to cloud'
                          : 'All local schedules and tasks match SemBase cloud'),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSyncCard(bool isGuest, bool isPro) {
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
            color: AppTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.sync_rounded, color: AppTheme.primaryGreenLight, size: 20),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Background Auto-Sync',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryDark),
              ),
            ),
            const SizedBox(width: 8),
            ProBadge(isProActive: isPro),
          ],
        ),
        subtitle: const Text(
          'Automatically stream offline schedule mutations to the cloud database when internet connects.',
          style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryDark, height: 1.3),
        ),
        value: _isAutoSync && isPro,
        activeThumbColor: AppTheme.primaryGreen,
        onChanged: isGuest
            ? null
            : (val) async {
                if (!isPro) {
                  ProGateDialog.show(
                    context,
                    featureName: 'Multi-Device Real-Time Cloud Sync',
                    featureDescription:
                        'Automatic background synchronization and multi-device cloud backups require SemBase Pro. You can still export and restore unlimited manual JSON backups 100% free!',
                    featureIcon: Icons.cloud_sync_rounded,
                  );
                  return;
                }
                await SyncOutboxWorker.setAutoSyncEnabled(val);
                setState(() => _isAutoSync = val);
              },
      ),
    );
  }

  Widget _buildManualOperationsCard(bool isGuest, bool isPro) {
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
            'Force manual synchronization between your device and the cloud database:',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isGuest || _isPushing || _isPulling
                      ? null
                      : () {
                          if (!isPro) {
                            ProGateDialog.show(
                              context,
                              featureName: 'Multi-Device Cloud Push',
                              featureDescription:
                                  'Pushing data to the central cloud database requires SemBase Pro. You can create unlimited personal JSON backups locally on your device for free anytime.',
                              featureIcon: Icons.cloud_upload_rounded,
                            );
                            return;
                          }
                          _handleManualPush();
                        },
                  icon: _isPushing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreenLight))
                      : const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: const Text('Push to Cloud', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                    foregroundColor: AppTheme.primaryGreenLight,
                    side: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isGuest || _isPushing || _isPulling
                      ? null
                      : () {
                          if (!isPro) {
                            ProGateDialog.show(
                              context,
                              featureName: 'Multi-Device Cloud Pull',
                              featureDescription:
                                  'Restoring schedules directly from the cloud database requires SemBase Pro. You can import local personal JSON backups for free anytime.',
                              featureIcon: Icons.cloud_download_rounded,
                            );
                            return;
                          }
                          _handleManualPull();
                        },
                  icon: _isPulling
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentCyan))
                      : const Icon(Icons.cloud_download_outlined, size: 16),
                  label: const Text('Pull from Cloud', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentCyan,
                    side: const BorderSide(color: AppTheme.accentCyan, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutboxInfoCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pending Sync Mutations:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _pendingMutationsCount > 0 ? AppTheme.accentAmber.withOpacity(0.2) : AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_pendingMutationsCount records',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _pendingMutationsCount > 0 ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'SemBase uses a resilient local transactional outbox. Even without an active connection, all additions and edits are recorded locally in SQLite and synchronized automatically once network access resumes.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMutedDark, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _handleManualPush() async {
    setState(() => _isPushing = true);
    try {
      if (SyncOutboxWorker.instance != null) {
        await SyncOutboxWorker.instance!.syncAllLocalDataToCloud();
      }
      await _loadState();
      if (mounted) {
        AppToast.showSuccess(
          context,
          'Cloud sync push completed successfully!',
          icon: Icons.cloud_upload_outlined,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Sync failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isPushing = false);
    }
  }

  Future<void> _handleManualPull() async {
    setState(() => _isPulling = true);
    try {
      if (SyncOutboxWorker.instance != null) {
        await SyncOutboxWorker.instance!.pullCloudDataToLocalDatabase(force: true);
      }
      await _loadState();
      if (mounted) {
        AppToast.showSuccess(
          context,
          'Local database updated from cloud!',
          icon: Icons.cloud_download_outlined,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Pull error: $e');
      }
    } finally {
      if (mounted) setState(() => _isPulling = false);
    }
  }
}
