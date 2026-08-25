import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_client/core/theme/app_colors.dart';

/// Génère l'échelle typographique à partir de la font family du tenant.
///
/// Inter est utilisée par défaut (bundlée dans assets/fonts/) — aucun appel
/// réseau au boot. Poppins et Playfair Display sont chargées via Google Fonts
/// si le tenant les a configurées.
///
/// L'échelle est calibrée pour le style "food-forward minimaliste" :
/// hiérarchie forte, tailles généreuses, font-weight contrasté.
abstract final class AppTypography {
  /// Génère un [TextTheme] pour la [fontFamily] donnée.
  ///
  /// [fontFamily] doit être `null` (Inter), `'poppins'`, ou `'playfair_display'`.
  /// Toute autre valeur est ignorée silencieusement → fallback Inter.
  static TextTheme generate({String? fontFamily}) {
    final base = _baseTheme();
    if (fontFamily == null) return base;

    return switch (fontFamily) {
      'poppins' => GoogleFonts.poppinsTextTheme(base),
      'playfair_display' => GoogleFonts.playfairDisplayTextTheme(base),
      _ => base,
    };
  }

  static TextTheme _baseTheme() => const TextTheme(
        // Héros : titre de page principale, bannière produit prominent
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -1.0,
        ),

        // Section : titre de catégorie, heading de fiche produit
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.5,
        ),

        // Carte produit : nom du produit — doit tenir en 2 lignes max
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),

        // Corps : description produit, contenu textuel général
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),

        // Corps secondaire : allergènes, conditions, mentions légales
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.grey700,
        ),

        // Badge, prix, label important
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),

        // Micro-label : statut commande, tag disponibilité
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      );
}
