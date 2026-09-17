import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/widgets/allergen_badge.dart';
import 'package:app_client/features/catalog/widgets/extra_item_tile.dart';
import 'package:app_client/features/catalog/widgets/recommended_products_row.dart';
import 'package:app_client/features/catalog/widgets/variant_selector.dart';
import 'package:app_client/l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final productAsync =
        ref.watch(productDetailProvider(int.parse(widget.productId)));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      body: productAsync.when(
        loading: () => const Center(
          child: KitchenLoadingIndicator(
            color: KitchenColors.cognac,
            size: 38,
          ),
        ),
        error: (error, _) => _ErrorView(message: _friendlyProductError(error)),
        data: (product) {
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
                onQuantityChanged: (quantity) =>
                    setState(() => _quantity = quantity),
              ),
              _AddToCartBar(
                total: _computeTotal(product),
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
    final l10n = AppLocalizations.of(context)!;

    final heroImage = product.imageUrl != null
        ? Image.network(
            product.imageUrl!,
            fit: BoxFit.cover,
            cacheWidth: 900,
            errorBuilder: (_, __, ___) => const _ImageFallback(),
          )
        : const _ImageFallback();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          stretch: true,
          backgroundColor: KitchenColors.paperLight,
          foregroundColor: KitchenColors.espresso,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'product-${product.id}',
              child: Stack(
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
                          KitchenColors.espresso.withValues(alpha: 0.16),
                          KitchenColors.paper,
                        ],
                        stops: const [0.45, 0.78, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KitchenSpacing.lg,
              KitchenSpacing.lg,
              KitchenSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: KitchenTypography.display.copyWith(
                          fontSize: 40,
                        ),
                      ),
                    ),
                    if (!product.isAvailable)
                      _UnavailableBadge(label: l10n.productUnavailable),
                  ],
                ),
                const SizedBox(height: KitchenSpacing.sm),
                Text(
                  product.displayPrice,
                  style: KitchenTypography.signature.copyWith(
                    color: KitchenColors.cognac,
                  ),
                ),
                if (product.indicativePriceLabel != null) ...[
                  const SizedBox(height: KitchenSpacing.xxs),
                  Text(
                    product.indicativePriceLabel!,
                    style: KitchenTypography.body.copyWith(
                      color: KitchenColors.textMuted,
                    ),
                  ),
                ],
                if (product.description?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: KitchenSpacing.md),
                  Text(
                    product.description!.trim(),
                    style: KitchenTypography.body.copyWith(
                      color: KitchenColors.textMuted,
                    ),
                  ),
                ],
                if (product.allergens.isNotEmpty) ...[
                  const SizedBox(height: KitchenSpacing.lg),
                  Text(
                    l10n.productContainsLabel,
                    style: KitchenTypography.label.copyWith(
                      color: KitchenColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: KitchenSpacing.xs),
                  Wrap(
                    spacing: KitchenSpacing.xs,
                    runSpacing: KitchenSpacing.xs,
                    children: product.allergens
                        .map((code) => AllergenBadge(code: code))
                        .toList(),
                  ),
                ],
                if (product.hasVariants) ...[
                  const SizedBox(height: KitchenSpacing.xl),
                  VariantSelector(
                    variants: product.variants,
                    selectedVariantId: selectedVariantId,
                    basePrice: product.price,
                    onChanged: onVariantChanged,
                  ),
                ],
                if (product.hasExtras) ...[
                  const SizedBox(height: KitchenSpacing.xl),
                  Text(
                    l10n.productExtrasLabel,
                    style: KitchenTypography.title.copyWith(fontSize: 25),
                  ),
                  const SizedBox(height: KitchenSpacing.sm),
                  ...product.extras.map(
                    (extra) => ExtraItemTile(
                      extra: extra,
                      isSelected: selectedExtras.contains(extra.id),
                      onChanged: (selected) =>
                          onExtraChanged(extra.id, selected),
                    ),
                  ),
                ],
                const SizedBox(height: KitchenSpacing.xl),
                _QuantitySelector(
                  quantity: quantity,
                  onChanged: onQuantityChanged,
                ),
                const SizedBox(height: KitchenSpacing.lg),
                Divider(
                  color: KitchenColors.brown700.withValues(alpha: 0.14),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: RecommendedProductsRow(
            categoryId: product.categoryId,
            currentProductId: product.id,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).width >= 900 ? 124 : 146,
          ),
        ),
      ],
    );
  }
}

class _UnavailableBadge extends StatelessWidget {
  const _UnavailableBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KitchenSpacing.sm,
        vertical: KitchenSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: KitchenColors.terracotta.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        border: Border.all(color: KitchenColors.terracotta),
      ),
      child: Text(
        label,
        style: KitchenTypography.label.copyWith(
          color: KitchenColors.terracotta,
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      elevation: KitchenElevation.inset,
      borderRadius: BorderRadius.circular(KitchenRadius.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: KitchenSpacing.md,
        vertical: KitchenSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.productQuantityLabel,
            style: KitchenTypography.title.copyWith(fontSize: 24),
          ),
          const Spacer(),
          _StepperButton(
            icon: Icons.remove,
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 42,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: KitchenTypography.title.copyWith(fontSize: 24),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onPressed: quantity < 10 ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 42,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: KitchenColors.cognac.withValues(alpha: 0.13),
          disabledBackgroundColor: KitchenColors.flour.withValues(alpha: 0.7),
          foregroundColor: KitchenColors.espresso,
          disabledForegroundColor: KitchenColors.textMuted.withValues(
            alpha: 0.5,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.total,
    required this.quantity,
    required this.isAvailable,
    required this.onAddToCart,
  });

  final double total;
  final int quantity;
  final bool isAvailable;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = 12 + MediaQuery.of(context).padding.bottom;
    final label = isAvailable
        ? l10n.productAddToCartButton
        : l10n.productUnavailableButton;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KitchenColors.paper.withValues(alpha: 0.94),
          boxShadow: const [
            BoxShadow(
              color: Color(0x222D1B13),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(
            KitchenSpacing.lg,
            KitchenSpacing.sm,
            KitchenSpacing.lg,
            bottomInset,
          ),
          child: KitchenSurface(
            elevation: KitchenElevation.flat,
            borderRadius: BorderRadius.circular(KitchenRadius.lg),
            padding: const EdgeInsets.all(KitchenSpacing.xs),
            color: KitchenColors.paperLight.withValues(alpha: 0.92),
            child: KitchenEmbossedButton(
              enabled: isAvailable,
              onPressed: isAvailable ? onAddToCart : null,
              semanticLabel: label,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(label)),
                  if (isAvailable) ...[
                    const SizedBox(width: KitchenSpacing.md),
                    Text(
                      formatPrice(total),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: KitchenColors.flour,
      child: Center(
        child: Icon(
          Icons.local_pizza_outlined,
          size: 64,
          color: KitchenColors.cognac,
        ),
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
      backgroundColor: KitchenColors.paper,
      appBar: AppBar(
        backgroundColor: KitchenColors.paper,
        foregroundColor: KitchenColors.espresso,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KitchenSpacing.lg),
          child: KitchenSurface(
            padding: const EdgeInsets.all(KitchenSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: KitchenColors.terracotta,
                ),
                const SizedBox(height: KitchenSpacing.sm),
                Text(
                  message,
                  style: KitchenTypography.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _friendlyProductError(Object error) {
  if (error is AppException) return error.message;
  return 'Impossible de charger ce produit pour le moment.';
}
