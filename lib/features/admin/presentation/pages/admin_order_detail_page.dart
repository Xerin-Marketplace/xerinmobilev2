import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../presentation/cubit/admin_cubit.dart';

class AdminOrderDetailPage extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailPage({super.key, required this.orderId});

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  String? _selectedStatus;

  static const _statusOptions = [
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadOrderDetail(widget.orderId);
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
        title: const Text('Order Detail'),
      ),
      body: SafeArea(
        child: BlocConsumer<AdminCubit, AdminState>(
          listener: (context, state) {
            if (state is AdminError) {
              NotificationService().error(state.message);
            }
            if (state is AdminActionSuccess) {
              NotificationService().success(state.message);
            }
          },
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminOrderDetailLoaded) {
              return _buildContent(state.order, cs);
            }
            return Center(
              child: Text('Loading...',
                  style:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> order, ColorScheme cs) {
    final status = order['status']?.toString() ?? 'pending';
    final orderId =
        order['id']?.toString() ?? order['order_number']?.toString() ?? '';
    final total = order['total']?.toString() ??
        order['total_amount']?.toString() ??
        '0';
    final currency = order['currency']?.toString() ?? 'TZS';
    final customerName =
        order['customer_name']?.toString() ?? order['buyer_name']?.toString() ?? '';
    final items = order['items'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Order #$orderId',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      const Spacer(),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(cs, 'Customer', customerName),
                  _infoRow(cs, 'Total', '$total $currency'),
                  if (order['created_at'] != null)
                    _infoRow(cs, 'Created', order['created_at'].toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Items',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text('No items',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))
          else
            ...items.map((item) {
              final itemMap = item as Map<String, dynamic>;
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                      BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                      itemMap['product_name']?.toString() ??
                          itemMap['name']?.toString() ??
                          'Unknown Product',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  subtitle: Text(
                    'Qty: ${itemMap['quantity']?.toString() ?? '1'} - ${itemMap['price']?.toString() ?? '0'} $currency',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          Text('Update Status',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus ?? status,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.replaceAll('_', ' ')),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _selectedStatus == null
                    ? null
                    : () => context
                        .read<AdminCubit>()
                        .updateOrderStatus(widget.orderId, _selectedStatus!),
                child: const Text('Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ColorScheme cs, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.5))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ),
        ],
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
