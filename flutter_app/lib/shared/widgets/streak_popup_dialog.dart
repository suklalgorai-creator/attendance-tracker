import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import 'app_button.dart';

/// Modal dialog popup replicating `StreakPopup.jsx` and styling in `components.css`.
class StreakPopupDialog extends StatefulWidget {
  final int streak;
  final VoidCallback? onClose;

  const StreakPopupDialog({super.key, required this.streak, this.onClose});

  @override
  State<StreakPopupDialog> createState() => _StreakPopupDialogState();
}

class _StreakPopupDialogState extends State<StreakPopupDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: -8.0 * (math.pi / 180.0),
      end: 8.0 * (math.pi / 180.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          width: MediaQuery.of(context).size.width * 0.9,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark
                        ? AppColors.glassBorderDark
                        : AppColors.glassBorderLight,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // .streak-fire-large with fireBurn animation
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '🔥',
                          style: TextStyle(
                            fontSize: 80,
                            shadows: [
                              Shadow(
                                color: AppColors.amber.withValues(alpha: 0.6),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // .streak-popup-title
                    Text(
                      '${widget.streak} Day Streak!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: paperColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // .streak-popup-desc
                    Text(
                      "You're on fire! Keep attending classes to maintain your streak.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Button: .btn-present.btn-wide
                    AppButton.present(
                      label: 'Awesome',
                      isWide: true,
                      onPressed:
                          widget.onClose ?? () => Navigator.of(context).pop(),
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

/// Helper function to display the Streak Popup dialog
Future<T?> showStreakDialog<T>(
  BuildContext context, {
  required int streak,
  VoidCallback? onClose,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Streak Popup',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (ctx, anim1, anim2) => StreakPopupDialog(
      streak: streak,
      onClose: () {
        Navigator.of(ctx).pop();
        onClose?.call();
      },
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(
        parent: anim1,
        curve: const Cubic(0.175, 0.885, 0.32, 1.275),
      );
      return Transform.scale(
        scale: Tween<double>(begin: 0.8, end: 1.0).evaluate(curved),
        child: Opacity(opacity: anim1.value, child: child),
      );
    },
  );
}
