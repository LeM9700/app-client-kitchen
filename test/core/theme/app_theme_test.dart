import 'package:app_client/core/models/tenant_branding.dart';
import 'package:app_client/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TenantBranding', () {
    test('demo() retourne le branding de la maquette client', () {
      final branding = TenantBranding.demo();
      expect(branding.primaryColor, const Color(0xFFFF0045));
      expect(branding.secondaryColor, const Color(0xFF285A50));
      expect(branding.slug, 'demo');
    });

    test('parse correctement une couleur hex #RRGGBB', () {
      const branding = TenantBranding(slug: 'test', primaryColorHex: '#E63946');
      expect(branding.primaryColor, const Color(0xFFE63946));
    });

    test('retourne la couleur par défaut si primaryColorHex est null', () {
      const branding = TenantBranding(slug: 'test');
      expect(branding.primaryColor, const Color(0xFFFF0045));
    });

    test('retourne la couleur par défaut si hex malformé', () {
      const branding = TenantBranding(slug: 'test', primaryColorHex: 'invalid');
      expect(branding.primaryColor, const Color(0xFFFF0045));
    });

    test('parse correctement depuis JSON (format API)', () {
      final json = {
        'slug': 'pizzeria-roma',
        'display_name': 'Pizzeria Roma',
        'logo_url': 'https://example.com/logo.png',
        'primary_color': '#2ECC71',
        'secondary_color': '#1A1A2E',
        'font_family': 'poppins',
      };
      final branding = TenantBranding.fromJson(json);
      expect(branding.primaryColorHex, '#2ECC71');
      expect(branding.primaryColor, const Color(0xFF2ECC71));
      expect(branding.fontFamily, 'poppins');
      expect(branding.displayName, 'Pizzeria Roma');
    });

    test('fromJson tolère les champs null', () {
      final json = {'slug': 'test'};
      final branding = TenantBranding.fromJson(json);
      expect(branding.primaryColorHex, isNull);
      expect(branding.logoUrl, isNull);
    });
  });

  group('AppTheme', () {
    test('génère un ThemeData valide depuis le branding de démo', () {
      final theme = AppTheme.generate(TenantBranding.demo());
      expect(theme, isA<ThemeData>());
      expect(theme.colorScheme.primary, const Color(0xFFFF0045));
      expect(theme.useMaterial3, isTrue);
    });

    test('applique correctement la couleur primaire du tenant', () {
      const branding = TenantBranding(
        slug: 'test',
        primaryColorHex: '#3498DB',
      );
      final theme = AppTheme.generate(branding);
      expect(theme.colorScheme.primary, const Color(0xFF3498DB));
    });

    test('génère un ThemeData sans crash si tous les champs sont null', () {
      const branding = TenantBranding(slug: 'empty');
      expect(() => AppTheme.generate(branding), returnsNormally);
    });
  });
}
