import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';

enum KitchenDeliveryStatusType { idle, checking, valid, invalid, error }

class KitchenDeliveryStatus extends StatelessWidget {
  const KitchenDeliveryStatus({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
  });

  final KitchenDeliveryStatusType type;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      KitchenDeliveryStatusType.valid => KitchenColors.olive,
      KitchenDeliveryStatusType.invalid ||
      KitchenDeliveryStatusType.error =>
        KitchenColors.terracotta,
      KitchenDeliveryStatusType.checking => KitchenColors.cognac,
      KitchenDeliveryStatusType.idle => KitchenColors.textMuted,
    };
    final icon = switch (type) {
      KitchenDeliveryStatusType.valid => Icons.check_circle_outline,
      KitchenDeliveryStatusType.invalid => Icons.report_gmailerrorred_outlined,
      KitchenDeliveryStatusType.error => Icons.wifi_off_rounded,
      KitchenDeliveryStatusType.checking => Icons.radar_rounded,
      KitchenDeliveryStatusType.idle => Icons.location_on_outlined,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(KitchenSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KitchenRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: type == KitchenDeliveryStatusType.checking
                ? KitchenLoadingIndicator(color: color, size: 28)
                : Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KitchenTypography.label.copyWith(color: color),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: KitchenSpacing.xxs),
                  Text(
                    subtitle!,
                    style: KitchenTypography.body.copyWith(
                      color: KitchenColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
