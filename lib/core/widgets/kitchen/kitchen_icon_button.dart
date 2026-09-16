import 'package:flutter/material.dart';

import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';

class KitchenIconButton extends StatelessWidget {
  const KitchenIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return KitchenEmbossedButton(
      onPressed: onPressed,
      isLoading: isLoading,
      semanticLabel: semanticLabel,
      shape: BoxShape.circle,
      padding: const EdgeInsets.all(14),
      child: Icon(icon),
    );
  }
}
