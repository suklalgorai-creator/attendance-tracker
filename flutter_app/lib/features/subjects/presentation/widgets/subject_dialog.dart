import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subject_providers.dart';

/// Available curated subject colors matching design tokens.
const List<String> kSubjectColors = [
  '#10B981', // Emerald
  '#F43F5E', // Rose
  '#F59E0B', // Amber
  '#3B82F6', // Blue
  '#8B5CF6', // Purple
  '#6366F1', // Indigo
  '#14B8A6', // Teal
  '#06B6D4', // Cyan
  '#F97316', // Orange
  '#EC4899', // Pink
  '#64748B', // Slate
];

/// Curated academic icons with their string keys.
const Map<String, IconData> kAcademicIcons = {
  'school': Icons.school_rounded,
  'book': Icons.menu_book_rounded,
  'computer': Icons.computer_rounded,
  'calculate': Icons.calculate_rounded,
  'science': Icons.science_rounded,
  'history_edu': Icons.history_edu_rounded,
  'palette': Icons.palette_rounded,
  'fitness_center': Icons.fitness_center_rounded,
  'language': Icons.language_rounded,
  'insights': Icons.insights_rounded,
};

/// Color parser utility for hex strings.
Color parseHexColor(String hex, {Color fallback = AppColors.inkGreen}) {
  try {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
  } catch (_) {}
  return fallback;
}

/// Modal dialog for adding or editing a subject.
class SubjectDialog extends ConsumerStatefulWidget {
  final SubjectEntity? subject;
  final VoidCallback? onSaved;
  final VoidCallback? onDeleted;

  const SubjectDialog({
    super.key,
    this.subject,
    this.onSaved,
    this.onDeleted,
  });

  bool get isEdit => subject != null;

  @override
  ConsumerState<SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends ConsumerState<SubjectDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;

  late String _selectedColor;
  late String _selectedIcon;
  late bool _hasCustomTarget;
  late double _targetPercentage;

  String? _nameError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final subject = widget.subject;
    _nameController = TextEditingController(text: subject?.name ?? '');
    _codeController = TextEditingController(text: subject?.code ?? '');

    _selectedColor = subject?.color ?? kSubjectColors.first;
    _selectedIcon = subject?.icon ?? 'school';
    if (!kAcademicIcons.containsKey(_selectedIcon)) {
      _selectedIcon = 'school';
    }

