import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';

/// Pressable "carved" charcoal button — dual light/dark shadow pair that
/// inverts (becomes an inset look) while pressed.
class NeumorphicButton extends StatefulWidget {
  const NeumorphicButton({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 16,
    this.padding,
  });

  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: KodMomeDesignPack.microDuration,
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _pressed
                ? [KodMomeDesignPack.charcoalDeep, KodMomeDesignPack.charcoal]
                : [KodMomeDesignPack.charcoal, KodMomeDesignPack.charcoalDeep],
          ),
          boxShadow: _pressed
              ? [
                  const BoxShadow(
                    color: KodMomeDesignPack.neuDarkShadow,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                    spreadRadius: -2,
                  ),
                ]
              : [
                  const BoxShadow(
                    color: KodMomeDesignPack.neuDarkShadow,
                    blurRadius: KodMomeDesignPack.neuBlur,
                    offset: KodMomeDesignPack.neuOffset,
                  ),
                  BoxShadow(
                    color: KodMomeDesignPack.neuLightShadow,
                    blurRadius: KodMomeDesignPack.neuBlur,
                    offset: -KodMomeDesignPack.neuOffset,
                  ),
                ],
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: KodMomeDesignPack.cream,
            fontWeight: FontWeight.w700,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Gold-outlined `TextFormField` decoration for auth forms — cream text on
/// a transparent/glass background, matching the medallion's gold ring.
InputDecoration kodMomeAuthFieldDecoration({
  required String label,
  String? errorText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? hintText,
}) {
  OutlineInputBorder border(Color color, {double width = 1.5}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    errorText: errorText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: false,
    labelStyle:
        TextStyle(color: KodMomeDesignPack.cream.withValues(alpha: 0.65)),
    hintStyle: TextStyle(color: KodMomeDesignPack.cream.withValues(alpha: 0.4)),
    errorStyle: const TextStyle(color: KodMomeDesignPack.redAccent),
    enabledBorder: border(KodMomeDesignPack.primary.withValues(alpha: 0.4)),
    focusedBorder: border(KodMomeDesignPack.primary, width: 2),
    errorBorder: border(KodMomeDesignPack.redAccent),
    focusedErrorBorder: border(KodMomeDesignPack.redAccent, width: 2),
  );
}

/// Inset "carved" field decoration (promo code input, quantity stepper) —
/// shadows point inward instead of outward.
BoxDecoration kodMomeNeumorphicFieldDecoration({double borderRadius = 14}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(borderRadius),
    color: KodMomeDesignPack.charcoalDeep,
    boxShadow: [
      BoxShadow(
        color: KodMomeDesignPack.neuDarkShadow,
        blurRadius: KodMomeDesignPack.neuBlur / 2,
        offset: KodMomeDesignPack.neuOffset / 3,
      ),
    ],
    border: Border.all(color: KodMomeDesignPack.neuLightShadow, width: 1),
  );
}
