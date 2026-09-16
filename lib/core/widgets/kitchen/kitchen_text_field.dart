import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

class KitchenTextField extends StatelessWidget {
  const KitchenTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.errorText,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: KitchenRadius.field,
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autofillHints: autofillHints,
      cursorColor: KitchenColors.cognac,
      style: const TextStyle(
        color: KitchenColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: KitchenColors.espresso),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: KitchenColors.paperLight.withValues(alpha: 0.78),
        labelStyle: const TextStyle(color: KitchenColors.textMuted),
        hintStyle: TextStyle(
          color: KitchenColors.textMuted.withValues(alpha: 0.72),
        ),
        errorStyle: const TextStyle(color: KitchenColors.terracotta),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        enabledBorder: border(KitchenColors.brown700.withValues(alpha: 0.18)),
        focusedBorder: border(KitchenColors.cognac, width: 1.5),
        errorBorder: border(KitchenColors.terracotta, width: 1.25),
        focusedErrorBorder: border(KitchenColors.terracotta, width: 1.5),
      ),
    );
  }
}
