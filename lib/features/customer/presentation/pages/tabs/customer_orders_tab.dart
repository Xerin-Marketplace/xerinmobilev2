import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../shared/widgets/guest_auth_gate.dart';
import '../../cubit/customer_cubit.dart';
import '../../cubit/customer_state.dart';
import '../../../data/models/order_model.dart';

class CustomerOrdersTab extends StatefulWidget {
  const CustomerOrdersTab({super.key});

  @override
  State<CustomerOrdersTab> createState() => _CustomerOrdersTabState();
}

class _CustomerOrdersTabState extends State<CustomerOrdersTab> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final _filters = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  String _formatDate(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final d = DateTime.parse(createdAt);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return createdAt;
    }
  }

  List<OrderModel> _applyFilters(List<OrderModel> orders) {
    var result = orders;
    if (_selectedFilter != 'All') {
      result = result.where((o) {
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
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((o) {
        if (o.orderNumber.toLowerCase().contains(q)) return true;
        if (o.status.toLowerCase().contains(q)) return true;
        if (o.items.any((i) => i.productName.toLowerCase().contains(q))) return true;
        return false;
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (GuestAuthGate.isGuest) {
      return GuestAuthGate(
        title: 'Sign In to View Orders',
        message: 'Track your purchases and view order history. Sign in to access your orders.',
        child: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          final orders = state is CustomerLoaded ? state.orders : <OrderModel>[];
          final filtered = _applyFilters(orders);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.search, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cs.onSurface.withValues(alpha: 0.04),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (ctx, i) {
                    final f = _filters[i];
                    final isActive = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state is CustomerLoading && orders.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text('No orders found',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
                                ),
                                const SizedBox(height: 6),
                                Text('Your order history will appear here',
                                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final order = filtered[index];
                              final statusColor = _statusColor(order.status);
                              final productImages = order.items
                                  .where((item) => item.productImage != null && item.productImage!.isNotEmpty)
                                  .take(4)
                                  .map((item) => item.productImage!)
                                  .toList();
                              final extraCount = order.items.length > 4 ? order.items.length - 4 : 0;

                              return GestureDetector(
                                onTap: () {
                                  context.push(AppConstants.orderDetailRoute, extra: {'order': order});
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cs.onSurface.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(Icons.receipt_long, size: 18, color: statusColor),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          order.orderRef,
                                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          order.orderNumber,
                                                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                order.displayStatus,
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (productImages.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          child: Row(
                                            children: [
                                              ...productImages.map((img) => Padding(
                                                padding: const EdgeInsets.only(right: 6),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    img,
                                                    width: 52,
                                                    height: 52,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      width: 52,
                                                      height: 52,
                                                      decoration: BoxDecoration(
                                                        color: cs.onSurface.withValues(alpha: 0.06),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(Icons.image_outlined, size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
                                                    ),
                                                  ),
                                                ),
                                              )),
                                              if (extraCount > 0)
                                                Container(
                                                  width: 52,
                                                  height: 52,
                                                  decoration: BoxDecoration(
                                                    color: cs.onSurface.withValues(alpha: 0.06),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '+$extraCount',
                                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.5)),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                                        decoration: BoxDecoration(
                                          color: cs.onSurface.withValues(alpha: 0.02),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Date',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.35)),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.calendar_today_outlined, size: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                                                      const SizedBox(width: 4),
                                                      Text(_formatDate(order.createdAt),
                                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 28,
                                              color: cs.onSurface.withValues(alpha: 0.06),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Items',
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.35)),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.inventory_2_outlined, size: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                                                        const SizedBox(width: 4),
                                                        Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 28,
                                              color: cs.onSurface.withValues(alpha: 0.06),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Total',
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.35)),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(order.formattedTotal,
                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
