import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../domain/entities/timetable_session_entity.dart';
import 'timetable_day_row.dart';

/// Interactive weekly timetable editor matching `react_app/src/components/TimetableEditor.jsx`
/// with responsive adaptation down to 320px screen width.
///
/// Ownership: Timetable Feature
// ==========================================
// TIMETABLE - Weekly Schedule Editor
// ==========================================
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
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final activeSubjects = widget.subjects
        .where((s) => s.active && !s.isDeleted)
        .toList();
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
          TimetableDayRow(
            day: sortedDays[i],
            sessions: (widget.timetable[sortedDays[i]] ?? const [])
                .where((s) => !s.isDeleted)
                .toList(),
            activeSubjects: activeSubjects,
            subjectById: subjectById,
            selectedSubjectId:
                _selectedSubjectByDay[sortedDays[i]] ??
                (activeSubjects.isNotEmpty ? activeSubjects.first.id : ''),
            onSelectedSubjectChanged: (subjectId) {
              setState(() => _selectedSubjectByDay[sortedDays[i]] = subjectId);
            },
            onAddSession: widget.onAddSession,
            onRemoveSession: widget.onRemoveSession,
          ),
        ],
      ],
    );
  }
}
