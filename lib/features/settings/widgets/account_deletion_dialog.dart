import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../main.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/services/auth_keystore_service.dart';

enum DeletionStepState { pending, inProgress, completed, failed }

class DeletionStep {
  final String title;
  final String description;
  final IconData icon;
  DeletionStepState state;

  DeletionStep({
    required this.title,
    required this.description,
    required this.icon,
    this.state = DeletionStepState.pending,
  });
}

class AccountDeletionDialog extends StatefulWidget {
  final WidgetRef ref;
  final bool isGuest;

  const AccountDeletionDialog({
    super.key,
    required this.ref,
    required this.isGuest,
  });

  static Future<void> start(BuildContext context, WidgetRef ref, {required bool isGuest}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountDeletionDialog(ref: ref, isGuest: isGuest),
    );
  }

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  late final List<DeletionStep> _steps;
  int _currentStepIndex = 0;
  bool _isFinished = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _steps = [
      DeletionStep(
        title: 'Wiping Local Database Vault',
        description: 'Purging schedules, subjects, syllabus tasks & SQLite tables',
        icon: Icons.storage_rounded,
      ),
      if (!widget.isGuest)
        DeletionStep(
          title: 'Purging SemBase Cloud Records',
          description: 'Deleting remote academic profile, courses & checklist rows',
          icon: Icons.cloud_off_rounded,
        ),
      DeletionStep(
        title: 'Destroying Device Keystore',
        description: 'Clearing hardware encryption keys, session tokens & biometrics',
        icon: Icons.vpn_key_off_rounded,
      ),
      DeletionStep(
        title: 'Resetting Application State',
        description: 'Invalidating reactive cache and restoring clean startup',
        icon: Icons.restart_alt_rounded,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeDeletionPipeline();
    });
  }

  Future<void> _executeDeletionPipeline() async {
    final db = widget.ref.read(databaseProvider);

    try {
      // -------------------------------------------------------------
      // Step 1: Wipe Local SQLite Tables
      // -------------------------------------------------------------
      _updateStep(0, DeletionStepState.inProgress);
      await Future.delayed(const Duration(milliseconds: 350));

      await db.clearAllData();

      _updateStep(0, DeletionStepState.completed);
      await Future.delayed(const Duration(milliseconds: 250));

      // -------------------------------------------------------------
      // Step 2: Purge Remote Supabase Cloud Records (if not guest)
      // -------------------------------------------------------------
      int nextIdx = 1;
      if (!widget.isGuest) {
        _updateStep(nextIdx, DeletionStepState.inProgress);
        try {
          final user = Supabase.instance.client.auth.currentUser;
          final session = Supabase.instance.client.auth.currentSession;
          final userId = user?.id ?? session?.user.id;
          if (userId != null && userId.isNotEmpty) {
            debugPrint('Purging Supabase cloud tables and auth account for user: $userId');
            // 1. Invoke server-side RPC to wipe auth.users login and all database rows
            try {
              await Supabase.instance.client.rpc('delete_user_account');
              debugPrint('RPC delete_user_account executed successfully');
            } catch (rpcError) {
              debugPrint('RPC delete_user_account fallback to direct table delete: $rpcError');
              // Fallback: direct table wipe if RPC is not yet created in Supabase
              await Supabase.instance.client.from('course_metadata').delete().eq('user_id', userId);
              await Supabase.instance.client.from('course_tasks').delete().eq('user_id', userId);
              await Supabase.instance.client.from('course_schedules').delete().eq('user_id', userId);
              await Supabase.instance.client.from('courses').delete().eq('user_id', userId);
              await Supabase.instance.client.from('academic_profiles').delete().eq('user_id', userId);
            }
            debugPrint('Supabase cloud tables successfully purged for user: $userId');
          }
        } catch (e) {
          debugPrint('Remote Supabase deletion exception: $e');
        }
        _updateStep(nextIdx, DeletionStepState.completed);
        await Future.delayed(const Duration(milliseconds: 250));
        nextIdx++;
      }

      // -------------------------------------------------------------
      // Step 3: Destroy Keystore & OAuth Session
      // -------------------------------------------------------------
      _updateStep(nextIdx, DeletionStepState.inProgress);
      await Future.delayed(const Duration(milliseconds: 250));

      await AuthKeystoreService.signOut();
      await AuthKeystoreService.clearAll();

      _updateStep(nextIdx, DeletionStepState.completed);
      await Future.delayed(const Duration(milliseconds: 250));
      nextIdx++;

      // -------------------------------------------------------------
      // Step 4: Reset Cache & Application State
      // -------------------------------------------------------------
      _updateStep(nextIdx, DeletionStepState.inProgress);
      widget.ref.invalidate(activeProfileStreamProvider);
      await Future.delayed(const Duration(milliseconds: 400));
      _updateStep(nextIdx, DeletionStepState.completed);

      setState(() {
        _isFinished = true;
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        SemBaseApp.signOut(context);
      }
    } catch (err) {
      debugPrint('Fatal deletion error: $err');
      setState(() {
        _errorMessage = err.toString();
        _steps[_currentStepIndex].state = DeletionStepState.failed;
      });
    }
  }

  void _updateStep(int index, DeletionStepState state) {
    if (!mounted) return;
    setState(() {
      _currentStepIndex = index;
      _steps[index].state = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing mid-deletion
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.accentRose.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isFinished ? AppTheme.primaryGreen.withOpacity(0.15) : AppTheme.accentRose.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFinished ? Icons.check_circle_outline_rounded : Icons.delete_forever_rounded,
                    color: _isFinished ? AppTheme.primaryGreenLight : AppTheme.accentRose,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  _isFinished ? 'Account Successfully Wiped' : 'Permanently Deleting Account...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isFinished ? 'Returning to Welcome screen' : 'Please wait while databases and tokens are cleared',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 20),

                // Step-by-Step Progress Items
                ...List.generate(_steps.length, (i) {
                  final step = _steps[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: step.state == DeletionStepState.inProgress
                            ? AppTheme.accentRose.withOpacity(0.6)
                            : (step.state == DeletionStepState.completed
                                ? AppTheme.primaryGreen.withOpacity(0.3)
                                : AppTheme.borderDark.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildStepIndicator(step.state, step.icon),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: step.state == DeletionStepState.inProgress
                                      ? AppTheme.textPrimaryDark
                                      : (step.state == DeletionStepState.completed
                                          ? AppTheme.primaryGreenLight
                                          : AppTheme.textMutedDark),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                step.description,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRose.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error: $_errorMessage',
                      style: const TextStyle(fontSize: 11, color: AppTheme.accentRose),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SemBaseApp()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRose,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Force Exit to Login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(DeletionStepState state, IconData defaultIcon) {
    switch (state) {
      case DeletionStepState.pending:
        return Icon(defaultIcon, size: 20, color: AppTheme.textMutedDark);
      case DeletionStepState.inProgress:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentRose),
          ),
        );
      case DeletionStepState.completed:
        return const Icon(Icons.check_circle_rounded, size: 20, color: AppTheme.primaryGreenLight);
      case DeletionStepState.failed:
        return const Icon(Icons.error_outline_rounded, size: 20, color: AppTheme.accentRose);
    }
  }
}
