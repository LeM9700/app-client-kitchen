import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/cart/models/menu_cart_item.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/menu.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/providers/menu_provider.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/catalog/repositories/menu_repository.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/repositories/checkout_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockCheckoutRepository extends Mock implements CheckoutRepository {}

class _MockCatalogRepository extends Mock implements CatalogRepository {}

class _MockMenuRepository extends Mock implements MenuRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<CartItem>[]);
    registerFallbackValue(<MenuCartItem>[]);
    registerFallbackValue(Options());
  });

  test('CheckoutRepository envoie menu_items sans prix client', () async {
    final client = _MockApiClient();
    when(
      () => client.post<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {'id': 77},
        requestOptions: RequestOptions(path: ApiEndpoints.orders),
      ),
    );

    final orderId = await CheckoutRepository(client).createOrder(
      items: const [],
      menuItems: [_item()],
      orderType: 'pickup',
      idempotencyKey: 'menu-order-key',
    );

    expect(orderId, 77);
    final request = verify(
      () => client.post<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: captureAny(named: 'data'),
        options: captureAny(named: 'options'),
      ),
    ).captured;
    final data = request.first as Map<String, dynamic>;
    final options = request.last as Options;
    expect(data['items'], isEmpty);
    expect(data['menu_items'], [
      {
        'menu_id': 12,
        'quantity': 1,
        'selections': [
          {
            'group_id': 31,
            'product_id': 8,
            'quantity': 1,
          },
        ],
      },
    ]);
    expect((data['menu_items'] as List).single, isNot(contains('fixed_price')));
    expect(options.headers?['Idempotency-Key'], 'menu-order-key');
  });

  test('revalidation bloque un menu devenu indisponible', () async {
    final checkout = _MockCheckoutRepository();
    final catalog = _MockCatalogRepository();
    final menus = _MockMenuRepository();
    final container = ProviderContainer(
      overrides: [
        checkoutRepositoryProvider.overrideWithValue(checkout),
        catalogRepositoryProvider.overrideWithValue(catalog),
        menuRepositoryProvider.overrideWithValue(menus),
      ],
    );
    addTearDown(container.dispose);
    container.listen(checkoutProvider, (_, __) {});
    container.read(cartProvider.notifier).addMenuItem(_item());
    when(() => menus.getMenu(12)).thenAnswer(
      (_) async => _menu(available: false),
    );

    await container.read(checkoutProvider.notifier).revalidateCart();

    final state = container.read(checkoutProvider);
    expect(state.currentStep, CheckoutStep.revalidation);
    expect(state.error, contains('recomposer'));
    expect(container.read(cartProvider).menuItemList, hasLength(1));
  });

  test('revalidation signale et applique un nouveau prix serveur', () async {
    final checkout = _MockCheckoutRepository();
    final catalog = _MockCatalogRepository();
    final menus = _MockMenuRepository();
    final container = ProviderContainer(
      overrides: [
        checkoutRepositoryProvider.overrideWithValue(checkout),
        catalogRepositoryProvider.overrideWithValue(catalog),
        menuRepositoryProvider.overrideWithValue(menus),
      ],
    );
    addTearDown(container.dispose);
    container.listen(checkoutProvider, (_, __) {});
    container.read(cartProvider.notifier).addMenuItem(_item());
    when(() => menus.getMenu(12)).thenAnswer(
      (_) async => _menu(fixedPrice: 18.5),
    );

    await container.read(checkoutProvider.notifier).revalidateCart();

    final state = container.read(checkoutProvider);
    expect(state.currentStep, CheckoutStep.revalidation);
    expect(state.menuPriceAlerts, hasLength(1));
    expect(state.menuPriceAlerts.single.oldPrice, 16.9);
    expect(state.menuPriceAlerts.single.newPrice, 18.5);
    expect(container.read(cartProvider).menuItemList.single.unitPrice, 18.5);
  });

  test('createOrder transmet les menus revalides au repository', () async {
    final checkout = _MockCheckoutRepository();
    final catalog = _MockCatalogRepository();
    final menus = _MockMenuRepository();
    final container = ProviderContainer(
      overrides: [
        checkoutRepositoryProvider.overrideWithValue(checkout),
        catalogRepositoryProvider.overrideWithValue(catalog),
        menuRepositoryProvider.overrideWithValue(menus),
      ],
    );
    addTearDown(container.dispose);
    container.listen(checkoutProvider, (_, __) {});
    container.read(cartProvider.notifier).addMenuItem(_item());
    when(() => menus.getMenu(12)).thenAnswer((_) async => _menu());
    when(
      () => checkout.createOrder(
        items: any(named: 'items'),
        menuItems: any(named: 'menuItems'),
        orderType: any(named: 'orderType'),
        idempotencyKey: any(named: 'idempotencyKey'),
        deliveryAddress: any(named: 'deliveryAddress'),
        deliveryZoneId: any(named: 'deliveryZoneId'),
        establishmentId: any(named: 'establishmentId'),
        deliveryLat: any(named: 'deliveryLat'),
        deliveryLng: any(named: 'deliveryLng'),
        customerPhone: any(named: 'customerPhone'),
        deliveryInstructions: any(named: 'deliveryInstructions'),
        promoCode: any(named: 'promoCode'),
      ),
    ).thenAnswer((_) async => 88);

    final result =
        await container.read(checkoutProvider.notifier).createOrder();

    expect(result, 88);
    final captured = verify(
      () => checkout.createOrder(
        items: any(named: 'items'),
        menuItems: captureAny(named: 'menuItems'),
        orderType: any(named: 'orderType'),
        idempotencyKey: any(named: 'idempotencyKey'),
        deliveryAddress: any(named: 'deliveryAddress'),
        deliveryZoneId: any(named: 'deliveryZoneId'),
        establishmentId: any(named: 'establishmentId'),
        deliveryLat: any(named: 'deliveryLat'),
        deliveryLng: any(named: 'deliveryLng'),
        customerPhone: any(named: 'customerPhone'),
        deliveryInstructions: any(named: 'deliveryInstructions'),
        promoCode: any(named: 'promoCode'),
      ),
    ).captured.single as List<MenuCartItem>;
    expect(captured, hasLength(1));
    expect(captured.single.menu.id, 12);
  });
}

MenuCartItem _item() => MenuCartItem(
      menu: _menu(),
      selections: const [
        MenuCartSelection(
          groupId: 31,
          groupName: 'Pizza',
          product: _product,
        ),
      ],
    );

CatalogMenu _menu({bool available = true, double fixedPrice = 16.9}) =>
    CatalogMenu(
      id: 12,
      name: 'Menu midi',
      fixedPrice: fixedPrice,
      displayOrder: 0,
      isAvailable: available,
      unavailableReasons: available ? const [] : const ['Produit indisponible'],
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
              product: _product,
              isOperationallyAvailable: true,
            ),
          ],
        ),
      ],
    );

const _product = Product(
  id: 8,
  name: 'Margherita',
  price: 12,
  categoryId: 1,
);
