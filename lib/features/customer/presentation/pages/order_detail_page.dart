import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../cubit/customer_cubit.dart';
import '../../data/models/order_model.dart';
import '../../data/models/escrow_model.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  OrderModel? _freshOrder;
  EscrowSummary? _escrow;
  bool _loading = false;
  bool _isApproving = false;

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

  Future<void> _approveReceipt() async {
    setState(() => _isApproving = true);
    final success = await context.read<CustomerCubit>().approveReceipt(order.id);
    if (mounted) {
      setState(() => _isApproving = false);
      if (success) _refresh();
    }
  }

  OrderModel get order => _freshOrder ?? widget.order;

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
    final statusColor = _statusColor(order.status);
    final canApprove = order.status.toLowerCase() == 'delivered' &&
        (_escrow == null || !_escrow!.canCustomerApprove);

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
          // Status header
          _buildStatusHeader(cs, statusColor),
          const SizedBox(height: 16),

          // Stepper for status history
          if (order.statusHistory.isNotEmpty) ...[
            _buildStepper(cs),
            const SizedBox(height: 16),
          ],

          // Order items
          _buildSectionTitle('Order Items', cs),
          const SizedBox(height: 8),
          ...order.items.map((item) => _buildItemCard(item, cs)),
          const SizedBox(height: 16),

          // Shipments
          if (order.shipments.isNotEmpty) ...[
            _buildSectionTitle('Shipments', cs),
            const SizedBox(height: 8),
            ...order.shipments.map((s) => _buildShipmentCard(s, cs)),
            const SizedBox(height: 16),
          ],

          // Escrow
          if (_escrow != null) ...[
            _buildSectionTitle('Escrow', cs),
            const SizedBox(height: 8),
            _buildEscrowCard(_escrow!, cs),
            const SizedBox(height: 16),
          ],

          // Order summary
          _buildSectionTitle('Order Summary', cs),
          const SizedBox(height: 8),
          _buildSummaryCard(cs),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppConstants.orderTrackingRoute, extra: {'order': order}),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Track Order'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppConstants.invoiceRoute, extra: {'order': order}),
                  icon: const Icon(Icons.receipt_outlined, size: 18),
                  label: const Text('Invoice'),
                ),
              ),
            ],
          ),
          if (canApprove) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isApproving ? null : _approveReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isApproving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Receipt', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ColorScheme cs, Color statusColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_long, size: 22, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.displayStatus,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                  Text('Created ${_formatDate(order.createdAt)}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: order.orderRef));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order code copied'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(order.orderRef, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    const SizedBox(width: 4),
                    Icon(Icons.copy, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(ColorScheme cs) {
    final history = order.statusHistory.reversed.toList();
    final accentColor = _statusColor(order.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 16),
            ...history.asMap().entries.map((entry) {
              final i = entry.key;
              final h = entry.value;
              final isLast = i == history.length - 1;
              final color = _statusColor(h.status);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: isLast ? Border.all(color: accentColor, width: 2) : null,
                            ),
                            child: Icon(
                              isLast ? Icons.radio_button_checked : Icons.check_rounded,
                              size: 14,
                              color: color,
                            ),
                          ),
                          if (!isLast) Container(width: 2, height: 32, color: cs.onSurface.withValues(alpha: 0.08)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_humanize(h.status),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                                ),
                                if (isLast) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('Latest',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accentColor),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (h.notes != null && h.notes!.isNotEmpty)
                              Text(h.notes!,
                                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                              ),
                            if (h.createdAt != null)
                              Text(_formatDate(h.createdAt),
                                style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _buildItemCard(OrderItemModel item, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: item.productImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.productImage!, width: 40, height: 40, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.shopping_bag_outlined, size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                ),
              )
            : Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.shopping_bag_outlined, size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
              ),
        title: Text(item.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Qty ${item.quantity} × ${item.formattedPrice}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        trailing: Text(item.formattedTotal, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
      ),
    );
  }

  Widget _buildShipmentCard(ShipmentModel shipment, ColorScheme cs) {
    final color = _statusColor(shipment.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
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
                  child: Text(shipment.carrierName ?? 'Xerin Express',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(_humanize(shipment.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
            if (shipment.trackingNumber != null) ...[
              const SizedBox(height: 8),
              Text('Tracking: ${shipment.trackingNumber}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
            ],
            if (shipment.estimatedDeliveryFrom != null || shipment.estimatedDeliveryTo != null) ...[
              const SizedBox(height: 4),
              Text('ETA: ${_formatDate(shipment.estimatedDeliveryFrom)} - ${_formatDate(shipment.estimatedDeliveryTo)}',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowCard(EscrowSummary escrow, ColorScheme cs) {
    final isHeld = escrow.status.toLowerCase() == 'held' || escrow.status.toLowerCase() == 'funds_held';
    final escrowColor = isHeld ? const Color(0xFF3B82F6) : const Color(0xFF22C55E);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: escrowColor),
                const SizedBox(width: 8),
                Text(_humanize(escrow.status),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: escrowColor)),
              ],
            ),
            const Divider(height: 16),
            _row('Seller entitlement', _formatMoney(escrow.sellerAmount, escrow.currency), cs),
            _row('Commission', _formatMoney(escrow.commissionAmount, escrow.currency), cs),
            _row('Protected', _formatMoney(escrow.remainingAmount, escrow.currency), cs),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _row('Subtotal', _formatMoney(order.subtotal, order.currency), cs),
            if (order.shippingAmount > 0)
              _row('Shipping', _formatMoney(order.shippingAmount, order.currency), cs),
            if (order.taxAmount > 0)
              _row('Tax', _formatMoney(order.taxAmount, order.currency), cs),
            if (order.discountAmount > 0)
              _row('Discount', '- ${_formatMoney(order.discountAmount, order.currency)}', cs),
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

  Widget _row(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }
}
