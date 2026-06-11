import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class AppTextFormField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final int? maxLength;
  final String? initialValue;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;

  const AppTextFormField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.maxLength,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textAlign: textAlign,
      textCapitalization: textCapitalization,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      obscureText: obscureText,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      style: TextStyle(color: context.colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: context.colors.textSecondary,
          fontSize: 12,
        ),
        hintStyle: TextStyle(
          color: context.colors.textMuted,
          fontSize: 12,
        ),
        filled: true,
        fillColor: context.colors.bgCard,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: context.colors.textMuted) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon, color: context.colors.textMuted),
                onPressed: onSuffixIconPressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: context.colors.border.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: context.colors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: context.colors.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
