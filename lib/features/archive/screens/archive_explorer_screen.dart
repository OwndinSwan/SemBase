import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_toast.dart';
import '../../../shared/widgets/animated_confirm_dialog.dart';
import '../../../shared/widgets/pro_badge.dart';
import '../../../shared/widgets/pro_gate_dialog.dart';
import '../../subject_hub/screens/subject_detail_screen.dart';

/// Screen allowing students to browse, inspect, and restore archived semesters & CORs
class ArchiveExplorerScreen extends ConsumerWidget {
  const ArchiveExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final activeProfileAsync = ref.watch(activeProfileStreamProvider);
    final activeProfileId = activeProfileAsync.value?.id;
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Archive & History'),
      ),
      body: StreamBuilder<List<AcademicProfile>>(
        stream: db.watchAllProfiles(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }

          final rawProfiles = snapshot.data ?? [];
          if (rawProfiles.isEmpty) {
            return const Center(
              child: Text(
                'No academic terms recorded yet.',
                style: TextStyle(color: AppTheme.textSecondaryDark),
              ),
            );
          }

          // Deduplicate profiles by schoolYear & semester, prioritizing active profile
          final Map<String, AcademicProfile> uniqueMap = {};
          for (final p in rawProfiles) {
            final key = '${p.schoolYear.trim().toUpperCase()}_${p.semester.trim().toUpperCase()}';
            if (!uniqueMap.containsKey(key) || p.id == activeProfileId) {
              uniqueMap[key] = p;
            }
          }
          final profiles = uniqueMap.values.toList();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final isActive = profile.id == activeProfileId;
              final isLockedPastTerm = !isActive && index > 1 && !isPro;
              return _buildProfileArchiveCard(context, profile, isActive, db, isPro, isLockedPastTerm);
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileArchiveCard(
    BuildContext context,
    AcademicProfile profile,
    bool isActive,
    AppDatabase db,
    bool isPro,
    bool isLockedPastTerm,
  ) {
    return StreamBuilder<List<Course>>(
      stream: db.watchCoursesForProfile(profile.id, includeArchived: true),
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];
        final totalUnits = courses.fold<double>(0.0, (sum, c) => sum + c.lecUnits + c.labUnits);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryGreen.withOpacity(0.5)
                  : (isLockedPastTerm ? AppTheme.accentAmber.withOpacity(0.4) : AppTheme.borderDark.withOpacity(0.4)),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.schoolYear} - ${profile.semester}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Student No: ${profile.studentNo} • Sec: ${profile.section}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ACTIVE TERM',
                        style: TextStyle(
                          color: AppTheme.primaryGreenLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isLockedPastTerm)
                    ProBadge(isProActive: isPro)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.borderDark.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PAST TERM',
                        style: TextStyle(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatBadge(Icons.menu_book_outlined, '${courses.length} Subjects'),
                  const SizedBox(width: 8),
                  _buildStatBadge(Icons.fitness_center_outlined, '${totalUnits.toInt()} Total Units'),
                ],
              ),
              const Divider(color: AppTheme.borderDark, height: 24),
              if (courses.isEmpty)
                const Text('No courses recorded under this term.', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12))
              else
                ...courses.map((c) => InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SubjectDetailScreen(courseId: c.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right, color: AppTheme.primaryGreenLight, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${c.courseCode} - ${c.courseTitle}',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(c.lecUnits + c.labUnits).toInt()}u',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )),
              if (!isActive) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isLockedPastTerm && !isPro ? AppTheme.accentAmber : AppTheme.primaryGreen),
                      foregroundColor: isLockedPastTerm && !isPro ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restore_page_outlined,
                          size: 16,
                          color: isLockedPastTerm && !isPro ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isLockedPastTerm && !isPro ? 'Restore Historical Archive' : 'Set as Active Semester',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLockedPastTerm && !isPro) ...[
                          const SizedBox(width: 8),
                          const ProBadge(),
                        ],
                      ],
                    ),
                    onPressed: () async {
                      if (isLockedPastTerm && !isPro) {
                        ProGateDialog.show(
                          context,
                          featureName: 'Unlimited Multi-Semester Archiving',
                          featureDescription:
                              'Restoring and managing multiple historical semesters throughout your 4-year degree requires SemBase Pro. Free users have access to their active term + 1 past semester.',
                          featureIcon: Icons.history_edu_rounded,
                        );
                        return;
                      }

                      final confirmed = await AnimatedConfirmDialog.show(
                        context,
                        title: 'Switch Active Term',
                        message: 'Switch to "${profile.schoolYear} - ${profile.semester}" as your active dashboard semester?',
                        confirmLabel: 'Switch Term',
                        confirmColor: AppTheme.primaryGreen,
                        icon: Icons.restore_page_outlined,
                      );
                      if (confirmed) {
                        await db.restoreTerm(profile.id);
                        await db.setActiveProfile(profile.id);
                        if (context.mounted) {
                          AppToast.showSuccess(context, '${profile.schoolYear} set as active semester.');
                        }
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondaryDark),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark)),
        ],
      ),
    );
  }
}
