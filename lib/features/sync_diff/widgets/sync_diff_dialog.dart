import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_toast.dart';
import '../../cor_parser/services/gemini_cor_parser_service.dart';
import '../models/cor_diff_result.dart';
import '../services/sync_diff_service.dart';

class SyncDiffDialog extends ConsumerStatefulWidget {
  final CorDiffSummary diffSummary;
  final String? rawText;
  final bool isAiParsed;
  final VoidCallback onApplied;

  const SyncDiffDialog({
    super.key,
    required this.diffSummary,
    this.rawText,
    this.isAiParsed = false,
    required this.onApplied,
  });

  @override
  ConsumerState<SyncDiffDialog> createState() => _SyncDiffDialogState();
}

class _SyncDiffDialogState extends ConsumerState<SyncDiffDialog> {
  late CorDiffSummary _currentDiffSummary;
  late bool _isAiParsed;
  bool _archivePrevious = true;
  bool _isApplying = false;
  bool _isReExtracting = false;

  @override
  void initState() {
    super.initState();
    _currentDiffSummary = widget.diffSummary;
    _isAiParsed = widget.isAiParsed;
  }

  Future<void> _reExtractWithGemini() async {
    if (widget.rawText == null || widget.rawText!.isEmpty) return;

    setState(() => _isReExtracting = true);
    try {
      final aiParsed = await GeminiCorParserService.extractWithGemini(widget.rawText!);
      final db = ref.read(databaseProvider);
      final diffService = SyncDiffService(db);
      final newSummary = await diffService.computeDiff(aiParsed);

      if (mounted) {
        setState(() {
          _currentDiffSummary = newSummary;
          _isAiParsed = true;
          _isReExtracting = false;
        });
        AppToast.showSuccess(
          context,
          'Schedule successfully re-extracted with SemBase AI!',
          icon: Icons.auto_awesome_rounded,
        );
      }
    } catch (e) {
      AppLogService.error(
        AppLogService.catSync,
        'SemBase AI In-Dialog Re-extraction error: $e',
      );
      if (mounted) {
        setState(() => _isReExtracting = false);
        final cleanMsg = GeminiCorParserService.sanitizeUserErrorMessage(e);
        AppToast.showError(context, cleanMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _currentDiffSummary;
    final incoming = summary.incomingData;

    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sync_alt_rounded, color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sync Schedule Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                      Text(
                        summary.isNewSemester ? 'New Academic Semester detected' : 'Schedule Updates & Modifications',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMutedDark, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // AI Verified Badge or In-Dialog Fix Banner
            if (_isAiParsed)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Extracted with SemBase AI',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                          Text(
                            'High precision extraction with instructor & room detection.',
                            style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryDark),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AI VERIFIED',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ),
                  ],
                ),
              )
            else if (widget.rawText != null && widget.rawText!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentAmber.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppTheme.accentAmber, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Are these details incorrect?',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Re-parse with SemBase AI (Internet required)',
                            style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isReExtracting ? null : _reExtractWithGemini,
                      icon: _isReExtracting
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.auto_awesome, size: 13, color: Colors.black),
                      label: Text(
                        _isReExtracting ? 'Analyzing...' : 'Fix with AI',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),

            // Metadata Chips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetaCol('Student ID', incoming.studentNo),
                  _buildMetaCol('Section', incoming.section),
                  _buildMetaCol('Total Units', '${incoming.totalUnits}'),
                  _buildMetaCol('Subjects', '${incoming.courses.length}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Diff Status Summary Counts
            Row(
              children: [
                _buildCountChip('Added', summary.added.length, AppTheme.primaryGreen),
                const SizedBox(width: 8),
                _buildCountChip('Modified', summary.modified.length, AppTheme.accentAmber),
                const SizedBox(width: 8),
                _buildCountChip('Dropped', summary.dropped.length, AppTheme.accentRose),
                const SizedBox(width: 8),
                _buildCountChip('Unchanged', summary.unchanged.length, AppTheme.textSecondaryDark),
              ],
            ),
            const SizedBox(height: 12),

            // Diff Items List
            Expanded(
              child: ListView.separated(
                itemCount: summary.diffItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = summary.diffItems[index];
                  return _buildDiffCard(item);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Archive option if new semester
            if (summary.isNewSemester && summary.existingProfile != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentIndigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentIndigo.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _archivePrevious,
                      activeColor: AppTheme.accentIndigo,
                      onChanged: (val) => setState(() => _archivePrevious = val ?? true),
                    ),
                    const Expanded(
                      child: Text(
                        'Auto-archive previous term subjects',
                        style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryDark),
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryDark,
                      side: const BorderSide(color: AppTheme.borderDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isApplying ? null : _applyDiff,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isApplying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Apply & Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMutedDark)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark)),
      ],
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffCard(CourseDiffItem item) {
    Color badgeColor;
    String badgeText;

    switch (item.diffType) {
      case DiffType.added:
        badgeColor = AppTheme.primaryGreen;
        badgeText = 'ADDED';
        break;
      case DiffType.modified:
        badgeColor = AppTheme.accentAmber;
        badgeText = 'MODIFIED';
        break;
      case DiffType.dropped:
        badgeColor = AppTheme.accentRose;
        badgeText = 'DROPPED';
        break;
      case DiffType.unchanged:
        badgeColor = AppTheme.textSecondaryDark;
        badgeText = 'UNCHANGED';
        break;
    }

    final title = item.newCourse?.courseTitle ?? item.existingCourse?.courseTitle ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.courseCode} - $title',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
                if (item.newCourse?.instructorName != null && item.newCourse!.instructorName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.accentCyan),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Instructor: ${item.newCourse!.instructorName}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.accentCyan, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item.changeDetails.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.changeDetails.join(' • '),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyDiff() async {
    setState(() => _isApplying = true);
    final db = ref.read(databaseProvider);
    final service = SyncDiffService(db);

    try {
      await service.applyDiff(
        _currentDiffSummary,
        archivePreviousSemester: _archivePrevious,
      );
      final incoming = _currentDiffSummary.incomingData;
      AppLogService.success(
        AppLogService.catAction,
        'Imported & applied schedule for ${incoming.semester} A.Y. ${incoming.schoolYear}',
        details: 'Student ID: ${incoming.studentNo}, Section: ${incoming.section}, Total Subjects: ${incoming.courses.length}',
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onApplied();
        AppToast.showSuccess(
          context,
          'Academic Schedule & COR successfully updated!',
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (e) {
      AppLogService.error(
        AppLogService.catAction,
        'Failed to apply COR schedule import',
        details: '$e',
      );
      if (mounted) {
        setState(() => _isApplying = false);
        AppToast.showError(context, 'Failed to apply schedule: $e');
      }
    }
  }
}
