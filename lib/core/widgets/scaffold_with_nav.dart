import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/theme/app_colors.dart';
import 'package:app_client/core/widgets/network_banner.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';

/// Root shell for the customer app navigation.
///
/// Mobile follows the supplied mockups with a red pill bottom navigation.
/// Wide layouts switch to a compact rail so desktop/tablet demos remain usable.
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
          body: NetworkBanner(child: shell),
          bottomNavigationBar: _MobilePillNav(
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

class _MobilePillNav extends StatelessWidget {
  const _MobilePillNav({
    required this.selectedIndex,
    required this.cartCount,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(24, 0, 24, bottom > 0 ? 8 : 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandRed,
          borderRadius: BorderRadius.circular(42),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandRed.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          height: 78,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _destinations(cartCount),
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
      color: AppColors.brandRed,
      child: SafeArea(
        child: NavigationRail(
          backgroundColor: AppColors.brandRed,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          labelType: NavigationRailLabelType.all,
          indicatorColor: Colors.white,
          selectedIconTheme: const IconThemeData(color: AppColors.brandRed),
          unselectedIconTheme: const IconThemeData(color: Colors.white),
          selectedLabelTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelTextStyle: const TextStyle(color: Colors.white),
          leading: const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 24),
            child: Icon(Icons.local_pizza, color: Colors.white, size: 34),
          ),
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: Text('Menu'),
            ),
            NavigationRailDestination(
              icon: _CartIcon(count: cartCount, selected: false),
              selectedIcon: _CartIcon(count: cartCount, selected: true),
              label: const Text('Panier'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: Text('Commandes'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: Text('Compte'),
            ),
          ],
        ),
      ),
    );
  }
}

List<NavigationDestination> _destinations(int cartCount) => [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Menu',
        tooltip: 'Voir le menu',
      ),
      NavigationDestination(
        icon: _CartIcon(count: cartCount, selected: false),
        selectedIcon: _CartIcon(count: cartCount, selected: true),
        label: 'Panier',
        tooltip: 'Voir le panier',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Commandes',
        tooltip: 'Mes commandes',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Compte',
        tooltip: 'Mon compte',
      ),
    ];

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected ? Icons.shopping_bag : Icons.shopping_bag_outlined,
    );
    if (count <= 0) return icon;

    return Badge(
      label: Text(count > 9 ? '9+' : '$count'),
      child: icon,
    );
  }
}
