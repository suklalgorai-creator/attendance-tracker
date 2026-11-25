import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../domain/entities/timetable_session_entity.dart';

/// Single weekday row inside [TimetableEditor] rendering scheduled sessions
/// and a responsive subject dropdown + "Add session" button.
///
/// Ownership: Timetable Feature
// ==========================================
// TIMETABLE - Weekday Sessions Row
// ==========================================
class TimetableDayRow extends StatelessWidget {
  static const List<String> dayNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  final int day;
  final List<TimetableSessionEntity> sessions;
  final List<SubjectEntity> activeSubjects;
  final Map<String, SubjectEntity> subjectById;
  final String selectedSubjectId;
  final ValueChanged<String> onSelectedSubjectChanged;
  final void Function(int day, String subjectId) onAddSession;
  final void Function(int day, String sessionId) onRemoveSession;

  const TimetableDayRow({
    super.key,
    required this.day,
    required this.sessions,
    required this.activeSubjects,
    required this.subjectById,
    required this.selectedSubjectId,
    required this.onSelectedSubjectChanged,
    required this.onAddSession,
    required this.onRemoveSession,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final inputBg = isDark ? AppColors.inputBgDark : AppColors.inputBgLight;
    final borderColor = isDark
        ? AppColors.ruleBrightDark
        : AppColors.ruleBrightLight;

    final effectiveValue = activeSubjects.any((s) => s.id == selectedSubjectId)
        ? selectedSubjectId
        : (activeSubjects.isNotEmpty ? activeSubjects.first.id : '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              (day >= 0 && day < dayNames.length ? dayNames[day] : 'Day $day')
                  .toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: mutedColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scheduled Sessions
              for (final session in sessions)
                Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          subjectById[session.subjectId]?.name ??
                              (session.label.isNotEmpty
                                  ? session.label
                                  : 'Unknown subject'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: paperColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label:
                            'Remove ${session.label.isNotEmpty ? session.label : "session"}',
                        button: true,
                        child: InkWell(
                          onTap: () => onRemoveSession(day, session.id),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight,
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: paperColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Add Session Selector + Button
              if (activeSubjects.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 250;
                    final dropdown = Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: inputBg,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: effectiveValue.isNotEmpty
                              ? effectiveValue
                              : null,
                          isExpanded: true,
                          dropdownColor: isDark
                              ? AppColors.surfaceSolidDark
                              : AppColors.paperDark,
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: paperColor,
                          ),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: paperColor,
                          ),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              onSelectedSubjectChanged(newValue);
                            }
                          },
                          items: [
                            for (final sub in activeSubjects)
                              DropdownMenuItem<String>(
                                value: sub.id,
                                child: Text(
                                  sub.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: paperColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );

                    final addButton = AppButton.present(
                      label: 'Add session',
                      isWide: isNarrow,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      fontSize: 13,
                      onPressed: effectiveValue.isNotEmpty
                          ? () => onAddSession(day, effectiveValue)
                          : null,
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          dropdown,
                          const SizedBox(height: 6),
                          addButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: dropdown),
                        const SizedBox(width: 8),
                        addButton,
                      ],
                    );
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Create a subject first.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
