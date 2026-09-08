import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../cubit/customer_cubit.dart';
import '../../data/models/order_model.dart';
import '../../data/models/escrow_model.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel? order;
  final String? orderId;

  const OrderDetailPage({super.key, required this.order}) : orderId = null;

  const OrderDetailPage.fromId({super.key, required this.orderId}) : order = null;

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
    if (widget.order != null) {
      _freshOrder = widget.order;
    }
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final cubit = context.read<CustomerCubit>();
    final id = widget.orderId ?? widget.order?.id ?? _freshOrder?.id;
    if (id == null || id.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final order = await cubit.getOrderById(id);
    final escrowData = await cubit.getEscrowStatus(id);
    if (mounted) {
      setState(() {
        if (order != null) _freshOrder = order;
        _escrow = escrowData != null ? EscrowSummary.fromJson(escrowData) : null;
        _loading = false;
      });
    }
  }

  Future<void> _approveReceipt() async {
    final id = order.id;
    setState(() => _isApproving = true);
    final success = await context.read<CustomerCubit>().approveReceipt(id);
    if (mounted) {
      setState(() => _isApproving = false);
      if (success) _refresh();
    }
  }

  OrderModel get order => _freshOrder ?? widget.order!;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (order.id.isEmpty && _loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final statusColor = _statusColor(order.status);
    final canApprove = order.status.toLowerCase() == 'delivered' &&
        (_escrow == null || !_escrow!.canCustomerApprove);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${order.orderRef}'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildStatusHero(cs, isDark, statusColor),
          const SizedBox(height: 16),

          if (order.statusHistory.isNotEmpty) ...[
            _buildTimeline(cs, isDark),
            const SizedBox(height: 16),
          ],

          _buildSectionLabel('Order Items', cs, '${order.items.length} item${order.items.length == 1 ? '' : 's'}'),
          const SizedBox(height: 10),
          ...order.items.map((item) => _buildItemCard(item, cs)),
          const SizedBox(height: 16),

          if (order.shipments.isNotEmpty) ...[
            _buildSectionLabel('Shipments', cs, '${order.shipments.length} shipment${order.shipments.length == 1 ? '' : 's'}'),
            const SizedBox(height: 10),
            ...order.shipments.map((s) => _buildShipmentCard(s, cs)),
            const SizedBox(height: 16),
          ],

          if (_escrow != null) ...[
            _buildSectionLabel('Escrow Protection', cs, null),
            const SizedBox(height: 10),
            _buildEscrowCard(_escrow!, cs),
            const SizedBox(height: 16),
          ],

          _buildSectionLabel('Order Summary', cs, null),
          const SizedBox(height: 10),
          _buildSummaryCard(cs),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppConstants.orderTrackingRoute, extra: {'order': order}),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
                  ),
                  icon: Icon(Icons.local_shipping_outlined, size: 18, color: cs.primary),
                  label: Text('Track Order', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppConstants.invoiceRoute, extra: {'order': order}),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
                  ),
                  icon: Icon(Icons.receipt_outlined, size: 18, color: cs.primary),
                  label: Text('Invoice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                ),
              ),
            ],
          ),
          if (canApprove) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isApproving ? null : _approveReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isApproving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Receipt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusHero(ColorScheme cs, bool isDark, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.08),
            statusColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.receipt_long, size: 24, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.displayStatus,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: statusColor),
                    ),
                    const SizedBox(height: 2),
                    Text('Placed ${_formatDate(order.createdAt)}',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Order Code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(width: 8),
                  Text(order.orderRef, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(width: 6),
                  Icon(Icons.copy, size: 13, color: cs.onSurface.withValues(alpha: 0.3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ColorScheme cs, bool isDark) {
    final history = order.statusHistory.reversed.toList();
    final accentColor = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
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
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: isLast ? Border.all(color: accentColor, width: 2) : null,
                          ),
                          child: Icon(
                            isLast ? Icons.radio_button_checked : Icons.check_rounded,
                            size: 16,
                            color: color,
                          ),
                        ),
                        if (!isLast) Container(width: 2, height: 36, color: cs.onSurface.withValues(alpha: 0.08)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_humanize(h.status),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                              ),
                              if (isLast) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Latest',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: accentColor),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (h.notes != null && h.notes!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(h.notes!,
                              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                            ),
                          ],
                          if (h.createdAt != null) ...[
                            const SizedBox(height: 2),
                            Text(_formatDate(h.createdAt),
                              style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3)),
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
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, ColorScheme cs, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface)),
        if (subtitle != null)
          Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildItemCard(OrderItemModel item, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.productImage != null && item.productImage!.isNotEmpty
                  ? Image.network(item.productImage!, width: 48, height: 48, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.shopping_bag_outlined, size: 22, color: cs.onSurface.withValues(alpha: 0.3)),
                      ),
                    )
                  : Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.shopping_bag_outlined, size: 22, color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Qty ${item.quantity}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('× ${item.formattedPrice}',
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(item.formattedTotal,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentCard(ShipmentModel shipment, ColorScheme cs) {
    final color = _statusColor(shipment.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_shipping_outlined, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(shipment.carrierName ?? 'Xerin Express',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(_humanize(shipment.status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            if (shipment.trackingNumber != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.numbers, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text('Tracking: ${shipment.trackingNumber}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                ],
              ),
            ],
            if (shipment.estimatedDeliveryFrom != null || shipment.estimatedDeliveryTo != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text('ETA: ${_formatDate(shipment.estimatedDeliveryFrom)} - ${_formatDate(shipment.estimatedDeliveryTo)}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowCard(EscrowSummary escrow, ColorScheme cs) {
    final isHeld = escrow.status.toLowerCase() == 'held' || escrow.status.toLowerCase() == 'funds_held';
    final escrowColor = isHeld ? const Color(0xFF3B82F6) : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
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
                  color: escrowColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shield_outlined, size: 18, color: escrowColor),
              ),
              const SizedBox(width: 10),
              Text(_humanize(escrow.status),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: escrowColor)),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Seller entitlement', _formatMoney(escrow.sellerAmount, escrow.currency), cs),
          _summaryRow('Commission', _formatMoney(escrow.commissionAmount, escrow.currency), cs),
          _summaryRow('Protected', _formatMoney(escrow.remainingAmount, escrow.currency), cs),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', _formatMoney(order.subtotal, order.currency), cs),
          if (order.shippingAmount > 0)
            _summaryRow('Shipping', _formatMoney(order.shippingAmount, order.currency), cs),
          if (order.taxAmount > 0)
            _summaryRow('Tax', _formatMoney(order.taxAmount, order.currency), cs),
          if (order.discountAmount > 0)
            _summaryRow('Discount', '- ${_formatMoney(order.discountAmount, order.currency)}', cs),
          const SizedBox(height: 6),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface)),
              Text(order.formattedTotal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme cs) {
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
}
