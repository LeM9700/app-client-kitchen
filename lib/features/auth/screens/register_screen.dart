import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_brand_logo.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_photo_background.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_text_field.dart';
import 'package:app_client/core/widgets/legal_links.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedLegal = false;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_acceptedLegal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authLegalAcceptRequired)),
      );
      return;
    }

    setState(() => _fieldErrors = {});

    await ref.read(authNotifierProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.whenOrNull(
      error: (e, _) {
        if (e is ValidationException) {
          setState(() => _fieldErrors = e.fieldErrors);
          return;
        }
        final message =
            e is AppException ? e.message : l10n.authRegisterFailedError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      data: (_) => context.go(widget.redirectTo ?? AppRoutes.home),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;
    final heading = l10n.authRegisterHeading.replaceAll('\n', ' ');

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: KitchenPhotoBackground(
        assetPath: KitchenAssets.loginBackground,
        alignment: Alignment.center,
        overlayColor: KitchenColors.paperLight.withValues(alpha: 0.42),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  KitchenSpacing.lg,
                  KitchenSpacing.md,
                  KitchenSpacing.lg,
                  KitchenSpacing.lg + MediaQuery.paddingOf(context).bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - KitchenSpacing.xl,
                      maxWidth: 460,
                    ),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton.filledTonal(
                                onPressed: _goBack,
                                tooltip: l10n.authCloseTooltip,
                                icon: const Icon(Icons.arrow_back),
                              ),
                            ),
                            const SizedBox(height: KitchenSpacing.sm),
                            const Center(
                              child: KitchenBrandLogo(size: 88, light: true),
                            ),
                            const SizedBox(height: KitchenSpacing.lg),
                            Text(
                              heading,
                              textAlign: TextAlign.center,
                              style: KitchenTypography.title.copyWith(
                                fontSize: 33,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: KitchenSpacing.xs),
                            Text(
                              'Un compte suffit pour suivre vos commandes et retrouver vos avantages.',
                              textAlign: TextAlign.center,
                              style: KitchenTypography.body.copyWith(
                                color: KitchenColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: KitchenSpacing.lg),
                            KitchenSurface(
                              elevation: KitchenElevation.flat,
                              borderRadius:
                                  BorderRadius.circular(KitchenRadius.xl),
                              color: KitchenColors.paper.withValues(alpha: 0.8),
                              padding: const EdgeInsets.fromLTRB(
                                KitchenSpacing.md,
                                KitchenSpacing.lg,
                                KitchenSpacing.md,
                                KitchenSpacing.lg,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  KitchenTextField(
                                    controller: _fullNameCtrl,
                                    label: l10n.authFullNameLabel,
                                    prefixIcon: Icons.person_outline,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    errorText: _fieldErrors['full_name'],
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? l10n.authFullNameRequiredError
                                            : null,
                                  ),
                                  const SizedBox(height: KitchenSpacing.md),
                                  KitchenTextField(
                                    controller: _emailCtrl,
                                    label: l10n.authEmailLabel,
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.email,
                                      AutofillHints.username,
                                    ],
                                    errorText: _fieldErrors['email'],
                                    validator: (v) =>
                                        (v == null || !v.contains('@'))
                                            ? l10n.authEmailInvalidError
                                            : null,
                                  ),
                                  const SizedBox(height: KitchenSpacing.md),
                                  KitchenTextField(
                                    controller: _passwordCtrl,
                                    label: l10n.authPasswordLabel,
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    errorText: _fieldErrors['password'],
                                    onSubmitted: (_) => _submit(),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Afficher le mot de passe'
                                          : 'Masquer le mot de passe',
                                      color: KitchenColors.espresso,
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 8)
                                            ? l10n.authPasswordMinLength
                                            : null,
                                  ),
                                  const SizedBox(height: KitchenSpacing.md),
                                  _LegalAcceptance(
                                    value: _acceptedLegal,
                                    onChanged: (value) => setState(
                                      () => _acceptedLegal = value,
                                    ),
                                  ),
                                  const SizedBox(height: KitchenSpacing.lg),
                                  KitchenEmbossedButton(
                                    onPressed: isLoading ? null : _submit,
                                    isLoading: isLoading,
                                    semanticLabel:
                                        l10n.authRegisterSubmitButton,
                                    child: Text(
                                      l10n.authRegisterSubmitButton
                                          .toUpperCase(),
                                    ),
                                  ),
                                  const SizedBox(height: KitchenSpacing.md),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        l10n.authHaveAccountPrompt,
                                        style: KitchenTypography.body.copyWith(
                                          color: KitchenColors.textMuted,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.push(
                                          '${AppRoutes.login}'
                                          '${widget.redirectTo != null ? '?redirect=${Uri.encodeComponent(widget.redirectTo!)}' : ''}',
                                        ),
                                        child: Text(l10n.authLoginSubmitButton),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LegalAcceptance extends StatelessWidget {
  const _LegalAcceptance({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      elevation: KitchenElevation.inset,
      borderRadius: BorderRadius.circular(KitchenRadius.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: KitchenSpacing.sm,
        vertical: KitchenSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: value,
            activeColor: KitchenColors.cognac,
            checkColor: const Color.fromARGB(255, 250, 247, 247),
            onChanged: (next) => onChanged(next ?? false),
          ),
          const Expanded(
            child: LegalLinks(),
          ),
        ],
      ),
    );
  }
}
