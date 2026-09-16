import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_shadows.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/features/promotions/models/promotion.dart';
import 'package:app_client/features/promotions/providers/promotions_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';

const double _promoHeroCompactHeight = 212;
const double _promoHeroWideHeight = 228;
const double _promoHeroWideBreakpoint = 620;

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
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(
          KitchenSpacing.lg,
          0,
          KitchenSpacing.lg,
          KitchenSpacing.md,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxWidth >= _promoHeroWideBreakpoint
                ? _promoHeroWideHeight
                : _promoHeroCompactHeight;

            return SizedBox(
              height: height,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(KitchenRadius.xl),
                  ),
                  color: KitchenColors.flour,
                  boxShadow: KitchenShadows.soft,
                ),
                child: Center(
                  child: KitchenLoadingIndicator(
                    color: KitchenColors.cognac,
                    size: 34,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (promotions) {
        if (promotions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: KitchenSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxWidth >= _promoHeroWideBreakpoint
                  ? _promoHeroWideHeight
                  : _promoHeroCompactHeight;

              return Column(
                children: [
                  SizedBox(
                    height: height,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: promotions.length,
                      onPageChanged: (index) => setState(() => _page = index),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KitchenSpacing.lg,
                        ),
                        child: _HeroSlide(promotion: promotions[index]),
                      ),
                    ),
                  ),
                  if (promotions.length > 1) ...[
                    const SizedBox(height: KitchenSpacing.sm),
                    _Dots(count: promotions.length, activeIndex: _page),
                  ],
                ],
              );
            },
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
    final l10n = AppLocalizations.of(context)!;
    final code = promotion.code.trim().toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(KitchenRadius.xl),
        onTap: () => context.push(AppRoutes.promotions),
        child: Ink(
          key: const Key('promo-hero-card'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KitchenRadius.xl),
            boxShadow: KitchenShadows.raised,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(KitchenRadius.xl),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 430;
                final textWidthFactor = isCompact ? 0.68 : 0.56;
                final imageWidth = isCompact ? 300.0 : 420.0;
                final imageRight = isCompact ? -116.0 : -78.0;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            KitchenColors.espresso,
                            KitchenColors.cognacPressed,
                            KitchenColors.terracotta,
                          ],
                          stops: [0, 0.58, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -24,
                      top: 20,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: KitchenColors.olive.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                    Positioned(
                      right: imageRight,
                      top: isCompact ? -24 : -44,
                      bottom: isCompact ? -42 : -62,
                      width: imageWidth,
                      child: IgnorePointer(
                        child: Image.asset(
                          KitchenAssets.heroHomePromo,
                          key: const Key('promo-hero-image'),
                          fit: BoxFit.contain,
                          alignment: Alignment.centerRight,
                          semanticLabel: 'Pizza promotionnelle KOD MOME',
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            KitchenColors.espresso.withValues(alpha: 0.90),
                            KitchenColors.espresso.withValues(alpha: 0.64),
                            KitchenColors.espresso.withValues(
                              alpha: isCompact ? 0.38 : 0.08,
                            ),
                          ],
                          stops: const [0, 0.50, 1],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isCompact ? KitchenSpacing.md : KitchenSpacing.lg,
                          KitchenSpacing.md,
                          KitchenSpacing.md,
                          KitchenSpacing.md,
                        ),
                        child: SizedBox(
                          width: constraints.maxWidth * textWidthFactor,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _PromoEyebrow(),
                              const SizedBox(height: KitchenSpacing.xs),
                              Text(
                                promotion.displayDiscount,
                                style: KitchenTypography.title.copyWith(
                                  color: KitchenColors.whiteWarm,
                                  fontSize: 45,
                                  height: 0.92,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: KitchenSpacing.xs),
                              Text(
                                promotion.displayTitle,
                                style: KitchenTypography.body.copyWith(
                                  color: KitchenColors.whiteWarm,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  height: 1.18,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: KitchenSpacing.sm),
                              Wrap(
                                spacing: KitchenSpacing.xs,
                                runSpacing: KitchenSpacing.xs,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (code.isNotEmpty)
                                    _PromoCodeBadge(code: code),
                                  _PromoCta(label: l10n.promoViewOffer),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoEyebrow extends StatelessWidget {
  const _PromoEyebrow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KitchenColors.whiteWarm.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        border: Border.all(
          color: KitchenColors.whiteWarm.withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KitchenSpacing.sm,
          vertical: 5,
        ),
        child: Text(
          'OFFRE DU MOMENT',
          style: KitchenTypography.label.copyWith(
            color: KitchenColors.whiteWarm,
            fontSize: 11,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _PromoCodeBadge extends StatelessWidget {
  const _PromoCodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KitchenColors.whiteWarm,
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KitchenSpacing.sm,
          vertical: 7,
        ),
        child: Text(
          'Code $code',
          style: KitchenTypography.label.copyWith(
            color: KitchenColors.espresso,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _PromoCta extends StatelessWidget {
  const _PromoCta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KitchenColors.whiteWarm.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(KitchenRadius.pill),
        border: Border.all(
          color: KitchenColors.whiteWarm.withValues(alpha: 0.30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KitchenSpacing.sm,
          vertical: 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: KitchenTypography.label.copyWith(
                color: KitchenColors.whiteWarm,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: KitchenSpacing.xxs),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: KitchenColors.whiteWarm,
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
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? KitchenColors.cognac
                : KitchenColors.brown700.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
