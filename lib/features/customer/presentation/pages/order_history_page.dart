import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/order_model.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().loadAll();
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'paid':
        return const Color(0xFFF59E0B);
      case 'processing':
      case 'received_at_hub':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'cancelled':
      case 'refunded':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatDateTime(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      final hour = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '${date.day}/${date.month}/${date.year} $hour:$min';
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return _buildLoadingState(colorScheme);
          }
          if (state is CustomerError) {
            return _buildErrorState(state, colorScheme);
          }
          if (state is CustomerLoaded) {
            final orders = state.orders;
            final filtered = _selectedFilter == 'All'
                ? orders
                : orders.where((o) {
                    final s = o.status.toLowerCase();
                    switch (_selectedFilter.toLowerCase()) {
                      case 'pending':
                        return s == 'pending' || s == 'paid';
                      case 'processing':
                        return s == 'processing' || s == 'received_at_hub';
                      case 'shipped':
                        return s == 'shipped';
                      case 'delivered':
                        return s == 'delivered';
                      case 'cancelled':
                        return s == 'cancelled' || s == 'refunded';
                      default:
                        return true;
                    }
                  }).toList();

            if (orders.isEmpty) {
              return _buildEmptyState(colorScheme);
            }

            return Column(
              children: [
                _buildFilterTabs(colorScheme),
                if (filtered.isEmpty)
                  _buildEmptyState(colorScheme)
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.06)),
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        return _buildOrderItem(order, colorScheme);
                      },
                    ),
                  ),
              ],
            );
          }
          return _buildLoadingState(colorScheme);
        },
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }

  Widget _buildErrorState(CustomerError state, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(state.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<CustomerCubit>().loadAll(),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No orders found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text(_selectedFilter == 'All' ? 'Your orders will appear here' : 'No $_selectedFilter orders',
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3)),
            ),
          ],
        ),
      );
  }

  Widget _buildFilterTabs(ColorScheme cs) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        children: _filters.map((filter) {
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cs.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(filter,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order, ColorScheme cs) {
    final statusColor = _statusColor(order.status);
    final deliveryRange = order.estimatedDeliveryRange;
    final shipment = order.primaryShipment;

    return GestureDetector(
      onTap: () => context.push(AppConstants.orderDetailRoute, extra: {'order': order}),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ${order.orderRef}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(_formatDateTime(order.createdAt),
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
                Text(order.displayStatus,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...order.items.take(2).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text('Qty: ${item.quantity}',
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                  Text(item.formattedPrice,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Text(order.displayDeliveryStatus,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
            ),
            if (deliveryRange != null)
              Text('Est. delivery: $deliveryRange',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            if (shipment?.trackingNumber != null)
              Text('Tracking: ${shipment!.trackingNumber}',
                style: TextStyle(fontSize: 11, color: cs.primary),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.items.length > 2)
                  Text('+${order.items.length - 2} more items',
                    style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                  )
                else
                  Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                Row(
                  children: [
                    Text('Total: ',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                    Text(order.formattedTotal,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
