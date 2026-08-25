import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/widgets/allergen_badge.dart';
import 'package:app_client/features/catalog/widgets/extra_item_tile.dart';
import 'package:app_client/features/catalog/widgets/recommended_products_row.dart';
import 'package:app_client/features/catalog/widgets/variant_selector.dart';

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

    return Scaffold(
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
                    const SnackBar(
                      content: Text('Ajouté au panier'),
                    ),
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

    return CustomScrollView(
      slivers: [
        // AppBar avec image hero
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'product-${product.id}',
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (_, __, ___) => const _ImageFallback(),
                    )
                  : const _ImageFallback(),
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
                        style: theme.textTheme.headlineMedium,
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
                          'Indisponible',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Prix de base
                Text(
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
                    style: theme.textTheme.bodyMedium,
                  ),
                ],

                // Allergènes
                if (product.allergens.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Contient',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                  Text('Suppléments', style: theme.textTheme.titleLarge),
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

    return Row(
      children: [
        Text('Quantité', style: theme.textTheme.titleLarge),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
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

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAvailable ? 'Ajouter au panier' : 'Produit indisponible',
              ),
              if (isAvailable)
                Text(
                  formatPrice(total),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
            ],
          ),
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
      appBar: AppBar(),
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
              const Text(
                'Impossible de charger ce produit.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
