import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../widgets/timetable_editor.dart';

/// Full-screen Timetable configuration page matching React styling and architecture.
class TimetablePage extends ConsumerWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final settingsAsync = ref.watch(settingsStreamProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final timetableAsync = ref.watch(timetableStreamProvider);

    final classDays = settingsAsync.valueOrNull?.classDays ?? const [1, 2, 3, 4, 5];
    final subjects = subjectsAsync.valueOrNull ?? const [];
    final timetable = timetableAsync.valueOrNull ?? const {};

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimaryLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: paperColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Timetable',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: paperColor,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'WEEKLY SCHEDULE',
                        style: AppTypography.cardTitle(paperColor).copyWith(
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Configure recurring subjects for each class day of the week to enable automated daily schedule tracking.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: mutedColor,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                TimetableEditor(
                  classDays: classDays,
                  timetable: timetable,
                  subjects: subjects,
                  onAddSession: (day, subjectId) async {
                    try {
                      await ref.read(timetableRepositoryProvider).addSession(day, subjectId);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add session: $e')),
                        );
                      }
                    }
                  },
                  onRemoveSession: (day, sessionId) async {
                    try {
                      await ref.read(timetableRepositoryProvider).removeSession(day, sessionId);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove session: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
