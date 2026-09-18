import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Uniform In-App Floating HUD & Toast System
/// Standardizes all in-app HUD notifications to match the sleek Auto Sync floating HUD design
/// and prevents toast stacking by clearing queued SnackBars.
class AppToast {
  /// Cloud Sync HUD - Pure Green (#10B981)
  static void showSync(
    BuildContext context,
    String message, {
    IconData icon = Icons.cloud_done_outlined,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(context, message: message, color: AppTheme.primaryGreen, icon: icon, duration: duration, action: action);
  }

  /// Success / Completion HUD - Deep Emerald (#059669)
  static void showSuccess(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_outline_rounded,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(context, message: message, color: const Color(0xFF059669), icon: icon, duration: duration, action: action);
  }

  /// Campus & Room Proximity Arrival Alert - Vibrant Purple / Violet (#8B5CF6)
  static void showArrival(
    BuildContext context,
    String message, {
    IconData icon = Icons.near_me_rounded,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _show(context, message: message, color: const Color(0xFF8B5CF6), icon: icon, duration: duration, action: action);
  }

  /// Navigation & Route HUD - Sky / Ocean Blue (#0284C7)
  static void showNavigation(
    BuildContext context,
    String message, {
    IconData icon = Icons.directions_walk_rounded,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(context, message: message, color: const Color(0xFF0284C7), icon: icon, duration: duration, action: action);
  }

  /// Academic Deadlines & Schedule Shift HUD - Royal Indigo Blue (#3B82F6)
  static void showDeadline(
    BuildContext context,
    String message, {
    IconData icon = Icons.event_repeat_rounded,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    _show(context, message: message, color: const Color(0xFF3B82F6), icon: icon, duration: duration, action: action);
  }

  /// Mock Location & GPS Simulation HUD - Teal / Cyan (#0D9488)
  static void showMockLocation(
    BuildContext context,
    String message, {
    IconData icon = Icons.gps_fixed_rounded,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(context, message: message, color: const Color(0xFF0D9488), icon: icon, duration: duration, action: action);
  }

  /// General Info / System / Clipboard HUD - Deep Slate (#334155)
  static void showInfo(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(context, message: message, color: const Color(0xFF334155), icon: icon, duration: duration, action: action);
  }

  /// Warning & Uncalibrated Rooms HUD - Warm Amber (#F59E0B)
  static void showWarning(
    BuildContext context,
    String message, {
    IconData icon = Icons.warning_amber_rounded,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(context, message: message, color: AppTheme.accentAmber, icon: icon, duration: duration, action: action);
  }

  /// Error & Destructive HUD - Crimson Rose (#F43F5E)
  static void showError(
    BuildContext context,
    String message, {
    IconData icon = Icons.error_outline_rounded,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(context, message: message, color: AppTheme.accentRose, icon: icon, duration: duration, action: action);
  }

  /// Standard HUD SnackBar builder with 10px rounded corners & floating presentation
  static SnackBar buildHudSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
      action: action,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  /// Shows the HUD via a ScaffoldMessengerState and clears any previous stacked snackbars immediately
  static void showWithMessenger(
    ScaffoldMessengerState? messenger, {
    required String message,
    required Color color,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (messenger == null) return;
    // Clears all existing/stacked snackbars immediately to prevent stacking
    messenger.clearSnackBars();
    messenger.showSnackBar(
      buildHudSnackBar(
        message: message,
        backgroundColor: color,
        icon: icon,
        duration: duration,
        action: action,
      ),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color color,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    showWithMessenger(
      messenger,
      message: message,
      color: color,
      icon: icon,
      duration: duration,
      action: action,
    );
  }
}
