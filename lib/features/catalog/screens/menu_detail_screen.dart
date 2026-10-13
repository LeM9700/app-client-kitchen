import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/cart/models/menu_cart_item.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/menu.dart';
import 'package:app_client/features/catalog/providers/menu_provider.dart';

class MenuDetailScreen extends ConsumerStatefulWidget {
  const MenuDetailScreen({super.key, required this.menuId});

  final int menuId;

  @override
  ConsumerState<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends ConsumerState<MenuDetailScreen> {
  final Map<int, List<MenuCartSelection>> _selections = {};

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuDetailProvider(widget.menuId));
    return Scaffold(
      backgroundColor: KitchenColors.paper,
      body: menuAsync.when(
        loading: () => const Center(
          child: KitchenLoadingIndicator(
            color: KitchenColors.cognac,
            size: 38,
          ),
        ),
        error: (error, _) => _MenuLoadError(
          message: error is AppException
              ? error.message
              : 'Impossible de charger ce menu.',
          onRetry: () => ref.invalidate(menuDetailProvider(widget.menuId)),
        ),
        data: (menu) => Stack(
          children: [
            _MenuBody(
              menu: menu,
              selections: _selections,
              onConfigure: (group, product) =>
                  _configureProduct(menu, group, product),
              onRemove: _removeSelection,
            ),
            _MenuAddBar(
              menu: menu,
              complete: _isComplete(menu),
              onAdd: () => _addToCart(menu),
            ),
          ],
        ),
      ),
    );
  }

  bool _isComplete(CatalogMenu menu) {
    if (!menu.isAvailable) return false;
    return menu.groups.every((group) {
      final count = (_selections[group.id] ?? const [])
          .fold(0, (total, selection) => total + selection.quantity);
      return group.isAvailable &&
          count >= group.minChoices &&
          count <= group.maxChoices;
    });
  }

  Future<void> _configureProduct(
    CatalogMenu menu,
    CatalogMenuGroup group,
    CatalogMenuProduct product,
  ) async {
    if (!product.isOperationallyAvailable) return;
    final current = _selections[group.id] ?? const [];
    final existing = current
        .where((selection) => selection.product.id == product.product.id)
        .firstOrNull;
    if (existing == null && current.length >= group.maxChoices) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vous pouvez choisir au maximum ${group.maxChoices} option(s) dans ${group.name}.',
          ),
        ),
      );
      return;
    }

    final configured = await showModalBottomSheet<MenuCartSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KitchenColors.paperLight,
      builder: (context) => _ProductOptionsSheet(
        group: group,
        menuProduct: product,
        existing: existing,
      ),
    );
    if (configured == null || !mounted) return;

    setState(() {
      final updated = [...current]..removeWhere(
          (selection) => selection.product.id == product.product.id,
        );
      if (group.maxChoices == 1) updated.clear();
      updated.add(configured);
      _selections[group.id] = updated;
    });
  }

  void _removeSelection(int groupId, int productId) {
    setState(() {
      final updated = [...?_selections[groupId]]
        ..removeWhere((selection) => selection.product.id == productId);
      if (updated.isEmpty) {
        _selections.remove(groupId);
      } else {
        _selections[groupId] = updated;
      }
    });
  }

  void _addToCart(CatalogMenu menu) {
    if (!_isComplete(menu)) return;
    final selections = menu.groups
        .expand((group) => _selections[group.id] ?? const <MenuCartSelection>[])
        .toList();
    ref.read(cartProvider.notifier).addMenuItem(
          MenuCartItem(menu: menu, selections: selections),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menu.name} ajoute au panier.'),
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () => context.push(AppRoutes.cart),
        ),
      ),
    );
  }
}

class _MenuBody extends StatelessWidget {
  const _MenuBody({
    required this.menu,
    required this.selections,
    required this.onConfigure,
    required this.onRemove,
  });

