import 'package:flutter/material.dart';

/// Palette de couleurs fixes de l'application, indépendantes du tenant.
///
/// Les couleurs tenant (primaire/secondaire) sont dans [TenantBrandingX].
/// Ces couleurs sont utilisées pour les surfaces, les états, et les neutres.
abstract final class AppColors {
  // Brand demo palette inspired by the supplied mobile mockups.
  static const Color brandRed = Color(0xFFFF0045);
  static const Color brandRedSoft = Color(0xFFE7B2B2);
  static const Color brandGreen = Color(0xFF285A50);
  static const Color priceGreen = Color(0xFF087A33);

  // ── Neutres ───────────────────────────────────────────────────────────────
  static const Color black = Color(0xFF0D0D0D);
  static const Color white = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E5E5);
  static const Color grey400 = Color(0xFF9E9E9E);
  static const Color grey700 = Color(0xFF616161);

  // ── États ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB71C1C);
  static const Color warning = Color(0xFFF57F17);
  static const Color info = Color(0xFF01579B);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// Overlay semi-transparent sur les photos hero (food-forward).
  /// 50% noir pour garantir la lisibilité du texte sur images claires.
  static const Color photoOverlay = Color(0x80000000);
}
