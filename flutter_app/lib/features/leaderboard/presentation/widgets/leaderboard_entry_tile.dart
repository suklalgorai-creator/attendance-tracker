import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';

/// Ranking list item rendered inside [LeaderboardPage] showing rank medal/index,
/// student name, optional "You" indicator, streak badge, and attendance percent.
///
/// Ownership: Leaderboard Feature
// ==========================================
// LEADERBOARD - Entry Tile
// ==========================================
class LeaderboardEntryTile extends StatelessWidget {
  final int index;
  final LeaderboardEntryEntity entry;

  const LeaderboardEntryTile({
    super.key,
    required this.index,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final rank = index + 1;
    final (rankBadge, rankColor) = switch (rank) {
      1 => ('🥇', const Color(0xFFF59E0B)),
      2 => ('🥈', const Color(0xFFC0C0C0)),
      3 => ('🥉', const Color(0xFFCD7F32)),
      _ => ('#$rank', mutedColor),
    };

    final isYou = entry.isCurrentUser;

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
              // Rank & Name
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

              // Streak Pill & Percentage
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
