import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerOrderDetailPage extends StatefulWidget {
  final String orderId;

  const SellerOrderDetailPage({super.key, required this.orderId});

  @override
  State<SellerOrderDetailPage> createState() => _SellerOrderDetailPageState();
}

class _SellerOrderDetailPageState extends State<SellerOrderDetailPage> {
  final _messageController = TextEditingController();
  bool _isInternal = false;

  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadOrderDetail(widget.orderId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: BlocConsumer<SellerCubit, SellerState>(
        listener: (context, state) {
          if (state is SellerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
          if (state is SellerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          }
        },
        builder: (context, state) {
          if (state is SellerLoading || state is SellerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SellerOrderDetailLoaded) {
            return _buildContent(context, state);
          }
          if (state is SellerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SellerCubit>().loadOrderDetail(widget.orderId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, SellerOrderDetailLoaded state) {
    final order = state.order;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusCard(context, order),
        const SizedBox(height: 16),
        _buildCustomerInfo(context, order),
        const SizedBox(height: 16),
        _buildItems(context, order),
        const SizedBox(height: 16),
        _buildShippingInfo(context, order),
        const SizedBox(height: 16),
        _buildActionButtons(context, order),
        const SizedBox(height: 16),
        _buildMessages(context, state),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, SellerOrderModel order) {
    final statusColor = _getStatusColor(order.sellerStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Seller Status', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              Text(
                _formatStatus(order.sellerStatus),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Status', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(order.orderStatus, style: const TextStyle(fontSize: 13)),
            ],
          ),
          if (order.cancellationReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Cancel reason: ${order.cancellationReason}', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, SellerOrderModel order) {
    return _buildSection(context, 'Customer', [
      _buildRow('Name', order.customerName),
      if (order.customerPhone != null) _buildRow('Phone', order.customerPhone!),
      _buildRow('Items', '${order.itemCount}'),
      _buildRow('Subtotal', _formatMoney(order.sellerSubtotal, order.currency)),
    ]);
  }

  Widget _buildItems(BuildContext context, SellerOrderModel order) {
    return _buildSection(context, 'Items', order.items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (item.variantName != null)
                    Text(item.variantName!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Qty: ${item.quantity} x ${_formatMoney(item.unitPrice, order.currency)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text(_formatMoney(item.totalPrice, order.currency), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }).toList());
  }

  Widget _buildShippingInfo(BuildContext context, SellerOrderModel order) {
    return _buildSection(context, 'Shipping', [
      if (order.shippingMethodName != null) _buildRow('Method', order.shippingMethodName!),
      if (order.shippingCarrier != null) _buildRow('Carrier', order.shippingCarrier!),
      if (order.estimatedDeliveryFrom != null)
        _buildRow('ETA From', _formatDate(order.estimatedDeliveryFrom!)),
      if (order.estimatedDeliveryTo != null)
        _buildRow('ETA To', _formatDate(order.estimatedDeliveryTo!)),
      if (order.shippingAddress != null) ...[
        const SizedBox(height: 4),
        Text('Address:', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
        Text(_formatAddress(order.shippingAddress!), style: const TextStyle(fontSize: 13)),
      ],
    ]);
  }

  Widget _buildActionButtons(BuildContext context, SellerOrderModel order) {
    final status = order.sellerStatus;
    final theme = Theme.of(context);

    List<Widget> buttons = [];

    if (status == 'new') {
      buttons.add(_buildActionButton(
        context,
        label: 'Accept Order',
        icon: Uicons.check,
        color: Colors.green,
        onTap: () => _showNotesDialog(context, 'Accept Order', (notes) {
          context.read<SellerCubit>().acceptOrder(order.id, notes: notes);
        }),
      ));
    }

    if (status == 'accepted') {
      buttons.add(_buildActionButton(
        context,
        label: 'Start Processing',
        icon: Uicons.boxOpen,
        color: Colors.orange,
        onTap: () => _showNotesDialog(context, 'Start Processing', (notes) {
          context.read<SellerCubit>().startProcessing(order.id, notes: notes);
        }),
      ));
    }

    if (status == 'processing') {
      buttons.add(_buildActionButton(
        context,
        label: 'Ready to Ship',
        icon: Uicons.truckBox,
        color: Colors.amber.shade700,
        onTap: () => _showNotesDialog(context, 'Ready to Ship', (notes) {
          context.read<SellerCubit>().readyToShip(order.id, notes: notes);
        }),
      ));
    }

    if (status == 'ready_to_ship') {
      buttons.add(_buildActionButton(
        context,
        label: 'Dispatch',
        icon: Uicons.shippingFast,
        color: Colors.teal,
        onTap: () => _showDispatchDialog(context, order.id),
      ));
    }

    if (status != 'cancelled' && status != 'delivered' && status != 'shipped') {
      buttons.add(_buildActionButton(
        context,
        label: 'Request Cancellation',
        icon: Uicons.ban,
        color: Colors.red,
        onTap: () => _showCancelDialog(context, order.id),
      ));
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: buttons),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildMessages(BuildContext context, SellerOrderDetailLoaded state) {
    return _buildSection(context, 'Messages', [
      ...state.messages.map((m) => _buildMessageTile(m)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              minLines: 1,
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Uicons.paperPlane),
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                context.read<SellerCubit>().sendOrderMessage(
                      widget.orderId,
                      message: _messageController.text.trim(),
                      isInternal: _isInternal,
                    );
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    ]);
  }

  Widget _buildMessageTile(SellerOrderMessageModel message) {
    final isSeller = message.senderRoleLabel?.toLowerCase().contains('seller') ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSeller ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                message.senderRoleLabel ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              if (message.isInternal) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Internal', style: TextStyle(fontSize: 10, color: Colors.orange)),
                ),
              ],
              const Spacer(),
              Text(_formatDate(message.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(message.message),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showNotesDialog(BuildContext context, String title, Function(String?) onConfirm) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Add notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm(notesController.text.trim().isNotEmpty ? notesController.text.trim() : null);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDispatchDialog(BuildContext context, String orderId) {
    final carrierController = TextEditingController();
    final trackingController = TextEditingController();
    final trackingUrlController = TextEditingController();
    final locationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispatch Order'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: carrierController,
                  decoration: const InputDecoration(labelText: 'Carrier Name *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: trackingController,
                  decoration: const InputDecoration(labelText: 'Tracking Number *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: trackingUrlController,
                  decoration: const InputDecoration(labelText: 'Tracking URL', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                context.read<SellerCubit>().dispatchOrder(
                      orderId,
                      carrierName: carrierController.text.trim(),
                      trackingNumber: trackingController.text.trim(),
                      trackingUrl: trackingUrlController.text.trim().isNotEmpty ? trackingUrlController.text.trim() : null,
                      location: locationController.text.trim().isNotEmpty ? locationController.text.trim() : null,
                    );
              }
            },
            child: const Text('Dispatch'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Cancellation'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'Reason *', border: OutlineInputBorder()),
            maxLines: 3,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                context.read<SellerCubit>().cancelOrder(orderId, reason: reasonController.text.trim());
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new': return Colors.blue;
      case 'accepted': return Colors.indigo;
      case 'processing': return Colors.orange;
      case 'ready_to_ship': return Colors.amber.shade700;
      case 'shipped': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'cancellation_requested': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'ready_to_ship': return 'Ready to Ship';
      case 'cancellation_requested': return 'Cancellation';
      default: return status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }

  String _formatMoney(double amount, String currency) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAddress(Map<String, dynamic> addr) {
    final parts = <String>[];
    for (final key in ['street', 'city', 'region', 'country', 'phone']) {
      final val = addr[key];
      if (val != null && val.toString().isNotEmpty) parts.add(val.toString());
    }
    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }
}
