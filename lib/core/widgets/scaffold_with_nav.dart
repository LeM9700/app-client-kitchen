import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_shadows.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_brand_logo.dart';
import 'package:app_client/core/widgets/network_banner.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';

class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).totalQuantity;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            backgroundColor: KitchenColors.paper,
            body: NetworkBanner(
              child: Row(
                children: [
                  _DesktopRail(
                    selectedIndex: shell.currentIndex,
                    cartCount: cartCount,
                    onDestinationSelected: _onTabSelected,
                  ),
                  Expanded(child: shell),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: KitchenColors.paper,
          body: NetworkBanner(child: shell),
          bottomNavigationBar: _MobileKitchenNav(
            selectedIndex: shell.currentIndex,
            cartCount: cartCount,
            onDestinationSelected: _onTabSelected,
          ),
        );
      },
    );
  }

  void _onTabSelected(int index) {
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }
}

class _MobileKitchenNav extends StatelessWidget {
  const _MobileKitchenNav({
    required this.selectedIndex,
    required this.cartCount,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(18, 0, 18, bottom > 0 ? 8 : 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: KitchenGradients.paper,
          borderRadius: BorderRadius.circular(KitchenRadius.pill),
          border: Border.all(
            color: KitchenColors.whiteWarm.withValues(alpha: 0.9),
          ),
          boxShadow: KitchenShadows.raised,
        ),
        child: Padding(
          padding: const EdgeInsets.all(KitchenSpacing.xs),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Menu',
                tooltip: 'Voir le menu',
                selected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                icon: Icons.shopping_bag_outlined,
                selectedIcon: Icons.shopping_bag_rounded,
                label: 'Panier',
                tooltip: 'Voir le panier',
                selected: selectedIndex == 1,
                badgeCount: cartCount,
                onTap: () => onDestinationSelected(1),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long_rounded,
                label: 'Commandes',
                tooltip: 'Mes commandes',
                selected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Compte',
                tooltip: 'Mon compte',
                selected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.selectedIndex,
    required this.cartCount,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      color: KitchenColors.paperLight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KitchenSpacing.sm,
            vertical: KitchenSpacing.md,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: KitchenGradients.paper,
              borderRadius: BorderRadius.circular(KitchenRadius.xl),
              border: Border.all(
                color: KitchenColors.whiteWarm.withValues(alpha: 0.82),
              ),
              boxShadow: KitchenShadows.raised,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KitchenSpacing.xs,
                vertical: KitchenSpacing.md,
              ),
              child: Column(
                children: [
                  const KitchenBrandLogo(size: 50),
                  const SizedBox(height: KitchenSpacing.xl),
                  _RailItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Menu',
                    selected: selectedIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  _RailItem(
                    icon: Icons.shopping_bag_outlined,
                    selectedIcon: Icons.shopping_bag_rounded,
                    label: 'Panier',
                    selected: selectedIndex == 1,
                    badgeCount: cartCount,
                    onTap: () => onDestinationSelected(1),
                  ),
                  _RailItem(
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long_rounded,
                    label: 'Commandes',
                    selected: selectedIndex == 2,
                    onTap: () => onDestinationSelected(2),
                  ),
                  _RailItem(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Compte',
                    selected: selectedIndex == 3,
                    onTap: () => onDestinationSelected(3),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? KitchenColors.whiteWarm : KitchenColors.textMuted;

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          selected: selected,
          label: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(KitchenRadius.pill),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 58,
              decoration: BoxDecoration(
                gradient: selected ? KitchenGradients.cognac : null,
                color: selected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(KitchenRadius.pill),
                boxShadow: selected ? KitchenShadows.soft : const [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BadgedIcon(
                    icon: selected ? selectedIcon : icon,
                    color: foreground,
                    count: badgeCount,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KitchenTypography.label.copyWith(
                      color: foreground,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? KitchenColors.whiteWarm : KitchenColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: KitchenSpacing.sm),
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(KitchenRadius.lg),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: KitchenSpacing.xs,
              vertical: KitchenSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: selected ? KitchenGradients.cognac : null,
              borderRadius: BorderRadius.circular(KitchenRadius.lg),
            ),
            child: Column(
              children: [
                _BadgedIcon(
                  icon: selected ? selectedIcon : icon,
                  color: foreground,
                  count: badgeCount,
                ),
                const SizedBox(height: KitchenSpacing.xxs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KitchenTypography.label.copyWith(
                    color: foreground,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({
    required this.icon,
    required this.color,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final child = Icon(icon, color: color, size: 23);
    if (count <= 0) return child;

    return Badge(
      label: Text(count > 9 ? '9+' : '$count'),
      backgroundColor: KitchenColors.terracotta,
      textColor: KitchenColors.whiteWarm,
      child: child,
    );
  }
}
