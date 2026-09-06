import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_model.dart';

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
      {'title': 'Order Confirmed', 'desc': 'Your order has been received and confirmed'},
      {'title': 'Payment Verified', 'desc': 'Payment has been verified and seller notified'},
      {'title': 'Seller Preparing', 'desc': 'The seller is preparing your order for dispatch'},
      {'title': 'Received at Xerin Hub', 'desc': 'Your order has arrived at the Xerin fulfilment centre'},
      {'title': 'Out for Delivery', 'desc': 'Your order is on the way via Xerin Express'},
      {'title': 'Delivered', 'desc': 'Order has been delivered successfully'},
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
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back, size: 22, color: colorScheme.onSurface),
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
                    Text(
                      isCancelled ? 'Order Cancelled' : order.displayStatus.toUpperCase(),
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: _statusColor(order.status)),
                    ),
                    const SizedBox(height: 4),
                    Text('Order ${order.orderRef}',
                        style: TextStyle(
                            fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5))),
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
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(
                                    color: stepColor,
                                    shape: BoxShape.circle,
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
                                padding: const EdgeInsets.only(top: 0),
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
                    if (order.shipments.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text('Shipment Tracking',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      ...order.shipments.map((shipment) => _buildShipmentInfo(shipment, colorScheme)),
                    ],

                    const SizedBox(height: 28),
                    if (order.statusHistory.isNotEmpty) ...[
                      Text('Status History',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      ...order.statusHistory.map((h) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
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

  Widget _buildShipmentInfo(ShipmentModel shipment, ColorScheme cs) {
    final statusColor = _shipmentStatusColor(shipment.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              Text(shipment.status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ],
          ),
          if (shipment.estimatedDeliveryFrom != null || shipment.estimatedDeliveryTo != null) ...[
            const SizedBox(height: 8),
            Text('Est. delivery: ${_formatDateRange(shipment.estimatedDeliveryFrom, shipment.estimatedDeliveryTo)}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
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
