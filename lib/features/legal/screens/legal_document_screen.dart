import 'package:flutter/material.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';

enum LegalDocumentType {
  privacy,
  generalConditions,
  cgv,
  cgu,
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final document = _document(type);

    return Scaffold(
      backgroundColor: KitchenColors.paperLight,
      body: SafeArea(
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Retour',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: KitchenColors.espresso,
                  ),
                  const SizedBox(width: KitchenSpacing.xs),
                  Expanded(
                    child: Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: KitchenTypography.title.copyWith(fontSize: 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KitchenSpacing.lg),
              KitchenSurface(
                elevation: KitchenElevation.flat,
                borderRadius: BorderRadius.circular(KitchenRadius.lg),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegalNotice(icon: document.icon),
                    const SizedBox(height: KitchenSpacing.lg),
                    Text(
                      document.title,
                      style: KitchenTypography.title.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: KitchenSpacing.xs),
                    Text(
                      document.subtitle,
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                      ),
                    ),
                    if (document.officialUrl != null &&
                        document.officialUrl!.trim().isNotEmpty) ...[
                      const SizedBox(height: KitchenSpacing.lg),
                      Text(
                        'Document officiel configuré',
                        style: KitchenTypography.label.copyWith(
                          color: KitchenColors.brown700,
                        ),
                      ),
                      const SizedBox(height: KitchenSpacing.xs),
                      SelectableText(
                        document.officialUrl!,
                        style: KitchenTypography.body.copyWith(
                          color: KitchenColors.cognac,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: KitchenSpacing.xl),
                    for (var i = 0; i < document.sections.length; i += 1) ...[
                      _LegalSectionView(
                        index: i + 1,
                        section: document.sections[i],
                      ),
                      if (i < document.sections.length - 1)
                        const SizedBox(height: KitchenSpacing.lg),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalNotice extends StatelessWidget {
  const _LegalNotice({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KitchenSpacing.md),
      decoration: BoxDecoration(
        color: KitchenColors.terracotta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(KitchenRadius.md),
        border: Border.all(
          color: KitchenColors.terracotta.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KitchenColors.terracotta),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Text(
              'Contenu provisoire à valider juridiquement avant publication.',
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.espresso,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSectionView extends StatelessWidget {
  const _LegalSectionView({
    required this.index,
    required this.section,
  });

  final int index;
  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$index. ${section.title}',
          style: KitchenTypography.label.copyWith(
            color: KitchenColors.espresso,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: KitchenSpacing.xs),
        Text(
          section.body,
          style: KitchenTypography.body.copyWith(
            color: KitchenColors.textPrimary,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

_LegalDocument _document(LegalDocumentType type) {
  return switch (type) {
    LegalDocumentType.privacy => const _LegalDocument(
        title: 'Confidentialité',
        subtitle:
            'Base de politique de confidentialité pour l’application client O Pizza.',
        icon: Icons.privacy_tip_outlined,
        officialUrl: Env.privacyPolicyUrl,
        sections: [
          _LegalSection(
            'Données traitées',
            'Compte client, commandes, adresses de livraison, préférences et informations techniques nécessaires au fonctionnement du service.',
          ),
          _LegalSection(
            'Paiement',
            'Les données de paiement sont traitées par le prestataire de paiement configuré. L’application ne doit pas stocker les numéros de carte.',
          ),
          _LegalSection(
            'Droits utilisateur',
            'Prévoir les modalités d’accès, rectification, suppression et opposition selon la réglementation applicable.',
          ),
        ],
      ),
    LegalDocumentType.generalConditions => const _LegalDocument(
        title: 'Conditions générales',
        subtitle:
            'Structure de conditions générales pour l’expérience de commande en ligne.',
        icon: Icons.description_outlined,
        officialUrl: Env.termsOfUseUrl,
        sections: [
          _LegalSection(
            'Objet',
            'Ces conditions encadrent l’utilisation de l’application de commande du restaurant.',
          ),
          _LegalSection(
            'Commande',
            'Le client sélectionne les produits, vérifie le panier, choisit un mode de retrait ou livraison puis valide sa commande.',
          ),
          _LegalSection(
            'Disponibilité',
            'Les produits et horaires peuvent varier selon le restaurant, le stock et les contraintes opérationnelles.',
          ),
        ],
      ),
    LegalDocumentType.cgv => const _LegalDocument(
        title: 'CGV',
        subtitle:
            'Structure provisoire de conditions générales de vente pour commandes restaurant.',
        icon: Icons.receipt_long_outlined,
        sections: [
          _LegalSection(
            'Prix',
            'Les prix sont indiqués toutes taxes comprises si applicable. Les frais de livraison sont confirmés au checkout.',
          ),
          _LegalSection(
            'Paiement',
            'Le paiement est effectué via le prestataire configuré. Une commande peut être refusée en cas d’échec ou d’annulation du paiement.',
          ),
          _LegalSection(
            'Annulation et remboursement',
            'Les règles d’annulation, de remboursement et de litige doivent être complétées par le restaurant et validées juridiquement.',
          ),
        ],
      ),
    LegalDocumentType.cgu => const _LegalDocument(
        title: 'CGU',
        subtitle:
            'Structure provisoire de conditions générales d’utilisation de l’application.',
        icon: Icons.rule_outlined,
        officialUrl: Env.termsOfUseUrl,
        sections: [
          _LegalSection(
            'Accès au service',
            'Le catalogue est consultable publiquement. Certaines actions, comme commander ou consulter la fidélité, peuvent nécessiter un compte.',
          ),
          _LegalSection(
            'Compte utilisateur',
            'L’utilisateur est responsable de la confidentialité de ses identifiants et des informations transmises.',
          ),
          _LegalSection(
            'Usage acceptable',
            'Toute utilisation frauduleuse, abusive ou perturbant le service peut entraîner une suspension d’accès.',
          ),
        ],
      ),
  };
}

class _LegalDocument {
  const _LegalDocument({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
    this.officialUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<_LegalSection> sections;
  final String? officialUrl;
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}
