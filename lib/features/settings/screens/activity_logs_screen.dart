import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_toast.dart';
import '../../../shared/widgets/animated_confirm_dialog.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'ALL';
  String _selectedLevel = 'ALL';
  List<AppLogEntry> _logs = [];
  bool _isLoading = true;
  int _totalLogCount = 0;

  final List<String> _categories = [
    'ALL',
    AppLogService.catAlarm,
    AppLogService.catSync,
    AppLogService.catAuth,
    AppLogService.catPermission,
    AppLogService.catAction,
    AppLogService.catApp,
  ];

  final List<String> _levels = [
    'ALL',
    AppLogService.lvlSuccess,
    AppLogService.lvlInfo,
    AppLogService.lvlWarning,
    AppLogService.lvlError,
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final count = await AppLogService.getLogCount();
    final logs = await AppLogService.getLogs(
      category: _selectedCategory,
      level: _selectedLevel,
      searchQuery: _searchController.text,
      limit: 1000,
    );

    if (mounted) {
      setState(() {
        _logs = logs;
        _totalLogCount = count;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleExport() async {
    try {
      final path = await AppLogService.exportLogsAsText();
      if (mounted) {
        AppToast.showSuccess(
          context,
          'Exported logs to .txt file',
          icon: Icons.file_download_done_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to export logs: $e');
      }
    }
  }

  Future<void> _handleClearLogs() async {
    final confirmed = await AnimatedConfirmDialog.show(
      context,
      title: 'Clear All Activity Logs?',
      message: 'This will permanently remove all local activity and diagnostic records stored on this device.',
      confirmLabel: 'Clear Logs',
      confirmColor: AppTheme.accentRose,
      icon: Icons.delete_sweep_outlined,
    );

    if (confirmed) {
      await AppLogService.clearAllLogs();
      await _loadLogs();
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'ALARM':
        return AppTheme.accentAmber;
      case 'SYNC':
        return AppTheme.accentCyan;
      case 'AUTH':
        return const Color(0xFFA855F7); // Purple
      case 'PERMISSION':
        return const Color(0xFFEC4899); // Pink
      case 'ACTION':
        return AppTheme.primaryGreen;
      case 'APP':
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'SUCCESS':
        return AppTheme.primaryGreen;
      case 'INFO':
        return AppTheme.accentCyan;
      case 'WARNING':
        return AppTheme.accentAmber;
      case 'ERROR':
        return AppTheme.accentRose;
      default:
        return AppTheme.textSecondaryDark;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'SUCCESS':
        return Icons.check_circle_outline;
      case 'INFO':
        return Icons.info_outline;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'ERROR':
        return Icons.error_outline;
      default:
        return Icons.circle;
    }
  }

  void _showLogDetailsBottomSheet(AppLogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp);
        final catColor = _getCategoryColor(log.category);
        final lvlColor = _getLevelColor(log.level);
        final screenHeight = MediaQuery.of(ctx).size.height;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x30FFFFFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Top Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: catColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          log.category,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: catColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: lvlColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: lvlColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getLevelIcon(log.level), size: 12, color: lvlColor),
                            const SizedBox(width: 4),
                            Text(
                              log.level,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: lvlColor),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondaryDark),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0x15FFFFFF), height: 1),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Message',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          log.message,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryDark),
                        ),
                        if (log.details != null && log.details!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Technical Details / Payload',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryDark),
                              ),
                              Text(
                                '${log.details!.length} chars',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMutedDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0x15FFFFFF)),
                            ),
                            child: SelectableText(
                              log.details!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: AppTheme.accentCyan,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom Pinned Action Bar
                const Divider(color: Color(0x15FFFFFF), height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: log.formatForExport()));
                        Navigator.pop(ctx);
                        AppToast.showSuccess(
                          context,
                          'Log entry copied to clipboard',
                          icon: Icons.copy_rounded,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Activity & Diagnostic Logs'),
        actions: [
          IconButton(
            tooltip: 'Export Logs (.txt)',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _handleExport,
          ),
          IconButton(
            tooltip: 'Clear All Logs',
            icon: const Icon(Icons.delete_outline, color: AppTheme.accentRose),
            onPressed: _handleClearLogs,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Info & Retention Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x15FFFFFF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: AppTheme.accentCyan, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$_totalLogCount Total Entries',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '30D LOCAL RETENTION',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreenLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Stored 100% on-device. Older logs automatically purged.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadLogs(),
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryDark),
              decoration: InputDecoration(
                hintText: 'Search logs (e.g. CS101, Sync, exactAlarm)...',
                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondaryDark),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _loadLogs();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.cardDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0x15FFFFFF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0x15FFFFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
          ),

          // 3. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                final color = cat == 'ALL' ? AppTheme.accentCyan : _getCategoryColor(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                      _loadLogs();
                    },
                    selectedColor: color.withOpacity(0.25),
                    backgroundColor: AppTheme.cardDark,
                    checkmarkColor: color,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : AppTheme.textSecondaryDark,
                    ),
                    side: BorderSide(
                      color: isSelected ? color.withOpacity(0.6) : const Color(0x15FFFFFF),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }).toList(),
            ),
          ),

          // 4. Log List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notes_rounded, size: 48, color: AppTheme.textSecondaryDark.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text(
                              'No activity logs match your filter',
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryDark),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        color: AppTheme.primaryGreen,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            final catColor = _getCategoryColor(log.category);
                            final lvlColor = _getLevelColor(log.level);
                            final timeStr = DateFormat('MM-dd HH:mm:ss').format(log.timestamp);

                            return InkWell(
                              onTap: () => _showLogDetailsBottomSheet(log),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: log.level == 'ERROR'
                                        ? AppTheme.accentRose.withOpacity(0.4)
                                        : const Color(0x10FFFFFF),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Category Tag
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: catColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            log.category,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: catColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Level Tag
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: lvlColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_getLevelIcon(log.level), size: 10, color: lvlColor),
                                              const SizedBox(width: 3),
                                              Text(
                                                log.level,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: lvlColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textSecondaryDark,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      log.message,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimaryDark,
                                      ),
                                    ),
                                    if (log.details != null && log.details!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        log.details!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          color: AppTheme.textSecondaryDark.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