  final CatalogMenu menu;
  final Map<int, List<MenuCartSelection>> selections;
  final void Function(CatalogMenuGroup, CatalogMenuProduct) onConfigure;
  final void Function(int, int) onRemove;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          stretch: true,
          backgroundColor: KitchenColors.paperLight,
          foregroundColor: KitchenColors.espresso,
          flexibleSpace: FlexibleSpaceBar(
            background: _MenuHero(menu: menu),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            KitchenSpacing.lg,
            KitchenSpacing.lg,
            KitchenSpacing.lg,
            150,
          ),
          sliver: SliverList.list(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      menu.name,
                      style: KitchenTypography.display.copyWith(fontSize: 40),
                    ),
                  ),
                  const SizedBox(width: KitchenSpacing.md),
                  Text(
                    formatPrice(menu.fixedPrice),
                    style: KitchenTypography.signature.copyWith(
                      color: KitchenColors.cognac,
                    ),
                  ),
                ],
              ),
              if (menu.description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: KitchenSpacing.sm),
                Text(
                  menu.description!,
                  style: KitchenTypography.body.copyWith(
                    color: KitchenColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: KitchenSpacing.md),
              KitchenSurface(
                elevation: KitchenElevation.inset,
                padding: const EdgeInsets.all(KitchenSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: KitchenColors.olive),
                    const SizedBox(width: KitchenSpacing.sm),
                    Expanded(
                      child: Text(
                        'Le prix du menu reste fixe, variantes et extras compris.',
                        style: KitchenTypography.body.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              if (!menu.isAvailable) ...[
                const SizedBox(height: KitchenSpacing.md),
                _UnavailableMenu(reasons: menu.unavailableReasons),
              ],
              const SizedBox(height: KitchenSpacing.xl),
              for (var index = 0; index < menu.groups.length; index++) ...[
                _GroupSection(
                  index: index,
                  group: menu.groups[index],
                  selected: selections[menu.groups[index].id] ?? const [],
                  onConfigure: (product) =>
                      onConfigure(menu.groups[index], product),
                  onRemove: (productId) =>
                      onRemove(menu.groups[index].id, productId),
                ),
                if (index != menu.groups.length - 1)
                  const SizedBox(height: KitchenSpacing.xl),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuHero extends StatelessWidget {
  const _MenuHero({required this.menu});

  final CatalogMenu menu;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (menu.imageUrl?.trim().isNotEmpty == true)
          Image.network(
            menu.imageUrl!,
            fit: BoxFit.cover,
            cacheWidth: 1000,
            errorBuilder: (_, __, ___) => const _HeroFallback(),
          )
        else
          const _HeroFallback(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                KitchenColors.espresso.withValues(alpha: 0.12),
                KitchenColors.paper,
              ],
              stops: const [0.45, 0.8, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: KitchenColors.flour,
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 72,
          color: KitchenColors.cognac,
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.index,
    required this.group,
    required this.selected,
    required this.onConfigure,
    required this.onRemove,
  });

  final int index;
  final CatalogMenuGroup group;
  final List<MenuCartSelection> selected;
  final ValueChanged<CatalogMenuProduct> onConfigure;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final selectedCount = selected.fold(
      0,
      (total, selection) => total + selection.quantity,
    );
    final complete =
        selectedCount >= group.minChoices && selectedCount <= group.maxChoices;
    final requirement = group.minChoices == group.maxChoices
        ? '${group.minChoices} choix requis'
        : '${group.minChoices} a ${group.maxChoices} choix';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: complete
                    ? KitchenColors.olive
                    : KitchenColors.cognac.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: complete
                  ? const Icon(
                      Icons.check,
                      size: 19,
                      color: KitchenColors.whiteWarm,
                    )
                  : Text(
                      '${index + 1}',
                      style: KitchenTypography.label.copyWith(
                        color: KitchenColors.cognac,
                      ),
                    ),
            ),
            const SizedBox(width: KitchenSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: KitchenTypography.title.copyWith(fontSize: 27),
                  ),
                  Text(
                    '$requirement - $selectedCount selectionne(s)',
                    style: KitchenTypography.body.copyWith(
                      color: complete
                          ? KitchenColors.olive
                          : KitchenColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!group.isAvailable) ...[
          const SizedBox(height: KitchenSpacing.sm),
          Text(
            group.unavailableReason ?? 'Ce choix est indisponible.',
            style: KitchenTypography.body.copyWith(
              color: KitchenColors.terracotta,
            ),
          ),
        ],
        const SizedBox(height: KitchenSpacing.sm),
        ...group.products.map((menuProduct) {
          final selection = selected
              .where(
                (item) => item.product.id == menuProduct.product.id,
              )
              .firstOrNull;
          final maxReached =
              selection == null && selectedCount >= group.maxChoices;
          return Padding(
            padding: const EdgeInsets.only(bottom: KitchenSpacing.sm),
            child: _ProductChoice(
              menuProduct: menuProduct,
              selection: selection,
              enabled: group.isAvailable && !maxReached,
              onTap: () => onConfigure(menuProduct),
              onRemove: selection == null
                  ? null
                  : () => onRemove(menuProduct.product.id),
            ),
          );
        }),
      ],
    );
  }
}

class _ProductChoice extends StatelessWidget {
  const _ProductChoice({
    required this.menuProduct,
    required this.selection,
    required this.enabled,
    required this.onTap,
    required this.onRemove,
  });

  final CatalogMenuProduct menuProduct;
  final MenuCartSelection? selection;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final product = menuProduct.product;
    final available = menuProduct.isOperationallyAvailable;
    final options = selection?.optionLabels ?? const [];
    return KitchenSurface(
      elevation:
          selection == null ? KitchenElevation.flat : KitchenElevation.inset,
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          enabled: enabled && available,
          onTap: enabled && available ? onTap : null,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(KitchenRadius.sm),
            child: SizedBox.square(
              dimension: 54,
              child: product.imageUrl?.trim().isNotEmpty == true
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 150,
                      errorBuilder: (_, __, ___) => const _ProductFallback(),
                    )
                  : const _ProductFallback(),
            ),
          ),
          title: Text(
            product.name,
            style: KitchenTypography.body.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            !available
                ? menuProduct.unavailableReason ?? 'Indisponible'
                : options.isEmpty
                    ? 'Touchez pour choisir'
                    : options.join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KitchenTypography.body.copyWith(
              color: available
                  ? KitchenColors.textMuted
                  : KitchenColors.terracotta,
              fontSize: 13,
            ),
          ),
          trailing: selection == null
              ? const Icon(Icons.add_circle_outline)
              : IconButton(
                  tooltip: 'Retirer ce choix',
                  onPressed: onRemove,
                  icon: const Icon(Icons.check_circle),
                  color: KitchenColors.olive,
                ),
        ),
      ),
    );
  }
}

