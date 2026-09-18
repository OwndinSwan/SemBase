import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_theme.dart';

class WeeklyGridView extends StatefulWidget {
  final List<ScheduleWithCourse> schedules;
  final Function(String courseId)? onCourseTap;

  const WeeklyGridView({
    super.key,
    required this.schedules,
    this.onCourseTap,
  });

  @override
  State<WeeklyGridView> createState() => _WeeklyGridViewState();
}

class _WeeklyGridViewState extends State<WeeklyGridView> with SingleTickerProviderStateMixin {
  static const List<String> days = ['M', 'T', 'W', 'TH', 'F', 'S', 'SUN'];
  static const int gridStartHour = 7; // 07:00 AM
  static const int gridEndHour = 21; // 09:00 PM
  static const double hourRowHeight = 54.0;
  static const double dayColumnWidth = 86.0;
  static const double timeColumnWidth = 52.0;

  late final TransformationController _transformationController;
  Animation<Matrix4>? _animationReset;
  late final AnimationController _animationController;
  bool _isZoomedOut = true;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _transformationController.addListener(_onTransformationChanged);
    _resetHideControlsTimer();
  }

  void _onTransformationChanged() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final isOut = currentScale < 0.85;
    if (isOut != _isZoomedOut) {
      setState(() => _isZoomedOut = isOut);
    }
  }

  void _wakeControls() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _resetHideControlsTimer();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    _animationReset = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _animationController.reset();
    _animationReset?.addListener(() {
      _transformationController.value = _animationReset!.value;
    });
    _animationController.forward();
  }

  void _zoomToFit(double screenWidth) {
    _wakeControls();
    const totalGridWidth = timeColumnWidth + (dayColumnWidth + 6) * 7 + 24;
    final fitScale = (screenWidth / totalGridWidth).clamp(0.42, 0.95);

    final target = Matrix4.identity()..scale(fitScale, fitScale);
    _animateToMatrix(target);
  }

  void _zoomToFocus() {
    _wakeControls();
    final target = Matrix4.identity()..scale(1.0, 1.0);
    _animateToMatrix(target);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_view_week_outlined, size: 48, color: AppTheme.textMutedDark),
            SizedBox(height: 16),
            Text(
              'No scheduled classes found.',
              style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final totalHeight = (gridEndHour - gridStartHour) * hourRowHeight;
    final navBarPadding = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return Listener(
          onPointerDown: (_) => _wakeControls(),
          onPointerMove: (_) => _wakeControls(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // Interactive Pinch & Pan Timetable Grid
              InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                minScale: 0.35,
                maxScale: 2.5,
                onInteractionStart: (_) => _wakeControls(),
                onInteractionUpdate: (_) => _wakeControls(),
                onInteractionEnd: (_) => _resetHideControlsTimer(),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 12,
                    left: 12,
                    right: 12,
                    bottom: navBarPadding + 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row for Days
                      Row(
                        children: [
                          const SizedBox(width: timeColumnWidth), // Time column offset
                          ...days.map((day) => Container(
                                width: dayColumnWidth,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
                                ),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                child: Column(
                                  children: [
                                    Text(
                                      TimeFormatter.getFullDayName(day),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primaryGreenLight,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      day,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textMutedDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Grid Body
                      SizedBox(
                        height: totalHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time Labels Column
                            SizedBox(
                              width: timeColumnWidth,
                              height: totalHeight,
                              child: Stack(
                                children: [
                                  for (int h = gridStartHour; h <= gridEndHour; h++)
                                    Positioned(
                                      top: (h - gridStartHour) * hourRowHeight - 6,
                                      left: 0,
                                      right: 6,
                                      child: Text(
                                        TimeFormatter.formatMinutesTo12Hour(h * 60),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          color: AppTheme.textMutedDark,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Day Columns
                            ...days.map((day) {
                              final daySchedules = widget.schedules
                                  .where((s) => s.schedule.dayToken.toUpperCase() == day)
                                  .toList()
                                ..sort((a, b) => a.schedule.startMinutes.compareTo(b.schedule.startMinutes));

                              final positionedBlocks = _calculateOverlapLayout(daySchedules);

                              return Container(
                                width: dayColumnWidth,
                                height: totalHeight,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgDark.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.borderDark.withOpacity(0.2)),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    // Hour guidelines
                                    for (int h = gridStartHour; h < gridEndHour; h++)
                                      Positioned(
                                        top: (h - gridStartHour) * hourRowHeight,
                                        left: 0,
                                        right: 0,
                                        child: Divider(
                                          color: AppTheme.borderDark.withOpacity(0.25),
                                          height: 1,
                                        ),
                                      ),

                                    // Schedule Block Tiles
                                    ...positionedBlocks.map((block) {
                                      final item = block.item;
                                      final startMin = item.schedule.startMinutes;
                                      final endMin = item.schedule.endMinutes;

                                      final topOffset = ((startMin - (gridStartHour * 60)) / 60.0) * hourRowHeight;
                                      final blockHeight = ((endMin - startMin) / 60.0) * hourRowHeight;

                                      final isLab = item.schedule.sessionType.toLowerCase().contains('lab');
                                      final blockColor = isLab ? AppTheme.accentCyan : AppTheme.primaryGreen;

                                      final availableWidth = dayColumnWidth - 4;
                                      final tileWidth = availableWidth / block.totalColumns;
                                      final tileLeft = 2 + (block.columnIndex * tileWidth);

                                      return Positioned(
                                        top: topOffset.clamp(0.0, totalHeight - 24),
                                        left: tileLeft,
                                        width: tileWidth - 2,
                                        height: blockHeight > 28 ? blockHeight - 2 : 28,
                                        child: GestureDetector(
                                          onTap: () {
                                            _wakeControls();
                                            widget.onCourseTap?.call(item.course.id);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: blockColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: blockColor, width: 1.1),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: blockColor.withOpacity(0.12),
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1.5),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Course Code & Session Type Tag
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item.course.courseCode,
                                                        style: const TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w900,
                                                          color: Colors.white,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                                                      decoration: BoxDecoration(
                                                        color: blockColor.withOpacity(0.3),
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                      child: Text(
                                                        isLab ? 'LAB' : 'LEC',
                                                        style: TextStyle(
                                                          fontSize: 6.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: blockColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                // Subject Name (Course Title)
                                                if (item.course.courseTitle.isNotEmpty && blockHeight >= 34) ...[
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    item.course.courseTitle,
                                                    style: TextStyle(
                                                      fontSize: 7.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white.withOpacity(0.9),
                                                      height: 1.05,
                                                    ),
                                                    maxLines: blockHeight >= 60 ? 2 : 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],

                                                if (blockHeight >= 46) ...[
                                                  const SizedBox(height: 1),
                                                  // Room & Time
                                                  Text(
                                                    item.schedule.roomCode.isNotEmpty ? '📍 ${item.schedule.roomCode}' : '📍 TBA',
                                                    style: const TextStyle(
                                                      fontSize: 7,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.textSecondaryDark,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],

                                                if (blockHeight >= 64) ...[
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    '⏰ ${TimeFormatter.formatMinutesTo12Hour(startMin)} - ${TimeFormatter.formatMinutesTo12Hour(endMin)}',
                                                    style: const TextStyle(
                                                      fontSize: 6.5,
                                                      color: AppTheme.textMutedDark,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Quick Zoom Controller Pill with Auto Fade-In & Fade-Out
              Positioned(
                top: 12,
                right: 14,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderDark.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Zoom Out / Fit All Button
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _zoomToFit(screenWidth),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isZoomedOut ? AppTheme.primaryGreen.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_out_map_rounded,
                                    size: 14,
                                    color: _isZoomedOut ? AppTheme.primaryGreenLight : AppTheme.textSecondaryDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Fit Week',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isZoomedOut ? AppTheme.primaryGreenLight : AppTheme.textSecondaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),

                          // 100% Detail Button
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _zoomToFocus,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_isZoomedOut ? AppTheme.accentCyan.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.center_focus_strong_rounded,
                                    size: 14,
                                    color: !_isZoomedOut ? AppTheme.accentCyan : AppTheme.textSecondaryDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '100%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: !_isZoomedOut ? AppTheme.accentCyan : AppTheme.textSecondaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Groups overlapping items on the same day so they cleanly share column width side-by-side
  List<_PositionedScheduleBlock> _calculateOverlapLayout(List<ScheduleWithCourse> items) {
    if (items.isEmpty) return [];

    final List<_PositionedScheduleBlock> blocks = [];

    // Group clusters of overlapping schedules
    List<List<ScheduleWithCourse>> clusters = [];
    List<ScheduleWithCourse> currentCluster = [];
    int currentClusterEnd = -1;

    for (final item in items) {
      if (currentCluster.isEmpty) {
        currentCluster.add(item);
        currentClusterEnd = item.schedule.endMinutes;
      } else {
        if (item.schedule.startMinutes < currentClusterEnd) {
          // Overlaps with current cluster
          currentCluster.add(item);
          if (item.schedule.endMinutes > currentClusterEnd) {
            currentClusterEnd = item.schedule.endMinutes;
          }
        } else {
          // New cluster
          clusters.add(List.from(currentCluster));
          currentCluster = [item];
          currentClusterEnd = item.schedule.endMinutes;
        }
      }
    }
    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    // Assign sub-column index within each cluster
    for (final cluster in clusters) {
      final totalCols = cluster.length;
      for (int i = 0; i < cluster.length; i++) {
        blocks.add(_PositionedScheduleBlock(
          item: cluster[i],
          columnIndex: i,
          totalColumns: totalCols,
        ));
      }
    }

    return blocks;
  }
}

class _PositionedScheduleBlock {
  final ScheduleWithCourse item;
  final int columnIndex;
  final int totalColumns;

  _PositionedScheduleBlock({
    required this.item,
    required this.columnIndex,
    required this.totalColumns,
  });
}
