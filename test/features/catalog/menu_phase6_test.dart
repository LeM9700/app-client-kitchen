import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/features/cart/models/menu_cart_item.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/cart/screens/cart_screen.dart';
import 'package:app_client/features/catalog/models/menu.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/menu_provider.dart';
import 'package:app_client/features/catalog/repositories/menu_repository.dart';
import 'package:app_client/features/catalog/screens/menu_detail_screen.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  group('MenuRepository', () {
    test('parse le listing public et ses disponibilites', () async {
      final client = _MockApiClient();
      when(
        () => client.get<Map<String, dynamic>>(
          ApiEndpoints.menus,
          queryParameters: {'page': 1, 'page_size': 100},
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [_menuJson()],
            'total': 1,
            'page': 1,
            'page_size': 100,
            'pages': 1,
          },
          requestOptions: RequestOptions(path: ApiEndpoints.menus),
        ),
      );

      final menus = await MenuRepository(client).getMenus();

      expect(menus, hasLength(1));
      expect(menus.single.name, 'Menu midi');
      expect(menus.single.groups, hasLength(2));
      expect(
        menus.single.groups.first.products.first.product.isAvailable,
        isTrue,
      );
      expect(
        menus.single.groups.first.products.first.product.variants.first.name,
        'Grande',
      );
    });
  });

  group('panier menu', () {
    test('conserve le prix fixe et produit le payload de commande', () {
      final item = _cartMenuItem();
      final notifier = CartNotifier()..addMenuItem(item);

      expect(notifier.state.subtotal, 16.9);
      expect(notifier.state.totalQuantity, 1);
      expect(item.unitPrice, 16.9);
      expect(item.selections.first.optionLabels, ['Grande', 'Fromage']);
      expect(item.toOrderJson(), {
        'menu_id': 12,
        'quantity': 1,
        'selections': [
          {
            'group_id': 31,
            'product_id': 8,
            'quantity': 1,
            'variant_id': 81,
            'extras': [
              {'extra_id': 91, 'quantity': 1},
            ],
          },
          {
            'group_id': 32,
            'product_id': 9,
            'quantity': 1,
          },
        ],
      });
    });

    testWidgets('affiche la ligne parent puis les composants', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).addMenuItem(_cartMenuItem());
      final router = GoRouter(
        initialLocation: AppRoutes.cart,
        routes: [
          GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartScreen()),
          GoRoute(
            path: AppRoutes.checkout,
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Menu midi'), findsOneWidget);
      expect(find.text('Pizza : Margherita'), findsOneWidget);
      expect(find.text('Grande, Fromage'), findsOneWidget);
      expect(find.text('Boisson : Cola'), findsOneWidget);
      expect(find.textContaining('16.90'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('MenuDetailScreen', () {
    testWidgets('bloque puis ajoute une composition complete', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          menuDetailProvider.overrideWith((ref, id) async => _menu()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const MenuDetailScreen(menuId: 12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var addButton = tester.widget<KitchenEmbossedButton>(
        find.widgetWithText(KitchenEmbossedButton, 'Ajouter le menu'),
      );
      expect(addButton.enabled, isFalse);

      await _tapChoice(tester, 'Margherita');
      await tester.tap(find.text('Fromage'));
      await tester.tap(find.text('Valider ce choix'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Cola'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await _tapChoice(tester, 'Cola');
      await tester.tap(find.text('Valider ce choix'));
      await tester.pumpAndSettle();

      addButton = tester.widget<KitchenEmbossedButton>(
        find.widgetWithText(KitchenEmbossedButton, 'Ajouter le menu'),
      );
      expect(addButton.enabled, isTrue);
      await tester
          .tap(find.widgetWithText(KitchenEmbossedButton, 'Ajouter le menu'));
      await tester.pump();

      final cart = container.read(cartProvider);
      expect(cart.menuItemList, hasLength(1));
      expect(cart.menuItemList.single.selections, hasLength(2));
      expect(cart.subtotal, 16.9);
      expect(tester.takeException(), isNull);
    });
  });

  test('OrderItem parse une ligne menu avec ses composants', () {
    final item = OrderItem.fromJson({
      'id': 100,
      'item_type': 'menu',
      'parent_item_id': null,
      'menu_id': 12,
      'menu_name': 'Menu midi',
      'product_id': null,
      'quantity': 1,
      'unit_price': 16.9,
      'extras_total': 0.0,
      'total': 16.9,
      'extras': <dynamic>[],
      'components': [
        {
          'id': 101,
          'item_type': 'menu_component',
          'parent_item_id': 100,
          'menu_id': 12,
          'menu_name': 'Menu midi',
          'menu_group_id': 31,
          'menu_group_name': 'Pizza',
          'product_id': 8,
          'product_name': 'Margherita',
          'quantity': 1,
          'unit_price': 0.0,
          'extras_total': 0.0,
          'total': 0.0,
          'extras': <dynamic>[],
          'components': <dynamic>[],
        },
      ],
    });

    expect(item.productId, isNull);
    expect(item.menuName, 'Menu midi');
    expect(item.components.single.menuGroupName, 'Pizza');
    expect(item.components.single.productName, 'Margherita');
  });
}

Future<void> _tapChoice(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

MenuCartItem _cartMenuItem() {
  final menu = _menu();
  return MenuCartItem(
    menu: menu,
    selections: [
      MenuCartSelection(
        groupId: 31,
        groupName: 'Pizza',
        product: _pizza,
        selectedVariant: _pizza.variants.first,
        selectedExtraIds: const {91},
      ),
      const MenuCartSelection(
        groupId: 32,
        groupName: 'Boisson',
        product: _drink,
      ),
    ],
  );
}

CatalogMenu _menu({bool available = true}) {
  return CatalogMenu(
    id: 12,
    name: 'Menu midi',
    description: 'Une pizza et une boisson.',
    fixedPrice: 16.9,
    displayOrder: 0,
    isAvailable: available,
    unavailableReasons:
        available ? const [] : const ['Une selection est indisponible.'],
    groups: const [
      CatalogMenuGroup(
        id: 31,
        name: 'Pizza',
        minChoices: 1,
        maxChoices: 1,
        displayOrder: 0,
        isAvailable: true,
        products: [
          CatalogMenuProduct(
            menuGroupItemId: 301,
            displayOrder: 0,
            product: _pizza,
            isOperationallyAvailable: true,
          ),
        ],
      ),
      CatalogMenuGroup(
        id: 32,
        name: 'Boisson',
        minChoices: 1,
        maxChoices: 1,
        displayOrder: 1,
        isAvailable: true,
        products: [
          CatalogMenuProduct(
            menuGroupItemId: 302,
            displayOrder: 0,
            product: _drink,
            isOperationallyAvailable: true,
          ),
        ],
      ),
    ],
  );
}

const _pizza = Product(
  id: 8,
  name: 'Margherita',
  price: 12,
  categoryId: 1,
  variants: [ProductVariant(id: 81, name: 'Grande', priceDelta: 3)],
  extras: [ProductExtra(id: 91, name: 'Fromage', price: 2)],
);

const _drink = Product(
  id: 9,
  name: 'Cola',
  price: 3,
  categoryId: 2,
);

Map<String, dynamic> _menuJson() => {
      'id': 12,
      'name': 'Menu midi',
      'description': 'Une pizza et une boisson.',
      'fixed_price': 16.9,
      'image_url': null,
      'display_order': 0,
      'available_from': null,
      'available_until': null,
      'is_available': true,
      'unavailable_reasons': <String>[],
      'groups': [
        {
          'id': 31,
          'name': 'Pizza',
          'min_choices': 1,
          'max_choices': 1,
          'display_order': 0,
          'is_available': true,
          'unavailable_reason': null,
          'products': [
            {
              'id': 8,
              'name': 'Margherita',
              'base_price': 12.0,
              'category_id': 1,
              'is_active': true,
              'menu_group_item_id': 301,
              'display_order': 0,
              'availability': {'available': true},
              'allergens': <dynamic>[],
              'variants': [
                {
                  'id': 81,
                  'product_id': 8,
                  'name': 'Grande',
                  'price_delta': 3.0,
                  'is_active': true,
                },
              ],
              'extras': [
                {
                  'id': 91,
                  'name': 'Fromage',
                  'price': 2.0,
                  'is_active': true,
                },
              ],
            },
          ],
        },
        {
          'id': 32,
          'name': 'Boisson',
          'min_choices': 1,
          'max_choices': 1,
          'display_order': 1,
          'is_available': true,
          'unavailable_reason': null,
          'products': <dynamic>[],
        },
      ],
    };
