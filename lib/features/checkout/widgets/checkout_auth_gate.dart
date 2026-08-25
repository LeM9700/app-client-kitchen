import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';

/// Auth inline dans le tunnel de checkout (Plan 12, décision d'architecture n°1).
///
/// Affiché par `CheckoutScreen` tant que `accessTokenProvider` est `null`.
/// Bandeau contexte panier + 2 onglets (connexion / inscription) qui
/// partagent le même [authNotifierProvider] — dès qu'un des deux
/// formulaires réussit, `accessTokenProvider` est renseigné par
/// [AuthNotifier] et l'écran parent bascule automatiquement vers les étapes
/// checkout (`AnimatedSwitcher` côté `CheckoutScreen`, pas de navigation ici).
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
    final theme = Theme.of(context);

    return Column(
      children: [
        // Bandeau contexte panier (décision d'architecture n°3).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${cart.totalQuantity} article${cart.totalQuantity > 1 ? 's' : ''} · '
                    '${cart.subtotal.toStringAsFixed(2)} €',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Connectez-vous pour finaliser votre commande.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),

        // Onglets (décision d'architecture n°2).
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Je me connecte'),
            Tab(text: 'Je crée un compte'),
          ],
        ),

        // Formulaires.
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _LoginTabContent(),
              _RegisterTabContent(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet Connexion
// ─────────────────────────────────────────────────────────────────────────────

class _LoginTabContent extends ConsumerStatefulWidget {
  const _LoginTabContent();

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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((e as AppException).message)),
          );
        }
      },
      // Succès : CheckoutScreen détecte automatiquement le changement d'auth
      // via accessTokenProvider et affiche les étapes checkout (AnimatedSwitcher).
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _fieldErrors['email'],
              ),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Email invalide' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                errorText: _fieldErrors['password'],
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 8 ? '8 caractères minimum' : null,
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
                  : const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet Inscription
// ─────────────────────────────────────────────────────────────────────────────

/// [TECH DEBT corrigé] `fullName` est REQUIS ici (validator non-vide), pas un
/// bonus facultatif : `CustomerRegisterRequest.full_name` est `min_length=1`
/// côté API — un formulaire qui l'autoriserait vide serait "valide" côté
/// client mais reviendrait en 422 côté serveur. `phone` reste optionnel
/// (aucun validator), envoyé comme `null` si le champ est vide.
class _RegisterTabContent extends ConsumerStatefulWidget {
  const _RegisterTabContent();

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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((e as AppException).message)),
          );
        }
      },
      // Succès : idem _LoginTabContent — CheckoutScreen bascule automatiquement.
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Nom complet — OBLIGATOIRE (CustomerRegisterRequest.full_name).
            TextFormField(
              controller: _fullNameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                errorText: _fieldErrors['full_name'],
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nom requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _fieldErrors['email'],
              ),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Email invalide' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: '8 caractères minimum',
                errorText: _fieldErrors['password'],
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 8 ? '8 caractères minimum' : null,
            ),
            const SizedBox(height: 16),
            // Téléphone — optionnel, pas de validator.
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Téléphone (optionnel)',
                errorText: _fieldErrors['phone'],
              ),
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
                  : const Text('Créer mon compte'),
            ),
          ],
        ),
      ),
    );
  }
}
