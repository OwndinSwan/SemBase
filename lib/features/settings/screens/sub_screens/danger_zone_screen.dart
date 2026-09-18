import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/animated_confirm_dialog.dart';
import '../../../auth/services/auth_keystore_service.dart';
import '../../widgets/account_deletion_dialog.dart';

class DangerZoneScreen extends ConsumerStatefulWidget {
  const DangerZoneScreen({super.key});

  @override
  ConsumerState<DangerZoneScreen> createState() => _DangerZoneScreenState();
}

class _DangerZoneScreenState extends ConsumerState<DangerZoneScreen> {
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final email = await AuthKeystoreService.getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _userEmail == null || _userEmail!.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danger Zone'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. Re-index Cache Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.refresh_rounded, color: AppTheme.accentAmber, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clear Cache & Re-index',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryDark),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Refresh local timetable indexing and reminders',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Fixes display glitches or stale notification offsets. Your subjects, tasks, and notes will NOT be deleted.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMutedDark, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed = await AnimatedConfirmDialog.show(
                              context,
                              title: 'Clear Cache & Re-index?',
                              message: 'This will re-index your local schedule cache. Your subjects, tasks, and archived terms will be preserved.',
                              confirmLabel: 'Re-index',
                              confirmColor: AppTheme.accentAmber,
                              icon: Icons.refresh,
                            );

                            if (confirmed && mounted) {
                              AppToast.showSuccess(
                                context,
                                'Cache re-indexed successfully!',
                                icon: Icons.cleaning_services_rounded,
                              );
                            }
                          },
                          icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: AppTheme.accentAmber),
                          label: const Text('Re-index Local Cache', style: TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.accentAmber, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Account Deletion Card (Only for Cloud Accounts)
                if (!isGuest) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentRose.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentRose.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.delete_forever_rounded, color: AppTheme.accentRose, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delete Account Permanently',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentRose),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Irreversible erasure of cloud vaults',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Permanently deletes your cloud profile, synchronized subjects, and checklist records from SemBase cloud servers.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMutedDark, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirmed = await AnimatedConfirmDialog.show(
                                context,
                                title: 'Delete Account Permanently?',
                                message: 'This will permanently erase your local vault, cloud schedules, and syllabus tasks. This action cannot be undone.',
                                confirmLabel: 'Delete Account',
                                confirmColor: AppTheme.accentRose,
                                icon: Icons.delete_forever_rounded,
                              );

                              if (confirmed && mounted) {
                                AccountDeletionDialog.start(context, ref, isGuest: isGuest);
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Proceed to Account Deletion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentRose.withOpacity(0.15),
                              foregroundColor: AppTheme.accentRose,
                              side: const BorderSide(color: AppTheme.accentRose, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
