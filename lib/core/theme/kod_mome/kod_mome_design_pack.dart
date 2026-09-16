import 'package:flutter/material.dart';

/// Bespoke design tokens for the Kod Mome tenant only — dark, glass,
/// neumorphic and gold-foil treatment lifted from the restaurant's real
/// brand assets (medallion logo, promo flyer, menu graphic).
///
/// This is deliberately NOT a generalized per-tenant design-token system:
/// gated everywhere by [Env.isKodMomeBuild], applied screen by screen. See
/// the "Kod Mome — DA sur-mesure" plan for the full rationale.
abstract final class KodMomeDesignPack {
  // ── Couleurs de marque (extraites des visuels réels) ───────────────────────
  static const String primaryHex = '#D4A73C'; // or / moutarde
  static const String secondaryHex = '#5B1220'; // bordeaux profond
  static const Color primary = Color(0xFFD4A73C);
  static const Color secondary = Color(0xFF5B1220);
  static const Color charcoal = Color(0xFF1A1714); // fond principal
  static const Color charcoalDeep = Color(0xFF171310); // fond le plus sombre
  static const Color cream =
      Color(0xFFF2E9D8); // texte clair / liseré médaillon
  static const Color orangeAccent = Color(0xFFD98A3D); // médaillon
  static const Color redAccent = Color(0xFFC0272D); // accent promo/erreur

  /// `ColorScheme` réservé aux widgets bespoke des écrans retouchés — ne pas
  /// câbler dans le `ThemeData` global (voir `tenant_theme_provider.dart`).
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: charcoalDeep,
    secondary: secondary,
    onSecondary: cream,
    error: redAccent,
    onError: cream,
    surface: charcoal,
    onSurface: cream,
  );

  // ── Glass ────────────────────────────────────────────────────────────────
  /// Flou réel (`BackdropFilter`) — réservé à une seule surface héro par
  /// écran, jamais dans une liste qui scrolle (coût de repaint).
  static const double glassBlurSigmaHero = 18;
  static const double glassOpacity = 0.12;
  static const List<Color> glassBorderGradient = [
    Color(0x59F2E9D8), // cream @ 35%
    Color(0x14F2E9D8), // cream @ 8%
  ];

  // ── Neumorphism ──────────────────────────────────────────────────────────
  static const Color neuLightShadow = Color(0x14F2E9D8); // cream, faible
  static const Color neuDarkShadow = Color(0x99000000); // noir, marqué
  static const Offset neuOffset = Offset(6, 6);
  static const double neuBlur = 12;

  // ── Or / shimmer ─────────────────────────────────────────────────────────
  static const List<Color> goldGradient = [
    Color(0xFFF2D680),
    primary,
    Color(0xFF9C7A1E),
  ];
  static const Duration shimmerDuration = Duration(milliseconds: 2200);

  // ── Assets ───────────────────────────────────────────────────────────────
  static const String medallionAssetPath =
      'assets/images/kod-mome/medallion.jpg';

  // ── Motion ───────────────────────────────────────────────────────────────
  static const Duration entranceDuration = Duration(milliseconds: 450);
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Duration microDuration = Duration(milliseconds: 120);
  static const Duration celebrationDuration = Duration(milliseconds: 900);
}
