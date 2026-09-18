import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/calendar_export_sheet.dart';
import '../widgets/weekly_grid_view.dart';

class ScheduleViewScreen extends ConsumerWidget {
  final Function(String courseId)? onCourseTap;

  const ScheduleViewScreen({super.key, this.onCourseTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final profileAsync = ref.watch(activeProfileStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Schedule'),
        actions: [
          // Export Button
          IconButton(
            icon: const Icon(Icons.ios_share, color: AppTheme.primaryGreenLight),
            tooltip: 'Export .ICS or Share',
            onPressed: () => _openExportSheet(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.calendar_today_outlined, size: 48, color: AppTheme.textMutedDark),
                  SizedBox(height: 16),
                  Text('No Academic Schedule Loaded', style: TextStyle(fontSize: 16, color: AppTheme.textSecondaryDark)),
                  SizedBox(height: 4),
                  Text('Import your schedule or COR from the Dashboard.', style: TextStyle(fontSize: 12, color: AppTheme.textMutedDark)),
                ],
              ),
            );
          }

          return StreamBuilder<List<ScheduleWithCourse>>(
            stream: db.watchAllActiveSchedules(profile.id),
            builder: (context, snapshot) {
              final allSchedules = snapshot.data ?? [];
              return WeeklyGridView(
                schedules: allSchedules,
                onCourseTap: onCourseTap,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppTheme.accentRose)),
        ),
      ),
    );
  }

  Future<void> _openExportSheet(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final profile = await db.getActiveProfile();
    if (profile == null) return;
    final schedules = await db.getAllActiveSchedules(profile.id);

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => CalendarExportSheet(
          profile: profile,
          schedules: schedules,
        ),
      );
    }
  }
}
