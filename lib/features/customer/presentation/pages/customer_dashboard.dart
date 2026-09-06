import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../common/presentation/widgets/modern_bottom_nav.dart';
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

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final cartCount = cartState is CartLoaded ? cartState.itemCount : 0;

        final navItems = [
          const NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home'),
          const NavItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: 'Explore'),
          NavItem(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart,
            label: 'Cart',
            badgeCount: cartCount,
          ),
          const NavItem(
              icon: Icons.favorite_outline,
              activeIcon: Icons.favorite,
              label: 'Wishlist'),
          const NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile'),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: ModernBottomNav(
            selectedIndex: _selectedIndex,
            onTap: _onNavTap,
            items: navItems,
          ),
        );
      },
    );
  }
}
