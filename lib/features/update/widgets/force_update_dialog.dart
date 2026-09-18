import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/app_update_service.dart';
import '../../../shared/theme/app_theme.dart';

class ForceUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const ForceUpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) async {
    await showDialog(
      context: context,
      barrierDismissible: !updateInfo.isMandatory,
      builder: (_) => ForceUpdateDialog(updateInfo: updateInfo),
    );
  }

  Future<void> _launchDownloadUrl() async {
    final uri = Uri.parse(updateInfo.downloadUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      debugPrint('Could not launch update URL with externalApplication: $e');
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      } catch (err) {
        debugPrint('Fallback launch failed: $err');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !updateInfo.isMandatory,
      child: AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Rocket Icon Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(Icons.rocket_launch_rounded, size: 40, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'New Version Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),

            // Version Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Text(
                'v${updateInfo.currentVersion} ➔ v${updateInfo.latestVersion}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
              ),
            ),
            const SizedBox(height: 16),

            // Release Notes Box
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    updateInfo.releaseNotes,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Update Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _launchDownloadUrl,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download & Install Update', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),

            if (!updateInfo.isMandatory) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Remind Me Later', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
