import 'package:flutter/material.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/theme/app_colors.dart';

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
    final theme = Theme.of(context);
    final document = _document(type);

    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: SafeArea(
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(document.icon, color: AppColors.brandRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Contenu provisoire a valider juridiquement avant publication.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(document.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                document.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey700,
                ),
              ),
              if (document.officialUrl != null &&
                  document.officialUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Document officiel configure',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  document.officialUrl!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ...document.sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(section.body, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

_LegalDocument _document(LegalDocumentType type) {
  return switch (type) {
    LegalDocumentType.privacy => const _LegalDocument(
        title: 'Confidentialite',
        subtitle:
            'Base de politique de confidentialite pour l application client O Pizza.',
        icon: Icons.privacy_tip_outlined,
        officialUrl: Env.privacyPolicyUrl,
        sections: [
          _LegalSection(
            'Donnees traitees',
            'Compte client, commandes, adresses de livraison, preferences et informations techniques necessaires au fonctionnement du service.',
          ),
          _LegalSection(
            'Paiement',
            'Les donnees de paiement sont traitees par le prestataire de paiement configure. L application ne doit pas stocker les numeros de carte.',
          ),
          _LegalSection(
            'Droits utilisateur',
            'Prevoir les modalites d acces, rectification, suppression et opposition selon la reglementation applicable.',
          ),
        ],
      ),
    LegalDocumentType.generalConditions => const _LegalDocument(
        title: 'Conditions generales',
        subtitle:
            'Structure de conditions generales pour l experience de commande en ligne.',
        icon: Icons.description_outlined,
        sections: [
          _LegalSection(
            'Objet',
            'Ces conditions encadrent l utilisation de l application de commande du restaurant.',
          ),
          _LegalSection(
            'Commande',
            'Le client selectionne les produits, verifie le panier, choisit un mode de retrait ou livraison puis valide sa commande.',
          ),
          _LegalSection(
            'Disponibilite',
            'Les produits et horaires peuvent varier selon le restaurant, le stock et les contraintes operationnelles.',
          ),
        ],
      ),
    LegalDocumentType.cgv => const _LegalDocument(
        title: 'CGV',
        subtitle:
            'Structure provisoire de conditions generales de vente pour commandes restaurant.',
        icon: Icons.receipt_long_outlined,
        sections: [
          _LegalSection(
            'Prix',
            'Les prix sont indiques toutes taxes comprises si applicable. Les frais de livraison sont confirmes au checkout.',
          ),
          _LegalSection(
            'Paiement',
            'Le paiement est effectue via le prestataire configure. Une commande peut etre refusee en cas d echec ou d annulation du paiement.',
          ),
          _LegalSection(
            'Annulation et remboursement',
            'Les regles d annulation, de remboursement et de litige doivent etre completees par le restaurant et validees juridiquement.',
          ),
        ],
      ),
    LegalDocumentType.cgu => const _LegalDocument(
        title: 'CGU',
        subtitle:
            'Structure provisoire de conditions generales d utilisation de l application.',
        icon: Icons.rule_outlined,
        sections: [
          _LegalSection(
            'Acces au service',
            'Le catalogue est consultable publiquement. Certaines actions, comme commander ou consulter la fidelite, peuvent necessiter un compte.',
          ),
          _LegalSection(
            'Compte utilisateur',
            'L utilisateur est responsable de la confidentialite de ses identifiants et des informations transmises.',
          ),
          _LegalSection(
            'Usage acceptable',
            'Toute utilisation frauduleuse, abusive ou perturbant le service peut entrainer une suspension d acces.',
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
