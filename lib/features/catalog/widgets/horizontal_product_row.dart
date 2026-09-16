import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';
import 'package:app_client/l10n/app_localizations.dart';

class HorizontalProductRow extends StatelessWidget {
  const HorizontalProductRow({
    super.key,
    required this.title,
    required this.productsAsync,
    this.onSeeAll,
  });

  final String title;
  final AsyncValue<List<Product>> productsAsync;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return productsAsync.when(
      loading: () => _RowSkeleton(title: title),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: KitchenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RowHeader(title: title, onSeeAll: onSeeAll),
              SizedBox(
                height: 252,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: KitchenSpacing.lg,
                  ),
                  itemCount: products.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: KitchenSpacing.md),
                  itemBuilder: (_, index) => SizedBox(
                    width: 166,
                    child: ProductCard(
                      product: products[index],
                      enableHero: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RowHeader extends StatelessWidget {
  const _RowHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.sm,
        KitchenSpacing.md,
        KitchenSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: KitchenTypography.title.copyWith(fontSize: 28),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                AppLocalizations.of(context)!.productRowSeeAll,
                style: KitchenTypography.label.copyWith(
                  color: KitchenColors.cognac,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KitchenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RowHeader(title: title),
          SizedBox(
            height: 252,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: KitchenSpacing.lg,
              ),
              itemCount: 3,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: KitchenSpacing.md),
              itemBuilder: (_, __) => const SizedBox(
                width: 166,
                child: KitchenSurface(
                  borderRadius: BorderRadius.all(
                    Radius.circular(KitchenRadius.lg),
                  ),
                  child: Center(
                    child: KitchenLoadingIndicator(
                      color: KitchenColors.cognac,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
