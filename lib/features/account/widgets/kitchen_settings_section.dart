import 'package:flutter/material.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

class KitchenSettingsSection extends StatelessWidget {
  const KitchenSettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: KitchenSpacing.xs,
              bottom: KitchenSpacing.sm,
            ),
            child: Text(
              title,
              style: KitchenTypography.label.copyWith(
                color: KitchenColors.brown700,
                fontSize: 13,
              ),
            ),
          ),
          ..._spaced(children),
        ],
      ),
    );
  }

  List<Widget> _spaced(List<Widget> widgets) {
    final spaced = <Widget>[];
    for (var i = 0; i < widgets.length; i += 1) {
      if (i > 0) {
        spaced.add(const SizedBox(height: KitchenSpacing.sm));
      }
      spaced.add(widgets[i]);
    }
    return spaced;
  }
}
