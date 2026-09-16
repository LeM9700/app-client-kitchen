import 'package:flutter/material.dart';

abstract final class KitchenAssets {
  static const String splashBackground =
      'assets/images/kod-mome/splash_background.webp';
  static const String loginBackground =
      'assets/images/kod-mome/login_background.webp';
  static const String onboardingIngredients =
      'assets/images/kod-mome/onboarding_ingredients.webp';
  static const String onboardingCraft =
      'assets/images/kod-mome/onboarding_craft.webp';
  static const String heroHomePromo =
      'assets/images/kod-mome/hero_home_promo.webp';
  static const String localLogo = 'assets/images/kod-mome/medallion.jpg';
}

abstract final class KitchenColors {
  static const Color paper = Color(0xFFF4EBDD);
  static const Color paperLight = Color(0xFFFFF8EE);
  static const Color surface = Color(0xFFF8F0E5);
  static const Color espresso = Color(0xFF2D1B13);
  static const Color brown900 = Color(0xFF321B12);
  static const Color brown700 = Color(0xFF70401F);
  static const Color cognac = Color(0xFF985522);
  static const Color cognacPressed = Color(0xFF7E451B);
  static const Color olive = Color(0xFF627A45);
  static const Color textPrimary = Color(0xFF2D1B13);
  static const Color textMuted = Color(0xFF76685E);
  static const Color whiteWarm = Color(0xFFFFFDF8);
  static const Color flour = Color(0xFFE9D9C2);
  static const Color terracotta = Color(0xFFB84D33);
  static const Color warmShadow = Color(0x402D1B13);
  static const Color warmHighlight = Color(0xCFFFF8EE);
  static const Color photoScrim = Color(0x661D100B);
}

abstract final class KitchenGradients {
  static const LinearGradient paper = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      KitchenColors.paperLight,
      KitchenColors.paper,
      KitchenColors.surface,
    ],
  );

  static const LinearGradient cognac = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB56A2C),
      KitchenColors.cognac,
      KitchenColors.cognacPressed,
    ],
  );
}
