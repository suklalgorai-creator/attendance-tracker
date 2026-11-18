import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../timetable/domain/entities/timetable_session_entity.dart';

/// Card displayed on the Dashboard prompting the user to mark today's scheduled sessions.
/// Disappears when no sessions are scheduled for today or all have been marked.
class TodaysScheduleCard extends ConsumerWidget {
  final DateTime? now;
  final VoidCallback? onReviewIndividually;

  const TodaysScheduleCard({
    super.key,
    this.now,
    this.onReviewIndividually,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveNow = now ?? DateTime.now();
    final todayStr = AppDateUtils.formatDateKey(effectiveNow);
    final dayOfWeek = effectiveNow.weekday % 7; // 0=Sun .. 6=Sat

    final settingsAsync = ref.watch(settingsStreamProvider);
    final timetableAsync = ref.watch(timetableStreamProvider);
    final recordsAsync = ref.watch(attendanceRecordsStreamProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    final settings = settingsAsync.valueOrNull;
    final timetable = timetableAsync.valueOrNull ?? const {};
    final records = recordsAsync.valueOrNull ?? const [];
    final subjects = subjectsAsync.valueOrNull ?? const [];

    // Check if today is configured as an active class day
    if (settings != null && !settings.classDays.contains(dayOfWeek)) {
      return const SizedBox.shrink();
    }

    // Get today's scheduled sessions
    final daySessions = (timetable[dayOfWeek] ?? const [])
        .where((s) => !s.isDeleted)
        .toList();

    if (daySessions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Map today's attendance records by session ID
    final todayRecordsBySession = <String, AttendanceRecordEntity>{};
    for (final record in records) {
      if (record.date == todayStr && !record.isDeleted) {
        todayRecordsBySession[record.sessionId] = record;
      }
    }

    // Find unmarked sessions
    final unmarkedSessions = <TimetableSessionEntity>[];
    for (final session in daySessions) {
      final rec = todayRecordsBySession[session.id];
      if (rec == null || rec.status == AttendanceStatus.unmarked) {
        unmarkedSessions.add(session);
      }
    }

    // If all scheduled sessions for today are already marked, collapse
    if (unmarkedSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final subjectById = {for (final s in subjects) s.id: s};

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header Row
          Row(
            children: [
              const Text('⏰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Mark Today's Scheduled Sessions",
                  style: AppTypography.cardTitle(paperColor).copyWith(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${unmarkedSessions.length} ${unmarkedSessions.length == 1 ? "session" : "sessions"} waiting to be recorded for today.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 12),

          // Period Pills / Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final session in daySessions) ...[
                _buildSessionChip(
                  session: session,
                  record: todayRecordsBySession[session.id],
                  subjectName: subjectById[session.subjectId]?.name ??
                      (session.label.isNotEmpty ? session.label : 'Subject'),
                  isDark: isDark,
                  paperColor: paperColor,
                  mutedColor: mutedColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Quick Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton.present(
                label: 'Mark all present',
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                fontSize: 13,
                onPressed: () => _markAll(
                  context,
                  ref,
                  unmarkedSessions,
                  todayStr,
                  AttendanceStatus.present,
                ),
              ),
              AppButton.absent(
                label: 'Mark all absent',
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                fontSize: 13,
                onPressed: () => _markAll(
                  context,
                  ref,
                  unmarkedSessions,
                  todayStr,
                  AttendanceStatus.absent,
                ),
              ),
              AppButton.ghost(
                label: 'Review individually',
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                fontSize: 13,
                onPressed: () {
                  if (onReviewIndividually != null) {
                    onReviewIndividually!();
                  } else {
                    context.go('/register');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildSessionChip({
    required TimetableSessionEntity session,
    required AttendanceRecordEntity? record,
    required String subjectName,
    required bool isDark,
    required Color paperColor,
    required Color mutedColor,
  }) {
    final status = record?.status ?? AttendanceStatus.unmarked;

    Color chipBg;
    Color chipBorder;
    Color textColor;
    TextDecoration? textDecoration;

    switch (status) {
      case AttendanceStatus.present:
        chipBg = AppColors.inkGreenSoft;
        chipBorder = AppColors.inkGreen.withValues(alpha: 0.3);
        textColor = AppColors.inkGreen;
        break;
      case AttendanceStatus.absent:
        chipBg = AppColors.penRedSoft;
        chipBorder = AppColors.penRed.withValues(alpha: 0.3);
        textColor = AppColors.penRed;
        textDecoration = TextDecoration.lineThrough;
        break;
      default:
        chipBg = isDark ? AppColors.ruleBrightDark : AppColors.ruleBrightLight;
        chipBorder = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;
        textColor = paperColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        border: Border.all(color: chipBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        subjectName,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
          decoration: textDecoration,
        ),
      ),
    );
  }

  Future<void> _markAll(
    BuildContext context,
    WidgetRef ref,
    List<TimetableSessionEntity> sessions,
    String dateStr,
    AttendanceStatus status,
  ) async {
    final now = DateTime.now();
    final newRecords = sessions.map((session) {
      return AttendanceRecordEntity(
        id: 'att_${dateStr}_${session.id}',
        date: dateStr,
        subjectId: session.subjectId,
        sessionId: session.id,
        status: status,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    try {
      await ref.read(attendanceRepositoryProvider).saveAttendanceRecords(newRecords);
      if (context.mounted) {
        final label = status == AttendanceStatus.present ? 'Present' : 'Absent';
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked all ${sessions.length} sessions as $label'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark sessions: $e')),
        );
      }
    }
  }
}