    _hasCustomTarget = subject?.targetPercentage != null;
    _targetPercentage = subject?.targetPercentage ?? 75.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      setState(() {
        _nameError = 'Subject name is required';
      });
      return;
    }

    setState(() {
      _nameError = null;
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim().isEmpty ? null : _codeController.text.trim();
      final target = _hasCustomTarget ? _targetPercentage : null;

      if (widget.isEdit) {
        final updated = widget.subject!.copyWith(
          name: rawName,
          code: code,
          clearCode: code == null,
          color: _selectedColor,
          icon: _selectedIcon,
          targetPercentage: target,
          clearTargetPercentage: !_hasCustomTarget,
        );
        await ref.read(subjectControllerProvider.notifier).updateSubject(updated);
      } else {
        await ref.read(subjectControllerProvider.notifier).addSubject(
              name: rawName,
              code: code,
              color: _selectedColor,
              icon: _selectedIcon,
              targetPercentage: target,
            );
      }

      widget.onSaved?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _nameError = e.toString().replaceFirst('ArgumentError: ', '');
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.subject == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
        final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(
              color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
            ),
          ),
          title: Text(
            'Delete Subject',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: paperColor,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${widget.subject!.name}"? Your past attendance history for this subject will be preserved.',
            style: GoogleFonts.outfit(
              color: mutedColor,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.outfit(
                  color: AppColors.penRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      await ref.read(subjectControllerProvider.notifier).deleteSubject(widget.subject!.id);
      widget.onDeleted?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          width: MediaQuery.of(context).size.width * 0.92,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.isEdit ? 'Edit Subject' : 'Add Subject',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: paperColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 22),
                            color: mutedColor,
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Subject Name Field
                      AppTextField(
                        key: const Key('subject_name_field'),
                        controller: _nameController,
                        label: 'SUBJECT NAME',
                        hint: 'e.g. Computer Networks',
                        errorText: _nameError,
                        onChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Subject Code Field
                      AppTextField(
                        key: const Key('subject_code_field'),
                        controller: _codeController,
                        label: 'SUBJECT CODE (OPTIONAL)',
                        hint: 'e.g. CS301',
                      ),
                      const SizedBox(height: 18),

                      // Color Picker Section
                      Text(
                        'COLOR ACCENT',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kSubjectColors.map((hex) {
                          final color = parseHexColor(hex);
                          final isSelected = _selectedColor.toUpperCase() == hex.toUpperCase();

                          return GestureDetector(
                            key: Key('color_swatch_$hex'),
                            onTap: () {
                              setState(() {
                                _selectedColor = hex;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Academic Icon Selector Section
                      Text(
                        'ICON',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kAcademicIcons.entries.map((entry) {
                          final isSelected = _selectedIcon == entry.key;
                          final activeColor = parseHexColor(_selectedColor);

                          return GestureDetector(
                            key: Key('icon_chip_${entry.key}'),
                            onTap: () {
                              setState(() {
                                _selectedIcon = entry.key;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor.withValues(alpha: 0.2)
                                    : (isDark ? AppColors.inputBgDark : AppColors.inputBgLight),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: isSelected
                                      ? activeColor
                                      : (isDark
                                          ? AppColors.glassBorderDark
                                          : AppColors.glassBorderLight),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Icon(
                                entry.value,
                                size: 20,
                                color: isSelected ? activeColor : mutedColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Target Percentage Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CUSTOM TARGET',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: mutedColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _hasCustomTarget
                                      ? 'Override global target (${_targetPercentage.toInt()}%)'
                                      : 'Use global threshold (default)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: mutedColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            key: const Key('custom_target_toggle'),
                            value: _hasCustomTarget,
                            activeThumbColor: AppColors.inkGreen,
                            onChanged: (val) {
                              setState(() {
                                _hasCustomTarget = val;
                              });
                            },
                          ),
                        ],
                      ),

                      if (_hasCustomTarget) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: parseHexColor(_selectedColor),
                                  thumbColor: parseHexColor(_selectedColor),
                                  inactiveTrackColor: isDark ? AppColors.ruleDark : AppColors.ruleLight,
                                ),
                                child: Slider(
                                  key: const Key('target_slider'),
                                  value: _targetPercentage,
                                  min: 5.0,
                                  max: 100.0,
                                  divisions: 19,
                                  label: '${_targetPercentage.toInt()}%',
                                  onChanged: (val) {
                                    setState(() {
                                      _targetPercentage = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: parseHexColor(_selectedColor).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                '${_targetPercentage.toInt()}%',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: parseHexColor(_selectedColor),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons Row
                      Row(
                        children: [
                          if (widget.isEdit) ...[
                            AppButton.clear(
                              key: const Key('delete_subject_button'),
                              label: 'Delete',
                              isLoading: _isLoading,
                              onPressed: _handleDelete,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: AppButton.ghost(
                              key: const Key('cancel_subject_button'),
                              label: 'Cancel',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton.present(
                              key: const Key('save_subject_button'),
                              label: widget.isEdit ? 'Update' : 'Save',
                              isLoading: _isLoading,
                              onPressed: _handleSave,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to open SubjectDialog.
Future<T?> showSubjectDialog<T>(
  BuildContext context, {
  SubjectEntity? subject,
  VoidCallback? onSaved,
  VoidCallback? onDeleted,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Subject Dialog',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) => SubjectDialog(
      subject: subject,
      onSaved: onSaved,
      onDeleted: onDeleted,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return Transform.scale(
        scale: Tween<double>(begin: 0.9, end: 1.0).evaluate(curved),
        child: Opacity(
          opacity: anim1.value,
          child: child,
        ),
      );
    },
  );
}
