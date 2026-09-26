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
import 'package:app_client/features/auth/providers/auth_provider.dart';

/// Édition du profil — `PATCH /customer/me`.
///
/// Le profil accepte un email facultatif: les comptes créés par téléphone ou
/// par la caisse peuvent le compléter plus tard.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl =
        TextEditingController(text: user?.phoneE164 ?? user?.phone ?? '');
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _fieldErrors = {});

    final fullName = _fullNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    await ref.read(profileEditNotifierProvider.notifier).updateProfile(
          fullName: fullName.isEmpty ? null : fullName,
          email: email.isEmpty ? null : email,
          phone: phone.isEmpty ? null : phone,
        );

    if (!mounted) return;

    final state = ref.read(profileEditNotifierProvider);
    state.whenOrNull(
      error: (e, _) {
        if (e is ValidationException) {
          setState(() => _fieldErrors = e.fieldErrors);
        }
        if (e is AppException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      },
      data: (_) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour.')),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileEditNotifierProvider).isLoading;
    final currentUser = ref.watch(currentUserProvider);
    final profileIncomplete = currentUser?.pendingProfileCompletion ?? false;

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
                    'Mes informations',
                    style: KitchenTypography.title.copyWith(fontSize: 31),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KitchenSpacing.lg),
            if (profileIncomplete) ...[
              KitchenSurface(
                padding: const EdgeInsets.all(KitchenSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.assignment_ind_outlined,
                      color: KitchenColors.cognac,
                    ),
                    const SizedBox(width: KitchenSpacing.sm),
                    Expanded(
                      child: Text(
                        'Complétez vos informations pour finaliser votre compte fidélité.',
                        style: KitchenTypography.body.copyWith(
                          color: KitchenColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KitchenSpacing.md),
            ],
            KitchenSurface(
              padding: const EdgeInsets.all(KitchenSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Identité',
                      style: KitchenTypography.label.copyWith(
                        color: KitchenColors.brown700,
                      ),
                    ),
                    const SizedBox(height: KitchenSpacing.md),
                    KitchenTextField(
                      controller: _fullNameCtrl,
                      label: 'Nom complet',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      errorText: _fieldErrors['full_name'],
                      autofillHints: const [AutofillHints.name],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Le nom complet est requis'
                          : null,
                    ),
                    const SizedBox(height: KitchenSpacing.md),
                    KitchenTextField(
                      controller: _emailCtrl,
                      label: 'Email (facultatif)',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      errorText: _fieldErrors['email'],
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || email.contains('@')) {
                          return null;
                        }
                        return 'Email invalide';
                      },
                    ),
                    const SizedBox(height: KitchenSpacing.md),
                    KitchenTextField(
                      controller: _phoneCtrl,
                      label: 'Téléphone',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      errorText: _fieldErrors['phone'],
                      autofillHints: const [AutofillHints.telephoneNumber],
                    ),
                    const SizedBox(height: KitchenSpacing.lg),
                    KitchenEmbossedButton(
                      onPressed: isLoading ? null : _submit,
                      isLoading: isLoading,
                      semanticLabel: 'Enregistrer mes informations',
                      child: const Text('Enregistrer'),
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
