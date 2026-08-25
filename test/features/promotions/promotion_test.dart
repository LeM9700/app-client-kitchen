import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/promotions/models/promotion.dart';

void main() {
  group('Promotion', () {
    test(
        'fromJson mappe les champs réels de PromotionPublicOut '
        '(discount_type "percent", ends_at → expiresAt, min_order_amount → '
        'minimumOrderAmount)', () {
      final promo = Promotion.fromJson({
        'id': 1,
        'code': 'TEST10',
        'description': 'Réduction de bienvenue',
        'discount_type': 'percent',
        'discount_value': 10,
        'min_order_amount': 15.0,
        'starts_at': '2026-07-01T00:00:00Z',
        'ends_at': '2026-08-01T00:00:00Z',
      });

      expect(promo.id, 1);
      expect(promo.code, 'TEST10');
      expect(promo.description, 'Réduction de bienvenue');
      expect(promo.discountType, DiscountType.percent);
      expect(promo.discountValue, 10);
      expect(promo.minimumOrderAmount, 15.0);
      expect(promo.startsAt, DateTime.parse('2026-07-01T00:00:00Z'));
      expect(promo.expiresAt, DateTime.parse('2026-08-01T00:00:00Z'));
    });

    test('fromJson mappe discount_type "fixed"', () {
      final promo = Promotion.fromJson({
        'id': 2,
        'code': 'FIXED5',
        'discount_type': 'fixed',
        'discount_value': 5,
      });

      expect(promo.discountType, DiscountType.fixed);
    });

    test('displayDiscount retourne le bon format pour percent', () {
      const promo = Promotion(
        id: 1,
        code: 'TEST10',
        discountType: DiscountType.percent,
        discountValue: 10,
      );
      expect(promo.displayDiscount, '-10%');
    });

    test('displayDiscount retourne le bon format pour fixed', () {
      const promo = Promotion(
        id: 2,
        code: 'TEST5',
        discountType: DiscountType.fixed,
        discountValue: 5,
      );
      expect(promo.displayDiscount, '-5.00 €');
    });

    test('displayTitle utilise description si renseignée', () {
      const promo = Promotion(
        id: 1,
        code: 'TEST10',
        description: 'Offre spéciale',
        discountType: DiscountType.percent,
        discountValue: 10,
      );
      expect(promo.displayTitle, 'Offre spéciale');
    });

    test('displayTitle retombe sur code si description absente ou vide', () {
      const withoutDescription = Promotion(
        id: 1,
        code: 'TEST10',
        discountType: DiscountType.percent,
        discountValue: 10,
      );
      expect(withoutDescription.displayTitle, 'TEST10');

      const withBlankDescription = Promotion(
        id: 1,
        code: 'TEST10',
        description: '   ',
        discountType: DiscountType.percent,
        discountValue: 10,
      );
      expect(withBlankDescription.displayTitle, 'TEST10');
    });

    test('isExpiringSoon true si expiration dans 12h', () {
      final promo = Promotion(
        id: 1,
        code: 'TEST',
        discountType: DiscountType.fixed,
        discountValue: 5,
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );
      expect(promo.isExpiringSoon, true);
    });

    test('isExpiringSoon false si expiration dans plus de 24h', () {
      final promo = Promotion(
        id: 1,
        code: 'TEST',
        discountType: DiscountType.fixed,
        discountValue: 5,
        expiresAt: DateTime.now().add(const Duration(days: 3)),
      );
      expect(promo.isExpiringSoon, false);
    });

    test('isExpiringSoon false si pas de date d\'expiration', () {
      const promo = Promotion(
        id: 1,
        code: 'TEST',
        discountType: DiscountType.fixed,
        discountValue: 5,
      );
      expect(promo.isExpiringSoon, false);
    });

    test('isExpiringSoon false si déjà expirée', () {
      final promo = Promotion(
        id: 1,
        code: 'TEST',
        discountType: DiscountType.fixed,
        discountValue: 5,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(promo.isExpiringSoon, false);
    });
  });
}
