import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/backup/local_backup_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/app_toast.dart';

class PersonalBackupScreen extends ConsumerStatefulWidget {
  const PersonalBackupScreen({super.key});

  @override
  ConsumerState<PersonalBackupScreen> createState() => _PersonalBackupScreenState();
}

class _PersonalBackupScreenState extends ConsumerState<PersonalBackupScreen> {
  int _courseCount = 0;
  int _taskCount = 0;
  int _scheduleCount = 0;
  int _pinCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = ref.read(databaseProvider);
    final courses = await db.select(db.courses).get();
    final tasks = await db.select(db.courseTasks).get();
    final schedules = await db.select(db.courseSchedules).get();
    final pins = await db.select(db.campusPins).get();

    if (mounted) {
      setState(() {
        _courseCount = courses.length;
        _taskCount = tasks.length;
        _scheduleCount = schedules.length;
        _pinCount = pins.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Data Backup'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. Overview Card
                _buildOverviewCard(),
                const SizedBox(height: 20),

                // 2. Export Section
                _buildSectionHeader('Create Backup Archive', Icons.file_download_rounded),
                const SizedBox(height: 8),
                _buildExportCard(db),
                const SizedBox(height: 20),

                // 3. Import Section
                _buildSectionHeader('Restore Backup Archive', Icons.file_upload_rounded),
                const SizedBox(height: 8),
                _buildImportCard(db),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondaryDark,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_zip_rounded, color: AppTheme.accentCyan, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Vault Storage',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '100% offline portable JSON backups',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderDark, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatPill('Subjects', '$_courseCount', AppTheme.accentCyan),
              _buildStatPill('Schedules', '$_scheduleCount', AppTheme.accentAmber),
              _buildStatPill('Checklist', '$_taskCount', AppTheme.primaryGreenLight),
              _buildStatPill('Pins', '$_pinCount', const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(AppDatabase db) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export all your registered subjects, timetable slots, syllabus tasks, faculty metadata, and calibrated campus room pins into a portable .json backup file.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleExportBackup(db),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export & Share Backup (.json)', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard(AppDatabase db) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Restore a previously exported backup file. You can choose to cleanly replace your database or smartly merge new subjects without losing recent task edits.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleImportBackup(db),
              icon: const Icon(Icons.file_upload_outlined, size: 18, color: AppTheme.accentCyan),
              label: const Text('Select Backup File to Restore', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.accentCyan, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
        ),
      ],
    );
  }

  Future<void> _handleExportBackup(AppDatabase db) async {
    try {
      AppToast.showInfo(
        context,
        'Preparing personal backup archive...',
        icon: Icons.archive_outlined,
        duration: const Duration(seconds: 1),
      );
      await LocalBackupService.shareBackupFile(db);
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to export backup: $e');
      }
    }
  }

  Future<void> _handleImportBackup(AppDatabase db) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        return;
      }

      final file = File(result.files.first.path!);
      final content = await file.readAsString();

      final summary = LocalBackupService.parseAndValidateBackup(content);
      final decodedJson = jsonDecode(content) as Map<String, dynamic>;

      if (!mounted) return;

      bool overwriteMode = false;

      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, a1, a2) => const SizedBox(),
        transitionBuilder: (dialogCtx, anim, secAnim, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
          return ScaleTransition(
            scale: curved,
            child: FadeTransition(
              opacity: anim,
              child: StatefulBuilder(
                builder: (modalCtx, setModalState) {
                  return Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 380,
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.accentCyan.withOpacity(0.35), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentCyan.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.restore_page_rounded, color: AppTheme.accentCyan, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Import Personal Backup',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryDark,
                                          ),
                                        ),
                                        Text(
                                          'Verify backup contents and restore mode',
                                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryDark, size: 20),
                                    onPressed: () => Navigator.of(dialogCtx).pop(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgDarkElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.borderDark),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Academic Profile:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark)),
                                        Text(
                                          '${summary.section ?? "N/A"} (${summary.studentNumber ?? "N/A"})',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Term / School Year:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark)),
                                        Text(
                                          '${summary.semester ?? "N/A"} (${summary.schoolYear ?? "N/A"})',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreenLight),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(color: AppTheme.borderDark, height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatPill('Courses', summary.courseCount.toString(), AppTheme.accentCyan),
                                        _buildStatPill('Schedules', summary.scheduleCount.toString(), AppTheme.accentAmber),
                                        _buildStatPill('Tasks', summary.taskCount.toString(), AppTheme.primaryGreenLight),
                                        _buildStatPill('Pins', summary.pinCount.toString(), const Color(0xFF8B5CF6)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Restore Strategy',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => setModalState(() => overwriteMode = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: !overwriteMode ? AppTheme.accentCyan.withOpacity(0.18) : AppTheme.bgDarkElevated,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: !overwriteMode ? AppTheme.accentCyan : AppTheme.borderDark,
                                            width: !overwriteMode ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Smart Merge',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: !overwriteMode ? AppTheme.accentCyan : AppTheme.textPrimaryDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text('Keeps recent edits', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryDark)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => setModalState(() => overwriteMode = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: overwriteMode ? AppTheme.accentRose.withOpacity(0.18) : AppTheme.bgDarkElevated,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: overwriteMode ? AppTheme.accentRose : AppTheme.borderDark,
                                            width: overwriteMode ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Clean Restore',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: overwriteMode ? AppTheme.accentRose : AppTheme.textPrimaryDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text('Replaces local vault', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryDark)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.of(dialogCtx).pop(),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textSecondaryDark,
                                        side: const BorderSide(color: AppTheme.borderDark),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        Navigator.of(dialogCtx).pop();

                                        final res = await LocalBackupService.restoreBackupData(
                                          db,
                                          decodedJson,
                                          overwrite: overwriteMode,
                                        );

                                        if (mounted) {
                                          if (res.success) {
                                            await _loadStats();
                                            AppToast.showSuccess(
                                              context,
                                              '${res.message} (${res.coursesRestored} courses, ${res.tasksRestored} tasks)',
                                              icon: Icons.unarchive_outlined,
                                            );
                                          } else {
                                            AppToast.showError(context, 'Import error: ${res.message}');
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: overwriteMode ? AppTheme.accentRose : AppTheme.accentCyan,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: Text(
                                        overwriteMode ? 'Restore & Replace' : 'Confirm Import',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Invalid backup file: $e');
      }
    }
  }
}
