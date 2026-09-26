import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_text_field.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';

class PhoneAuthFlow extends ConsumerStatefulWidget {
  const PhoneAuthFlow({
    super.key,
    required this.createAccount,
    required this.onAuthenticated,
    this.beforeSendCode,
    this.title,
    this.subtitle,
    this.submitLabel,
  });

  final bool createAccount;
  final VoidCallback onAuthenticated;
  final FutureOr<bool> Function()? beforeSendCode;
  final String? title;
  final String? subtitle;
  final String? submitLabel;

  @override
  ConsumerState<PhoneAuthFlow> createState() => _PhoneAuthFlowState();
}

class _PhoneAuthFlowState extends ConsumerState<PhoneAuthFlow> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final gate = widget.beforeSendCode;
    if (gate != null && !await gate()) {
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showMessage('Téléphone requis.');
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);
    if (widget.createAccount) {
      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      if (firstName.isEmpty || lastName.isEmpty) {
        _showMessage('Prénom et nom sont requis.');
        return;
      }
      await notifier.registerPhone(
        phone: phone,
        firstName: firstName,
        lastName: lastName,
      );
    } else {
      await notifier.startPhoneAuth(phone: phone);
    }

    if (!mounted) return;
    ref.read(authNotifierProvider).whenOrNull(
          error: (e, _) =>
              _showMessage(_messageFor(e, 'Impossible d’envoyer le SMS.')),
          data: (_) => setState(() => _codeSent = true),
        );
  }

  Future<void> _verifyCode() async {
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (phone.isEmpty || code.isEmpty) {
      _showMessage('Téléphone et code sont requis.');
      return;
    }

    await ref.read(authNotifierProvider.notifier).verifyPhone(
          phone: phone,
          code: code,
        );

    if (!mounted) return;
    ref.read(authNotifierProvider).whenOrNull(
          error: (e, _) => _showMessage(_messageFor(e, 'Code invalide.')),
          data: (_) => widget.onAuthenticated(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final createAccount = widget.createAccount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title ??
              (createAccount
                  ? 'Créer un compte par téléphone'
                  : 'Se connecter par téléphone'),
          style: KitchenTypography.title.copyWith(fontSize: 28),
        ),
        const SizedBox(height: KitchenSpacing.xs),
        Text(
          widget.subtitle ??
              (createAccount
                  ? 'Un code SMS confirme votre numéro. L’email pourra être ajouté plus tard.'
                  : 'Recevez un code SMS pour retrouver votre compte fidélité.'),
          style: KitchenTypography.body.copyWith(
            color: KitchenColors.textMuted,
          ),
        ),
        const SizedBox(height: KitchenSpacing.lg),
        KitchenTextField(
          controller: _phoneCtrl,
          label: 'Téléphone',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction:
              createAccount ? TextInputAction.next : TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          onSubmitted: (_) {
            if (!createAccount && !_codeSent) {
              _sendCode();
            }
          },
        ),
        if (createAccount) ...[
          const SizedBox(height: KitchenSpacing.md),
          Row(
            children: [
              Expanded(
                child: KitchenTextField(
                  controller: _firstNameCtrl,
                  label: 'Prénom',
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                ),
              ),
              const SizedBox(width: KitchenSpacing.sm),
              Expanded(
                child: KitchenTextField(
                  controller: _lastNameCtrl,
                  label: 'Nom',
                  prefixIcon: Icons.person_outline,
                  textInputAction:
                      _codeSent ? TextInputAction.next : TextInputAction.done,
                  autofillHints: const [AutofillHints.familyName],
                  onSubmitted: (_) {
                    if (!_codeSent) {
                      _sendCode();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        if (_codeSent) ...[
          const SizedBox(height: KitchenSpacing.md),
          KitchenTextField(
            controller: _codeCtrl,
            label: 'Code SMS',
            prefixIcon: Icons.sms_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verifyCode(),
          ),
          const SizedBox(height: KitchenSpacing.xs),
          Text(
            'Code envoyé. Vous pouvez demander un nouveau code si besoin.',
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: KitchenSpacing.lg),
        KitchenEmbossedButton(
          onPressed: isLoading ? null : (_codeSent ? _verifyCode : _sendCode),
          isLoading: isLoading,
          semanticLabel: _codeSent ? 'Vérifier le code' : 'Envoyer le code',
          child: Text(
            (_codeSent
                    ? 'Vérifier le code'
                    : widget.submitLabel ?? 'Envoyer le code')
                .toUpperCase(),
          ),
        ),
        if (_codeSent)
          TextButton(
            onPressed: isLoading ? null : _sendCode,
            child: const Text('Renvoyer un code'),
          ),
      ],
    );
  }

  String _messageFor(Object error, String fallback) {
    if (error is AppException) return error.message;
    return fallback;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
