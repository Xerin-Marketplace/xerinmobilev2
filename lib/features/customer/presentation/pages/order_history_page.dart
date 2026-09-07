import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        if (o.orderRef.toLowerCase().contains(q)) return true;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            onPressed: () => context.read<CustomerCubit>().loadAll(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerError) {
            return _buildError(state, cs);
          }

          final allOrders = state is CustomerLoaded ? state.orders : <OrderModel>[];
          final filtered = _applyFilters(allOrders);

          if (allOrders.isEmpty) {
            return _buildEmpty(cs);
          }

          return Column(
            children: [
              _buildSearchAndFilters(cs, allOrders.length),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty(cs, filtered: true)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(filtered[index], cs);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(ColorScheme cs, int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search orders...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((f) {
                final isSelected = f == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(f, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$totalCount orders',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, ColorScheme cs) {
    final statusColor = _statusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(AppConstants.orderDetailRoute, extra: {'order': order}),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: order.orderRef));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Order code copied'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            order.orderRef,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.formattedTotal,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.displayStatus,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(AppConstants.orderTrackingRoute, extra: {'order': order}),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Track',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs, {bool filtered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            filtered ? 'No orders match your search' : 'No orders yet',
            style: TextStyle(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 4),
          Text(
            filtered ? 'Try a different filter or search term' : 'Your orders will appear here',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(CustomerError state, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(state.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<CustomerCubit>().loadAll(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
