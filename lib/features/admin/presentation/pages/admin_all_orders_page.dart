import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../presentation/cubit/admin_cubit.dart';

class AdminAllOrdersPage extends StatefulWidget {
  const AdminAllOrdersPage({super.key});

  @override
  State<AdminAllOrdersPage> createState() => _AdminAllOrdersPageState();
}

class _AdminAllOrdersPageState extends State<AdminAllOrdersPage> {
  String? _statusFilter;
  final _searchController = TextEditingController();

  static const _statusOptions = [
    {'value': null, 'label': 'All'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'processing', 'label': 'Processing'},
    {'value': 'shipped', 'label': 'Shipped'},
    {'value': 'delivered', 'label': 'Delivered'},
    {'value': 'cancelled', 'label': 'Cancelled'},
    {'value': 'completed', 'label': 'Completed'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadAllOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('All Orders'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search orders...',
                  prefixIcon: const Icon(Uicons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                onSubmitted: (value) => context
                    .read<AdminCubit>()
                    .loadAllOrders(status: _statusFilter, search: value),
              ),
            ),
            _buildFilterChips(cs),
            Expanded(
              child: BlocConsumer<AdminCubit, AdminState>(
                listener: (context, state) {
                  if (state is AdminError) {
                    NotificationService().error(state.message);
                  }
                },
                builder: (context, state) {
                  if (state is AdminLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is AdminAllOrdersLoaded) {
                    if (state.orders.isEmpty) {
                      return _buildEmpty(cs);
                    }
                    return RefreshIndicator(
                      onRefresh: () => context
                          .read<AdminCubit>()
                          .loadAllOrders(
                              status: _statusFilter,
                              search: _searchController.text),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _orderCard(state.orders[index], cs),
                      ),
                    );
                  }
                  return _buildEmpty(cs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((opt) {
            final value = opt['value'];
            final isSelected = _statusFilter == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(opt['label']!),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _statusFilter = value);
                  context.read<AdminCubit>().loadAllOrders(
                      status: value, search: _searchController.text);
                },
                selectedColor: cs.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Uicons.truckBox,
              size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No Orders',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order, ColorScheme cs) {
    final status = order['status']?.toString() ?? 'pending';
    final orderId = order['id']?.toString() ?? order['order_number']?.toString() ?? '';
    final total = order['total']?.toString() ?? order['total_amount']?.toString() ?? '0';
    final currency = order['currency']?.toString() ?? 'TZS';
    final customerName = order['customer_name']?.toString() ??
        order['buyer_name']?.toString() ??
        '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text('#$orderId',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (customerName.isNotEmpty)
              Text(customerName,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text('$total $currency',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.primary)),
          ],
        ),
        trailing: _statusBadge(status),
        onTap: () {
          context.push('/admin-order-detail?id=$orderId');
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'completed':
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'processing':
      case 'shipped':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
