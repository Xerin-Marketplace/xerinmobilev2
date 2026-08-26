import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../../data/models/order_model.dart';
import '../../../../core/theme/uicons.dart';

class OrderTrackingPage extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingPage({super.key, required this.order});

  Color _shipmentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'dispatched':
      case 'in_transit':
        return const Color(0xFF8B5CF6);
      case 'out_for_delivery':
        return const Color(0xFF3B82F6);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'processing':
      case 'received_at_hub':
      case 'paid':
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
      case 'paid':
        return 1;
      case 'processing':
        return 2;
      case 'received_at_hub':
        return 3;
      case 'shipped':
        return 4;
      case 'delivered':
      case 'completed':
        return 5;
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
      {'icon': Uicons.receipt, 'title': 'Order Confirmed', 'desc': 'Your order has been received and confirmed'},
      {'icon': Uicons.badgeCheck, 'title': 'Payment Verified', 'desc': 'Payment has been verified and seller notified'},
      {'icon': Uicons.box, 'title': 'Seller Preparing', 'desc': 'The seller is preparing your order for dispatch'},
      {'icon': Uicons.warehouse, 'title': 'Received at Xerin Hub', 'desc': 'Your order has arrived at the Xerin fulfilment centre'},
      {'icon': Uicons.shippingFast, 'title': 'Out for Delivery', 'desc': 'Your order is on the way via Xerin Express'},
      {'icon': Uicons.checkCircle, 'title': 'Delivered', 'desc': 'Order has been delivered successfully'},
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
                            isCancelled ? Uicons.circleXmark : Uicons.shippingFast,
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
                          Text('Order ${order.orderRef}',
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
                                    isCompleted ? Uicons.check : step['icon'] as IconData,
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
                    // Shipment tracking info
                    if (order.shipments.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text('Shipment Tracking',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      ...order.shipments.map((shipment) => _buildShipmentCard(shipment, colorScheme, isDark)),
                    ],

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

  Widget _buildShipmentCard(ShipmentModel shipment, ColorScheme cs, bool isDark) {
    final statusColor = _shipmentStatusColor(shipment.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shipment header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Uicons.shippingFast, color: statusColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shipment.carrierName ?? 'Xerin Express',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    if (shipment.trackingNumber != null) ...[
                      const SizedBox(height: 2),
                      Text('Tracking: ${shipment.trackingNumber}',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(shipment.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          if (shipment.estimatedDeliveryFrom != null || shipment.estimatedDeliveryTo != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Uicons.clock, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text('Est. delivery: ${_formatDateRange(shipment.estimatedDeliveryFrom, shipment.estimatedDeliveryTo)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ],
          // Tracking events
          if (shipment.trackingEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...shipment.trackingEvents.map((event) => _buildTrackingEvent(event, cs, statusColor)),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingEvent(ShipmentTrackingEventModel event, ColorScheme cs, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2, height: 28,
                color: cs.onSurface.withValues(alpha: 0.1),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 2),
                  Text(event.location!,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
                if (event.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(event.notes!,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
                if (event.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(_formatDate(event.createdAt!),
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(String? from, String? to) {
    String fmt(String? iso) {
      if (iso == null) return '';
      try {
        final dt = DateTime.parse(iso);
        return '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        return iso;
      }
    }
    final f = fmt(from);
    final t = fmt(to);
    if (f.isEmpty) return 'By $t';
    if (t.isEmpty) return 'From $f';
    return '$f - $t';
  }
}
