import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/daily_task_entity.dart';

/// Date navigation header and rolling planning-horizon strip for DailyFlow.
///
/// Ownership: DailyFlow Feature
// ==========================================
// DAILYFLOW - Date Navigation Header
// Allows stepping backward/forward or picking an arbitrary calendar date.
// ==========================================
class DailyFlowDateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DailyFlowDateHeader({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  String _formatDayHeader(DateTime date) {
    final todayKey = AppDateUtils.todayStr();
    final key = AppDateUtils.formatDateKey(date);
    if (key == todayKey) return 'Today';
    final tomorrowKey = AppDateUtils.formatDateKey(
      DateTime.now().add(const Duration(days: 1)),
    );
    if (key == tomorrowKey) return 'Tomorrow';
    final yesterdayKey = AppDateUtils.formatDateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    if (key == yesterdayKey) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                onDateSelected(selectedDate.subtract(const Duration(days: 1))),
            icon: Icon(Icons.chevron_left_rounded, color: paper),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  onDateSelected(picked);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: [
                    Text(
                      _formatDayHeader(selectedDate),
                      style: AppTypography.cardTitle(paper),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('EEE, MMM d').format(selectedDate),
                      style: AppTypography.bodySmall(muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                onDateSelected(selectedDate.add(const Duration(days: 1))),
            icon: Icon(Icons.chevron_right_rounded, color: paper),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// DAILYFLOW - Rolling Planning Horizon Strip
// Displays upcoming days with pending task counts across the planning horizon.
// ==========================================
class DailyFlowHorizonStrip extends StatelessWidget {
  final DateTime selectedDate;
  final int horizonDays;
  final List<DailyTaskEntity> tasks;
  final ValueChanged<DateTime> onSelectDate;

  const DailyFlowHorizonStrip({
    super.key,
    required this.selectedDate,
    required this.horizonDays,
    required this.tasks,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedKey = AppDateUtils.formatDateKey(selectedDate);
    final count = horizonDays.clamp(1, 14);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final day = today.add(Duration(days: index));
          final key = AppDateUtils.formatDateKey(day);
          final isSelected = key == selectedKey;
          final pendingCount = tasks
              .where(
                (t) =>
                    !t.isDeleted &&
                    !t.status.isTerminal &&
                    t.scheduledDate == key,
              )
              .length;
          final label = index == 0
              ? 'Today'
              : (index == 1 ? 'Tomorrow' : DateFormat('EEE d').format(day));

          return ChoiceChip(
            label: Text(pendingCount > 0 ? '$label ($pendingCount)' : label),
            selected: isSelected,
            onSelected: (_) => onSelectDate(day),
          );
        },
      ),
    );
  }
}
