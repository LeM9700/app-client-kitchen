import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

class KitchenCheckoutStepHeader extends StatelessWidget {
  const KitchenCheckoutStepHeader({
    super.key,
    required this.activeIndex,
    this.labels = const ['Adresse', 'Recapitulatif', 'Paiement'],
  });

  final int activeIndex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Progression checkout, etape ${activeIndex + 1} sur ${labels.length}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KitchenSpacing.lg,
          KitchenSpacing.md,
          KitchenSpacing.lg,
          KitchenSpacing.sm,
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              Expanded(
                child: _StepPill(
                  index: i,
                  label: labels[i],
                  active: i == activeIndex,
                  complete: i < activeIndex,
                ),
              ),
              if (i < labels.length - 1)
                Container(
                  width: 22,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  color: (i < activeIndex
                          ? KitchenColors.cognac
                          : KitchenColors.brown700)
                      .withValues(alpha: i < activeIndex ? 0.56 : 0.18),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.index,
    required this.label,
    required this.active,
    required this.complete,
  });

  final int index;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color =
        active || complete ? KitchenColors.cognac : KitchenColors.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(
        horizontal: KitchenSpacing.xs,
        vertical: KitchenSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: active
            ? KitchenColors.cognac.withValues(alpha: 0.14)
            : KitchenColors.paperLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        border: Border.all(color: color.withValues(alpha: active ? 0.4 : 0.18)),
        boxShadow: active
            ? [
                BoxShadow(
                  color: KitchenColors.cognac.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active || complete
                    ? KitchenColors.cognac
                    : KitchenColors.flour,
                shape: BoxShape.circle,
              ),
              child: complete
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: KitchenColors.whiteWarm,
                    )
                  : Text(
                      '${index + 1}',
                      style: KitchenTypography.label.copyWith(
                        color: active
                            ? KitchenColors.whiteWarm
                            : KitchenColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
            ),
            const SizedBox(width: KitchenSpacing.xs),
            Text(
              label,
              style: KitchenTypography.label.copyWith(
                color: active ? KitchenColors.espresso : color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
