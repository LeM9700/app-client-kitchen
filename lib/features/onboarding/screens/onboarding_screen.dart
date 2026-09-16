import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_icon_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_page_indicator.dart';
import 'package:app_client/features/onboarding/models/onboarding_page_data.dart';
import 'package:app_client/features/onboarding/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _activeIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingStorageProvider).setCompleted();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _next() async {
    if (_activeIndex == kitchenOnboardingPages.length - 1) {
      await _finish();
      return;
    }
    HapticFeedback.selectionClick();
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPhotoHeight = (size.height * 0.53).clamp(290.0, 520.0);

    return Scaffold(
      backgroundColor: KitchenColors.paper,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: kitchenOnboardingPages.length,
              onPageChanged: (index) => setState(() => _activeIndex = index),
              itemBuilder: (context, index) {
                return _OnboardingPage(
                  data: kitchenOnboardingPages[index],
                  photoHeight: topPhotoHeight,
                  pageController: _pageController,
                  index: index,
                );
              },
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 16,
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  foregroundColor: KitchenColors.espresso,
                  backgroundColor:
                      KitchenColors.paperLight.withValues(alpha: 0.72),
                ),
                child: const Text('Passer'),
              ),
            ),
            Positioned(
              left: KitchenSpacing.xl,
              right: KitchenSpacing.xl,
              bottom: MediaQuery.paddingOf(context).bottom + 28,
              child: Row(
                children: [
                  KitchenPageIndicator(
                    count: kitchenOnboardingPages.length,
                    activeIndex: _activeIndex,
                  ),
                  const Spacer(),
                  KitchenIconButton(
                    icon: Icons.arrow_forward_rounded,
                    semanticLabel:
                        _activeIndex == kitchenOnboardingPages.length - 1
                            ? 'Terminer'
                            : 'Page suivante',
                    onPressed: _next,
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.photoHeight,
    required this.pageController,
    required this.index,
  });

  final OnboardingPageData data;
  final double photoHeight;
  final PageController pageController;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        final page = pageController.hasClients
            ? pageController.page ?? pageController.initialPage.toDouble()
            : 0.0;
        final delta = (page - index).clamp(-1.0, 1.0);
        return Stack(
          children: [
            SizedBox(
              height: photoHeight,
              width: double.infinity,
              child: Transform.translate(
                offset: Offset(delta * -18, 0),
                child: Image.asset(
                  data.assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            Positioned(
              top: photoHeight - 130,
              left: 0,
              right: 0,
              height: 190,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      KitchenColors.paper.withValues(alpha: 0),
                      KitchenColors.paper.withValues(alpha: 0.92),
                      KitchenColors.paper,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: photoHeight - 34,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 124),
                child: Transform.translate(
                  offset: Offset(delta * 22, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        textScaler: TextScaler.linear(
                          MediaQuery.textScalerOf(context)
                              .scale(1)
                              .clamp(1.0, 1.18)
                              .toDouble(),
                        ),
                        style: KitchenTypography.display.copyWith(
                          fontSize: 42,
                          height: 0.96,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        data.description,
                        style: KitchenTypography.body.copyWith(
                          fontSize: 17,
                          color: KitchenColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        data.signature,
                        style: KitchenTypography.signature.copyWith(
                          fontSize: 30,
                          color: KitchenColors.brown700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
