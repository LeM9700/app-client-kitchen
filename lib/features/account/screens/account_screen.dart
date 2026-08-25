import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/widgets/empty_state.dart';
import 'package:app_client/features/auth/models/user.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';

/// Écran "Mon compte" — hub de gestion de l'identité utilisateur
/// (plan-18 : profil, sessions actives, mot de passe, déconnexion).
///
/// Deux états distincts, jamais mélangés :
/// - non connecté → invitation à se connecter (le catalogue reste 100%
///   public, voir `app_router.dart` : seul `/account` requiert l'auth) ;
/// - connecté → hub complet.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(accessTokenProvider) != null;

    if (!isAuthenticated) {
      return const _UnauthenticatedAccountScreen();
    }

    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: ListView(
        children: [
          _UserHeader(user: user),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Mes commandes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.orders),
          ),
          ListTile(
            leading: const Icon(Icons.stars_outlined),
            title: const Text('Programme fidélité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.loyalty),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Modifier le profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.profileEdit),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.changePassword),
          ),
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('Sessions actives'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.sessions),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Confidentialite'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Conditions generales'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.generalConditions),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('CGV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.cgv),
          ),
          ListTile(
            leading: const Icon(Icons.rule_outlined),
            title: const Text('CGU'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.cgu),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFB71C1C)),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(color: Color(0xFFB71C1C)),
            ),
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // [Décision d'architecture n°3, plan-18] AuthNotifier.logout() révoque
      // côté serveur ET efface les tokens locaux même si l'appel échoue —
      // rien à gérer ici. Le router guard (`app_router.dart`) détecte
      // `accessTokenProvider == null` et redirige automatiquement.
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// En-tête utilisateur
// ─────────────────────────────────────────────────────────────────────────

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = user?.fullName?.trim();
    final initial = (displayName != null && displayName.isNotEmpty)
        ? displayName[0].toUpperCase()
        : (user?.email.isNotEmpty == true ? user!.email[0].toUpperCase() : '?');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              initial,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (displayName != null && displayName.isNotEmpty)
                      ? displayName
                      : (user?.email ?? ''),
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user!.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!user!.emailVerified) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Email non vérifié',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// État non connecté
// ─────────────────────────────────────────────────────────────────────────

class _UnauthenticatedAccountScreen extends StatelessWidget {
  const _UnauthenticatedAccountScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: EmptyState(
        title: 'Vous n\'êtes pas connecté',
        subtitle: 'Connectez-vous pour accéder à vos commandes, votre '
            'fidélité et vos informations personnelles.',
        icon: Icons.person_outline,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push(AppRoutes.register),
              child: const Text('Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }
}
