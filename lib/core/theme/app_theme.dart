import 'package:flutter/material.dart';

import 'package:app_client/core/models/tenant_branding.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/core/theme/app_typography.dart';

/// Génère un [ThemeData] Material 3 complet à partir du branding tenant.
///
/// Entrée : [TenantBranding] (couleurs + font)
/// Sortie : [ThemeData] injecté dans [MaterialApp.theme]
///
/// Tous les composants Material (boutons, champs, cards, navigation) héritent
/// automatiquement des couleurs tenant via le [ColorScheme].
abstract final class AppTheme {
  /// Génère le [ThemeData] pour le [branding] donné.
  ///
  /// Appelé par [appThemeProvider] à chaque changement de branding.
  /// Le [ThemeData] est immutable — une nouvelle instance est créée si le
  /// branding change (ex: changement de couleur en prod via l'admin tenant).
  static ThemeData generate(TenantBranding branding) {
    final primary = branding.primaryColor;
    final secondary = branding.secondaryColor;
    final textTheme = AppTypography.generate(fontFamily: branding.fontFamily);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.white,

      // ── AppBar : fond blanc, pas d'ombre, titre centré ──────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.black),
        iconTheme: const IconThemeData(color: AppColors.black),
      ),

      // ── Boutons primaires : couleur tenant, hauteur fixe 52px ───────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.grey200,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelMedium?.copyWith(fontSize: 16),
          elevation: 0,
        ),
      ),

      // ── Boutons outline ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: BorderSide(color: secondary, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelMedium?.copyWith(fontSize: 16),
        ),
      ),

      // ── TextButton ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelMedium,
        ),
      ),

      // ── Champs de saisie ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.grey700),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.grey400),
      ),

      // ── Bottom navigation ─────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Indicateur de sélection : teinte primaire légère (12% opacité)
        indicatorColor: Colors.white,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? primary : Colors.white,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: Colors.white, size: 24);
        }),
      ),

      // ── Cards : sans élévation, bordure légère, coins arrondis ──────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.grey200),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Chips : filtres catégorie, allergènes ─────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        selectedColor: primary.withValues(alpha: 0.15),
        disabledColor: AppColors.grey200,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.black,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: AppColors.white),
      ),
    );
  }
}
