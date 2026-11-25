import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/theme_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../providers/settings_controller.dart';

/// Card managing theme mode, user name, degree program, and semester.
class PersonalizationCard extends ConsumerStatefulWidget {
  final UserSettingsEntity settings;

  const PersonalizationCard({super.key, required this.settings});

  @override
  ConsumerState<PersonalizationCard> createState() =>
      _PersonalizationCardState();
}

class _PersonalizationCardState extends ConsumerState<PersonalizationCard> {
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

  late final TextEditingController _nameController;
  late final TextEditingController _programController;
  late final TextEditingController _courseController;

  final FocusNode _programFocus = FocusNode();
  final FocusNode _courseFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settings.name);
    _programController = TextEditingController(
      text: widget.settings.programName,
    );
    _courseController = TextEditingController(text: widget.settings.courseName);

    // Apply toTitleCase on blur matching React
    _programFocus.addListener(() {
      if (!_programFocus.hasFocus) {
        final titleCased = SettingsController.toTitleCase(
          _programController.text,
        );
        if (titleCased != _programController.text) {
          _programController.text = titleCased;
        }
        ref
            .read(settingsControllerProvider.notifier)
            .updateProgramName(_programController.text);
      }
    });

    _courseFocus.addListener(() {
      if (!_courseFocus.hasFocus) {
        final titleCased = SettingsController.toTitleCase(
          _courseController.text,
        );
        if (titleCased != _courseController.text) {
          _courseController.text = titleCased;
        }
        ref
            .read(settingsControllerProvider.notifier)
            .updateCourseName(_courseController.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PersonalizationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings.name != _nameController.text &&
        !_nameController.selection.isValid) {
      _nameController.text = widget.settings.name;
    }
    if (widget.settings.programName != _programController.text &&
        !_programFocus.hasFocus) {
      _programController.text = widget.settings.programName;
    }
    if (widget.settings.courseName != _courseController.text &&
        !_courseFocus.hasFocus) {
      _courseController.text = widget.settings.courseName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _programController.dispose();
    _courseController.dispose();
    _programFocus.dispose();
    _courseFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final authUser = ref.watch(authNotifierProvider).user;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personalization', style: AppTypography.cardTitle(paperColor)),
          const SizedBox(height: 16),
          // Theme switch row
          Text('THEME', style: AppTypography.inputLabel(mutedColor)),
          const SizedBox(height: 8),
          AppButton(
            label: isDark
                ? '☀️ Switch to Light Mode'
                : '🌙 Switch to Dark Mode',
            variant: AppButtonVariant.ghost,
            isWide: true,
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(height: 16),
          // Your Name field
          AppTextField(
            label: 'Your Name',
            controller: _nameController,
            hint:
                authUser?.displayName != null &&
                    authUser!.displayName!.isNotEmpty
                ? authUser.displayName!
                : 'Enter your name',
            onChanged: (val) {
              ref.read(settingsControllerProvider.notifier).updateName(val);
            },
          ),
          const SizedBox(height: 16),
          // Degree / Program name field with suggestions
          _buildAutocompleteField(
            label: 'Degree / Program name',
            controller: _programController,
            focusNode: _programFocus,
            options: defaultPrograms,
            hint: 'e.g. B.Tech CSE',
            onChanged: (val) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updateProgramName(val);
            },
          ),
          const SizedBox(height: 16),
          // Semester name field with suggestions
          _buildAutocompleteField(
            label: 'Semester name',
            controller: _courseController,
            focusNode: _courseFocus,
            options: defaultSemesters,
            hint: 'e.g. Semester 6',
            onChanged: (val) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updateCourseName(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> options,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return options;
        }
        return options.where(
          (option) => option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          ),
        );
      },
      onSelected: (String selection) {
        controller.text = selection;
        onChanged(selection);
      },
      fieldViewBuilder:
          (
            context,
            fieldTextEditingController,
            fieldFocusNode,
            onFieldSubmitted,
          ) {
            return AppTextField(
              label: label,
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              hint: hint,
              onChanged: onChanged,
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
        final bgColor = isDark ? AppColors.ruleDark : AppColors.ruleLight;
        final borderColor = isDark
            ? AppColors.glassBorderDark
            : AppColors.glassBorderLight;

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
            child: Container(
              width: 280,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      child: Text(
                        option,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: paperColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
