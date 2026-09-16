import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_text_field.dart';
import 'package:app_client/features/account/providers/account_provider.dart';
import 'package:app_client/features/account/widgets/kitchen_settings_section.dart';
import 'package:app_client/features/account/widgets/kitchen_settings_tile.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteState = ref.watch(deleteAccountNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: KitchenColors.paperLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _PageHeader(
              title: 'Plus',
              onBack: () => context.pop(),
            ),
            const SizedBox(height: KitchenSpacing.lg),
            KitchenSettingsSection(
              title: 'Sécurité',
              children: [
                KitchenSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Changer le mot de passe',
                  subtitle: 'Mettre à jour vos accès',
                  semanticLabel: 'Changer le mot de passe',
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
                KitchenSettingsTile(
                  icon: Icons.devices_outlined,
                  title: 'Sessions actives',
                  subtitle: 'Voir les appareils connectés',
                  semanticLabel: 'Voir les sessions actives',
                  onTap: () => context.push(AppRoutes.sessions),
                ),
              ],
            ),
            const SizedBox(height: KitchenSpacing.lg),
            KitchenSettingsSection(
              title: 'À propos',
              children: [
                KitchenSettingsTile(
                  icon: Icons.stars_outlined,
                  title: 'Programme fidélité',
                  subtitle: 'Points, récompenses et historique',
                  semanticLabel: 'Voir ma fidélité',
                  onTap: () => context.push(AppRoutes.loyalty),
                ),
                KitchenSettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Conditions générales',
                  semanticLabel: 'Voir les conditions générales',
                  onTap: () => context.push(AppRoutes.generalConditions),
                ),
                KitchenSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Politique de confidentialité',
                  semanticLabel: 'Voir la politique de confidentialité',
                  onTap: () => context.push(AppRoutes.privacy),
                ),
                KitchenSettingsTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'CGV',
                  semanticLabel: 'Voir les CGV',
                  onTap: () => context.push(AppRoutes.cgv),
                ),
                KitchenSettingsTile(
                  icon: Icons.rule_outlined,
                  title: 'CGU',
                  semanticLabel: 'Voir les CGU',
                  onTap: () => context.push(AppRoutes.cgu),
                ),
              ],
            ),
            const SizedBox(height: KitchenSpacing.lg),
            KitchenSettingsSection(
              title: 'Compte',
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
            const SizedBox(height: KitchenSpacing.lg),
            KitchenSettingsSection(
              title: 'Zone sensible',
              children: [
                KitchenSettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Supprimer mon compte',
                  subtitle: 'Désactive le compte après confirmation',
                  semanticLabel: 'Supprimer définitivement mon compte',
                  destructive: true,
                  enabled: !deleteState.isLoading,
                  showChevron: false,
                  trailing: deleteState.isLoading
                      ? const KitchenLoadingIndicator(
                          size: 26,
                          color: KitchenColors.terracotta,
                        )
                      : null,
                  onTap: deleteState.isLoading
                      ? null
                      : () => _startDeleteAccount(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Votre panier local reste disponible.'),
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
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  Future<void> _startDeleteAccount(BuildContext context, WidgetRef ref) async {
    final password = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeleteAccountSheet(),
    );
    if (password == null || password.isEmpty) return;

    HapticFeedback.mediumImpact();
    await ref
        .read(deleteAccountNotifierProvider.notifier)
        .deleteAccount(password: password);

    if (!context.mounted) return;
    final state = ref.read(deleteAccountNotifierProvider);
    state.whenOrNull(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte supprimé.')),
        );
        context.go(AppRoutes.home);
      },
      error: (e, _) {
        final message = e is AppException
            ? e.message
            : 'Impossible de supprimer le compte.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Retour',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: KitchenColors.espresso,
        ),
        const SizedBox(width: KitchenSpacing.xs),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KitchenTypography.title.copyWith(fontSize: 32),
          ),
        ),
      ],
    );
  }
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    final password = _passwordController.text;
    if (password.isEmpty) return;
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
        child: KitchenSurface(
          borderRadius: BorderRadius.circular(KitchenRadius.lg),
          padding: const EdgeInsets.all(KitchenSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Supprimer votre compte ?',
                style: KitchenTypography.title.copyWith(fontSize: 28),
              ),
              const SizedBox(height: KitchenSpacing.sm),
              Text(
                'Cette action désactive votre compte et révoque vos sessions. '
                'Saisissez votre mot de passe pour confirmer.',
                style: KitchenTypography.body.copyWith(
                  color: KitchenColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: KitchenSpacing.lg),
              KitchenTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                errorText: _submitted && _passwordController.text.isEmpty
                    ? 'Le mot de passe est requis'
                    : null,
                onSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  tooltip: _obscure
                      ? 'Afficher le mot de passe'
                      : 'Masquer le mot de passe',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: KitchenColors.espresso,
                  ),
                ),
              ),
              const SizedBox(height: KitchenSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: KitchenSpacing.sm),
                  Expanded(
                    child: KitchenEmbossedButton(
                      onPressed: _submit,
                      semanticLabel: 'Supprimer définitivement mon compte',
                      child: const Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
