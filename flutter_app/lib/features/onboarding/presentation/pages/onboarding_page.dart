import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/day_picker_widget.dart';
import '../../../../shared/widgets/mesh_backdrop.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../settings/domain/entities/user_settings_entity.dart';
import '../widgets/onboarding_suggestion_chips.dart';

/// First-run onboarding wizard configuring degree, semester, start date,
/// target attendance percentage, and weekly class days.
///
/// Replicates `react_app/src/pages/OnboardingPage.jsx`.
///
/// Ownership: Onboarding Feature
// ==========================================
// ONBOARDING - Setup Wizard Page
// ==========================================
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final TextEditingController _programController;
  late final TextEditingController _courseController;
  late final TextEditingController _minPercentController;
  late final TextEditingController _startDateController;

  late DateTime _startDate;
  late List<int> _classDays;
  bool _isSubmitting = false;

  static const List<String> defaultPrograms = [
    'B.Tech CSE',
    'B.Tech IT',
    'B.Tech ECE',
    'B.Tech Mechanical',
    'B.Tech Civil',
    'BCA',
    'MCA',
    'BBA',
    'MBA',
    'B.Sc',
    'B.Com',
    'BA',
  ];

  static const List<String> defaultSemesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _classDays = const [1, 2, 3, 4, 5];

    _programController = TextEditingController();
    _courseController = TextEditingController();
    _minPercentController = TextEditingController(text: '75');
    _startDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_startDate),
    );
  }

  @override
  void dispose() {
    _programController.dispose();
    _courseController.dispose();
    _minPercentController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isAfter(today) ? today : _startDate,
      firstDate: DateTime(2000),
      lastDate: today,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.inkGreen,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceSolidDark,
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.inkGreen,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.paperLight,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleStartTracking() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final rawMin = double.tryParse(_minPercentController.text.trim()) ?? 75.0;
      final clampedMin = rawMin.clamp(1.0, 100.0);
      final finalDays = _classDays.isNotEmpty
          ? _classDays
          : const [1, 2, 3, 4, 5];
      final formattedDate = DateFormat('yyyy-MM-dd').format(_startDate);

      final settings = UserSettingsEntity(
        programName: _programController.text.trim(),
        courseName: _courseController.text.trim(),
        startDate: formattedDate,
        minPercent: clampedMin,
        classDays: finalDays,
      );

      // Save user profile configuration
      await ref.read(settingsRepositoryProvider).saveSettings(settings);

      // Mark onboarding completed in Auth system
      await ref.read(authNotifierProvider.notifier).completeOnboarding();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimaryLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 36.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title: Set up your register (Gradient Text)
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: isDark
                              ? [
                                  AppColors.textGradientStartDark,
                                  AppColors.textGradientEndDark,
                                ]
                              : [
                                  AppColors.textGradientStartLight,
                                  AppColors.textGradientEndLight,
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Text(
                          'Set up your register',
                          textAlign: TextAlign.center,
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        'A daily attendance tracker that shows exactly how safe — or how behind — you are.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge(
                          mutedColor,
                        ).copyWith(fontSize: 14.5, height: 1.45),
                      ),
                      const SizedBox(height: 28),

                      // Field 1: Degree / Program name
                      AppTextField(
                        controller: _programController,
                        label: 'Degree / Program name (optional)',
                        hint: 'e.g. B.Tech CSE',
                        onSubmitted: (val) {
                          _programController.text = toTitleCase(val);
                        },
                      ),
                      const SizedBox(height: 8),
                      OnboardingSuggestionChips(
                        suggestions: defaultPrograms,
                        onSelected: (program) =>
                            setState(() => _programController.text = program),
                      ),
                      const SizedBox(height: 20),

                      // Field 2: Semester name
                      AppTextField(
                        controller: _courseController,
                        label: 'Semester name (optional)',
                        hint: 'e.g. Semester 3',
                        onSubmitted: (val) {
                          _courseController.text = toTitleCase(val);
                        },
                      ),
                      const SizedBox(height: 8),
                      OnboardingSuggestionChips(
                        suggestions: defaultSemesters,
                        onSelected: (semester) =>
                            setState(() => _courseController.text = semester),
                      ),
                      const SizedBox(height: 20),

                      // Field 3: Classes started on
                      GestureDetector(
                        onTap: _pickStartDate,
                        child: AbsorbPointer(
                          child: AppTextField(
                            controller: _startDateController,
                            label: 'Classes started on',
                            hint: 'YYYY-MM-DD',
                            readOnly: true,
                            suffixIcon: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.inkGreen,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Field 4: Minimum attendance required
                      AppTextField(
                        controller: _minPercentController,
                        label: 'Minimum attendance required',
                        hint: '75',
                        keyboardType: TextInputType.number,
                        suffixIcon: Center(
                          widthFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Text(
                              '%',
                              style: AppTypography.labelLarge.copyWith(
                                color: mutedColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Field 5: Which days do you have class?
                      Text(
                        'Which days do you have class?',
                        style: AppTypography.inputLabel(
                          isDark ? AppColors.mutedDark : AppColors.mutedLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DayPickerWidget(
                        selectedDays: _classDays,
                        onDaysChanged: (days) {
                          setState(() {
                            _classDays = days;
                          });
                        },
                      ),
                      const SizedBox(height: 36),

                      // Submit Button: Start tracking
                      AppButton(
                        label: 'Start tracking',
                        variant: AppButtonVariant.present,
                        isWide: true,
                        isLoading: _isSubmitting,
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        fontSize: 16,
                        onPressed: _handleStartTracking,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
