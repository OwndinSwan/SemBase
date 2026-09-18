import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import 'subject_detail_screen.dart';

enum SubjectFilter {
  all,
  activeTasks,
  upcomingDeadlines,
  completed,
}

class SubjectHubListScreen extends ConsumerStatefulWidget {
  const SubjectHubListScreen({super.key});

  @override
  ConsumerState<SubjectHubListScreen> createState() => _SubjectHubListScreenState();
}

class _SubjectHubListScreenState extends ConsumerState<SubjectHubListScreen> {
  final TextEditingController _searchController = TextEditingController();
  SubjectFilter _selectedFilter = SubjectFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final profileAsync = ref.watch(activeProfileStreamProvider);
    final navBarPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Hub'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(
                'No subjects found. Import your schedule or COR from the Dashboard.',
                style: TextStyle(color: AppTheme.textSecondaryDark),
              ),
            );
          }

          return StreamBuilder<List<CourseWithDetails>>(
            stream: db.watchAllCoursesWithDetailsForProfile(profile.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
              }

              final allCourses = snapshot.data ?? [];

              if (allCourses.isEmpty) {
                return const Center(
                  child: Text(
                    'No active subjects for this semester.',
                    style: TextStyle(color: AppTheme.textSecondaryDark),
                  ),
                );
              }

              // Compute counts for filter chips
              final totalCount = allCourses.length;
              final activeTasksCount = allCourses.where((c) => c.tasks.any((t) => !t.isCompleted)).length;
              final deadlinesCount = allCourses.where((c) => c.tasks.any((t) => t.dueDate != null && !t.isCompleted)).length;
              final completedCount = allCourses.where((c) => c.tasks.isNotEmpty && c.tasks.every((t) => t.isCompleted)).length;

              // Filter courses
              final filteredCourses = allCourses.where((c) {
                // 1. Text search filter
                if (_searchQuery.isNotEmpty) {
                  final codeMatch = c.course.courseCode.toLowerCase().contains(_searchQuery);
                  final titleMatch = c.course.courseTitle.toLowerCase().contains(_searchQuery);
                  final profMatch = c.metadata?.profName?.toLowerCase().contains(_searchQuery) ?? false;
                  if (!codeMatch && !titleMatch && !profMatch) return false;
                }

                // 2. Filter chip
                switch (_selectedFilter) {
                  case SubjectFilter.all:
                    return true;
                  case SubjectFilter.activeTasks:
                    return c.tasks.any((t) => !t.isCompleted);
                  case SubjectFilter.upcomingDeadlines:
                    return c.tasks.any((t) => t.dueDate != null && !t.isCompleted);
                  case SubjectFilter.completed:
                    return c.tasks.isNotEmpty && c.tasks.every((t) => t.isCompleted);
                }
              }).toList();

              // Sort upcoming deadlines first if selected
              if (_selectedFilter == SubjectFilter.upcomingDeadlines) {
                filteredCourses.sort((a, b) {
                  final aDue = a.tasks.where((t) => t.dueDate != null && !t.isCompleted).map((t) => t.dueDate!).fold<DateTime?>(null, (min, d) => min == null || d.isBefore(min) ? d : min);
                  final bDue = b.tasks.where((t) => t.dueDate != null && !t.isCompleted).map((t) => t.dueDate!).fold<DateTime?>(null, (min, d) => min == null || d.isBefore(min) ? d : min);
                  if (aDue == null) return 1;
                  if (bDue == null) return -1;
                  return aDue.compareTo(bDue);
                });
              }

              return Column(
                children: [
                  // 1. Search Bar
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryDark),
                      decoration: InputDecoration(
                        hintText: 'Search subjects, course codes, professors...',
                        hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMutedDark),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: AppTheme.textMutedDark),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderDark.withOpacity(0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderDark.withOpacity(0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                      ),
                    ),
                  ),

                  // 2. Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All ($totalCount)',
                          filter: SubjectFilter.all,
                          icon: Icons.grid_view_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Active Tasks ($activeTasksCount)',
                          filter: SubjectFilter.activeTasks,
                          icon: Icons.checklist_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Upcoming Deadlines ($deadlinesCount)',
                          filter: SubjectFilter.upcomingDeadlines,
                          icon: Icons.alarm_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Completed ($completedCount)',
                          filter: SubjectFilter.completed,
                          icon: Icons.task_alt_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 3. Course List
                  Expanded(
                    child: filteredCourses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.search_off_outlined, size: 40, color: AppTheme.textMutedDark),
                                SizedBox(height: 8),
                                Text(
                                  'No subjects match your filter.',
                                  style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 6,
                              bottom: navBarPadding + 80,
                            ),
                            itemCount: filteredCourses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final details = filteredCourses[index];
                              return _buildCourseCard(context, details);
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required SubjectFilter filter,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderDark.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.textSecondaryDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseWithDetails details) {
    final course = details.course;
    final totalUnits = course.lecUnits + course.labUnits;
    final tasks = details.tasks;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final progress = tasks.isNotEmpty ? (completedTasks / tasks.length) : 0.0;

    // Check nearest active deadline
    final activeDeadlines = tasks
        .where((t) => t.dueDate != null && !t.isCompleted)
        .map((t) => t.dueDate!)
        .toList();
    activeDeadlines.sort();
    final nearestDeadline = activeDeadlines.isNotEmpty ? activeDeadlines.first : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubjectDetailScreen(courseId: course.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.courseCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$totalUnits Units (Lec: ${course.lecUnits}, Lab: ${course.labUnits})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreenLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              course.courseTitle,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryDark),
            ),

            if (nearestDeadline != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm, size: 12, color: AppTheme.accentAmber),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${TimeFormatter.formatDate(nearestDeadline)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Task progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppTheme.bgDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreenLight),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completedTasks/${tasks.length} tasks',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMutedDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
