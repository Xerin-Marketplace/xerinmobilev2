import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../cubit/customer_cubit.dart';
import '../../data/models/order_model.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? _escrowStatus;
  bool _isApprovingReceipt = false;

  @override
  void initState() {
    super.initState();
    _fetchEscrowStatus();
  }

  Future<void> _fetchEscrowStatus() async {
    final result = await context.read<CustomerCubit>().getEscrowStatus(widget.order.id);
    if (mounted) {
      setState(() {
        _escrowStatus = result;
      });
    }
  }

  Future<void> _approveReceipt() async {
    setState(() => _isApprovingReceipt = true);
    final success = await context.read<CustomerCubit>().approveReceipt(widget.order.id);
    if (mounted) {
      setState(() => _isApprovingReceipt = false);
      if (success) {
        _fetchEscrowStatus();
      }
    }
  }

  OrderModel get order => widget.order;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(order.status);
    final canApproveReceipt = order.status.toLowerCase() == 'delivered' &&
        (_escrowStatus == null || _escrowStatus!['receipt_approved'] != true);

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
                    child: Text(
                      'Order ${order.orderRef}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
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
                    Text(order.displayStatus.toUpperCase(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                    if (order.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text('Placed on ${_formatDate(order.createdAt!)}',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionTitle('Items', colorScheme),
                    const SizedBox(height: 8),
                    ...order.items.map((item) => _buildItemRow(item, colorScheme)),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Order Summary', colorScheme),
                    const SizedBox(height: 8),
                    _buildSummary(order, colorScheme),
                    if (order.shipments.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Delivery Status', colorScheme),
                      const SizedBox(height: 8),
                      ...order.shipments.map((s) => _buildShipmentInfo(s, colorScheme)),
                    ],
                    if (_escrowStatus != null) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Escrow & Payment', colorScheme),
                      const SizedBox(height: 8),
                      _buildEscrowInfo(_escrowStatus!, colorScheme),
                    ],
                    if (order.statusHistory.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Status History', colorScheme),
                      const SizedBox(height: 8),
                      ...order.statusHistory.map((h) => _buildHistoryRow(h, colorScheme)),
                    ],
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Notes', colorScheme),
                      const SizedBox(height: 8),
                      Text(order.notes!,
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.push(AppConstants.invoiceRoute, extra: {'order': order}),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View Invoice', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppConstants.orderTrackingRoute, extra: {'order': order}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Track Order', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (canApproveReceipt) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, height: 48,
                        child: ElevatedButton(
                          onPressed: _isApprovingReceipt ? null : _approveReceipt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isApprovingReceipt
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Confirm Receipt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
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

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
  }

  Widget _buildItemRow(OrderItemModel item, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('Qty: ${item.quantity} × ${item.formattedPrice}',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
          Text(item.formattedTotal,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(OrderModel order, ColorScheme cs) {
    return Column(
      children: [
        _summaryRow('Subtotal', order.formattedSubtotal, cs),
        if (order.discountAmount > 0) ...[
          const SizedBox(height: 8),
          _summaryRow('Discount', '- ${_formatPrice(order.discountAmount, order.currency)}', cs,
              valueColor: cs.primary),
        ],
        if (order.shippingAmount > 0) ...[
          const SizedBox(height: 8),
          _summaryRow('Shipping', _formatPrice(order.shippingAmount, order.currency), cs),
        ],
        if (order.taxAmount > 0) ...[
          const SizedBox(height: 8),
          _summaryRow('Tax', _formatPrice(order.taxAmount, order.currency), cs),
        ],
        const SizedBox(height: 12),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text(order.formattedTotal,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryRow(OrderStatusHistoryModel history, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(history.status.toUpperCase(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                if (history.notes != null)
                  Text(history.notes!,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
              ],
            ),
          ),
          if (history.createdAt != null)
            Text(_formatDate(history.createdAt!),
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme cs, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? cs.onSurface,
            )),
      ],
    );
  }

  Widget _buildEscrowInfo(Map<String, dynamic> escrow, ColorScheme cs) {
    final escrowStatus = escrow['escrow_status'] as String? ?? 'pending';
    final receiptApproved = escrow['receipt_approved'] as bool? ?? false;
    final fundsReleased = escrow['funds_released'] as bool? ?? false;
    final sellerPayoutStatus = escrow['seller_payout_status'] as String?;

    Color escrowColor;
    switch (escrowStatus.toLowerCase()) {
      case 'released':
      case 'completed':
        escrowColor = const Color(0xFF22C55E);
        break;
      case 'held':
      case 'funds_held':
        escrowColor = const Color(0xFF3B82F6);
        break;
      case 'refunded':
        escrowColor = const Color(0xFFE53935);
        break;
      default:
        escrowColor = const Color(0xFFF59E0B);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Escrow: ${escrowStatus.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: escrowColor),
        ),
        const SizedBox(height: 4),
        Text('Your payment is protected',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 12),
        _summaryRow('Receipt Confirmed', receiptApproved ? 'Yes' : 'No', cs,
            valueColor: receiptApproved ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)),
        const SizedBox(height: 8),
        _summaryRow('Funds Released', fundsReleased ? 'Yes' : 'No', cs,
            valueColor: fundsReleased ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)),
        if (sellerPayoutStatus != null) ...[
          const SizedBox(height: 8),
          _summaryRow('Seller Payout', sellerPayoutStatus.toUpperCase(), cs),
        ],
        if (!receiptApproved && order.status.toLowerCase() == 'delivered') ...[
          const SizedBox(height: 12),
          Text('Confirm receipt to release funds to the seller and complete the transaction.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ],
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

  String _formatPrice(double amount, String currency) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  Widget _buildShipmentInfo(ShipmentModel shipment, ColorScheme cs) {
    final color = _statusColor(shipment.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shipment.status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
          if (shipment.carrierName != null) ...[
            const SizedBox(height: 2),
            Text('Carrier: ${shipment.carrierName}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ],
          if (shipment.trackingNumber != null) ...[
            const SizedBox(height: 4),
            Text('Tracking: ${shipment.trackingNumber}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
            ),
          ],
          if (shipment.estimatedDeliveryFrom != null || shipment.estimatedDeliveryTo != null) ...[
            const SizedBox(height: 4),
            Text('Est. delivery: ${order.estimatedDeliveryRange ?? ''}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
          if (shipment.trackingEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Tracking History',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            ...shipment.trackingEvents.map((e) => _buildTrackingEvent(e, cs)),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingEvent(ShipmentTrackingEventModel event, ColorScheme cs) {
    final color = _statusColor(event.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (event.createdAt != null)
                Container(
                  width: 2, height: 24,
                  color: cs.onSurface.withValues(alpha: 0.1),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                if (event.location != null && event.location!.isNotEmpty)
                  Text(event.location!,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                if (event.notes != null && event.notes!.isNotEmpty)
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
}
