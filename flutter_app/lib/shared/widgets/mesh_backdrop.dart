import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared ambient mesh gradient backdrop matching `react_app/src/styles/global.css`
/// for both Dark Mode (`#050505` + 15% emerald/rose/blue orbs) and
/// Light Mode (`#F8FAFC` + 40%/30%/40% emerald/rose/blue orbs).
class MeshBackdrop extends StatelessWidget {
  const MeshBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimaryLight;

    final mesh1 = isDark
        ? const Color(0x2610B981) // rgba(16, 185, 129, 0.15)
        : const Color(0x6634D399); // rgba(52, 211, 153, 0.40)
    final mesh2 = isDark
        ? const Color(0x26F43F5E) // rgba(244, 63, 94, 0.15)
        : const Color(0x4DFB7185); // rgba(251, 113, 133, 0.30)
    final mesh3 = isDark
        ? const Color(0x263B82F6) // rgba(59, 130, 246, 0.15)
        : const Color(0x6660A5FA); // rgba(96, 165, 250, 0.40)

    return IgnorePointer(
      child: ColoredBox(
        color: bgColor,
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -100,
              width: 520,
              height: 440,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [mesh1, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -140,
              bottom: -120,
              width: 500,
              height: 440,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [mesh2, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 180,
              left: 80,
              width: 400,
              height: 380,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [mesh3, Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
