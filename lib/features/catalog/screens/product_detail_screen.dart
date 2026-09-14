import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';
import 'package:app_client/design_system/kod_mome/glass_surface.dart';
import 'package:app_client/design_system/kod_mome/gold_foil_text.dart';
import 'package:app_client/design_system/kod_mome/neumorphic_surface.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/widgets/allergen_badge.dart';
import 'package:app_client/features/catalog/widgets/extra_item_tile.dart';
import 'package:app_client/features/catalog/widgets/recommended_products_row.dart';
import 'package:app_client/features/catalog/widgets/variant_selector.dart';
import 'package:app_client/l10n/app_localizations.dart';

/// Fiche détail d'un produit.
///
/// Route : `/catalog/products/:productId` (go_router).
/// Chargement via [productDetailProvider] (autoDispose.family).
///
/// State local :
/// - [_selectedVariantId] : variante active (null = première par défaut).
/// - [_selectedExtras] : set des ids d'extras sélectionnés.
/// - [_quantity] : quantité (1 par défaut, min 1 max 10).
///
/// Pas de Riverpod pour ce state local : durée de vie = lifecycle de l'écran,
/// pas besoin de partage cross-widget.
///
/// [⚡ PERF] Image hero réutilise le tag `product-{id}` de [ProductCard] et
/// [_RecommendationCard] — transition fluide sans double requête réseau.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int? _selectedVariantId;
  final Set<int> _selectedExtras = {};
  int _quantity = 1;

  // Calcule le prix total selon variante + extras sélectionnés.
  double _computeTotal(Product product) {
    double base = product.price;

    if (_selectedVariantId != null) {
      final variant =
          product.variants.where((v) => v.id == _selectedVariantId).firstOrNull;
      if (variant != null) base += variant.priceDelta;
    }

    for (final extraId in _selectedExtras) {
      final extra = product.extras.where((e) => e.id == extraId).firstOrNull;
      if (extra != null) base += extra.price;
    }

    return base * _quantity;
  }

  String _formatPrice(double price) => '${price.toStringAsFixed(2)} €';

  @override
  Widget build(BuildContext context) {
    final productAsync =
        ref.watch(productDetailProvider(int.parse(widget.productId)));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          Env.isKodMomeBuild ? KodMomeDesignPack.charcoal : null,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (product) {
          // Initialise la variante par défaut si non sélectionnée
          if (_selectedVariantId == null && product.hasVariants) {
            _selectedVariantId = product.variants.first.id;
          }

          return Stack(
            children: [
              _ScrollBody(
                product: product,
                selectedVariantId: _selectedVariantId,
                selectedExtras: _selectedExtras,
                quantity: _quantity,
                onVariantChanged: (id) =>
                    setState(() => _selectedVariantId = id),
                onExtraChanged: (extraId, selected) {
                  setState(() {
                    if (selected) {
                      _selectedExtras.add(extraId);
                    } else {
                      _selectedExtras.remove(extraId);
                    }
                  });
                },
                onQuantityChanged: (q) => setState(() => _quantity = q),
              ),

              // Bouton "Ajouter au panier" flottant en bas
              _AddToCartBar(
                total: _computeTotal(product),
                formatPrice: _formatPrice,
                quantity: _quantity,
                isAvailable: product.isAvailable,
                onAddToCart: () {
                  final selectedVariant = _selectedVariantId == null
                      ? null
                      : product.variants
                          .where((v) => v.id == _selectedVariantId)
                          .firstOrNull;
                  final selectedExtraIds = product.extras
                      .where(
                        (extra) =>
                            extra.available &&
                            _selectedExtras.contains(extra.id),
                      )
                      .map((extra) => extra.id)
                      .toSet();

                  ref.read(cartProvider.notifier).addItem(
                        product,
                        quantity: _quantity,
                        variant: selectedVariant,
                        extraIds: selectedExtraIds,
                      );
                  ref.read(analyticsReporterProvider).track(
                    'cart_item_added',
                    {
                      'source': 'product_detail',
                      'product_id': product.id,
                      'quantity': _quantity,
                      'variant_id': selectedVariant?.id,
                      'extra_ids': selectedExtraIds.toList()..sort(),
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.productAddedToCart)),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Scroll body
// ──────────────────────────────────────────────────────────────────────────────

class _ScrollBody extends StatelessWidget {
  const _ScrollBody({
    required this.product,
    required this.selectedVariantId,
    required this.selectedExtras,
    required this.quantity,
    required this.onVariantChanged,
    required this.onExtraChanged,
    required this.onQuantityChanged,
  });

  final Product product;
  final int? selectedVariantId;
  final Set<int> selectedExtras;
  final int quantity;
  final ValueChanged<int> onVariantChanged;
  final void Function(int extraId, bool selected) onExtraChanged;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;

    final heroImage = product.imageUrl != null
        ? Image.network(
            product.imageUrl!,
            fit: BoxFit.cover,
            cacheWidth: 800,
            errorBuilder: (_, __, ___) => const _ImageFallback(),
          )
        : const _ImageFallback();

    return CustomScrollView(
      slivers: [
        // AppBar avec image hero
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: isKodMome ? KodMomeDesignPack.charcoal : null,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'product-${product.id}',
              child: isKodMome
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        heroImage,
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                KodMomeDesignPack.charcoal
                                    .withValues(alpha: 0.9),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    )
                  : heroImage,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + disponibilité
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: isKodMome ? KodMomeDesignPack.cream : null,
                        ),
                      ),
                    ),
                    if (!product.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.productUnavailable,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Prix de base
                isKodMome
                    ? GoldFoilText(
                        product.displayPrice,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      )
                    : Text(
                        product.displayPrice,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                // Description
                if (product.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    product.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isKodMome
                          ? KodMomeDesignPack.cream.withValues(alpha: 0.75)
                          : null,
                    ),
                  ),
                ],

                // Allergènes
                if (product.allergens.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.productContainsLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isKodMome
                          ? KodMomeDesignPack.cream.withValues(alpha: 0.6)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: product.allergens
                        .map((code) => AllergenBadge(code: code))
                        .toList(),
                  ),
                ],

                // Sélecteur variante
                if (product.hasVariants) ...[
                  const SizedBox(height: 24),
                  VariantSelector(
                    variants: product.variants,
                    selectedVariantId: selectedVariantId,
                    basePrice: product.price,
                    onChanged: onVariantChanged,
                  ),
                ],

                // Extras
                if (product.hasExtras) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.productExtrasLabel,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isKodMome ? KodMomeDesignPack.cream : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...product.extras.map(
                    (extra) => ExtraItemTile(
                      extra: extra,
                      isSelected: selectedExtras.contains(extra.id),
                      onChanged: (selected) =>
                          onExtraChanged(extra.id, selected),
                    ),
                  ),
                ],

                // Sélecteur quantité
                const SizedBox(height: 24),
                _QuantitySelector(
                  quantity: quantity,
                  onChanged: onQuantityChanged,
                ),

                const SizedBox(height: 16),
                const Divider(),
              ],
            ),
          ),
        ),

        // Produits recommandés
        SliverToBoxAdapter(
          child: RecommendedProductsRow(
            categoryId: product.categoryId,
            currentProductId: product.id,
          ),
        ),

        // Space for the fixed add-to-cart bar plus the mobile navigation pill.
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).width >= 900 ? 116 : 136,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sélecteur quantité
// ──────────────────────────────────────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKodMome = Env.isKodMomeBuild;
    final textColor = isKodMome ? KodMomeDesignPack.cream : null;
    final iconColor = isKodMome ? KodMomeDesignPack.primary : null;

    return Row(
      children: [
        Text(
          AppLocalizations.of(context)!.productQuantityLabel,
          style: theme.textTheme.titleLarge?.copyWith(color: textColor),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: iconColor),
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(color: textColor),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: iconColor),
          onPressed: quantity < 10 ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Barre "Ajouter au panier"
// ──────────────────────────────────────────────────────────────────────────────

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.total,
    required this.formatPrice,
    required this.quantity,
    required this.isAvailable,
    required this.onAddToCart,
  });

  final double total;
  final String Function(double) formatPrice;
  final int quantity;
  final bool isAvailable;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isKodMome = Env.isKodMomeBuild;
    final bottomInset = 12 + MediaQuery.of(context).padding.bottom;
    final label =
        isAvailable ? l10n.productAddToCartButton : l10n.productUnavailableButton;

    final ctaRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        if (isAvailable)
          Text(
            formatPrice(total),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
      ],
    );

    if (isKodMome) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
          // Seule surface avec vrai flou (BackdropFilter) de cet écran — voir
          // les garde-fous perf du plan Kod Mome (une surface héro max par
          // écran, jamais dans une liste qui scrolle).
          child: KodMomeGlassSurface(
            variant: KodMomeGlassVariant.hero,
            borderRadius: 20,
            padding: EdgeInsets.zero,
            child: Opacity(
              opacity: isAvailable ? 1 : 0.5,
              child: NeumorphicButton(
                borderRadius: 20,
                onTap: isAvailable ? onAddToCart : () {},
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ctaRow,
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isAvailable ? onAddToCart : null,
          child: ctaRow,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Fallbacks
// ──────────────────────────────────────────────────────────────────────────────

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.local_pizza_outlined, size: 64),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Env.isKodMomeBuild ? KodMomeDesignPack.charcoal : null,
      appBar: AppBar(
        backgroundColor: Env.isKodMomeBuild ? KodMomeDesignPack.charcoal : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.productLoadErrorMessage,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
