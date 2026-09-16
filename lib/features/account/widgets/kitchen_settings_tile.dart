import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_motion.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_shadows.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

class KitchenSettingsTile extends StatefulWidget {
  const KitchenSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.destructive = false,
    this.enabled = true,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool destructive;
  final bool enabled;
  final bool showChevron;

  @override
  State<KitchenSettingsTile> createState() => _KitchenSettingsTileState();
}

class _KitchenSettingsTileState extends State<KitchenSettingsTile> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_interactive) return;
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.destructive ? KitchenColors.terracotta : KitchenColors.espresso;
    final muted = widget.destructive
        ? KitchenColors.terracotta.withValues(alpha: 0.74)
        : KitchenColors.textMuted;
    final disabled = !widget.enabled;

    return Semantics(
      button: _interactive,
      enabled: widget.enabled,
      label: widget.semanticLabel ?? widget.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _handleTap,
        child: AnimatedScale(
          duration: KitchenMotion.fast,
          curve: KitchenMotion.pressCurve,
          scale: _pressed ? 0.985 : 1,
          child: AnimatedContainer(
            duration: KitchenMotion.fast,
            curve: KitchenMotion.pressCurve,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: KitchenSpacing.md,
              vertical: KitchenSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: KitchenRadius.card,
              color: disabled
                  ? KitchenColors.flour.withValues(alpha: 0.52)
                  : KitchenColors.surface,
              gradient: disabled ? null : KitchenGradients.paper,
              border: Border.all(
                color: widget.destructive
                    ? KitchenColors.terracotta.withValues(alpha: 0.18)
                    : KitchenColors.whiteWarm.withValues(alpha: 0.72),
              ),
              boxShadow: disabled
                  ? const []
                  : _pressed
                      ? KitchenShadows.pressed
                      : KitchenShadows.soft,
            ),
            child: Row(
              children: [
                _TileIcon(icon: widget.icon, color: foreground),
                const SizedBox(width: KitchenSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: KitchenTypography.label.copyWith(
                          color:
                              disabled ? KitchenColors.textMuted : foreground,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.subtitle != null &&
                          widget.subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: KitchenTypography.body.copyWith(
                            color: disabled ? KitchenColors.textMuted : muted,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: KitchenSpacing.sm),
                  widget.trailing!,
                ] else if (widget.showChevron && widget.onTap != null) ...[
                  const SizedBox(width: KitchenSpacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: muted,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KitchenColors.paperLight.withValues(alpha: 0.84),
        boxShadow: const [
          BoxShadow(
            color: Color(0x222D1B13),
            blurRadius: 10,
            offset: Offset(3, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0xCCFFF8EE),
            blurRadius: 8,
            offset: Offset(-3, -3),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
