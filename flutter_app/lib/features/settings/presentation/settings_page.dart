import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings View',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: paperColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage targets, reminders, backups, and preferences.',
                style: GoogleFonts.outfit(color: mutedColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          onTap: () => context.push('/timetable'),
          child: Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timetable & Schedule',
                      style: AppTypography.cardTitle(paperColor).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure weekly recurring subject timetable',
                      style: GoogleFonts.outfit(fontSize: 13, color: mutedColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: mutedColor),
            ],
          ),
        ),
      ],
    );
  }
}
