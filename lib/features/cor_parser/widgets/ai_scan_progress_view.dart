import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// Highly-polished, futuristic AI Neural Scanner animation widget
/// shown during SemBase AI schedule extraction.
class AiScanProgressView extends StatefulWidget {
  final VoidCallback? onCancel;

  const AiScanProgressView({
    super.key,
    this.onCancel,
  });

  @override
  State<AiScanProgressView> createState() => _AiScanProgressViewState();
}

class _AiScanProgressViewState extends State<AiScanProgressView>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  static const _stages = [
    (title: 'Digitizing Schedule Document', subtitle: 'Extracting text layout & timetable tokens...', progress: 0.22),
    (title: 'Neural Entity Extraction', subtitle: 'Detecting course titles, units & instructors...', progress: 0.58),
    (title: 'Time & Grid Normalization', subtitle: 'Parsing day tokens, start/end times & room codes...', progress: 0.85),
    (title: 'Assembling Schedule Architecture', subtitle: 'Synthesizing courses into SemBase timetable...', progress: 0.98),
  ];

  int _currentStageIndex = 0;

  @override
  void initState() {
    super.initState();

    // Laser beam vertical sweep animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Radar pulse wave animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Simulated smooth progress timer
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    )..forward();

    _progressController.addListener(() {
      final val = _progressController.value;
      if (val < 0.28) {
        if (_currentStageIndex != 0) setState(() => _currentStageIndex = 0);
      } else if (val < 0.62) {
        if (_currentStageIndex != 1) setState(() => _currentStageIndex = 1);
      } else if (val < 0.88) {
        if (_currentStageIndex != 2) setState(() => _currentStageIndex = 2);
      } else {
        if (_currentStageIndex != 3) setState(() => _currentStageIndex = 3);
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_currentStageIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentAmber.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentAmber.withOpacity(0.2),
                      AppTheme.accentCyan.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentAmber.withOpacity(0.6), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.accentAmber, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'SEMBASE AI NEURAL SCANNER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppTheme.accentAmber,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  final pct = (_progressController.value * 100).toInt();
                  return Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentAmber,
                      letterSpacing: 0.5,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Central Holographic Scanner Box
          SizedBox(
            height: 130,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Background Grid Mesh
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: CustomPaint(
                      painter: _GridWireframePainter(),
                      size: Size.infinite,
                    ),
                  ),

                  // Radar Pulse Circles
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _RadarPulsePainter(_pulseController.value),
                        );
                      },
                    ),
                  ),

                  // Center AI Neural Node
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentAmber.withOpacity(0.9),
                            AppTheme.accentAmber.withOpacity(0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentAmber.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.psychology_rounded,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  // Animated Vertical Laser Scan Beam
                  AnimatedBuilder(
                    animation: _scanController,
                    builder: (context, _) {
                      return Positioned(
                        top: _scanController.value * 118,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.accentCyan.withOpacity(0.7),
                                AppTheme.accentAmber,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentCyan.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic Stage Indicator Text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Column(
              key: ValueKey<int>(_currentStageIndex),
              children: [
                Text(
                  stage.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryDark,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  stage.subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Glowing Linear Progress Track
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: AppTheme.bgDark,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentAmber),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Step Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_stages.length, (idx) {
              final isPassed = idx <= _currentStageIndex;
              final isCurrent = idx == _currentStageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isCurrent ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isPassed ? AppTheme.accentAmber : AppTheme.borderDark,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.accentAmber.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the futuristic wireframe grid background
class _GridWireframePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderDark.withOpacity(0.4)
      ..strokeWidth = 0.7;

    const step = 16.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the radiating radar waves
class _RadarPulsePainter extends CustomPainter {
  final double progress;

  _RadarPulsePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.7;

    for (int i = 0; i < 3; i++) {
      final p = (progress + (i / 3.0)) % 1.0;
      final radius = p * maxRadius;
      final opacity = (1.0 - p) * 0.45;

      final paint = Paint()
        ..color = AppTheme.accentCyan.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
