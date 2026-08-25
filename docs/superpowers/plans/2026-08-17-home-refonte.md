# Home Refonte (rows horizontales + hero) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer la grille produit unique de la home par un hero carrousel de promotions + des rows horizontales par section (Incontournables, catégories), rendre le cœur favori et le quick-add fonctionnels sur `ProductCard`, remonter la fidélité dans le header, désactiver honnêtement la cloche notifications, et corriger l'écran "Voir tout" (titre dynamique, retrait des filtres factices "Nearest"/"Best Rating", liste complète des catégories).

**Architecture:** Deux nouveaux widgets réutilisables (`HorizontalProductRow`, `PromoHeroCarousel`) consomment les providers Riverpod existants (`featuredProductsProvider`, `filteredProductsProvider`, `promotionsProvider`, `loyaltyAccountProvider`) — aucun nouveau endpoint backend. Les favoris sont un nouveau `StateNotifierProvider` 100% en mémoire (même convention que le panier, non persisté entre sessions).

**Tech Stack:** Flutter, flutter_riverpod (StateNotifierProvider/ConsumerWidget), go_router, mocktail + flutter_test pour les tests.

**Spec:** Synthèse cible Phase 14 de l'audit UX/UI home/catalogue (conversation du 2026-08-17) — portée limitée ici au sous-système 100% client (voir "Hors périmètre" ci-dessous).

## Global Constraints

- Aucun changement backend (`api-pizza`) dans ce plan.
- Aucune nouvelle dépendance pubspec — tout se construit avec ce qui est déjà déclaré.
- Les rows/hero se masquent silencieusement (pas d'`ErrorView` bruyant) en cas d'erreur ou de liste vide — une home ne doit pas afficher d'écran d'erreur par section.
- Ne pas inventer de données non supportées par l'API : pas de lien produit↔promotion (absent du modèle `Promotion`), donc pas de badge promo sur `ProductCard` ni de row "Offres du moment" basée sur des produits dans ce plan — le hero carrousel couvre déjà ce rôle avec les vraies données de `promotionsProvider`.
- La cloche notifications reste un icône non interactif (pas de `IconButton`) tant que le backend n'expose pas de flux de notifications consultable (`api-pizza/app/modules/notifications` ne gère que l'enregistrement des tokens push).
- L'adresse de livraison réelle dans le header, la persistance des favoris entre sessions, et le flux de notifications backend sont **hors périmètre** de ce plan (chantiers séparés).

---

## Task 1: FavoritesProvider

**Files:**
- Create: `lib/features/catalog/providers/favorites_provider.dart`
- Test: `test/features/catalog/favorites_provider_test.dart`

