import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      case 'received_at_hub':
      case 'paid':
        return const Color(0xFF3B82F6);
      case 'shipped':
      case 'dispatched':
      case 'in_transit':
      case 'out_for_delivery':
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
    final cs = Theme.of(context).colorScheme;
    final currentStep = _statusStep(order.status);
    final isCancelled = currentStep == -1;
    final accentColor = _statusColor(order.status);

    final steps = [
      _StepData(icon: Icons.receipt_long_outlined, title: 'Order Placed', desc: 'Your order has been received'),
      _StepData(icon: Icons.payments_outlined, title: 'Payment Verified', desc: 'Payment confirmed, seller notified'),
      _StepData(icon: Icons.inventory_2_outlined, title: 'Seller Preparing', desc: 'The seller is preparing your order'),
      _StepData(icon: Icons.warehouse_outlined, title: 'Xerin Hub', desc: 'Arrived at Xerin fulfilment centre'),
      _StepData(icon: Icons.local_shipping_outlined, title: 'Out for Delivery', desc: 'On the way via Xerin Express'),
      _StepData(icon: Icons.check_circle_outline, title: 'Delivered', desc: 'Order delivered successfully'),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, cs),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(cs, accentColor, isCancelled),
                    const SizedBox(height: 24),
                    if (!isCancelled) ...[
                      _buildTimeline(cs, steps, currentStep, accentColor),
                      if (order.shipments.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _buildSectionLabel('Shipment Details', cs),
                        const SizedBox(height: 12),
                        ...order.shipments.map((s) => _buildShipmentCard(s, cs)),
                      ],
                      if (order.statusHistory.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _buildSectionLabel('Status History', cs),
                        const SizedBox(height: 12),
                        _buildStatusHistory(cs),
                      ],
                    ] else ...[
                      _buildCancelledCard(cs),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back, size: 20, color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Track Order',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme cs, Color accentColor, bool isCancelled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCancelled ? Icons.cancel_outlined : Icons.local_shipping_outlined,
                  size: 22, color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCancelled ? 'Order Cancelled' : order.displayStatus.toUpperCase(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: accentColor),
                    ),
                    Text('Order ${order.orderRef}',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.estimatedDeliveryRange != null && !isCancelled) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 8),
                  Text('Est. delivery: ${order.estimatedDeliveryRange}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(ColorScheme cs, List<_StepData> steps, int currentStep, Color accentColor) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == steps.length - 1;

        final dotColor = isCompleted || isCurrent ? accentColor : cs.onSurface.withValues(alpha: 0.15);
        final lineColor = isCompleted ? accentColor.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.08);
        final titleColor = isCompleted || isCurrent ? cs.onSurface : cs.onSurface.withValues(alpha: 0.35);
        final descColor = isCompleted || isCurrent ? cs.onSurface.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.25);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: dotColor.withValues(alpha: isCompleted || isCurrent ? 0.15 : 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: isCurrent ? Border.all(color: accentColor, width: 2) : null,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : step.icon,
                        size: 16,
                        color: isCompleted ? accentColor : (isCurrent ? accentColor : cs.onSurface.withValues(alpha: 0.3)),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 36,
                        color: lineColor,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: titleColor),
                      ),
                      const SizedBox(height: 2),
                      Text(step.desc,
                        style: TextStyle(fontSize: 12, color: descColor),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('In Progress',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionLabel(String label, ColorScheme cs) {
    return Text(label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.6)),
    );
  }

  Widget _buildShipmentCard(ShipmentModel shipment, ColorScheme cs) {
    final statusColor = _statusColor(shipment.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_shipping_outlined, size: 18, color: statusColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shipment.carrierName ?? 'Xerin Express',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      if (shipment.trackingNumber != null)
                        Text(shipment.trackingNumber!,
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(shipment.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            if (shipment.estimatedDeliveryFrom != null || shipment.estimatedDeliveryTo != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text('Est. delivery: ${_formatDateRange(shipment.estimatedDeliveryFrom, shipment.estimatedDeliveryTo)}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
            if (shipment.trackingEvents.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...shipment.trackingEvents.asMap().entries.map((entry) {
                final i = entry.key;
                final event = entry.value;
                final isLast = i == shipment.trackingEvents.length - 1;
                return _buildTrackingEventRow(event, cs, statusColor, isLast);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingEventRow(ShipmentTrackingEventModel event, ColorScheme cs, Color accentColor, bool isLast) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2, height: 24,
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                if (event.location != null)
                  Text(event.location!,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                if (event.notes != null)
                  Text(event.notes!,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                if (event.createdAt != null)
                  Text(_formatDate(event.createdAt!),
                    style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistory(ColorScheme cs) {
    return Column(
      children: order.statusHistory.asMap().entries.map((entry) {
        final i = entry.key;
        final h = entry.value;
        final isLast = i == order.statusHistory.length - 1;
        final color = _statusColor(h.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2, height: 28,
                      color: cs.onSurface.withValues(alpha: 0.08),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    if (h.notes != null)
                      Text(h.notes!,
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                  ],
                ),
              ),
              if (h.createdAt != null)
                Text(_formatDate(h.createdAt!),
                  style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCancelledCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.cancel_outlined, size: 32, color: const Color(0xFFE53935).withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('This order was cancelled',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 4),
          Text('If you have any questions, please contact support.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
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

class _StepData {
  final IconData icon;
  final String title;
  final String desc;

  const _StepData({required this.icon, required this.title, required this.desc});
}
