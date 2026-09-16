import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_text_field.dart';
import 'package:app_client/features/account/providers/account_provider.dart';

/// Changement de mot de passe — `POST /auth/change-password`.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _fieldErrors = {});

    await ref.read(changePasswordNotifierProvider.notifier).changePassword(
          currentPassword: _currentPasswordCtrl.text,
          newPassword: _newPasswordCtrl.text,
        );

    if (!mounted) return;

    final state = ref.read(changePasswordNotifierProvider);
    state.whenOrNull(
      error: (e, _) {
        if (e is ValidationException) {
          setState(() => _fieldErrors = e.fieldErrors);
          if (e.fieldErrors.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message)),
            );
          }
        } else if (e is AuthException) {
          setState(() => _fieldErrors = {'current_password': e.message});
        } else if (e is AppException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      },
      data: (_) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mot de passe changé. Vos autres appareils ont été déconnectés.',
            ),
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(changePasswordNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: KitchenColors.paperLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Retour',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: KitchenColors.espresso,
                ),
                const SizedBox(width: KitchenSpacing.xs),
                Expanded(
                  child: Text(
                    'Mot de passe',
                    style: KitchenTypography.title.copyWith(fontSize: 31),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KitchenSpacing.lg),
            KitchenSurface(
              padding: const EdgeInsets.all(KitchenSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sécurité du compte',
                      style: KitchenTypography.label.copyWith(
                        color: KitchenColors.brown700,
                      ),
                    ),
                    const SizedBox(height: KitchenSpacing.md),
                    KitchenTextField(
                      controller: _currentPasswordCtrl,
                      label: 'Mot de passe actuel',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureCurrent,
                      textInputAction: TextInputAction.next,
                      errorText: _fieldErrors['current_password'],
                      autofillHints: const [AutofillHints.password],
                      suffixIcon: _VisibilityButton(
                        obscure: _obscureCurrent,
                        onPressed: () => setState(
                          () => _obscureCurrent = !_obscureCurrent,
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Le mot de passe actuel est requis'
                          : null,
                    ),
                    const SizedBox(height: KitchenSpacing.md),
                    KitchenTextField(
                      controller: _newPasswordCtrl,
                      label: 'Nouveau mot de passe',
                      prefixIcon: Icons.key_outlined,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      errorText: _fieldErrors['new_password'],
                      autofillHints: const [AutofillHints.newPassword],
                      suffixIcon: _VisibilityButton(
                        obscure: _obscureNew,
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      validator: (v) => (v == null || v.length < 8)
                          ? '8 caractères minimum'
                          : null,
                    ),
                    const SizedBox(height: KitchenSpacing.xs),
                    Text(
                      '8 caractères min., 1 majuscule, 1 chiffre, '
                      '1 caractère spécial (!@#\$%^&*)',
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: KitchenSpacing.md),
                    KitchenTextField(
                      controller: _confirmPasswordCtrl,
                      label: 'Confirmer le nouveau mot de passe',
                      prefixIcon: Icons.verified_user_outlined,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.newPassword],
                      suffixIcon: _VisibilityButton(
                        obscure: _obscureConfirm,
                        onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                      ),
                      validator: (v) => (v != _newPasswordCtrl.text)
                          ? 'Les mots de passe ne correspondent pas'
                          : null,
                    ),
                    const SizedBox(height: KitchenSpacing.lg),
                    KitchenEmbossedButton(
                      onPressed: isLoading ? null : _submit,
                      isLoading: isLoading,
                      semanticLabel: 'Changer le mot de passe',
                      child: const Text('Changer le mot de passe'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({
    required this.obscure,
    required this.onPressed,
  });

  final bool obscure;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscure ? 'Afficher' : 'Masquer',
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: KitchenColors.espresso,
      ),
    );
  }
}