**Interfaces:**
- Produces: `favoritesProvider` (`StateNotifierProvider<FavoritesNotifier, Set<int>>`), `FavoritesNotifier.toggle(int productId)`, `FavoritesNotifier.isFavorite(int productId) → bool`. Task 2 consomme ces deux symboles.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/catalog/favorites_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/catalog/providers/favorites_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('favoritesProvider', () {
    test('vide par défaut', () {
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('toggle() ajoute un produit absent', () {
      container.read(favoritesProvider.notifier).toggle(1);

      expect(container.read(favoritesProvider), {1});
    });

    test('toggle() retire un produit déjà favori', () {
      final notifier = container.read(favoritesProvider.notifier);
      notifier.toggle(1);

      notifier.toggle(1);

      expect(container.read(favoritesProvider), isEmpty);
    });

    test('isFavorite() reflète le state courant', () {
      final notifier = container.read(favoritesProvider.notifier);

      expect(notifier.isFavorite(1), false);

      notifier.toggle(1);

      expect(notifier.isFavorite(1), true);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/catalog/favorites_provider_test.dart`
Expected: FAIL — `favorites_provider.dart` n'existe pas (erreur d'import).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/catalog/providers/favorites_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Favoris produits — 100% en mémoire pour cette v1 (même convention que
/// [CartState] pour le panier, voir `features/cart/providers/cart_provider.dart`).
/// Non persisté entre sessions : aucun backend favoris n'existe aujourd'hui
/// (vérifié, aucun module `favorites`/`wishlist` côté `api-pizza`) — la
/// persistance cross-session est un chantier séparé.
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>(
  (ref) => FavoritesNotifier(),
);

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super(const {});

  bool isFavorite(int productId) => state.contains(productId);

  void toggle(int productId) {
    final updated = Set<int>.from(state);
    if (!updated.remove(productId)) {
      updated.add(productId);
    }
    state = updated;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/catalog/favorites_provider_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/catalog/providers/favorites_provider.dart test/features/catalog/favorites_provider_test.dart
git commit -m "feat: add local favorites provider"
```

---

## Task 2: ProductCard — cœur favori fonctionnel

**Files:**
- Modify: `lib/features/catalog/widgets/product_card.dart`
- Test: `test/features/catalog/product_card_test.dart`

**Interfaces:**
- Consumes: `favoritesProvider`, `FavoritesNotifier.toggle` (Task 1).
- Produces: `ProductCard` reste le même widget public (`ProductCard({product})`), maintenant `ConsumerWidget` au lieu de `StatelessWidget` — Task 3 et `HorizontalProductRow`/`home_screen.dart`/`search_screen.dart` continuent de l'instancier à l'identique.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/catalog/product_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';

const _product = Product(id: 1, name: 'Margherita', price: 10);

Future<ProviderContainer> _pumpCard(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 240, child: ProductCard(product: _product)),
        ),
      ),
    ),
  );

  return container;
}

void main() {
  group('ProductCard favorite toggle', () {
    testWidgets('affiche un coeur vide par défaut', (tester) async {
      await _pumpCard(tester);

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('tap sur le coeur bascule le favori sans naviguer',
        (tester) async {
      final container = await _pumpCard(tester);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(container.read(favoritesProvider), {1});
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('un second tap retire le favori', (tester) async {
      final container = await _pumpCard(tester);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();

      expect(container.read(favoritesProvider), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/catalog/product_card_test.dart`
Expected: FAIL — le cœur ne réagit pas au tap (`favoritesProvider` reste vide après tap).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/catalog/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';

/// Photo-first product card used in catalogue grids and horizontal rows.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(product.id)),
    );

    return InkWell(
      onTap: () => context.push(AppRoutes.productDetail(product.id.toString())),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Hero(
                  tag: 'product-${product.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.expand(
                      child: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              cacheWidth: 520,
                              errorBuilder: (_, __, ___) =>
                                  const _ProductImagePlaceholder(),
                            )
                          : const _ProductImagePlaceholder(),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FavoriteButton(
                    isFavorite: isFavorite,
                    onTap: () =>
                        ref.read(favoritesProvider.notifier).toggle(product.id),
                  ),
                ),
                if (!product.isAvailable)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Indisponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (product.description != null && product.description!.isNotEmpty)
            Text(
              product.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              product.isAvailable
                  ? "Disponible aujourd'hui"
                  : 'Momentanement indisponible',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 3),
          Text(
            product.displayPrice,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.priceGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 17,
            color: isFavorite ? AppColors.brandRed : const Color(0xFF6E6E6E),
          ),
        ),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.grey100,
      child: Icon(
        Icons.local_pizza_outlined,
        size: 42,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/catalog/product_card_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Run the full existing test suite for regressions**

Run: `flutter test test/features/catalog/product_detail_screen_test.dart`
Expected: PASS — `product_detail_screen_test.dart` pompe `ProductDetailScreen`, qui inclut `RecommendedProductsRow` → `ProductCard` transitivement ; il ne fournit pas d'override pour `favoritesProvider`, ce qui est correct puisque `favoritesProvider` n'a pas de dépendance externe (repository) et fonctionne avec sa valeur par défaut.

- [ ] **Step 6: Commit**

```bash
git add lib/features/catalog/widgets/product_card.dart test/features/catalog/product_card_test.dart
git commit -m "feat: make product card favorite heart functional"
```

---

## Task 3: ProductCard — quick-add pour les produits simples

**Files:**
- Modify: `lib/features/catalog/widgets/product_card.dart`
- Modify test: `test/features/catalog/product_card_test.dart`

**Interfaces:**
- Consumes: `cartProvider.notifier.addItem(Product product, {int quantity, ProductVariant? variant, Set<int> extraIds})` (existant, `features/cart/providers/cart_provider.dart`).
- Produces: aucun nouveau symbole public — `ProductCard` garde la même signature.

**Règle d'affichage :** le bouton quick-add n'apparaît que si `product.isAvailable && !product.hasVariants && !product.hasExtras` — un produit avec un choix obligatoire (taille, suppléments) doit passer par la fiche détail, pas de simplification qui fausserait le prix.

- [ ] **Step 1: Write the failing test**

```dart
// Ajouter à test/features/catalog/product_card_test.dart, dans un nouveau group
import 'package:app_client/features/cart/providers/cart_provider.dart';

const _simpleProduct = Product(id: 1, name: 'Margherita', price: 10);
const _productWithVariant = Product(
  id: 2,
  name: 'Regina',
  price: 12,
  variants: [ProductVariant(id: 1, name: 'Grande', priceDelta: 3)],
);

Future<ProviderContainer> _pumpCardFor(
  WidgetTester tester,
  Product product,
) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 240, child: ProductCard(product: product)),
        ),
      ),
    ),
  );

  return container;
}

// Dans main(), nouveau group :
group('ProductCard quick-add', () {
  testWidgets('affiche le bouton quick-add pour un produit sans variante/extra',
      (tester) async {
    await _pumpCardFor(tester, _simpleProduct);

    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('masque le bouton quick-add si le produit a des variantes',
      (tester) async {
    await _pumpCardFor(tester, _productWithVariant);

    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('tap sur quick-add ajoute le produit au panier sans naviguer',
      (tester) async {
    final container = await _pumpCardFor(tester, _simpleProduct);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    final cart = container.read(cartProvider);
    expect(cart.totalQuantity, 1);
    expect(cart.itemList.single.product.id, _simpleProduct.id);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/catalog/product_card_test.dart`
Expected: FAIL — `find.byIcon(Icons.add)` ne trouve rien, le panier reste vide après tap.

- [ ] **Step 3: Write minimal implementation**

Dans `lib/features/catalog/widgets/product_card.dart` :
- Ajouter l'import `import 'package:app_client/features/cart/providers/cart_provider.dart';`
- Dans `build`, ajouter après le calcul de `isFavorite` :

```dart
    final canQuickAdd =
        product.isAvailable && !product.hasVariants && !product.hasExtras;
```

- Dans le `Stack`, ajouter juste après le bloc `_FavoriteButton` (avant le bloc `if (!product.isAvailable)`) :

```dart
                if (canQuickAdd)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _QuickAddButton(
                      onTap: () => _quickAdd(context, ref),
                    ),
                  ),
```

- Ajouter la méthode privée dans la classe `ProductCard` (après `build`) :

```dart
  void _quickAdd(BuildContext context, WidgetRef ref) {
    ref.read(cartProvider.notifier).addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajouté au panier')),
    );
  }
```

- Ajouter le widget privé (à côté de `_FavoriteButton`) :

```dart
class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.brandRed,
          shape: BoxShape.circle,
        ),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.add, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/catalog/product_card_test.dart`
Expected: PASS (6 tests au total : 3 favori + 3 quick-add)

- [ ] **Step 5: Run regression on product detail + checkout tests**

Run: `flutter test test/features/catalog/product_detail_screen_test.dart test/features/checkout`
Expected: PASS — `addItem` a la même signature, `ProductDetailScreen` continue d'appeler sa propre logique d'ajout (pas affectée).

- [ ] **Step 6: Commit**

```bash
git add lib/features/catalog/widgets/product_card.dart test/features/catalog/product_card_test.dart
git commit -m "feat: add quick-add button on product card for variant-free products"
```

---

## Task 4: HorizontalProductRow (widget réutilisable)

**Files:**
- Create: `lib/features/catalog/widgets/horizontal_product_row.dart`
- Test: `test/features/catalog/horizontal_product_row_test.dart`

**Interfaces:**
- Consumes: `ProductCard` (Task 2/3), `ShimmerBlock` (`core/widgets/shimmer_skeleton.dart`, existant).
- Produces: `HorizontalProductRow({required String title, required AsyncValue<List<Product>> productsAsync, VoidCallback? onSeeAll})` — Task 6 (`home_screen.dart`) l'instancie avec ces trois paramètres exacts.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/catalog/horizontal_product_row_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/widgets/horizontal_product_row.dart';

const _products = [
  Product(id: 1, name: 'Margherita', price: 10),
  Product(id: 2, name: 'Regina', price: 12),
];

Future<void> _pump(
  WidgetTester tester,
  AsyncValue<List<Product>> productsAsync, {
  VoidCallback? onSeeAll,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: HorizontalProductRow(
            title: 'Pizzas',
            productsAsync: productsAsync,
            onSeeAll: onSeeAll,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('HorizontalProductRow', () {
    testWidgets('affiche un skeleton pendant le chargement', (tester) async {
      await _pump(tester, const AsyncValue.loading());

      expect(find.byType(ShimmerBlock), findsWidgets);
      expect(find.text('Pizzas'), findsOneWidget);
    });

    testWidgets('affiche les produits en scroll horizontal', (tester) async {
      await _pump(tester, const AsyncValue.data(_products));

      expect(find.text('Margherita'), findsOneWidget);
      expect(find.text('Regina'), findsOneWidget);
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('se masque silencieusement si la liste est vide',
        (tester) async {
      await _pump(tester, const AsyncValue.data([]));

      expect(find.text('Pizzas'), findsNothing);
    });

    testWidgets("se masque silencieusement en cas d'erreur", (tester) async {
      await _pump(tester, AsyncValue.error('boom', StackTrace.empty));

      expect(find.text('Pizzas'), findsNothing);
    });

    testWidgets('"Voir tout" déclenche le callback', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        const AsyncValue.data(_products),
        onSeeAll: () => tapped = true,
      );

      await tester.tap(find.text('Voir tout'));

      expect(tapped, true);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/catalog/horizontal_product_row_test.dart`
Expected: FAIL — `horizontal_product_row.dart` n'existe pas.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/catalog/widgets/horizontal_product_row.dart
import 'package:flutter/material.dart';

import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';

/// Row horizontale de produits réutilisable pour les sections de la home
/// (Incontournables, catégories). Se masque silencieusement en cas d'erreur
/// ou de liste vide — une home ne doit pas afficher d'écran d'erreur par
/// section, seulement les sections qui ont du contenu.
class HorizontalProductRow extends StatelessWidget {
  const HorizontalProductRow({
    super.key,
    required this.title,
    required this.productsAsync,
    this.onSeeAll,
  });

  final String title;
  final AsyncValue<List<Product>> productsAsync;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return productsAsync.when(
      loading: () => _RowSkeleton(title: title),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RowHeader(title: title, onSeeAll: onSeeAll),
              SizedBox(
                height: 236,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, index) => SizedBox(
                    width: 160,
                    child: ProductCard(product: products[index]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RowHeader extends StatelessWidget {
  const _RowHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('Voir tout')),
        ],
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RowHeader(title: title),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ShimmerBlock(borderRadius: 8)),
                  SizedBox(height: 8),
                  ShimmerBlock(height: 14, width: 120),
                  SizedBox(height: 6),
                  ShimmerBlock(height: 12, width: 60),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/catalog/horizontal_product_row_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/catalog/widgets/horizontal_product_row.dart test/features/catalog/horizontal_product_row_test.dart
git commit -m "feat: add reusable horizontal product row widget"
```

---

## Task 5: PromoHeroCarousel

**Files:**
- Create: `lib/features/catalog/widgets/promo_hero_carousel.dart`
- Test: `test/features/catalog/promo_hero_carousel_test.dart`

**Interfaces:**
- Consumes: `promotionsProvider` (`FutureProvider.autoDispose<List<Promotion>>`, existant dans `features/promotions/providers/promotions_provider.dart`), `Promotion.displayDiscount`/`Promotion.displayTitle` (existants), `AppRoutes.promotions`.
- Produces: `PromoHeroCarousel()` — sans paramètre, Task 6 l'instancie directement.

**Décision UX (Phase 13 de l'audit) :** swipe manuel avec dots, **pas d'autoplay forcé** — un contenu qui défile seul sans contrôle utilisateur pose un problème d'accessibilité (WCAG 2.2 / RGAA, contenu en mouvement).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/catalog/promo_hero_carousel_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/catalog/widgets/promo_hero_carousel.dart';
import 'package:app_client/features/promotions/models/promotion.dart';
import 'package:app_client/features/promotions/providers/promotions_provider.dart';

const _promo1 = Promotion(
  id: 1,
  code: 'PIZZA20',
  description: '-20% sur les pizzas',
  discountType: DiscountType.percent,
  discountValue: 20,
);
const _promo2 = Promotion(
  id: 2,
  code: 'BOISSON1',
  description: 'Boisson offerte',
  discountType: DiscountType.fixed,
  discountValue: 2.5,
);

Future<void> _pump(
  WidgetTester tester, {
  required List<Promotion> promotions,
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(body: PromoHeroCarousel()),
      ),
      GoRoute(
        path: AppRoutes.promotions,
        builder: (_, __) => const Scaffold(body: Text('Promotions screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        promotionsProvider.overrideWith((ref) async => promotions),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PromoHeroCarousel', () {
    testWidgets('se masque silencieusement sans promotion active',
        (tester) async {
      await _pump(tester, promotions: []);

      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('affiche la première promo et ses dots', (tester) async {
      await _pump(tester, promotions: [_promo1, _promo2]);

      expect(find.text('-20%'), findsOneWidget);
      expect(find.text('-20% sur les pizzas'), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(2));
    });

    testWidgets('aucun dot si une seule promotion active', (tester) async {
      await _pump(tester, promotions: [_promo1]);

      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets("tap sur le slide navigue vers l'écran promotions",
        (tester) async {
      await _pump(tester, promotions: [_promo1]);

      await tester.tap(find.text('-20% sur les pizzas'));
      await tester.pumpAndSettle();

      expect(find.text('Promotions screen'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/catalog/promo_hero_carousel_test.dart`
Expected: FAIL — `promo_hero_carousel.dart` n'existe pas.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/catalog/widgets/promo_hero_carousel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/promotions/models/promotion.dart';
import 'package:app_client/features/promotions/providers/promotions_provider.dart';

/// Hero carrousel de la home — met en avant les promotions actives.
///
/// Swipe manuel avec indicateurs (dots), pas d'autoplay forcé (voir décision
/// UX Phase 13 de l'audit home). Se masque silencieusement s'il n'y a aucune
/// promotion active.
class PromoHeroCarousel extends ConsumerStatefulWidget {
  const PromoHeroCarousel({super.key});

  @override
  ConsumerState<PromoHeroCarousel> createState() => _PromoHeroCarouselState();
}

class _PromoHeroCarouselState extends ConsumerState<PromoHeroCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(promotionsProvider);

    return promotionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: ShimmerBlock(height: 120, borderRadius: 16),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (promotions) {
        if (promotions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              SizedBox(
                height: 120,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: promotions.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _HeroSlide(promotion: promotions[index]),
                  ),
                ),
              ),
              if (promotions.length > 1) ...[
                const SizedBox(height: 10),
                _Dots(count: promotions.length, activeIndex: _page),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(AppRoutes.promotions),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.brandRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                promotion.displayDiscount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    promotion.displayTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Voir l'offre",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandRed : AppColors.grey200,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/catalog/promo_hero_carousel_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/catalog/widgets/promo_hero_carousel.dart test/features/catalog/promo_hero_carousel_test.dart
git commit -m "feat: add promo hero carousel widget"
```

---

## Task 6: HomeScreen refonte

**Files:**
- Modify: `lib/features/catalog/screens/home_screen.dart` (remplacement complet du fichier)
- Test: `test/features/catalog/home_screen_test.dart`

**Interfaces:**
- Consumes: `HorizontalProductRow` (Task 4), `PromoHeroCarousel` (Task 5), `categoriesProvider`/`featuredProductsProvider`/`filteredProductsProvider`/`selectedCategoryProvider` (existants, `features/catalog/providers/catalog_provider.dart`), `accessTokenProvider` (existant, `core/providers/auth_token_provider.dart`), `loyaltyAccountProvider` (existant, `features/loyalty/providers/loyalty_provider.dart`).
- Produces: `HomeScreen` garde la même signature publique (`const HomeScreen()`), utilisée telle quelle par le router (`core/router/app_router.dart`) — aucun changement de route.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/catalog/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/screens/home_screen.dart';
import 'package:app_client/features/promotions/providers/promotions_provider.dart';

const _pizzaCategory = Category(id: 1, name: 'Pizzas');
const _dessertCategory = Category(id: 2, name: 'Desserts');

const _margherita =
    Product(id: 1, name: 'Margherita', price: 10, categoryId: 1);
const _tiramisu = Product(
  id: 2,
  name: 'Tiramisu',
  price: 6,
  categoryId: 2,
  isFeatured: true,
);

Future<void> _pumpHome(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, __) => const Scaffold(body: Text('Search screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith(
          (ref) async => [_pizzaCategory, _dessertCategory],
        ),
        featuredProductsProvider.overrideWith((ref) async => [_tiramisu]),
        productsByCategoryProvider(1)
            .overrideWith((ref) async => [_margherita]),
        productsByCategoryProvider(2).overrideWith((ref) async => [_tiramisu]),
        promotionsProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HomeScreen', () {
    testWidgets('affiche la row Incontournables avec les produits vedettes',
        (tester) async {
      await _pumpHome(tester);

      expect(find.text('Incontournables'), findsOneWidget);
      expect(find.text('Tiramisu'), findsWidgets);
    });

    testWidgets('affiche une row par catégorie, nommée dynamiquement',
        (tester) async {
      await _pumpHome(tester);

      expect(find.text('Pizzas'), findsWidgets);
      expect(find.text('Desserts'), findsWidgets);
      expect(find.text('Margherita'), findsWidgets);
    });

    testWidgets('ne montre plus le vocabulaire marketplace multi-restaurants',
        (tester) async {
      await _pumpHome(tester);

      expect(find.text('Restaurant pres de vous'), findsNothing);
      expect(find.text('Nearest'), findsNothing);
      expect(find.text('Best Rating'), findsNothing);
    });

    testWidgets("la cloche notifications n'est plus un bouton tapable",
        (tester) async {
      await _pumpHome(tester);

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/catalog/home_screen_test.dart`
Expected: FAIL — la home actuelle affiche encore "Restaurant pres de vous", une grille unique, et un `IconButton.filledTonal` pour la cloche.

- [ ] **Step 3: Write minimal implementation**

Remplacer intégralement le contenu de `lib/features/catalog/screens/home_screen.dart` par :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/widgets/allergen_filter_bar.dart';
import 'package:app_client/features/catalog/widgets/horizontal_product_row.dart';
import 'package:app_client/features/catalog/widgets/promo_hero_carousel.dart';
import 'package:app_client/features/loyalty/providers/loyalty_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),
            const SliverToBoxAdapter(child: PromoHeroCarousel()),
            const SliverToBoxAdapter(child: _SearchEntry()),
            const SliverToBoxAdapter(child: AllergenFilterBar()),
            SliverToBoxAdapter(
              child: HorizontalProductRow(
                title: 'Incontournables',
                productsAsync: ref.watch(featuredProductsProvider),
                onSeeAll: () => context.push(AppRoutes.search),
              ),
            ),
            categoriesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 74,
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (categories) => SliverToBoxAdapter(
                child: _CategoryRows(categories: categories),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
    );
  }
}

class _CategoryRows extends ConsumerWidget {
  const _CategoryRows({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final category in categories)
          HorizontalProductRow(
            title: category.name,
            productsAsync: ref.watch(filteredProductsProvider(category.id)),
            onSeeAll: () {
              ref.read(selectedCategoryProvider.notifier).state = category.id;
              context.push(AppRoutes.search);
            },
          ),
      ],
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(accessTokenProvider) != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.grey100,
            child: Icon(Icons.person, color: AppColors.brandGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Livrer a', style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.priceGreen,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        'Adresse de livraison',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
                if (isAuthenticated) ...[
                  const SizedBox(height: 4),
                  const _LoyaltyBadge(),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Cloche décorative désactivée : aucun flux de notifications
          // consultable n'existe côté backend aujourd'hui (le module
          // `notifications` ne gère que l'enregistrement des tokens push).
          // Un bouton qui ne fait rien est trompeur — à réactiver une fois
          // l'endpoint de flux disponible (audit UX home, Phase 13).
          const Icon(Icons.notifications_none, color: AppColors.grey400),
        ],
      ),
    );
  }
}

class _LoyaltyBadge extends ConsumerWidget {
  const _LoyaltyBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(loyaltyAccountProvider);

    return accountAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (account) => InkWell(
        onTap: () => context.push(AppRoutes.loyalty),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.brandRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 14,
                color: AppColors.brandRed,
              ),
              const SizedBox(width: 4),
              Text(
                '${account.points} points',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: InkWell(
        onTap: () => context.push(AppRoutes.search),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.black),
              SizedBox(width: 10),
              Expanded(
                child: Text('Que souhaitez-vous commander ?'),
              ),
              VerticalDivider(width: 24),
              Icon(Icons.tune, color: AppColors.black),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/catalog/home_screen_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/catalog/screens/home_screen.dart test/features/catalog/home_screen_test.dart
git commit -m "feat: redesign home screen with hero carousel and horizontal rows"
```

---

## Task 7: SearchScreen — titre dynamique + retrait des filtres factices

**Files:**
- Modify: `lib/features/catalog/screens/search_screen.dart` (remplacement complet du fichier)
- Test: `test/features/catalog/search_screen_test.dart`

**Interfaces:**
- Consumes: `categoriesProvider`, `selectedCategoryProvider`, `featuredProductsProvider`, `filteredProductsProvider`, `productsByCategoryProvider` (tous existants), `CategoryChip` (existant, `features/catalog/widgets/category_chip.dart`).
- Produces: `SearchScreen` garde la même signature publique — route `AppRoutes.search` inchangée.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/catalog/search_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/screens/search_screen.dart';

const _pizzaCategory = Category(id: 1, name: 'Pizzas');
const _dessertCategory = Category(id: 2, name: 'Desserts');
const _margherita =
    Product(id: 1, name: 'Margherita', price: 10, categoryId: 1);

Future<ProviderContainer> _pumpSearch(
  WidgetTester tester, {
  int? selectedCategoryId,
}) async {
  final container = ProviderContainer(
    overrides: [
      categoriesProvider.overrideWith(
        (ref) async => [_pizzaCategory, _dessertCategory],
      ),
      featuredProductsProvider.overrideWith((ref) async => [_margherita]),
      productsByCategoryProvider(1)
          .overrideWith((ref) async => [_margherita]),
    ],
  );
  addTearDown(container.dispose);

  if (selectedCategoryId != null) {
    container.read(selectedCategoryProvider.notifier).state =
        selectedCategoryId;
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SearchScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('SearchScreen', () {
    testWidgets(
        'titre générique "Explorer le menu" sans catégorie sélectionnée',
        (tester) async {
      await _pumpSearch(tester);

      expect(find.text('Explorer le menu'), findsOneWidget);
      expect(find.text('Recommendations'), findsNothing);
    });

    testWidgets('titre = nom de la catégorie sélectionnée', (tester) async {
      await _pumpSearch(tester, selectedCategoryId: 1);

      expect(find.text('Pizzas'), findsWidgets);
      expect(find.text('Explorer le menu'), findsNothing);
    });

    testWidgets('affiche toutes les catégories, sans filtres factices',
        (tester) async {
      await _pumpSearch(tester);

      expect(find.text('Tout'), findsOneWidget);
      expect(find.text('Pizzas'), findsOneWidget);
      expect(find.text('Desserts'), findsOneWidget);
      expect(find.text('Nearest'), findsNothing);
      expect(find.text('Best Rating'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/catalog/search_screen_test.dart`
Expected: FAIL — le titre actuel est toujours "Recommendations", les chips "Nearest"/"Best Rating" sont présentes et "Desserts" n'apparaît pas dans les filtres.

- [ ] **Step 3: Write minimal implementation**

Remplacer intégralement le contenu de `lib/features/catalog/screens/search_screen.dart` par :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/core/widgets/empty_state.dart';
import 'package:app_client/core/widgets/error_view.dart';
import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/widgets/category_chip.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';

/// Écran d'exploration complète du catalogue ("Voir tout" depuis la home).
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ListHeader(
                title:
                    _titleFor(categoriesAsync.valueOrNull, selectedCategoryId),
              ),
            ),
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                loading: () => const SizedBox(
                  height: 54,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) => _FilterStrip(
                  categories: categories,
                  selectedCategoryId: selectedCategoryId,
                ),
              ),
            ),
            _ProductGrid(categoryId: selectedCategoryId),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  String _titleFor(List<Category>? categories, int? selectedCategoryId) {
    if (selectedCategoryId == null || categories == null) {
      return 'Explorer le menu';
    }
    final selected =
        categories.where((c) => c.id == selectedCategoryId).firstOrNull;
    return selected?.name ?? 'Explorer le menu';
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 24, 42, 12),
      child: Row(
        children: [
          _HeaderButton(
            icon: Icons.arrow_back_ios_new,
            tooltip: 'Retour',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Cloche décorative désactivée — même raison que home_screen.dart :
          // pas de flux de notifications consultable côté backend.
          const Icon(Icons.notifications_none, color: AppColors.grey400),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 38,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 21),
      ),
    );
  }
}

class _FilterStrip extends ConsumerWidget {
  const _FilterStrip({
    required this.categories,
    required this.selectedCategoryId,
  });

  final List<Category> categories;
  final int? selectedCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 8),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return CategoryChip(
              label: 'Tout',
              isSelected: selectedCategoryId == null,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
            );
          }
          final category = categories[index - 1];
          return CategoryChip(
            label: category.name,
            isSelected: selectedCategoryId == category.id,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state =
                selectedCategoryId == category.id ? null : category.id,
          );
        },
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({required this.categoryId});

  final int? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId == null) {
      final featuredAsync = ref.watch(featuredProductsProvider);
      return featuredAsync.when(
        loading: () => const SliverToBoxAdapter(child: _ProductGridSkeleton()),
        error: (e, _) => SliverToBoxAdapter(
          child: ErrorView(
            message: 'Impossible de charger les recommendations.',
            onRetry: () => ref.invalidate(featuredProductsProvider),
          ),
        ),
        data: (products) => products.isEmpty
            ? const SliverToBoxAdapter(
                child: EmptyState(
                  title: 'Aucun produit disponible',
                  subtitle: 'Les produits recommandes apparaitront ici.',
                  icon: Icons.restaurant_menu_outlined,
                ),
              )
            : _ProductSliver(products: products),
      );
    }

    final filteredAsync = ref.watch(filteredProductsProvider(categoryId!));
    return filteredAsync.when(
      loading: () => const SliverToBoxAdapter(child: _ProductGridSkeleton()),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorView(
          message: 'Impossible de charger cette categorie.',
          onRetry: () =>
              ref.invalidate(productsByCategoryProvider(categoryId!)),
        ),
      ),
      data: (products) => products.isEmpty
          ? const SliverToBoxAdapter(
              child: EmptyState(
                title: 'Aucun produit disponible',
                subtitle: 'Essayez une autre categorie.',
                icon: Icons.search_off_outlined,
              ),
            )
          : _ProductSliver(products: products),
    );
  }
}

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: _gridDelegate(MediaQuery.sizeOf(context).width),
        itemCount: 8,
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ShimmerBlock(borderRadius: 8)),
            SizedBox(height: 8),
            ShimmerBlock(height: 14, width: 120),
            SizedBox(height: 6),
            ShimmerBlock(height: 12, width: 60),
          ],
        ),
      ),
    );
  }
}

