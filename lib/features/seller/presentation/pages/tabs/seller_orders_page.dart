import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/seller_cubit.dart';
import '../../cubit/seller_state.dart';
import '../../../data/models/seller_order_model.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerCubit>().refreshOrders();
    });
  }

  static const _filters = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  List<SellerOrderModel> _filterOrders(List<SellerOrderModel> orders) {
    if (_selectedFilter == 'All') return orders;
    final statusMap = {
      'Pending': 'pending',
      'Processing': 'processing',
      'Shipped': 'shipped',
      'Delivered': 'delivered',
      'Cancelled': 'cancelled',
    };
    final statusValue = statusMap[_selectedFilter] ?? _selectedFilter.toLowerCase();
    return orders.where((o) => o.status == statusValue).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                BlocBuilder<SellerCubit, SellerState>(
                  builder: (context, state) {
                    final count = state is SellerDashboardLoaded ? state.orders.length : 0;
                    return Text(
                      '$count orders total',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isActive = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SellerCubit, SellerState>(
              builder: (context, state) {
                if (state is SellerDashboardLoaded) {
                  final orders = _filterOrders(state.orders);
                  if (orders.isEmpty) {
                    return _buildEmptyState(colorScheme);
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<SellerCubit>().refreshOrders(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(order, colorScheme);
                      },
                    ),
                  );
                }
                if (state is SellerLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildEmptyState(colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(SellerOrderModel order, ColorScheme colorScheme) {
    final statusColor = _getStatusColor(order.status);
    final productName = order.items.isNotEmpty ? order.items.first.productName : 'Order';
    final itemCount = order.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.displayStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 14, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Customer: ${order.userId.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                order.orderRef,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$itemCount item(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                order.formattedTotal,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (order.status == 'pending' || order.status == 'processing') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => context
                        .read<SellerCubit>()
                        .updateOrderStatus(order.id, 'shipped', notes: 'Order shipped'),
                    child: const Text('Mark Shipped', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => context
                        .read<SellerCubit>()
                        .updateOrderStatus(order.id, 'delivered', notes: 'Order delivered'),
                    child: const Text('Deliver', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return const Color(0xFF22C55E);
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'shipped':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return const Color(0xFFE53935);
      case 'paid':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
