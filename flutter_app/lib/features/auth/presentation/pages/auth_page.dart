import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_banner.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../controllers/auth_providers.dart';
import '../widgets/google_logo_icon.dart';

/// Authentication screen replicating react_app/src/components/Auth.jsx.
class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimaryLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title: Attendance Tracker (Gradient Outfit Typography)
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDark
                            ? [AppColors.textGradientStartDark, AppColors.textGradientEndDark]
                            : [AppColors.textGradientStartLight, AppColors.textGradientEndLight],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        'Attendance Tracker',
                        textAlign: TextAlign.center,
                        style: AppTypography.courseTitle(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle: Sign in to track your attendance
                    Text(
                      'Sign in to track your attendance',
                      textAlign: TextAlign.center,
                      style: AppTypography.inputText(mutedColor).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Optional Error Banner
                    if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) ...[
                      AppBanner.danger(
                        message: authState.errorMessage!,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Google Sign-In Button (.btn-google)
                    _GoogleSignInButton(
                      isLoading: authState.isLoading,
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              ref.read(authNotifierProvider.notifier).signInWithGoogle();
                            },
                    ),
                    const SizedBox(height: 16),

                    // Guest Mode Button (.btn-ghost)
                    AppButton(
                      label: 'Skip for now (Use as Guest)',
                      variant: AppButtonVariant.ghost,
                      isWide: true,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      fontSize: 15,
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              ref.read(authNotifierProvider.notifier).signInAsGuest();
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Google Sign-In button replicating .btn-google from components.css
class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                else
                  const GoogleLogoIcon(size: 20),
                const SizedBox(width: 12),
                Text(
                  isLoading ? 'Connecting...' : 'Continue with Google',
                  style: AppTypography.outfitBase.copyWith(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
