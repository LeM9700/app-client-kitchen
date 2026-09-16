import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/account/widgets/kitchen_account_header.dart';
import 'package:app_client/features/account/widgets/kitchen_settings_section.dart';
import 'package:app_client/features/account/widgets/kitchen_settings_tile.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';

/// Espace compte client.
///
/// La logique d'auth reste inchangée : l'écran lit les providers existants et
/// délègue logout/profile/routes aux flows déjà câblés.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(accessTokenProvider) != null;

    if (!isAuthenticated) {
      return const _UnauthenticatedAccountScreen();
    }

    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: KitchenColors.paperLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
          children: [
            Text(
              'Mon compte',
              style: KitchenTypography.title.copyWith(fontSize: 34),
            ),
            const SizedBox(height: KitchenSpacing.md),
            KitchenAccountHeader(
              user: user,
              onEdit: () => context.push(AppRoutes.profileEdit),
            ),
            const SizedBox(height: KitchenSpacing.xl),
            KitchenSettingsSection(
              title: 'Mon espace',
              children: [
                KitchenSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Mes informations',
                  subtitle: 'Nom, téléphone et email',
                  semanticLabel: 'Modifier mes informations',
                  onTap: () => context.push(AppRoutes.profileEdit),
                ),
                KitchenSettingsTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Mes commandes',
                  subtitle: 'Historique et suivi',
                  semanticLabel: 'Voir mes commandes',
                  onTap: () => context.push(AppRoutes.orders),
                ),
                KitchenSettingsTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'Mes favoris',
                  subtitle: 'Pizzas sauvegardees',
                  semanticLabel: 'Voir mes favoris',
                  onTap: () => context.push(AppRoutes.favorites),
                ),
                KitchenSettingsTile(
                  icon: Icons.stars_outlined,
                  title: 'Ma fidélité',
                  subtitle: 'Points, récompenses et mouvements',
                  semanticLabel: 'Voir ma fidélité',
                  onTap: () => context.push(AppRoutes.loyalty),
                ),
                KitchenSettingsTile(
                  icon: Icons.tune_rounded,
                  title: 'Plus / Paramètres',
                  subtitle: 'Sécurité, légal et compte',
                  semanticLabel: 'Ouvrir les paramètres',
                  onTap: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
            const SizedBox(height: KitchenSpacing.xl),
            KitchenSettingsSection(
              title: 'Session',
              children: [
                KitchenSettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Se déconnecter',
                  subtitle: 'Fermer la session sur cet appareil',
                  semanticLabel: 'Se déconnecter',
                  destructive: true,
                  enabled: !authState.isLoading,
                  showChevron: false,
                  trailing: authState.isLoading
                      ? const KitchenLoadingIndicator(
                          size: 26,
                          color: KitchenColors.terracotta,
                        )
                      : null,
                  onTap: authState.isLoading
                      ? null
                      : () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Votre session sera fermée sur cet appareil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

class _UnauthenticatedAccountScreen extends StatelessWidget {
  const _UnauthenticatedAccountScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitchenColors.paperLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: KitchenSurface(
              padding: const EdgeInsets.all(KitchenSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Votre carnet Kitchen',
                    textAlign: TextAlign.center,
                    style: KitchenTypography.title.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: KitchenSpacing.sm),
                  Text(
                    'Connectez-vous pour retrouver vos commandes, vos points '
                    'fidélité et vos informations.',
                    textAlign: TextAlign.center,
                    style: KitchenTypography.body.copyWith(
                      color: KitchenColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: KitchenSpacing.lg),
                  KitchenEmbossedButton(
                    onPressed: () => context.push(AppRoutes.login),
                    semanticLabel: 'Se connecter',
                    child: const Text('Se connecter'),
                  ),
                  const SizedBox(height: KitchenSpacing.sm),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text('Créer un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
