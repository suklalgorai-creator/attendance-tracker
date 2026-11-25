import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/leaderboard_providers.dart';
import '../widgets/badges_showcase_widget.dart';
import '../widgets/leaderboard_entry_tile.dart';

/// Leaderboard & Gamification Screen matching `react_app/src/pages/LeaderboardPage.jsx`.
///
/// Displays current rank banner, streak badge showcase, and live opt-in rankings.
///
/// Ownership: Leaderboard Feature
// ==========================================
// LEADERBOARD - Main Page
// ==========================================
class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(leaderboardEntriesProvider);
    final myRank = ref.watch(myRankProvider);
    final streak = ref.watch(streakCountProvider).valueOrNull ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      children: [
        // Card 1: Leaderboard Overview & Current Rank
        GlassCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Leaderboard',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: paperColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Display names and calculated attendance percentages are shown.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
              if (myRank > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.ruleDark : AppColors.ruleLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.inkGreen.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'Your Rank',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: paperColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '#$myRank',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.inkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Card 2: Gamification Badges Showcase
        BadgesShowcaseWidget(currentStreak: streak),
        const SizedBox(height: 12),

        // Card 3: Class Rankings List
        GlassCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class Rankings',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: paperColor,
                ),
              ),
              const SizedBox(height: 12),
              entriesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Leaderboard is temporarily unavailable.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.penRed,
                    ),
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No students have opted in yet.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => LeaderboardEntryTile(
                      index: index,
                      entry: entries[index],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
