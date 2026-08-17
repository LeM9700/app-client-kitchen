import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/promotions/models/promotion.dart';
import 'package:app_client/features/promotions/providers/promotions_provider.dart';

/// Hero carrousel de la home — met en avant les promotions actives.
///
/// Swipe manuel avec indicateurs (dots), pas d'autoplay forcé (voir décision
/// UX Phase 13 de l'audit home). Se masque silencieusement s'il n'y a aucune
/// promotion active.
class PromoHeroCarousel extends ConsumerStatefulWidget {
  const PromoHeroCarousel({super.key});

  @override
  ConsumerState<PromoHeroCarousel> createState() => _PromoHeroCarouselState();
}

class _PromoHeroCarouselState extends ConsumerState<PromoHeroCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(promotionsProvider);

    return promotionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: ShimmerBlock(height: 120, borderRadius: 16),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (promotions) {
        if (promotions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              SizedBox(
                height: 120,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: promotions.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _HeroSlide(promotion: promotions[index]),
                  ),
                ),
              ),
              if (promotions.length > 1) ...[
                const SizedBox(height: 10),
                _Dots(count: promotions.length, activeIndex: _page),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(AppRoutes.promotions),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.brandRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                promotion.displayDiscount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    promotion.displayTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Voir l'offre",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandRed : AppColors.grey200,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
