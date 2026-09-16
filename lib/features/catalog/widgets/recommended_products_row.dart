import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';

class RecommendedProductsRow extends ConsumerWidget {
  const RecommendedProductsRow({
    super.key,
    required this.categoryId,
    required this.currentProductId,
  });

  final int? categoryId;
  final int currentProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = this.categoryId;
    if (categoryId == null) return const SizedBox.shrink();

    final productsAsync = ref.watch(productsByCategoryProvider(categoryId));

    return productsAsync.when(
      loading: () => const SizedBox(height: 140),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        final recommendations = products
            .where(
              (product) =>
                  product.id != currentProductId && product.isAvailable,
            )
            .take(6)
            .toList();

        if (recommendations.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: KitchenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KitchenSpacing.lg,
                  0,
                  KitchenSpacing.lg,
                  KitchenSpacing.sm,
                ),
                child: Text(
                  'Vous aimerez aussi',
                  style: KitchenTypography.title.copyWith(fontSize: 26),
                ),
              ),
              SizedBox(
                height: 226,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: KitchenSpacing.lg,
                  ),
                  itemCount: recommendations.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: KitchenSpacing.md),
                  itemBuilder: (context, index) => SizedBox(
                    width: 152,
                    child: ProductCard(product: recommendations[index]),
                  ),
                ),
              ),
              const SizedBox(height: KitchenSpacing.lg),
              Divider(
                color: KitchenColors.brown700.withValues(alpha: 0.14),
              ),
            ],
          ),
        );
      },
    );
  }
}
