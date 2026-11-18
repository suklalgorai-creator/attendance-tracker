import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_banner.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/view_toggles_widget.dart';
import '../providers/register_providers.dart';
import '../widgets/day_row.dart';

/// Main Register screen replicating `react_app/src/pages/RegisterPage.jsx`.
///
/// Features:
/// - Session Register card with glassmorphism styling ([GlassCard]).
/// - Quick actions: Leaderboard navigation button and [ViewTogglesWidget] (Week, Month, All).
/// - Responsive header layout preventing overflow down to 320px width.
/// - Descending date-sorted list of [DayRow] items.
/// - Empty state: "No class dates are available for this range."
class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerControllerProvider);
    final controller = ref.read(registerControllerProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final today = AppDateUtils.todayStr();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800.0),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with Title and Quick Actions (Wrapped for narrow screen responsiveness)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 10.0,
                    children: [
                      Text(
                        'Session Register',
                        style: GoogleFonts.outfit(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: mutedColor,
                        ),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children: [
                          AppButton.ghost(
                            label: 'Leaderboard',
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 6.0),
                            fontSize: 12.0,
                            onPressed: () => context.go('/leaderboard'),
                          ),
                          ViewTogglesWidget(
                            currentMode: state.viewMode,
                            onModeChanged: (mode) =>
                                controller.setViewMode(mode),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12.0),
                    AppBanner.danger(
                      message: state.errorMessage!,
                    ),
                  ],

                  const SizedBox(height: 16.0),

                  // Register list
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    )
                  else if (state.visibleDates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No class dates are available for this range.',
                          style: AppTypography.helperText(mutedColor),
                        ),
                      ),
                    )
                  else
                    ...state.visibleDates.map((dateStr) {
                      final legacyRecord = state.legacyByDate[dateStr];
                      final isToday = dateStr == today;
                      return DayRow(
                        key: ValueKey(dateStr),
                        dateStr: dateStr,
                        legacyRecord: legacyRecord,
                        isToday: isToday,
                        isHoliday: false,
                        onSaveDaily: ({
                          required date,
                          required held,
                          required attended,
                        }) =>
                            controller.saveDailyAttendance(
                          date: date,
                          held: held,
                          attended: attended,
                        ),
                        onDeleteDaily: (id) =>
                            controller.deleteDailyAttendance(id),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
