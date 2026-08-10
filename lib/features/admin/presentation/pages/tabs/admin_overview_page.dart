import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/admin_cubit.dart';
import '../../cubit/admin_state.dart';

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if (state is AdminError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<AdminCubit>().loadDashboard(),
          );
        }

        if (state is! AdminDashboardLoaded) {
          return _buildLoadingSkeleton();
        }

        final data = state;

        return RefreshIndicator(
          onRefresh: () => context.read<AdminCubit>().loadDashboard(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard Overview',
                    style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _StatCard(
                      icon: Icons.people_rounded,
                      label: 'Total Users',
                      value: '${data.totalUsers}',
                      color: Colors.blue,
                    ),
                    _StatCard(
                      icon: Icons.store_rounded,
                      label: 'Total Sellers',
                      value: '${data.totalSellers}',
                      color: Colors.purple,
                    ),
                    _StatCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending Sellers',
                      value: '${data.totalPendingSellers}',
                      color: Colors.orange,
                    ),
                    _StatCard(
                      icon: Icons.inventory_2_rounded,
                      label: 'Pending Products',
                      value: '${data.totalPendingProducts}',
                      color: Colors.teal,
                    ),
                    _StatCard(
                      icon: Icons.category_rounded,
                      label: 'Categories',
                      value: '${data.totalCategories}',
                      color: Colors.indigo,
                    ),
                    _StatCard(
                      icon: Icons.branding_watermark_rounded,
                      label: 'Brands',
                      value: '${data.totalBrands}',
                      color: Colors.pink,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (data.totalPendingSellers > 0) ...[
                  Text('Pending Seller Approvals',
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...data.pendingSellers.take(5).map((seller) =>
                      _PendingItemCard(
                        title: seller['business_name']?.toString() ??
                            seller['seller_name']?.toString() ??
                            'Unknown',
                        subtitle:
                            seller['email']?.toString() ?? 'No email',
                        status: seller['status']?.toString() ?? 'pending',
                        onApprove: () => context
                            .read<AdminCubit>()
                            .approveSeller(seller['id']?.toString() ?? ''),
                        onReject: () => context
                            .read<AdminCubit>()
                            .rejectSeller(seller['id']?.toString() ?? ''),
                      )),
                ],
                if (data.totalPendingProducts > 0) ...[
                  const SizedBox(height: 24),
                  Text('Pending Product Approvals',
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...data.pendingProducts.take(5).map((product) =>
                      _PendingItemCard(
                        title: product['name']?.toString() ?? 'Unknown Product',
                        subtitle:
                            'TZS ${product['price']?.toString() ?? '0'}',
                        status: product['status']?.toString() ?? 'pending',
                        onApprove: () => context
                            .read<AdminCubit>()
                            .approveProduct(product['id']?.toString() ?? ''),
                        onReject: () => context
                            .read<AdminCubit>()
                            .rejectProduct(product['id']?.toString() ?? ''),
                      )),
                ],
                if (data.totalPendingSellers == 0 && data.totalPendingProducts == 0) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('All caught up!',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                        const SizedBox(height: 4),
                        Text('No pending approvals',
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: List.generate(6, (_) => _SkeletonCard()),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 22,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 10,
                width: 70,
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: colorScheme.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('Failed to load',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingItemCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_rounded,
                  color: Colors.green),
              onPressed: onApprove,
              tooltip: 'Approve',
            ),
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Colors.red),
              onPressed: onReject,
              tooltip: 'Reject',
            ),
          ],
        ),
      ),
    );
  }
}
