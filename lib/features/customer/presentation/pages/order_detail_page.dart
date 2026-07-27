import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../data/models/order_model.dart';

class OrderDetailPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'processing':
      case 'confirmed':
        return Icons.pending_actions_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'cancelled':
      case 'failed':
        return Icons.cancel_rounded;
      case 'pending':
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(order.status);

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
                    child: Text(
                      'Order ${order.orderNumber}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _statusIcon(order.status),
                            color: statusColor,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            order.displayStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          if (order.createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Placed on ${_formatDate(order.createdAt!)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Items', colorScheme),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => _buildItemCard(item, colorScheme, isDark)),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Order Summary', colorScheme),
                    const SizedBox(height: 12),
                    _buildSummaryCard(order, colorScheme, isDark),
                    if (order.statusHistory.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Status History', colorScheme),
                      const SizedBox(height: 12),
                      ...order.statusHistory.map((h) => _buildHistoryItem(h, colorScheme, isDark)),
                    ],
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Notes', colorScheme),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252525) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
                        ),
                        child: Text(
                          order.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(
                          AppConstants.orderTrackingRoute,
                          extra: {'order': order},
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.local_shipping_rounded, size: 20),
                        label: const Text('Track Order',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
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

  Widget _buildItemCard(OrderItemModel item, ColorScheme cs, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.productImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2_outlined,
                        color: cs.primary.withValues(alpha: 0.4),
                        size: 22,
                      ),
                    ),
                  )
                : Icon(Icons.inventory_2_outlined, color: cs.primary.withValues(alpha: 0.4), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.quantity} × ${item.formattedPrice}',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
          Text(
            item.formattedTotal,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(OrderModel order, ColorScheme cs, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
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
              Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
              Text(order.formattedTotal,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(OrderStatusHistoryModel history, ColorScheme cs, bool isDark) {
    final color = _statusColor(history.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.status.toUpperCase(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                if (history.notes != null)
                  Text(
                    history.notes!,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
              ],
            ),
          ),
          if (history.createdAt != null)
            Text(
              _formatDate(history.createdAt!),
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
}
