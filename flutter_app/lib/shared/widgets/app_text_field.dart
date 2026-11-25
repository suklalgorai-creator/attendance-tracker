import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_typography.dart';

/// Text field matching React `.field` and `.field input` styles
/// Features amber focus halo, red error halo, and Outfit typography.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? minLines;
  final TextAlign textAlign;

  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.hintText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.textAlign = TextAlign.start,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode).removeListener(
        _handleFocusChange,
      );
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _effectiveFocusNode.hasFocus) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final effectiveHint = widget.hint ?? widget.hintText;

    Color borderColor;
    List<BoxShadow>? shadows;
    Color backgroundColor;

    if (hasError) {
      borderColor = AppColors.penRed;
      shadows = [
        const BoxShadow(
          color: AppColors.penRedSoft,
          spreadRadius: 4.0,
          blurRadius: 0.0,
        ),
      ];
      backgroundColor = isDark
          ? AppColors.surfaceSolidDark
          : AppColors.surfaceSolidLight;
    } else if (_isFocused) {
      borderColor = AppColors.amber;
      shadows = [
        const BoxShadow(
          color: AppColors.amberSoft,
          spreadRadius: 4.0,
          blurRadius: 0.0,
        ),
      ];
      backgroundColor = isDark
          ? AppColors.surfaceSolidDark
          : AppColors.surfaceSolidLight;
    } else {
      borderColor = isDark
          ? AppColors.ruleBrightDark
          : AppColors.ruleBrightLight;
      shadows = null;
      backgroundColor = isDark ? AppColors.inputBgDark : AppColors.inputBgLight;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              widget.label!,
              style: AppTypography.inputLabel(mutedColor),
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.card), // 16px
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: shadows,
          ),
          child: TextFormField(
            controller: widget.controller,
            initialValue: widget.controller == null
                ? widget.initialValue
                : null,
            focusNode: _effectiveFocusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            style: AppTypography.inputText(paperColor),
            cursorColor: AppColors.amber,
            decoration: InputDecoration(
              isDense: true,
              hintText: effectiveHint,
              hintStyle: AppTypography.inputHint(
                mutedColor.withValues(alpha: 0.6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 13.0,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
            ),
          ),
        ),
        if (hasError) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 6.0),
            child: Text(
              widget.errorText!,
              style: AppTypography.helperText(AppColors.penRed),
            ),
          ),
        ] else if (widget.helperText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 6.0),
            child: Text(
              widget.helperText!,
              style: AppTypography.helperText(mutedColor),
            ),
          ),
        ],
      ],
    );
  }
}
