import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/features/catalog/providers/display_currency_provider.dart';

/// Bouton du header d'accueil pour choisir une devise d'affichage
/// indicative — même structure que [NotificationBellButton] (icône +
/// badge). Purement un raccourci d'affichage, n'affecte jamais la devise
/// réellement facturée (verrouillée côté tenant, voir TenantConfig.currency).
class DisplayCurrencyButton extends ConsumerWidget {
  const DisplayCurrencyButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(displayCurrencyProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        KitchenEmbossedButton(
          onPressed: () => _openPicker(context, ref, selected),
          shape: BoxShape.circle,
          padding: EdgeInsets.zero,
          semanticLabel: 'Devise d\'affichage indicative',
          child: const Icon(Icons.currency_exchange_rounded, size: 20),
        ),
        if (selected != null)
          Positioned(
            right: -6,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 19),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: const BoxDecoration(
                color: KitchenColors.cognac,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              alignment: Alignment.center,
              child: Text(
                selected,
                style: KitchenTypography.label.copyWith(
                  color: KitchenColors.whiteWarm,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openPicker(BuildContext context, WidgetRef ref, String? selected) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Sinon la feuille se dimensionne sur la moitié de l'écran et son
      // contenu (titre + sous-titre + 6 lignes) déborde sur petit écran /
      // orientation paysage — isScrollControlled la laisse suivre son
      // contenu (jusqu'à l'écran entier), le SingleChildScrollView du
      // contenu absorbe le reste si besoin.
      isScrollControlled: true,
      builder: (context) => _DisplayCurrencySheet(selected: selected),
    );
  }
}

class _DisplayCurrencySheet extends ConsumerWidget {
  const _DisplayCurrencySheet({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Prix indicatif dans votre devise',
                style: KitchenTypography.title,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Conversion informative uniquement — le paiement reste '
                'toujours dans la devise du restaurant.',
                style: TextStyle(color: KitchenColors.textMuted, fontSize: 13),
              ),
            ),
            ListTile(
              title: const Text('Aucune conversion'),
              trailing: selected == null
                  ? const Icon(Icons.check, color: KitchenColors.cognac)
                  : null,
              onTap: () => _select(context, ref, null),
            ),
            for (final code in kSupportedDisplayCurrencies)
              ListTile(
                title: Text(code),
                trailing: selected == code
                    ? const Icon(Icons.check, color: KitchenColors.cognac)
                    : null,
                onTap: () => _select(context, ref, code),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, String? code) {
    ref.read(displayCurrencyProvider.notifier).select(code);
    Navigator.of(context).pop();
  }
}
