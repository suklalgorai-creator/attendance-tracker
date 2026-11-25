import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../dashboard/presentation/providers/dashboard_providers.dart';
import '../domain/entities/leaderboard_entry_entity.dart';
import 'providers/leaderboard_providers.dart';
import 'widgets/badges_showcase_widget.dart';

/// Full-featured Leaderboard & Gamification Screen.
///
/// Exact 1:1 visual and behavioral parity with `react_app/src/pages/LeaderboardPage.jsx`.
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
        // Card 1: Attendance Leaderboard Overview
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

        // Card 2: Gamification Badges Showcase (Bronze, Silver, Gold, Platinum)
        BadgesShowcaseWidget(currentStreak: streak),

        const SizedBox(height: 12),

        // Card 3: Rankings List Card
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
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _buildLeaderboardRow(
                        index: index,
                        entry: entry,
                        isDark: isDark,
                        paperColor: paperColor,
                        mutedColor: mutedColor,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow({
    required int index,
    required LeaderboardEntryEntity entry,
    required bool isDark,
    required Color paperColor,
    required Color mutedColor,
  }) {
    final rank = index + 1;
    String rankBadge;
    Color rankColor;

    if (rank == 1) {
      rankBadge = '🥇';
      rankColor = const Color(0xFFF59E0B); // Gold
    } else if (rank == 2) {
      rankBadge = '🥈';
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      rankBadge = '🥉';
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankBadge = '#$rank';
      rankColor = mutedColor;
    }

    final isYou = entry.isCurrentUser;

    // Styling matching React `.main-card-row` for the current user
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isYou
            ? AppColors.inkGreen.withValues(alpha: 0.12)
            : (isDark ? AppColors.ruleDark : AppColors.ruleLight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isYou
              ? AppColors.inkGreen
              : (isDark
                    ? AppColors.glassBorderDark
                    : AppColors.glassBorderLight),
          width: isYou ? 2.0 : 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rank + Name Column
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        rankBadge,
                        style: GoogleFonts.outfit(
                          fontSize: rank <= 3 ? 16 : 13,
                          fontWeight: FontWeight.w800,
                          color: rankColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              entry.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: isYou
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isYou ? AppColors.inkGreen : paperColor,
                              ),
                            ),
                          ),
                          if (isYou) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inkGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'You',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Percentage + Streak Pill Column
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.streak > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amberSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🔥 ${entry.streak}d',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '${entry.attendancePercent.toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: entry.attendancePercent >= 75.0
                          ? AppColors.inkGreen
                          : (entry.attendancePercent >= 65.0
                                ? AppColors.amber
                                : AppColors.penRed),
                    ),
                  ),
                ],
              ),
            ],
          );

          if (constraints.maxWidth < 260) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 260, child: content),
            );
          }

          return content;
        },
      ),
    );
  }
}
