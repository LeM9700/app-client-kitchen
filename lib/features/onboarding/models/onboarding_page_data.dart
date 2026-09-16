import 'package:app_client/core/theme/kitchen_tokens.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.assetPath,
    required this.title,
    required this.description,
    required this.signature,
  });

  final String assetPath;
  final String title;
  final String description;
  final String signature;
}

const kitchenOnboardingPages = [
  OnboardingPageData(
    assetPath: KitchenAssets.onboardingIngredients,
    title: 'Des ingrédients\nsélectionnés',
    description:
        'Des produits frais et de qualité\npour des pizzas authentiques.',
    signature: 'Le goût\nd’abord',
  ),
  OnboardingPageData(
    assetPath: KitchenAssets.onboardingCraft,
    title: 'Préparées\navec passion',
    description:
        'Un savoir-faire artisanal\npour des pizzas pleines de caractère.',
    signature: 'Plus qu’une pizza,\nune émotion',
  ),
];
