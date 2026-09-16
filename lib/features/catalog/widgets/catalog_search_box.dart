import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/providers/catalog_search_provider.dart';
import 'package:app_client/features/catalog/widgets/catalog_filter_sheet.dart';
import 'package:app_client/l10n/app_localizations.dart';

class CatalogSearchBox extends ConsumerStatefulWidget {
  const CatalogSearchBox({
    super.key,
    this.navigateOnSubmit = false,
    this.autofocus = false,
    this.padding = const EdgeInsets.fromLTRB(
      KitchenSpacing.lg,
      0,
      KitchenSpacing.lg,
      KitchenSpacing.md,
    ),
  });

  final bool navigateOnSubmit;
  final bool autofocus;
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<CatalogSearchBox> createState() => _CatalogSearchBoxState();
}

class _CatalogSearchBoxState extends ConsumerState<CatalogSearchBox> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(searchQueryProvider, (_, next) {
      if (_controller.text == next) return;
      _controller.value = _controller.value.copyWith(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
        composing: TextRange.empty,
      );
    });

    final l10n = AppLocalizations.of(context)!;
    final query = ref.watch(searchQueryProvider);
    final suggestionsAsync = ref.watch(catalogSuggestionsProvider);

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          KitchenSurface(
            elevation: KitchenElevation.inset,
            borderRadius: KitchenRadius.field,
            padding: const EdgeInsets.symmetric(
              horizontal: KitchenSpacing.md,
              vertical: KitchenSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: KitchenColors.espresso),
                const SizedBox(width: KitchenSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    textInputAction: TextInputAction.search,
                    style: KitchenTypography.body.copyWith(
                      color: KitchenColors.espresso,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.homeSearchPlaceholder,
                      hintStyle: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).state = value,
                    onSubmitted: (_) => _submitSearch(),
                  ),
                ),
                if (query.isNotEmpty)
                  IconButton(
                    tooltip: 'Effacer',
                    icon: const Icon(Icons.close_rounded),
                    color: KitchenColors.textMuted,
                    onPressed: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                      _focusNode.requestFocus();
                    },
                  ),
                Container(
                  width: 1,
                  height: 24,
                  color: KitchenColors.brown700.withValues(alpha: 0.16),
                ),
                const SizedBox(width: KitchenSpacing.xs),
                _FilterButton(
                  onPressed: () async {
                    await showCatalogFilterSheet(context);
                    if (widget.navigateOnSubmit && context.mounted) {
                      context.push(AppRoutes.search);
                    }
                  },
                ),
              ],
            ),
          ),
          if (query.trim().length >= 2)
            suggestionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (suggestions) => _SuggestionPanel(
                suggestions: suggestions,
                onSuggestionTap: (product) {
                  ref.read(searchQueryProvider.notifier).state = product.name;
                  context.push(AppRoutes.productDetail(product.id.toString()));
                },
                onClear: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  _focusNode.requestFocus();
                },
              ),
            ),
        ],
      ),
    );
  }

  void _submitSearch() {
    final query = ref.read(searchQueryProvider).trim();
    if (widget.navigateOnSubmit) {
      ref.read(selectedCategoryProvider.notifier).state = null;
      final encoded = Uri.encodeQueryComponent(query);
      context.push(
        query.isEmpty ? AppRoutes.search : '${AppRoutes.search}?q=$encoded',
      );
    } else {
      _focusNode.unfocus();
    }
  }
}

class _FilterButton extends ConsumerWidget {
  const _FilterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref.watch(catalogActiveFilterCountProvider);

    return Tooltip(
      message: 'Filtres',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.tune_rounded),
            color: KitchenColors.espresso,
          ),
          if (activeCount > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KitchenColors.terracotta,
                  borderRadius: BorderRadius.circular(KitchenRadius.pill),
                ),
                child: Text(
                  activeCount > 9 ? '9+' : '$activeCount',
                  style: KitchenTypography.label.copyWith(
                    color: KitchenColors.whiteWarm,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onClear,
  });

  final List<Product> suggestions;
  final ValueChanged<Product> onSuggestionTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: KitchenSpacing.sm),
      child: KitchenSurface(
        elevation: KitchenElevation.inset,
        borderRadius: BorderRadius.circular(KitchenRadius.md),
        padding: const EdgeInsets.all(KitchenSpacing.sm),
        child: suggestions.isEmpty
            ? Row(
                children: [
                  const Icon(
                    Icons.search_off_outlined,
                    color: KitchenColors.cognac,
                  ),
                  const SizedBox(width: KitchenSpacing.sm),
                  Expanded(
                    child: Text(
                      'Aucun produit correspondant',
                      style: KitchenTypography.body.copyWith(
                        color: KitchenColors.textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Nouvelle recherche'),
                  ),
                ],
              )
            : Column(
                children: [
                  for (final product in suggestions)
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: KitchenSpacing.xs,
                        ),
                        leading: const Icon(
                          Icons.local_pizza_outlined,
                          color: KitchenColors.cognac,
                        ),
                        title: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KitchenTypography.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          product.description ?? product.displayPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          product.displayPrice,
                          style: KitchenTypography.label.copyWith(
                            color: KitchenColors.cognac,
                          ),
                        ),
                        onTap: () => onSuggestionTap(product),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
