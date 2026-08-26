import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/generated/favorites_client/favorites.swagger.dart';

/// POC — client généré depuis openapi/favorites.json (voir
/// docs/openapi-codegen.md). Valide que les modèles générés
/// (dé)sérialisent correctement des payloads conformes au contrat réel de
/// `api-pizza/app/modules/favorites/schemas.py` — l'objectif du chantier
/// (réduire le risque de dérive de contrat), pas juste que le code compile.
void main() {
  group('Client généré OpenAPI — favorites', () {
    test('FavoriteResponse.fromJson lit un payload conforme au serveur', () {
      final response = FavoriteResponse.fromJson(const {
        'id': 12,
        'product_id': 34,
        'created_at': '2026-08-25T10:30:00Z',
      });

      expect(response.id, 12);
      expect(response.productId, 34);
      expect(response.createdAt, DateTime.parse('2026-08-25T10:30:00Z'));
    });

    test('FavoriteCreate.toJson produit le payload attendu par POST /favorites', () {
      const create = FavoriteCreate(productId: 42);

      expect(create.toJson(), {'product_id': 42});
    });

    test(
        'HTTPValidationError.fromJson lit une 422 FastAPI standard '
        '(GET /favorites/{product_id} avec un id non numérique)', () {
      final error = HTTPValidationError.fromJson(const {
        'detail': [
          {
            'loc': ['path', 'product_id'],
            'msg': 'Input should be a valid integer',
            'type': 'int_parsing',
          },
        ],
      });

      expect(error.detail, hasLength(1));
      expect(error.detail!.first.msg, 'Input should be a valid integer');
    });
  });
}