class _ProductSliver extends StatelessWidget {
  const _ProductSliver({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(42, 4, 42, 0),
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate(MediaQuery.sizeOf(context).width),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}

SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(double width) {
  final columns = width >= 1100 ? 4 : (width >= 700 ? 3 : 2);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: 24,
    crossAxisSpacing: width >= 700 ? 26 : 48,
    childAspectRatio: width >= 700 ? 0.86 : 0.68,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/catalog/search_screen_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Run the full test suite for final regression check**

Run: `flutter test`
Expected: PASS — l'ensemble de la suite (catalogue, panier, checkout, fidélité, promotions...) reste vert ; aucune modification hors des fichiers listés dans ce plan.

- [ ] **Step 6: Commit**

```bash
git add lib/features/catalog/screens/search_screen.dart test/features/catalog/search_screen_test.dart
git commit -m "fix: dynamic search screen title and remove fake marketplace filters"
```

---

## Hors périmètre (chantiers séparés, backend requis)

- Favoris persistés côté serveur (module `favorites` inexistant sur `api-pizza`).
- Flux de notifications in-app (le module `notifications` ne gère que les tokens push).
- Badge promo sur `ProductCard` et row "Offres du moment" basée sur des produits — nécessite un lien produit↔promotion absent du modèle `Promotion` actuel (`api-pizza/app/modules/promotions`).
- Adresse de livraison réelle dans le header home (réutiliser la sélection d'adresse existante du checkout, `step_address.dart` — à spécifier séparément).
- Mode de commande "sur place" (détection présence géoloc + QR table) et commande programmée (créneau même jour) — backend `orders`/`delivery` à faire évoluer.

## Self-Review

**1. Couverture spec (portée 100% client de la Phase 14) :**
- Hero carrousel manuel + dots → Task 5. ✓
- Row Incontournables → Task 6 (`featuredProductsProvider`). ✓
- Rows par catégorie → Task 6 (`_CategoryRows`). ✓
- Retrait vocabulaire marketplace ("Restaurant pres de vous", "Nearest", "Best Rating") → Task 6 + Task 7, couvert par les tests de régression. ✓
- Cœur favori fonctionnel → Task 1 + Task 2. ✓
- Quick-add produits simples → Task 3. ✓
- Cloche honnête (non trompeuse) → Task 6 + Task 7. ✓
- Fidélité visible dès la home → Task 6 (`_LoyaltyBadge`). ✓
- Titre dynamique + catégories complètes sur "Voir tout" → Task 7. ✓
- Items explicitement hors périmètre → documentés ci-dessus, pas de tâche fantôme.

**2. Placeholder scan :** aucun `TODO`/`TBD` dans les blocs de code ; chaque step contient le code réel à écrire.

**3. Cohérence des types :** `HorizontalProductRow({title, productsAsync, onSeeAll})` utilisé identiquement en Task 4 (définition) et Task 6 (usage x2). `PromoHeroCarousel()` sans paramètre, cohérent Task 5/Task 6. `FavoritesNotifier.toggle(int)`/`isFavorite(int)` cohérents Task 1/Task 2. `favoritesProvider` toujours importé depuis `features/catalog/providers/favorites_provider.dart`.
