import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../providers/daily_flow_controller.dart';

/// Inline task capture bar for DailyFlow with 1-tap add and reminder dialog launch.
///
/// Ownership: DailyFlow Feature
// ==========================================
// DAILYFLOW - Quick Add Task Bar
// Saves a task immediately for [selectedDate] or opens [DailyTaskEditorDialog].
// ==========================================
class DailyFlowQuickAddBar extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<String?> onOpenDetailedEditor;

  const DailyFlowQuickAddBar({
    super.key,
    required this.selectedDate,
    required this.onOpenDetailedEditor,
  });

  @override
  ConsumerState<DailyFlowQuickAddBar> createState() =>
      _DailyFlowQuickAddBarState();
}

class _DailyFlowQuickAddBarState extends ConsumerState<DailyFlowQuickAddBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitQuickTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final task = DailyTaskEntity(
      id: 'df_${now.microsecondsSinceEpoch}',
      title: title,
      scheduledDate: AppDateUtils.formatDateKey(widget.selectedDate),
      createdAt: now,
      updatedAt: now,
    );
    _controller.clear();
    await ref.read(dailyFlowControllerProvider.notifier).saveTask(task);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppTypography.inputText(paper),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitQuickTask(),
              decoration: InputDecoration(
                hintText: 'Add a task...',
                hintStyle: AppTypography.inputHint(
                  muted.withValues(alpha: 0.85),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Add with reminder & options',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              final draft = _controller.text.trim();
              _controller.clear();
              widget.onOpenDetailedEditor(draft.isEmpty ? null : draft);
            },
            icon: Icon(
              Icons.notifications_none_rounded,
              color: muted,
              size: 20,
            ),
          ),
          const SizedBox(width: 2),
          IconButton.filled(
            tooltip: 'Quick add task',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.inkGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: _submitQuickTask,
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
