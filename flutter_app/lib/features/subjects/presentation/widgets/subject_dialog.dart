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
import 'subject_appearance_pickers.dart';
import 'subject_style_tokens.dart';

export '../../../../core/utils/color_utils.dart' show parseHexColor;
export 'subject_style_tokens.dart';

/// Modal dialog for adding, editing, or deleting a subject with color accent,
/// academic icon, and optional custom target percentage threshold.
///
/// Ownership: Subjects Feature
// ==========================================
// SUBJECTS - Subject Editor Dialog
// ==========================================
class SubjectDialog extends ConsumerStatefulWidget {
  final SubjectEntity? subject;
  final VoidCallback? onSaved;
  final VoidCallback? onDeleted;

  const SubjectDialog({super.key, this.subject, this.onSaved, this.onDeleted});

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

  // ==========================================
  // SUBJECT DIALOG - Save & Delete Workflows
  // ==========================================

  Future<void> _handleSave() async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      setState(() => _nameError = 'Subject name is required');
      return;
    }

    setState(() {
      _nameError = null;
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim();
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
        await ref
            .read(subjectControllerProvider.notifier)
            .updateSubject(updated);
      } else {
        await ref
            .read(subjectControllerProvider.notifier)
            .addSubject(
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
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(
              color: isDark
                  ? AppColors.glassBorderDark
                  : AppColors.glassBorderLight,
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
            style: GoogleFonts.outfit(color: mutedColor, fontSize: 14),
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
      setState(() => _isLoading = true);

      await ref
          .read(subjectControllerProvider.notifier)
          .deleteSubject(widget.subject!.id);
      widget.onDeleted?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // ==========================================
  // SUBJECT DIALOG - Form Layout
  // ==========================================

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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Title & Close Button
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

                      // Subject Name & Optional Code Fields
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
                      AppTextField(
                        key: const Key('subject_code_field'),
                        controller: _codeController,
                        label: 'SUBJECT CODE (OPTIONAL)',
                        hint: 'e.g. CS301',
                      ),
                      const SizedBox(height: 18),

                      // Color Swatches
                      SubjectColorPicker(
                        selectedColor: _selectedColor,
                        onColorSelected: (hex) =>
                            setState(() => _selectedColor = hex),
                      ),
                      const SizedBox(height: 18),

                      // Academic Icon Selector
                      SubjectIconPicker(
                        selectedIcon: _selectedIcon,
                        selectedColor: _selectedColor,
                        onIconSelected: (key) =>
                            setState(() => _selectedIcon = key),
                      ),
                      const SizedBox(height: 18),

                      // Custom Attendance Target Override
                      SubjectTargetSection(
                        hasCustomTarget: _hasCustomTarget,
                        targetPercentage: _targetPercentage,
                        selectedColor: _selectedColor,
                        onToggleChanged: (val) =>
                            setState(() => _hasCustomTarget = val),
                        onTargetChanged: (val) =>
                            setState(() => _targetPercentage = val),
                      ),
                      const SizedBox(height: 24),

                      // Footer Action Buttons
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

/// Opens [SubjectDialog] with a centered scale + fade transition.
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
    pageBuilder: (ctx, anim1, anim2) =>
        SubjectDialog(subject: subject, onSaved: onSaved, onDeleted: onDeleted),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return Transform.scale(
        scale: Tween<double>(begin: 0.9, end: 1.0).evaluate(curved),
        child: Opacity(opacity: anim1.value, child: child),
      );
    },
  );
}
