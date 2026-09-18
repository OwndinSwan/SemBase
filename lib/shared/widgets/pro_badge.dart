import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard SemBase Pro Feature Badge
class ProBadge extends StatelessWidget {
  final bool isProActive;
  final String? customText;
  final Color? customColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const ProBadge({
    super.key,
    this.isProActive = false,
    this.customText,
    this.customColor,
    this.fontSize = 9.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final text = customText ?? (isProActive ? 'PRO ACTIVE' : 'PRO');
    final color = customColor ?? (isProActive ? AppTheme.primaryGreenLight : AppTheme.accentAmber);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
