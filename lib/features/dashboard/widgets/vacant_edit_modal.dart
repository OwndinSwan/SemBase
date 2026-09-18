import 'package:flutter/material.dart';
import '../../../core/services/vacant_period_service.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/timeline_item.dart';

class VacantEditModal extends StatefulWidget {
  final TimelineItem item;
  final String dayToken;

  const VacantEditModal({
    super.key,
    required this.item,
    required this.dayToken,
  });

  static Future<void> show(BuildContext context, TimelineItem item, String dayToken) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VacantEditModal(item: item, dayToken: dayToken),
    );
  }

  @override
  State<VacantEditModal> createState() => _VacantEditModalState();
}

class _VacantEditModalState extends State<VacantEditModal> {
  late TextEditingController _labelController;
  late int _startMinutes;
  late int _endMinutes;

  final List<String> _presetLabels = [
    'Vacant Period',
    'Lunch Break',
    'Study Session',
    'Library Time',
    'Gym / Workout',
    'Org Meeting',
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.item.customLabel ?? 'Vacant Period');
    _startMinutes = widget.item.startMinutes;
    _endMinutes = widget.item.endMinutes;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final currentMin = isStart ? _startMinutes : _endMinutes;
    final initialTime = TimeOfDay(hour: currentMin ~/ 60, minute: currentMin % 60);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final newMin = picked.hour * 60 + picked.minute;
      setState(() {
        if (isStart) {
          if (newMin < _endMinutes) _startMinutes = newMin;
        } else {
          if (newMin > _startMinutes) _endMinutes = newMin;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockId = widget.item.blockId ?? '${widget.dayToken}_${widget.item.startMinutes}_${widget.item.endMinutes}';
    final fullDay = TimeFormatter.getFullDayName(widget.dayToken);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 24;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomPadding,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentIndigo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.coffee_outlined, color: AppTheme.accentIndigo, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customize Vacant Period',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                        ),
                        Text(
                          '$fullDay (${widget.dayToken})',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Label Input
              const Text('Block Label / Activity Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMutedDark)),
              const SizedBox(height: 6),
              TextField(
                controller: _labelController,
                style: const TextStyle(color: AppTheme.textPrimaryDark),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.bgDark.withOpacity(0.6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderDark)),
                  hintText: 'e.g. Lunch Break, Study Time',
                  hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),

              // Quick Preset Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _presetLabels.map((preset) {
                    final isSelected = _labelController.text == preset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(preset, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textSecondaryDark)),
                        backgroundColor: isSelected ? AppTheme.accentIndigo : AppTheme.bgDark,
                        onPressed: () => setState(() => _labelController.text = preset),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Time Range Selectors
              const Text('Time Interval', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMutedDark)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: true),
                      icon: const Icon(Icons.access_time, size: 16, color: AppTheme.accentCyan),
                      label: Text(
                        TimeFormatter.formatMinutesTo12Hour(_startMinutes),
                        style: const TextStyle(color: AppTheme.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.borderDark.withOpacity(0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to', style: TextStyle(color: AppTheme.textMutedDark, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: false),
                      icon: const Icon(Icons.access_time_filled, size: 16, color: AppTheme.accentCyan),
                      label: Text(
                        TimeFormatter.formatMinutesTo12Hour(_endMinutes),
                        style: const TextStyle(color: AppTheme.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.borderDark.withOpacity(0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons: Save, Delete, Reset
              Row(
                children: [
                  // Delete / Hide Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await VacantPeriodService.hideBlock(blockId);
                        if (mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.accentRose),
                      label: const Text('Delete', style: TextStyle(color: AppTheme.accentRose, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.accentRose.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Save Changes Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final label = _labelController.text.trim();
                        await VacantPeriodService.setCustomLabel(blockId, label);
                        await VacantPeriodService.setCustomRange(blockId, _startMinutes, _endMinutes);
                        if (mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
