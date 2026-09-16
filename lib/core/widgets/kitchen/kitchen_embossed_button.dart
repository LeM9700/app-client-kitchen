import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_client/core/theme/kitchen_motion.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_shadows.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';

class KitchenEmbossedButton extends StatefulWidget {
  const KitchenEmbossedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.enabled = true,
    this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.shape = BoxShape.rectangle,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool enabled;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final BoxShape shape;

  @override
  State<KitchenEmbossedButton> createState() => _KitchenEmbossedButtonState();
}

class _KitchenEmbossedButtonState extends State<KitchenEmbossedButton> {
  bool _pressed = false;

  bool get _canPress =>
      widget.enabled && !widget.isLoading && widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_canPress || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_canPress) return;
    HapticFeedback.selectionClick();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !_canPress;
    final borderRadius =
        widget.shape == BoxShape.circle ? null : KitchenRadius.button;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _handleTap,
        child: AnimatedScale(
          duration: KitchenMotion.fast,
          curve: KitchenMotion.pressCurve,
          scale: _pressed ? 0.975 : 1,
          child: AnimatedContainer(
            duration: KitchenMotion.fast,
            curve: KitchenMotion.pressCurve,
            transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0, 0),
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: widget.padding,
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: borderRadius,
              gradient: disabled ? null : KitchenGradients.cognac,
              color: disabled ? KitchenColors.flour : null,
              border: Border.all(
                color: disabled
                    ? KitchenColors.textMuted.withValues(alpha: 0.24)
                    : KitchenColors.whiteWarm.withValues(alpha: 0.24),
              ),
              boxShadow: disabled
                  ? const []
                  : _pressed
                      ? KitchenShadows.pressed
                      : KitchenShadows.raised,
            ),
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              style: TextStyle(
                color: disabled
                    ? KitchenColors.textMuted
                    : KitchenColors.whiteWarm,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: disabled
                      ? KitchenColors.textMuted
                      : KitchenColors.whiteWarm,
                  size: 22,
                ),
                child: widget.isLoading
                    ? const Center(
                        child: KitchenLoadingIndicator(
                          size: 30,
                          color: KitchenColors.whiteWarm,
                        ),
                      )
                    : widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
