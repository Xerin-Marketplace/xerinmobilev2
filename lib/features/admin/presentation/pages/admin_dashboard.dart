import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import 'tabs/admin_overview_page.dart';
import 'tabs/admin_users_page.dart';
import 'tabs/admin_sellers_page.dart';
import 'tabs/admin_products_page.dart';
import 'tabs/admin_categories_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final _pages = const [
    AdminOverviewPage(),
    AdminUsersPage(),
    AdminSellersPage(),
    AdminProductsPage(),
    AdminCategoriesPage(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          NotificationService().success(state.message);
        } else if (state is AdminActionError) {
          NotificationService().error(state.message);
        } else if (state is AdminError) {
          NotificationService().error(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AdminLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Panel'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: isLoading
                    ? null
                    : () => context.read<AdminCubit>().loadDashboard(),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    context.go('/sign-in');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pages[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Users',
              ),
              NavigationDestination(
                icon: Icon(Icons.store_outlined),
                selectedIcon: Icon(Icons.store_rounded),
                label: 'Sellers',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category_rounded),
                label: 'Categories',
              ),
            ],
          ),
        );
      },
    );
  }
}
