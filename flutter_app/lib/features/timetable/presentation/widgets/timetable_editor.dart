import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../domain/entities/timetable_session_entity.dart';

const List<String> _kDayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Interactive weekly timetable editor matching React `TimetableEditor.jsx` with
/// responsive adaptation down to 320px screen width.
class TimetableEditor extends StatefulWidget {
  final List<int> classDays;
  final Map<int, List<TimetableSessionEntity>> timetable;
  final List<SubjectEntity> subjects;
  final void Function(int day, String subjectId) onAddSession;
  final void Function(int day, String sessionId) onRemoveSession;

  const TimetableEditor({
    super.key,
    required this.classDays,
    required this.timetable,
    required this.subjects,
    required this.onAddSession,
    required this.onRemoveSession,
  });

  @override
  State<TimetableEditor> createState() => _TimetableEditorState();
}

class _TimetableEditorState extends State<TimetableEditor> {
  final Map<int, String> _selectedSubjectByDay = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final inputBg = isDark ? AppColors.inputBgDark : AppColors.inputBgLight;
    final borderColor = isDark ? AppColors.ruleBrightDark : AppColors.ruleBrightLight;

    final activeSubjects = widget.subjects.where((s) => s.active && !s.isDeleted).toList();
    final subjectById = {for (final s in widget.subjects) s.id: s};

    final sortedDays = widget.classDays.toList()..sort();

    if (sortedDays.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text(
            'No class days configured. Update your settings to add schedule days.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: mutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < sortedDays.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildDayRow(
            day: sortedDays[i],
            activeSubjects: activeSubjects,
            subjectById: subjectById,
            isDark: isDark,
            paperColor: paperColor,
            mutedColor: mutedColor,
            inputBg: inputBg,
            borderColor: borderColor,
          ),
        ],
      ],
    );
  }

  Widget _buildDayRow({
    required int day,
    required List<SubjectEntity> activeSubjects,
    required Map<String, SubjectEntity> subjectById,
    required bool isDark,
    required Color paperColor,
    required Color mutedColor,
    required Color inputBg,
    required Color borderColor,
  }) {
    final sessions = (widget.timetable[day] ?? const [])
        .where((s) => !s.isDeleted)
        .toList();

    final selectedValue = _selectedSubjectByDay[day] ??
        (activeSubjects.isNotEmpty ? activeSubjects.first.id : '');

    // Ensure valid selection if active subjects list changed
    final effectiveValue = activeSubjects.any((s) => s.id == selectedValue)
        ? selectedValue
        : (activeSubjects.isNotEmpty ? activeSubjects.first.id : '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Label (48px fixed width)
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              (day >= 0 && day < _kDayNames.length ? _kDayNames[day] : 'Day $day').toUpperCase(),
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

        // Session list & Add Session controls
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Existing sessions list
              for (final session in sessions) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          subjectById[session.subjectId]?.name ??
                              (session.label.isNotEmpty ? session.label : 'Unknown subject'),
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
                        label: 'Remove ${session.label.isNotEmpty ? session.label : "session"}',
                        button: true,
                        child: InkWell(
                          onTap: () => widget.onRemoveSession(day, session.id),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
              ],

              // Add session row or empty subject hint
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
                          value: effectiveValue.isNotEmpty ? effectiveValue : null,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.surfaceSolidDark : AppColors.paperDark,
                          icon: Icon(Icons.arrow_drop_down_rounded, color: paperColor),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: paperColor,
                          ),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedSubjectByDay[day] = newValue;
                              });
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      fontSize: 13,
                      onPressed: effectiveValue.isNotEmpty
                          ? () => widget.onAddSession(day, effectiveValue)
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
