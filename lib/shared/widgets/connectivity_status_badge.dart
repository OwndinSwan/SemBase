import 'package:flutter/material.dart';
import '../../core/sync/sync_outbox_worker.dart';
import '../theme/app_theme.dart';

/// Compact real-time badge indicating Online / Offline / Syncing cloud status
class ConnectivityStatusBadge extends StatelessWidget {
  const ConnectivityStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SyncOutboxWorker.isSyncingNotifier,
      builder: (context, isSyncing, _) {
        if (isSyncing) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentCyan.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentCyan),
                ),
                SizedBox(width: 5),
                Text(
                  'Syncing...',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: SyncOutboxWorker.isOnlineNotifier,
          builder: (context, isOnline, _) {
            final color = isOnline ? AppTheme.primaryGreenLight : AppTheme.accentAmber;
            final bgColor = isOnline
                ? AppTheme.primaryGreen.withOpacity(0.15)
                : AppTheme.accentAmber.withOpacity(0.15);
            final label = isOnline ? 'Online' : 'Offline';
            final icon = isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
