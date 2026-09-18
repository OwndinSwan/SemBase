import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SessionTypeBadge extends StatelessWidget {
  final String sessionType;

  const SessionTypeBadge({super.key, required this.sessionType});

  @override
  Widget build(BuildContext context) {
    final isLab = sessionType.toLowerCase().contains('lab');
    final color = isLab ? AppTheme.accentCyan : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        isLab ? 'LAB' : 'LEC',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class TbaBadge extends StatelessWidget {
  const TbaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.35), width: 1),
      ),
      child: const Text(
        'TBA',
        style: TextStyle(
          color: AppTheme.accentAmber,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardDark.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: AppTheme.borderDark.withOpacity(0.4), width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }
    return content;
  }
}
