import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../../data/models/order_model.dart';

class OrderTrackingPage extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingPage({super.key, required this.order});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'processing':
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFE53935);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  int _statusStep(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
      case 'processing':
        return 1;
      case 'shipped':
        return 2;
      case 'delivered':
      case 'completed':
        return 3;
      case 'cancelled':
      case 'failed':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStep = _statusStep(order.status);
    final isCancelled = currentStep == -1;

    final steps = [
      {'icon': Icons.receipt_long_rounded, 'title': 'Order Placed', 'desc': 'Your order has been received'},
      {'icon': Icons.inventory_rounded, 'title': 'Processing', 'desc': 'Seller is preparing your order'},
      {'icon': Icons.local_shipping_rounded, 'title': 'Shipped', 'desc': 'Your order is on the way'},
      {'icon': Icons.check_circle_rounded, 'title': 'Delivered', 'desc': 'Order has been delivered'},
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  BackIconButton(
                    onTap: () => context.pop(),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('Track Order',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _statusColor(order.status).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _statusColor(order.status).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isCancelled ? Icons.cancel_rounded : Icons.local_shipping_rounded,
                            color: _statusColor(order.status),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isCancelled ? 'Order Cancelled' : order.displayStatus.toUpperCase(),
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: _statusColor(order.status)),
                          ),
                          const SizedBox(height: 4),
                          Text('Order #${order.orderNumber}',
                              style: TextStyle(
                                  fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (!isCancelled)
                      ...List.generate(steps.length, (index) {
                        final step = steps[index];
                        final isCompleted = index <= currentStep;
                        final isCurrent = index == currentStep;
                        final stepColor = isCompleted ? _statusColor(order.status) : colorScheme.onSurface.withValues(alpha: 0.2);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: stepColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCompleted ? Icons.check_rounded : step['icon'] as IconData,
                                    color: Colors.white, size: 20,
                                  ),
                                ),
                                if (index < steps.length - 1)
                                  Container(
                                    width: 2, height: 48,
                                    color: index < currentStep
                                        ? _statusColor(order.status)
                                        : colorScheme.onSurface.withValues(alpha: 0.1),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(step['title'] as String,
                                        style: TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.w700,
                                            color: isCompleted
                                                ? colorScheme.onSurface
                                                : colorScheme.onSurface.withValues(alpha: 0.4))),
                                    const SizedBox(height: 2),
                                    Text(step['desc'] as String,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme.onSurface.withValues(alpha: 0.4))),
                                    if (isCurrent && order.statusHistory.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Current status',
                                          style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w600,
                                              color: _statusColor(order.status))),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      })
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'This order was cancelled. If you have any questions, please contact support.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    if (order.statusHistory.isNotEmpty) ...[
                      Text('Status History',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      ...order.statusHistory.map((h) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF252525) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: _statusColor(h.status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(h.status.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface)),
                                ),
                                if (h.createdAt != null)
                                  Text(_formatDate(h.createdAt!),
                                      style: TextStyle(
                                          fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4))),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
