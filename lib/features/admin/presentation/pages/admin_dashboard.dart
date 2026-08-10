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
        final isError = state is AdminError;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Panel'),
            centerTitle: false,
            actions: [
              if (state is AdminActionLoading)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
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
              ? _buildLoadingSkeleton()
              : isError
                  ? _buildErrorView(state.message, colorScheme)
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

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: List.generate(6, (_) => _SkeletonCard()),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: colorScheme.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Failed to load',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<AdminCubit>().loadDashboard(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 24,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
