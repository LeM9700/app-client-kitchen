import 'package:flutter/material.dart';

import 'package:app_client/features/catalog/models/product.dart';

/// Tuile d'un extra/supplément dans la fiche produit.
///
/// [isSelected] + [onChanged] : state géré par le parent.
/// Indisponible → désactivé visuellement, non cliquable.
class ExtraItemTile extends StatelessWidget {
  const ExtraItemTile({
    super.key,
    required this.extra,
    required this.isSelected,
    required this.onChanged,
  });

  final ProductExtra extra;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = !extra.available;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: !isDisabled,
      title: Text(
        extra.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDisabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${extra.price.toStringAsFixed(2)} €',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDisabled
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Checkbox(
            value: isSelected,
            onChanged: isDisabled ? null : (v) => onChanged(v ?? false),
          ),
        ],
      ),
      onTap: isDisabled ? null : () => onChanged(!isSelected),
    );
  }
}
