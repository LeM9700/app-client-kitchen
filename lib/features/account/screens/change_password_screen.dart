import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/account/providers/account_provider.dart';

/// Changement de mot de passe — `POST /auth/change-password`
/// (plan-18, Décision d'architecture n°2 : ancien mot de passe requis pour
/// se protéger d'une prise de contrôle de compte via vol de session).
///
/// Politique serveur sur le nouveau mot de passe (min 8 caractères, ≥1
/// majuscule, ≥1 chiffre, ≥1 caractère parmi `!@#$%^&*`) est appliquée côté
/// serveur — les erreurs 422 remontent via [ValidationException.fieldErrors]
/// et sont affichées sur le champ concerné. Un ancien mot de passe incorrect
/// remonte en 401 ([AuthException], voir `AuthRepository.changePassword`) —
/// affiché comme une erreur sur le champ "mot de passe actuel" pour guider
/// l'utilisateur, même si ce n'est pas une `ValidationException`.
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
          // 401 INVALID_CREDENTIALS — mot de passe actuel incorrect. Pas une
          // ValidationException (voir doc de classe), mappé manuellement sur
          // le champ concerné pour une UX cohérente avec les autres erreurs.
          setState(() => _fieldErrors = {'current_password': e.message});
        } else if (e is AppException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      },
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mot de passe changé. Vos autres appareils ont été '
              'déconnectés.',
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
      appBar: AppBar(title: const Text('Changer le mot de passe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _currentPasswordCtrl,
                  obscureText: _obscureCurrent,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    errorText: _fieldErrors['current_password'],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Le mot de passe actuel est requis'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    helperText: '8 caractères min., 1 majuscule, 1 chiffre, '
                        '1 caractère spécial (!@#\$%^&*)',
                    helperMaxLines: 2,
                    errorText: _fieldErrors['new_password'],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? '8 caractères minimum'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => (v != _newPasswordCtrl.text)
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Changer le mot de passe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
