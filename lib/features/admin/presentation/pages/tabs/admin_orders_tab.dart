import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/theme/uicons.dart';
import '../../cubit/admin_cubit.dart';
import '../../../data/models/admin_models.dart';

class AdminOrdersTab extends StatefulWidget {
  final AdminDashboardLoaded? dashboardState;

  const AdminOrdersTab({super.key, this.dashboardState});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  bool _isReloading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AdminCubit>();
      if (cubit.state is! AdminOrdersLoaded && cubit.state is! AdminLoading) {
        cubit.loadOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AdminCubit, AdminState>(
      buildWhen: (prev, curr) =>
          curr is AdminLoading ||
          curr is AdminOrdersLoaded ||
          curr is AdminError,
      builder: (context, state) {
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminError) {
          return _errorView(colorScheme, state.message);
        }
        if (state is AdminOrdersLoaded) {
          return _ordersList(colorScheme, isDark, state);
        }

        final dash = widget.dashboardState;
        if (dash != null && dash.orders != null) {
          return _ordersBreakdown(colorScheme, isDark, dash.orders!);
        }

        if (!_isReloading) {
          _isReloading = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AdminCubit>().loadOrders();
            _isReloading = false;
          });
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _ordersBreakdown(ColorScheme cs, bool isDark, AdminDashboardOrdersModel orders) {
    final entries = orders.byStatus.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Orders Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => context.read<AdminCubit>().loadOrders(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Uicons.refresh, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Load All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _statusColor(e.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _humanize(e.key),
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.push(AppConstants.adminAllOrdersRoute),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Uicons.shoppingBag, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'View All Orders',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Uicons.angleRight, size: 14, color: cs.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _ordersList(ColorScheme cs, bool isDark, AdminOrdersLoaded state) {
    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.boxOpen, size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: state.orders.length,
      itemBuilder: (context, index) {
        final order = state.orders[index];
        final orderId = order['id']?.toString() ?? 'N/A';
        final status = order['status']?.toString() ?? 'unknown';
        final total = order['total']?.toString() ?? '0';

        return GestureDetector(
          onTap: () => context.push(AppConstants.adminOrderDetailRoute, extra: {'id': orderId}),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Uicons.shoppingBag, size: 20, color: _statusColor(status)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        _humanize(status),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  total,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _errorView(ColorScheme cs, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Uicons.circleExclamation, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<AdminCubit>().loadOrders(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'paid':
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'shipped':
      case 'out_for_delivery':
        return const Color(0xFF9C27B0);
      case 'delivered':
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF607D8B);
    }
  }

  String _humanize(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
