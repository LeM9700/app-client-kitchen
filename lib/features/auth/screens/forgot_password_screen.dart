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
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _returnToLogin() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.login);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.forgotPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _sent ? l10n.authEmailSentTitle : l10n.authForgotTitle;
    final body = _sent
        ? l10n.authEmailSentBody(_emailCtrl.text.trim())
        : l10n.authForgotBody;

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
                      maxWidth: 430,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            onPressed: _returnToLogin,
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
                          title,
                          textAlign: TextAlign.center,
                          style: KitchenTypography.title.copyWith(
                            fontSize: 34,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: KitchenSpacing.sm),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: KitchenTypography.body.copyWith(
                            color: KitchenColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: KitchenSpacing.lg),
                        KitchenSurface(
                          elevation: KitchenElevation.flat,
                          borderRadius: BorderRadius.circular(KitchenRadius.xl),
                          color: KitchenColors.paper.withValues(alpha: 0.8),
                          padding: const EdgeInsets.fromLTRB(
                            KitchenSpacing.md,
                            KitchenSpacing.lg,
                            KitchenSpacing.md,
                            KitchenSpacing.lg,
                          ),
                          child: _sent
                              ? _ConfirmationActions(
                                  onReturnToLogin: _returnToLogin,
                                )
                              : _ResetForm(
                                  formKey: _formKey,
                                  emailCtrl: _emailCtrl,
                                  isLoading: _isLoading,
                                  onSubmit: _submit,
                                  onReturnToLogin: _returnToLogin,
                                ),
                        ),
                      ],
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

class _ResetForm extends StatelessWidget {
  const _ResetForm({
    required this.formKey,
    required this.emailCtrl,
    required this.isLoading,
    required this.onSubmit,
    required this.onReturnToLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitchenTextField(
            controller: emailCtrl,
            label: l10n.authEmailLabel,
            hintText: 'client@email.fr',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => onSubmit(),
            validator: (v) => (v == null || !v.contains('@'))
                ? l10n.authEmailInvalidError
                : null,
          ),
          const SizedBox(height: KitchenSpacing.lg),
          KitchenEmbossedButton(
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
            semanticLabel: l10n.authForgotPasswordLink,
            child: const Text('ENVOYER LES INSTRUCTIONS'),
          ),
          const SizedBox(height: KitchenSpacing.sm),
          TextButton(
            onPressed: onReturnToLogin,
            style: TextButton.styleFrom(
              foregroundColor: KitchenColors.espresso,
              minimumSize: const Size(44, 44),
            ),
            child: Text(l10n.authLoginSubmitButton),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationActions extends StatelessWidget {
  const _ConfirmationActions({required this.onReturnToLogin});

  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          color: KitchenColors.olive,
          size: 46,
        ),
        const SizedBox(height: KitchenSpacing.md),
        KitchenEmbossedButton(
          onPressed: onReturnToLogin,
          semanticLabel: l10n.authLoginSubmitButton,
          child: Text(l10n.authLoginSubmitButton.toUpperCase()),
        ),
      ],
    );
  }
}
