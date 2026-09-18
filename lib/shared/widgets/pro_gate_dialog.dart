import 'package:flutter/material.dart';
import '../../features/settings/screens/sub_screens/subscription_plans_screen.dart';
import '../theme/app_theme.dart';

class ProGateDialog extends StatelessWidget {
  final String featureName;
  final String featureDescription;
  final IconData featureIcon;

  const ProGateDialog({
    super.key,
    required this.featureName,
    required this.featureDescription,
    this.featureIcon = Icons.diamond_rounded,
  });

  static Future<void> show(
    BuildContext context, {
    required String featureName,
    required String featureDescription,
    IconData featureIcon = Icons.diamond_rounded,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ProGateDialog(
        featureName: featureName,
        featureDescription: featureDescription,
        featureIcon: featureIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.bgDarkElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accentAmber.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentAmber.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge & Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentAmber.withOpacity(0.4)),
              ),
              child: Icon(featureIcon, color: AppTheme.accentAmber, size: 36),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentAmber.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 13, color: AppTheme.accentAmber),
                  SizedBox(width: 5),
                  Text(
                    'SEMBASE PRO FEATURE',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppTheme.accentAmber, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Feature Name
            Text(
              featureName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
            ),
            const SizedBox(height: 8),

            // Feature Description
            Text(
              featureDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryDark, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Free Guarantee Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryGreenLight, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All basic schedule viewing, task tracking, and local storage remain 100% free forever.',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.primaryGreenLight, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                  );
                },
                icon: const Icon(Icons.stars_rounded, size: 18),
                label: const Text('View Plans & Subscribe', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
