import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/order_model.dart';
import '../../../../core/theme/uicons.dart';

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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Uicons.checkCircle;
      case 'processing':
      case 'received_at_hub':
      case 'paid':
        return Uicons.clock;
      case 'shipped':
        return Uicons.shippingFast;
      case 'cancelled':
      case 'refunded':
        return Uicons.circleXmark;
      case 'pending':
      default:
        return Uicons.accessTime;
    }
  }

  IconData _deliveryIcon(String? shipmentStatus) {
    switch (shipmentStatus?.toLowerCase()) {
      case 'delivered':
        return Uicons.checkCircle;
      case 'out_for_delivery':
        return Uicons.truckBox;
      case 'in_transit':
        return Uicons.shippingFast;
      case 'dispatched':
        return Uicons.box;
      case 'ready_for_dispatch':
        return Uicons.boxOpen;
      case 'delivery_failed':
        return Uicons.circleExclamation;
      case 'cancelled':
      case 'returned_to_sender':
        return Uicons.circleXmark;
      case 'pending':
      default:
        return Uicons.clock;
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

  String _formatCompact(double amount) {
    if (amount >= 1000000000) return 'TZS ${(amount / 1000000000).toStringAsFixed(2)}B';
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(1)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<CustomerCubit, CustomerState>(
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

              return Column(
                children: [
                  _buildHeader(colorScheme),
                  if (orders.isNotEmpty) ...[
                    _buildKpiCards(state, colorScheme),
                    _buildFilterTabs(colorScheme),
                  ],
                  if (filtered.isEmpty)
                    _buildEmptyState(colorScheme)
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          return _buildOrderCard(order, colorScheme, isDark);
                        },
                      ),
                    ),
                ],
              );
            }
            return _buildLoadingState(colorScheme);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text('Loading your orders...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CustomerError state, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Uicons.circleExclamation, size: 36, color: cs.error),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(state.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<CustomerCubit>().loadAll(),
              icon: const Icon(Uicons.refresh, size: 18),
              label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          BackIconButton(
            onTap: () => context.pop(),
            color: cs.primary,
          ),
          const SizedBox(width: 16),
          Text('My Orders',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(CustomerLoaded state, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _buildKpiCard(
            'Total', '${state.totalOrders}',
            Uicons.shoppingBag, const Color(0xFFF47524), cs,
            sub: '${state.pendingOrders} pending',
          ),
          const SizedBox(width: 12),
          _buildKpiCard(
            'Delivered', '${state.deliveredOrders}',
            Uicons.checkCircle, const Color(0xFF22C55E), cs,
            sub: _formatCompact(state.totalSpent),
          ),
          const SizedBox(width: 12),
          _buildKpiCard(
            'Cancelled', '${state.cancelledOrders}',
            Uicons.circleXmark, const Color(0xFFE53935), cs,
            sub: '${state.processingOrders} active',
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, ColorScheme cs, {String? sub}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.4)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
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

  Widget _buildEmptyState(ColorScheme cs) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Uicons.shoppingBag, size: 44, color: cs.primary.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 20),
            Text('No orders found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text(_selectedFilter == 'All' ? 'Your orders will appear here' : 'No $_selectedFilter orders',
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, ColorScheme cs, bool isDark) {
    final statusColor = _statusColor(order.status);
    final statusIcon = _statusIcon(order.status);
    final deliveryColor = _statusColor(order.primaryShipment?.status ?? 'pending');
    final deliveryIcon = _deliveryIcon(order.primaryShipment?.status);

    return GestureDetector(
      onTap: () => context.push(AppConstants.orderDetailRoute, extra: {'order': order}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            _buildCardHeader(order, statusColor, statusIcon, cs),
            _buildCardItems(order, cs),
            _buildDeliveryStatus(order, deliveryColor, deliveryIcon, cs),
            _buildCardFooter(order, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(OrderModel order, Color color, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Text(order.displayStatus,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItems(OrderModel order, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: order.items.take(2).map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: item.productImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(item.productImage!, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(Uicons.box, color: cs.primary.withValues(alpha: 0.4), size: 20)),
                      )
                    : Icon(Uicons.box, color: cs.primary.withValues(alpha: 0.4), size: 20),
              ),
              const SizedBox(width: 12),
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
        )).toList(),
      ),
    );
  }

  Widget _buildDeliveryStatus(OrderModel order, Color color, IconData icon, ColorScheme cs) {
    final deliveryRange = order.estimatedDeliveryRange;
    final shipment = order.primaryShipment;
    final carrier = shipment?.carrierName ?? order.shippingCarrier;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Status',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                    const SizedBox(height: 2),
                    Text(order.displayDeliveryStatus,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                    ),
                  ],
                ),
              ),
              if (carrier != null && carrier.isNotEmpty)
                Text(carrier,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
            ],
          ),
          if (deliveryRange != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Uicons.truckBox, color: cs.onSurface.withValues(alpha: 0.3), size: 14),
                const SizedBox(width: 6),
                Text('Est. delivery: $deliveryRange',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ],
          if (shipment?.trackingNumber != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Uicons.box, color: cs.onSurface.withValues(alpha: 0.3), size: 14),
                const SizedBox(width: 6),
                Text('Tracking: ${shipment!.trackingNumber}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardFooter(OrderModel order, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cs.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
