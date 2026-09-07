import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../cubit/customer_cubit.dart';
import '../../data/models/order_model.dart';
import '../../data/models/escrow_model.dart';

class OrderTrackingPage extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingPage({super.key, required this.order});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  OrderModel? _freshOrder;
  EscrowSummary? _escrow;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final cubit = context.read<CustomerCubit>();
    final order = await cubit.getOrderById(widget.order.id);
    final escrowData = await cubit.getEscrowStatus(widget.order.id);
    if (mounted) {
      setState(() {
        _freshOrder = order;
        _escrow = escrowData != null ? EscrowSummary.fromJson(escrowData) : null;
        _loading = false;
      });
    }
  }

  OrderModel get order => _freshOrder ?? widget.order;

  Color _statusColor(String status, ColorScheme cs) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'processing':
      case 'received_at_hub':
      case 'paid':
        return cs.primary;
      case 'shipped':
      case 'dispatched':
      case 'in_transit':
      case 'out_for_delivery':
        return cs.tertiary;
      case 'cancelled':
      case 'failed':
        return cs.error;
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

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '${d.day}/${d.month}/${d.year}, $h:$m';
    } catch (_) {
      return iso;
    }
  }

  String _formatDateShort(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatMoney(num amount, String currency) {
    final formatted = amount.toDouble().toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  String _humanize(String s) =>
      s.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentStep = _statusStep(order.status);
    final isCancelled = currentStep == -1;
    final accentColor = _statusColor(order.status, cs);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${order.orderRef}'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order info header
          _buildOrderInfoCard(cs, accentColor),
          const SizedBox(height: 16),

          // Tracking stepper
          if (!isCancelled) ...[
            _buildStepper(cs, currentStep, cs.primary),
            const SizedBox(height: 16),
          ] else ...[
            _buildCancelledCard(cs),
            const SizedBox(height: 16),
          ],

          // Order items
          _buildSectionHeader('Order Items', cs),
          const SizedBox(height: 8),
          ...order.items.map((item) => _buildItemRow(item, cs)),
          const SizedBox(height: 16),

          // Shipment tracking
          if (order.shipments.isNotEmpty) ...[
            _buildSectionHeader('Shipment Tracking', cs),
            const SizedBox(height: 8),
            ...order.shipments.map((s) => _buildShipmentCard(s, cs)),
            const SizedBox(height: 16),
          ],

          // Tracking timeline from status history
          if (order.statusHistory.isNotEmpty) ...[
            _buildSectionHeader('Tracking Timeline', cs),
            const SizedBox(height: 8),
            _buildTimeline(cs),
            const SizedBox(height: 16),
          ],

          // Escrow
          if (_escrow != null) ...[
            _buildSectionHeader('Xerin Escrow', cs),
            const SizedBox(height: 8),
            _buildEscrowCard(_escrow!, cs),
            const SizedBox(height: 16),
          ],

          // Order summary
          _buildSectionHeader('Order Summary', cs),
          const SizedBox(height: 8),
          _buildSummary(cs),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppConstants.invoiceRoute, extra: {'order': order}),
                  icon: const Icon(Icons.receipt_outlined, size: 18),
                  label: const Text('Invoice'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(ColorScheme cs, Color accentColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_shipping_outlined, size: 20, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.displayStatus,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                      Text(
                        'Created ${_formatDate(order.createdAt)}',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('Order', order.orderRef, cs),
            _infoRow('Total', order.formattedTotal, cs),
            if (order.estimatedDeliveryRange != null)
              _infoRow('Est. Delivery', order.estimatedDeliveryRange!, cs),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildStepper(ColorScheme cs, int currentStep, Color accentColor) {
    final steps = [
      _StepData(icon: Icons.receipt_long_outlined, title: 'Order Placed', desc: 'Order received'),
      _StepData(icon: Icons.payments_outlined, title: 'Payment', desc: 'Payment confirmed'),
      _StepData(icon: Icons.inventory_2_outlined, title: 'Processing', desc: 'Seller preparing'),
      _StepData(icon: Icons.warehouse_outlined, title: 'Xerin Hub', desc: 'At fulfilment centre'),
      _StepData(icon: Icons.local_shipping_outlined, title: 'Shipped', desc: 'Out for delivery'),
      _StepData(icon: Icons.check_circle_outline, title: 'Delivered', desc: 'Order delivered'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;
            final isLast = index == steps.length - 1;

            final dotColor = isCompleted || isCurrent ? accentColor : cs.onSurface.withValues(alpha: 0.15);
            final lineColor = isCompleted ? accentColor.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.08);

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: dotColor.withValues(alpha: isCompleted || isCurrent ? 0.12 : 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: isCurrent ? Border.all(color: accentColor, width: 2) : null,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_rounded : step.icon,
                            size: 14,
                            color: isCompleted ? accentColor : (isCurrent ? accentColor : cs.onSurface.withValues(alpha: 0.3)),
                          ),
                        ),
                        if (!isLast) Container(width: 2, height: 28, color: lineColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCompleted || isCurrent ? cs.onSurface : cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                          Text(
                            step.desc,
                            style: TextStyle(
                              fontSize: 11,
                              color: isCompleted || isCurrent ? cs.onSurface.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCancelledCard(ColorScheme cs) {
    return Card(
      color: cs.error.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cancel_outlined, size: 32, color: cs.error.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text('Order Cancelled', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('Contact support if you have questions.', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme cs) {
    return Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _buildItemRow(OrderItemModel item, ColorScheme cs) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: item.productImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item.productImage!, width: 40, height: 40, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(width: 40, height: 40, color: cs.onSurface.withValues(alpha: 0.05), child: Icon(Icons.image_outlined, size: 20, color: cs.onSurface.withValues(alpha: 0.3))),
              ),
            )
          : Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.shopping_bag_outlined, size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
            ),
      title: Text(item.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('Qty ${item.quantity}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      trailing: Text(item.formattedTotal, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
    );
  }

  Widget _buildShipmentCard(ShipmentModel shipment, ColorScheme cs) {
    final color = _statusColor(shipment.status, cs);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shipment.carrierName ?? 'Xerin Express',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(_humanize(shipment.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
            if (shipment.trackingNumber != null) ...[
              const SizedBox(height: 8),
              Text('Tracking: ${shipment.trackingNumber}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
            ],
            if (shipment.estimatedDeliveryFrom != null || shipment.estimatedDeliveryTo != null) ...[
              const SizedBox(height: 4),
              Text('ETA: ${_formatDateShort(shipment.estimatedDeliveryFrom)} - ${_formatDateShort(shipment.estimatedDeliveryTo)}',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            ],
            if (shipment.trackingEvents.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...shipment.trackingEvents.map((e) => _buildTrackingEvent(e, cs, color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingEvent(ShipmentTrackingEventModel event, ColorScheme cs, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color.withValues(alpha: 0.6), shape: BoxShape.circle)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_humanize(event.status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
                if (event.location != null && event.location!.isNotEmpty)
                  Text(event.location!, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                if (event.notes != null && event.notes!.isNotEmpty)
                  Text(event.notes!, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                if (event.createdAt != null)
                  Text(_formatDate(event.createdAt), style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ColorScheme cs) {
    final history = order.statusHistory.reversed.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: history.asMap().entries.map((entry) {
            final i = entry.key;
            final h = entry.value;
            final isLast = i == history.length - 1;
            final color = _statusColor(h.status, cs);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color.withValues(alpha: 0.6), shape: BoxShape.circle)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_humanize(h.status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
                        if (h.notes != null && h.notes!.isNotEmpty)
                          Text(h.notes!, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                        if (h.createdAt != null)
                          Text(_formatDate(h.createdAt), style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3))),
                      ],
                    ),
                  ),
                  if (isLast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text('Latest', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEscrowCard(EscrowSummary escrow, ColorScheme cs) {
    final isHeld = escrow.status.toLowerCase() == 'held' || escrow.status.toLowerCase() == 'funds_held';
    final escrowColor = isHeld ? cs.primary : const Color(0xFF22C55E);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: escrowColor),
                const SizedBox(width: 8),
                Text(_humanize(escrow.status), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: escrowColor)),
              ],
            ),
            const Divider(height: 16),
            _infoRow('Seller entitlement', _formatMoney(escrow.sellerAmount, escrow.currency), cs),
            _infoRow('Marketplace commission', _formatMoney(escrow.commissionAmount, escrow.currency), cs),
            _infoRow('Still protected', _formatMoney(escrow.remainingAmount, escrow.currency), cs),
            const SizedBox(height: 8),
            Text(
              isHeld
                  ? 'Seller funds remain protected. Release starts after verified delivery.'
                  : 'Funds released to seller.',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _infoRow('Subtotal', _formatMoney(order.subtotal, order.currency), cs),
            if (order.shippingAmount > 0)
              _infoRow('Shipping', _formatMoney(order.shippingAmount, order.currency), cs),
            if (order.taxAmount > 0)
              _infoRow('Tax', _formatMoney(order.taxAmount, order.currency), cs),
            if (order.discountAmount > 0)
              _infoRow('Discount', '- ${_formatMoney(order.discountAmount, order.currency)}', cs),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
                Text(order.formattedTotal, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String desc;

  const _StepData({required this.icon, required this.title, required this.desc});
}
