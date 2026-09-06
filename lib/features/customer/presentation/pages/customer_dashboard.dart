import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/guest_auth_gate.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import 'tabs/customer_cart_page.dart';
import 'tabs/customer_explore_page.dart';
import 'tabs/customer_home_page.dart';
import 'tabs/customer_profile_page.dart';
import 'tabs/customer_wishlist_page.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    CustomerHomePage(),
    CustomerExplorePage(),
    CustomerCartPage(),
    CustomerWishlistPage(),
    CustomerProfilePage(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
    _NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Cart'),
    _NavItem(icon: Icons.favorite_outline, activeIcon: Icons.favorite, label: 'Wishlist'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'My Xerin'),
  ];

  bool get _isGuest {
    final tokenStorage = GetIt.instance<TokenStorage>();
    return !tokenStorage.isAuthenticated && tokenStorage.isGuest;
  }

  void _onNavTap(int index) {
    if (_isGuest && (index == 2 || index == 3 || index == 4)) {
      GuestAuthGate.showPrompt(
        context,
        title: index == 4 ? 'Sign In to View Profile' : 'Sign In to Continue',
        message: index == 4
            ? 'Sign in to view your profile, orders, and settings.'
            : 'Sign in to access your cart, wishlist, and checkout.',
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final cartCount = cartState is CartLoaded ? cartState.itemCount : 0;

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildNavBar(
            colorScheme: colorScheme,
            isDark: isDark,
            cartCount: cartCount,
          ),
        );
      },
    );
  }

  Widget _buildNavBar({
    required ColorScheme colorScheme,
    required bool isDark,
    required int cartCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _selectedIndex == index;
              final showBadge = index == 2 && cartCount > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onNavTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: _buildNavItem(
                    item: item,
                    isSelected: isSelected,
                    colorScheme: colorScheme,
                    showBadge: showBadge,
                    badgeCount: cartCount,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required _NavItem item,
    required bool isSelected,
    required ColorScheme colorScheme,
    required bool showBadge,
    required int badgeCount,
  }) {
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubicEmphasized,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with optional badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey(isSelected),
                  size: 23,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              if (showBadge)
                Positioned(
                  top: -4,
                  right: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          // Label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
              letterSpacing: 0.3,
            ),
            child: Text(item.label),
          ),
          // Active indicator dot
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubicEmphasized,
            width: isSelected ? 20 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
