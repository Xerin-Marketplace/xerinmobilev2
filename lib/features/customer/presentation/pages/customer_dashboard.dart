import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/presentation/widgets/modern_bottom_nav.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import 'tabs/customer_analytics_page.dart';
import 'tabs/customer_cart_page.dart';
import 'tabs/customer_explore_page.dart';
import 'tabs/customer_home_page.dart';
import 'tabs/customer_profile_page.dart';
import 'tabs/customer_wishlist_page.dart';
import '../../../../core/theme/uicons.dart';

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
    CustomerAnalyticsPage(),
    CustomerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final cartCount = cartState is CartLoaded ? cartState.itemCount : 0;

        final navItems = [
          const NavItem(
              icon: Uicons.home,
              activeIcon: Uicons.home,
              label: 'Home'),
          const NavItem(
              icon: Uicons.compass,
              activeIcon: Uicons.compass,
              label: 'Explore'),
          NavItem(
            icon: Uicons.shoppingCart,
            activeIcon: Uicons.shoppingCart,
            label: 'Cart',
            badgeCount: cartCount,
          ),
          const NavItem(
              icon: Uicons.heart,
              activeIcon: Uicons.heart,
              label: 'Wishlist'),
          const NavItem(
              icon: Uicons.barChart,
              activeIcon: Uicons.barChart,
              label: 'Stats'),
          const NavItem(
              icon: Uicons.user,
              activeIcon: Uicons.user,
              label: 'Profile'),
        ];

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: ModernBottomNav(
            selectedIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: navItems,
          ),
        );
      },
    );
  }
}
