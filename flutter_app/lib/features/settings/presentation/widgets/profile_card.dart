import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../domain/entities/user_settings_entity.dart';

/// Profile card displaying user avatar, name, account status, and auth actions.
class ProfileCard extends ConsumerWidget {
  final UserSettingsEntity settings;

  const ProfileCard({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final String displayName;
    if (settings.name.isNotEmpty) {
      displayName = settings.name;
    } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      displayName = user.displayName!;
    } else {
      displayName = 'Guest User';
    }

    final String emailHint;
    if (user != null && !user.isGuest && user.email != null && user.email!.isNotEmpty) {
      emailHint = user.email!;
    } else {
      emailHint = 'Not logged in — stored on this device only';
    }

    final String initialLetter;
    if (user?.email != null && user!.email!.isNotEmpty) {
      initialLetter = user.email![0].toUpperCase();
    } else if (displayName.isNotEmpty) {
      initialLetter = displayName[0].toUpperCase();
    } else {
      initialLetter = 'G';
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Profile',
              style: AppTypography.cardTitle(paperColor),
            ),
          ),
          const SizedBox(height: 16),
          // 88x88 circular avatar matching React
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                width: 2.0,
              ),
            ),
            child: ClipOval(
              child: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                  ? Image.network(
                      user.photoUrl!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackAvatar(initialLetter, isDark),
                    )
                  : _buildFallbackAvatar(initialLetter, isDark),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: paperColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emailHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 24),
          // Responsive button actions
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 280;
              final isLogged = user != null && !user.isGuest;

              final authBtn = AppButton(
                label: isLogged ? 'Log Out' : 'Sign In to Sync',
                variant: isLogged ? AppButtonVariant.ghost : AppButtonVariant.present,
                isWide: isNarrow,
                onPressed: () {
                  if (isLogged) {
                    ref.read(authNotifierProvider.notifier).signOut();
                  } else {
                    context.push('/auth');
                  }
                },
              );

              if (isNarrow) {
                return Column(
                  children: [
                    authBtn,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: authBtn),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String initialLetter, bool isDark) {
    return Container(
      color: isDark ? AppColors.ruleDark : AppColors.ruleLight,
      alignment: Alignment.center,
      child: Text(
        initialLetter,
        style: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.paperDark : AppColors.paperLight,
        ),
      ),
    );
  }
}