class _ProductFallback extends StatelessWidget {
  const _ProductFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: KitchenColors.flour,
      child: Icon(Icons.local_pizza_outlined, color: KitchenColors.cognac),
    );
  }
}

class _ProductOptionsSheet extends StatefulWidget {
  const _ProductOptionsSheet({
    required this.group,
    required this.menuProduct,
    this.existing,
  });

  final CatalogMenuGroup group;
  final CatalogMenuProduct menuProduct;
  final MenuCartSelection? existing;

  @override
  State<_ProductOptionsSheet> createState() => _ProductOptionsSheetState();
}

class _ProductOptionsSheetState extends State<_ProductOptionsSheet> {
  int? _variantId;
  late final Set<int> _extraIds;

  @override
  void initState() {
    super.initState();
    final product = widget.menuProduct.product;
    _variantId = widget.existing?.selectedVariant?.id ??
        (product.variants.isEmpty ? null : product.variants.first.id);
    _extraIds = {...?widget.existing?.selectedExtraIds};
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.menuProduct.product;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          KitchenSpacing.lg,
          KitchenSpacing.md,
          KitchenSpacing.lg,
          KitchenSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KitchenColors.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(KitchenRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: KitchenSpacing.md),
              Text(
                product.name,
                style: KitchenTypography.title.copyWith(fontSize: 30),
              ),
              const SizedBox(height: KitchenSpacing.xs),
              Text(
                'Inclus dans le prix fixe du menu',
                style: KitchenTypography.label.copyWith(
                  color: KitchenColors.olive,
                ),
              ),
              if (product.variants.isNotEmpty) ...[
                const SizedBox(height: KitchenSpacing.lg),
                Text(
                  'Variante',
                  style: KitchenTypography.title.copyWith(fontSize: 23),
                ),
                ...product.variants.map((variant) {
                  final selected = variant.id == _variantId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => setState(() => _variantId = variant.id),
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? KitchenColors.cognac
                          : KitchenColors.textMuted,
                    ),
                    title: Text(variant.name),
                  );
                }),
              ],
              if (product.extras.any((extra) => extra.available)) ...[
                const SizedBox(height: KitchenSpacing.md),
                Text(
                  'Extras',
                  style: KitchenTypography.title.copyWith(fontSize: 23),
                ),
                ...product.extras.where((extra) => extra.available).map(
                      (extra) => CheckboxListTile(
                        value: _extraIds.contains(extra.id),
                        onChanged: (selected) => setState(() {
                          if (selected == true) {
                            _extraIds.add(extra.id);
                          } else {
                            _extraIds.remove(extra.id);
                          }
                        }),
                        title: Text(extra.name),
                        subtitle: const Text('Sans changement de prix'),
                        activeColor: KitchenColors.cognac,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
              ],
              const SizedBox(height: KitchenSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: KitchenEmbossedButton(
                  onPressed: () {
                    final selectedVariant = _variantId == null
                        ? null
                        : product.variants
                            .where((variant) => variant.id == _variantId)
                            .firstOrNull;
                    Navigator.pop(
                      context,
                      MenuCartSelection(
                        groupId: widget.group.id,
                        groupName: widget.group.name,
                        product: product,
                        selectedVariant: selectedVariant,
                        selectedExtraIds: _extraIds,
                      ),
                    );
                  },
                  semanticLabel: 'Valider ${product.name}',
                  child: const Text('Valider ce choix'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuAddBar extends StatelessWidget {
  const _MenuAddBar({
    required this.menu,
    required this.complete,
    required this.onAdd,
  });

  final CatalogMenu menu;
  final bool complete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KitchenColors.paper.withValues(alpha: 0.96),
          boxShadow: const [
            BoxShadow(
              color: Color(0x222D1B13),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            KitchenSpacing.lg,
            KitchenSpacing.sm,
            KitchenSpacing.lg,
            KitchenSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!complete)
                Padding(
                  padding: const EdgeInsets.only(bottom: KitchenSpacing.xs),
                  child: Text(
                    menu.isAvailable
                        ? 'Completez tous les choix obligatoires.'
                        : 'Ce menu est temporairement indisponible.',
                    style: KitchenTypography.body.copyWith(
                      color: KitchenColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: KitchenEmbossedButton(
                  enabled: complete,
                  onPressed: complete ? onAdd : null,
                  semanticLabel: 'Ajouter ${menu.name} au panier',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(child: Text('Ajouter le menu')),
                      const SizedBox(width: KitchenSpacing.md),
                      Text(formatPrice(menu.fixedPrice)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableMenu extends StatelessWidget {
  const _UnavailableMenu({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return KitchenSurface(
      elevation: KitchenElevation.inset,
      padding: const EdgeInsets.all(KitchenSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block, color: KitchenColors.terracotta),
          const SizedBox(width: KitchenSpacing.sm),
          Expanded(
            child: Text(
              reasons.isEmpty
                  ? 'Ce menu est temporairement indisponible.'
                  : reasons.join('\n'),
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.terracotta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuLoadError extends StatelessWidget {
  const _MenuLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KitchenSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: KitchenColors.terracotta,
            ),
            const SizedBox(height: KitchenSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: KitchenSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
