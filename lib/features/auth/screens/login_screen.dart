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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _fieldErrors = {});

    final fallbackMessage = AppLocalizations.of(context)!.authLoginFailedError;

    await ref.read(authNotifierProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.whenOrNull(
      error: (e, _) {
        if (e is ValidationException) {
          setState(() => _fieldErrors = e.fieldErrors);
          return;
        }
        final message = e is AppException ? e.message : fallbackMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      data: (_) => context.go(widget.redirectTo ?? AppRoutes.home),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: KitchenPhotoBackground(
        assetPath: KitchenAssets.loginBackground,
        alignment: Alignment.center,
        overlayColor: KitchenColors.paperLight.withValues(alpha: 0.38),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 42,
                      maxWidth: 430,
                    ),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: KitchenSpacing.md),
                            const Center(
                              child: KitchenBrandLogo(size: 92, light: true),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'KOD MOME',
                              textAlign: TextAlign.center,
                              style: KitchenTypography.display.copyWith(
                                fontSize: 39,
                                color: KitchenColors.espresso,
                              ),
                            ),
                            Text(
                              'PIZZAS DE CARACTERE\nA TOUT MOMENT',
                              textAlign: TextAlign.center,
                              style: KitchenTypography.label.copyWith(
                                color: KitchenColors.brown700,
                                fontSize: 12,
                                height: 1.32,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'Bienvenue !',
                              textAlign: TextAlign.center,
                              style: KitchenTypography.title.copyWith(
                                fontSize: 31,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connectez-vous pour continuer\nvotre experience gourmande.',
                              textAlign: TextAlign.center,
                              style: KitchenTypography.body.copyWith(
                                color: KitchenColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 26),
                            KitchenSurface(
                              elevation: KitchenElevation.flat,
                              borderRadius:
                                  BorderRadius.circular(KitchenRadius.xl),
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                20,
                                18,
                                20,
                              ),
                              color:
                                  KitchenColors.paper.withValues(alpha: 0.76),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
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
                                  const SizedBox(height: 14),
                                  KitchenTextField(
                                    controller: _passwordCtrl,
                                    label: l10n.authPasswordLabel,
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
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
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => context.push(
                                        AppRoutes.forgotPassword,
                                      ),
                                      child: Text(l10n.authForgotPasswordLink),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  KitchenEmbossedButton(
                                    onPressed: isLoading ? null : _submit,
                                    isLoading: isLoading,
                                    semanticLabel: l10n.authLoginSubmitButton,
                                    child: Text(
                                      l10n.authLoginSubmitButton.toUpperCase(),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    l10n.authOrDivider.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: KitchenTypography.label.copyWith(
                                      color: KitchenColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () {
                                      final redirect = widget.redirectTo;
                                      context.push(
                                        '${AppRoutes.register}'
                                        '${redirect != null ? '?redirect=${Uri.encodeComponent(redirect)}' : ''}',
                                      );
                                    },
                                    child: Text(l10n.authCreateAccountButton),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Theme(
                              data: Theme.of(context).copyWith(
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: KitchenColors.espresso,
                                    textStyle: KitchenTypography.label.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              child: const LegalLinks(),
                            ),
                            const SizedBox(height: KitchenSpacing.md),
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
