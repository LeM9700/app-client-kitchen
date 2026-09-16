import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_text_field.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

/// Auth inline dans le tunnel de checkout.
///
/// Tant que l'utilisateur n'est pas connecté, ce widget garde le panier et le
/// checkout en place, puis laisse `CheckoutScreen` révéler les étapes dès que
/// `accessTokenProvider` est renseigné.
class CheckoutAuthGate extends ConsumerStatefulWidget {
  const CheckoutAuthGate({super.key});

  @override
  ConsumerState<CheckoutAuthGate> createState() => _CheckoutAuthGateState();
}

class _CheckoutAuthGateState extends ConsumerState<CheckoutAuthGate>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final copy = _CheckoutAuthCopy.from(AppLocalizations.of(context));

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KitchenSpacing.lg,
              KitchenSpacing.md,
              KitchenSpacing.lg,
              KitchenSpacing.sm,
            ),
            child: KitchenSurface(
              elevation: KitchenElevation.inset,
              padding: const EdgeInsets.all(KitchenSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: KitchenColors.cognac.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: KitchenColors.cognac,
                    ),
                  ),
                  const SizedBox(width: KitchenSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.totalQuantity} article${cart.totalQuantity > 1 ? 's' : ''} · ${formatPrice(cart.subtotal)}',
                          style: KitchenTypography.label.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: KitchenSpacing.xxs),
                        Text(
                          'Connectez-vous pour finaliser votre commande.',
                          style: KitchenTypography.body.copyWith(
                            color: KitchenColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KitchenSpacing.lg),
            child: KitchenSurface(
              elevation: KitchenElevation.flat,
              borderRadius: BorderRadius.circular(KitchenRadius.pill),
              padding: const EdgeInsets.all(KitchenSpacing.xs),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: KitchenColors.whiteWarm,
                unselectedLabelColor: KitchenColors.textMuted,
                labelStyle: KitchenTypography.label,
                unselectedLabelStyle: KitchenTypography.label,
                indicator: BoxDecoration(
                  gradient: KitchenGradients.cognac,
                  borderRadius: BorderRadius.circular(KitchenRadius.pill),
                ),
                tabs: const [
                  Tab(text: 'Connexion'),
                  Tab(text: 'Inscription'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LoginTabContent(copy: copy),
                _RegisterTabContent(copy: copy),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTabContent extends ConsumerStatefulWidget {
  const _LoginTabContent({required this.copy});

  final _CheckoutAuthCopy copy;

  @override
  ConsumerState<_LoginTabContent> createState() => _LoginTabContentState();
}

class _LoginTabContentState extends ConsumerState<_LoginTabContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyMessage(e))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final copy = widget.copy;

    return _AuthTabScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Retrouvez votre commande',
              style: KitchenTypography.title.copyWith(fontSize: 28),
            ),
            const SizedBox(height: KitchenSpacing.xs),
            Text(
              'On garde votre panier au chaud pendant la connexion.',
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
            const SizedBox(height: KitchenSpacing.lg),
            KitchenTextField(
              controller: _emailCtrl,
              label: copy.emailLabel,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              errorText: _fieldErrors['email'],
              validator: (v) =>
                  v == null || !v.contains('@') ? copy.emailInvalidError : null,
            ),
            const SizedBox(height: KitchenSpacing.md),
            KitchenTextField(
              controller: _passwordCtrl,
              label: copy.passwordLabel,
              prefixIcon: Icons.lock_outline,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              errorText: _fieldErrors['password'],
              suffixIcon: IconButton(
                tooltip: _obscure
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                color: KitchenColors.espresso,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
                  v == null || v.length < 8 ? copy.passwordMinLength : null,
            ),
            const SizedBox(height: KitchenSpacing.lg),
            KitchenEmbossedButton(
              onPressed: isLoading ? null : _submit,
              isLoading: isLoading,
              semanticLabel: copy.loginSubmitButton,
              child: Text(copy.loginSubmitButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterTabContent extends ConsumerStatefulWidget {
  const _RegisterTabContent({required this.copy});

  final _CheckoutAuthCopy copy;

  @override
  ConsumerState<_RegisterTabContent> createState() =>
      _RegisterTabContentState();
}

class _RegisterTabContentState extends ConsumerState<_RegisterTabContent> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _fieldErrors = {});

    final phone = _phoneCtrl.text.trim();

    await ref.read(authNotifierProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
          phone: phone.isEmpty ? null : phone,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.whenOrNull(
      error: (e, _) {
        if (e is ValidationException) {
          setState(() => _fieldErrors = e.fieldErrors);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyMessage(e))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final copy = widget.copy;

    return _AuthTabScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Créer un compte',
              style: KitchenTypography.title.copyWith(fontSize: 28),
            ),
            const SizedBox(height: KitchenSpacing.xs),
            Text(
              'Votre panier reste prêt pendant l’inscription.',
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
              ),
            ),
            const SizedBox(height: KitchenSpacing.lg),
            KitchenTextField(
              controller: _fullNameCtrl,
              label: copy.fullNameLabel,
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              errorText: _fieldErrors['full_name'],
              validator: (v) => v == null || v.trim().isEmpty
                  ? copy.fullNameRequiredError
                  : null,
            ),
            const SizedBox(height: KitchenSpacing.md),
            KitchenTextField(
              controller: _emailCtrl,
              label: copy.emailLabel,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              errorText: _fieldErrors['email'],
              validator: (v) =>
                  v == null || !v.contains('@') ? copy.emailInvalidError : null,
            ),
            const SizedBox(height: KitchenSpacing.md),
            KitchenTextField(
              controller: _passwordCtrl,
              label: copy.passwordLabel,
              hintText: copy.passwordMinLength,
              prefixIcon: Icons.lock_outline,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              errorText: _fieldErrors['password'],
              suffixIcon: IconButton(
                tooltip: _obscure
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                color: KitchenColors.espresso,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
                  v == null || v.length < 8 ? copy.passwordMinLength : null,
            ),
            const SizedBox(height: KitchenSpacing.md),
            KitchenTextField(
              controller: _phoneCtrl,
              label: 'Téléphone (optionnel)',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              errorText: _fieldErrors['phone'],
            ),
            const SizedBox(height: KitchenSpacing.lg),
            KitchenEmbossedButton(
              onPressed: isLoading ? null : _submit,
              isLoading: isLoading,
              semanticLabel: 'Créer mon compte',
              child: const Text('CRÉER MON COMPTE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTabScaffold extends StatelessWidget {
  const _AuthTabScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.md,
        KitchenSpacing.lg,
        KitchenSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: KitchenSurface(
        borderRadius: BorderRadius.circular(KitchenRadius.xl),
        padding: const EdgeInsets.all(KitchenSpacing.lg),
        child: child,
      ),
    );
  }
}

class _CheckoutAuthCopy {
  const _CheckoutAuthCopy({
    required this.emailLabel,
    required this.emailInvalidError,
    required this.passwordLabel,
    required this.passwordMinLength,
    required this.loginSubmitButton,
    required this.fullNameLabel,
    required this.fullNameRequiredError,
  });

  factory _CheckoutAuthCopy.from(AppLocalizations? l10n) {
    return _CheckoutAuthCopy(
      emailLabel: l10n?.authEmailLabel ?? 'Email',
      emailInvalidError:
          l10n?.authEmailInvalidError ?? 'Veuillez entrer un email valide.',
      passwordLabel: l10n?.authPasswordLabel ?? 'Mot de passe',
      passwordMinLength: l10n?.authPasswordMinLength ??
          'Le mot de passe doit contenir au moins 8 caracteres.',
      loginSubmitButton: l10n?.authLoginSubmitButton ?? 'Se connecter',
      fullNameLabel: l10n?.authFullNameLabel ?? 'Nom complet',
      fullNameRequiredError:
          l10n?.authFullNameRequiredError ?? 'Veuillez entrer votre nom.',
    );
  }

  final String emailLabel;
  final String emailInvalidError;
  final String passwordLabel;
  final String passwordMinLength;
  final String loginSubmitButton;
  final String fullNameLabel;
  final String fullNameRequiredError;
}

String _friendlyMessage(Object error) {
  if (error is AppException) return error.message;
  return 'Action impossible pour le moment.';
}
