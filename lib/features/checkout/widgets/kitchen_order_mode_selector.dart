import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';

class KitchenOrderModeSelector extends StatelessWidget {
  const KitchenOrderModeSelector({
    super.key,
    required this.selectedMode,
    required this.onSelected,
  });

  final DeliveryMode selectedMode;
  final ValueChanged<DeliveryMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeSegment(
            icon: Icons.delivery_dining_outlined,
            title: 'Livraison',
            subtitle: 'A domicile',
            selected: selectedMode == DeliveryMode.delivery,
            onTap: () => onSelected(DeliveryMode.delivery),
          ),
        ),
        const SizedBox(width: KitchenSpacing.sm),
        Expanded(
          child: _ModeSegment(
            icon: Icons.storefront_outlined,
            title: 'Retrait',
            subtitle: 'Retrait en boutique',
            selected: selectedMode == DeliveryMode.pickup,
            onTap: () => onSelected(DeliveryMode.pickup),
          ),
        ),
      ],
    );
  }
}

class _ModeSegment extends StatefulWidget {
  const _ModeSegment({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ModeSegment> createState() => _ModeSegmentState();
}

class _ModeSegmentState extends State<_ModeSegment> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.selected ? KitchenColors.cognac : KitchenColors.textMuted;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.selected
          ? '${widget.title}, selectionne'
          : 'Choisir ${widget.title}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _pressed ? 0.985 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(KitchenSpacing.md),
            decoration: BoxDecoration(
              gradient: widget.selected
                  ? KitchenGradients.cognac
                  : KitchenGradients.paper,
              color: widget.selected ? null : KitchenColors.surface,
              borderRadius: BorderRadius.circular(KitchenRadius.lg),
              border: Border.all(
                color: widget.selected
                    ? KitchenColors.whiteWarm.withValues(alpha: 0.3)
                    : KitchenColors.brown700.withValues(alpha: 0.14),
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: KitchenColors.cognac.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.icon,
                  color: widget.selected ? KitchenColors.whiteWarm : color,
                  size: 28,
                ),
                const SizedBox(height: KitchenSpacing.lg),
                Text(
                  widget.title,
                  style: KitchenTypography.label.copyWith(
                    color: widget.selected
                        ? KitchenColors.whiteWarm
                        : KitchenColors.espresso,
                  ),
                ),
                const SizedBox(height: KitchenSpacing.xxs),
                Text(
                  widget.subtitle,
                  style: KitchenTypography.body.copyWith(
                    color: widget.selected
                        ? KitchenColors.whiteWarm.withValues(alpha: 0.82)
                        : KitchenColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
