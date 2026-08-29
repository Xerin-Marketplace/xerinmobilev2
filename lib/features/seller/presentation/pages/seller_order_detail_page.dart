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

  void _showSideDrawer({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    Color confirmColor = Colors.green,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        barrierColor: Colors.black54,
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _SideActionDrawer(
          title: title,
          icon: icon,
          children: children,
          onConfirm: onConfirm,
          confirmLabel: confirmLabel,
          confirmColor: confirmColor,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: BlocConsumer<SellerCubit, SellerState>(
        listener: (context, state) {
          if (state is SellerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
          if (state is SellerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green),
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
                  const Icon(Uicons.circleExclamation,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<SellerCubit>()
                        .loadOrderDetail(widget.orderId),
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
        if (order.shipment != null) ...[
          _buildShipmentTracking(context, order.shipment!),
          const SizedBox(height: 16),
        ],
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
              Text('Seller Status',
                  style:
                      TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              Text(
                _formatStatus(order.sellerStatus),
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Status',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(_formatOrderStatus(order.orderStatus), style: const TextStyle(fontSize: 13)),
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
              child: Text('Cancellation reason: ${order.cancellationReason}',
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, SellerOrderModel order) {
    return _buildSection(context, 'Customer', [
      _buildRow('Name', order.customerName),
      if (order.customerPhone != null)
        _buildRow('Phone', order.customerPhone!),
      _buildRow('Items', '${order.itemCount}'),
      _buildRow('Total', _formatMoney(order.sellerSubtotal, order.currency)),
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
                  Text(item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (item.variantName != null)
                    Text(item.variantName!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  Text(
                      'Qty: ${item.quantity} x ${_formatMoney(item.unitPrice, order.currency)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text(_formatMoney(item.totalPrice, order.currency),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }).toList());
  }

  Widget _buildShippingInfo(BuildContext context, SellerOrderModel order) {
    return _buildSection(context, 'Shipping', [
      if (order.shippingMethodName != null)
        _buildRow('Method', order.shippingMethodName!),
      if (order.shippingCarrier != null)
        _buildRow('Carrier', order.shippingCarrier!),
      if (order.estimatedDeliveryFrom != null)
        _buildRow('From', _formatDate(order.estimatedDeliveryFrom!)),
      if (order.estimatedDeliveryTo != null)
        _buildRow('To', _formatDate(order.estimatedDeliveryTo!)),
      if (order.shippingAddress != null) ...[
        const SizedBox(height: 4),
        Text('Address:',
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
        Text(_formatAddress(order.shippingAddress!),
            style: const TextStyle(fontSize: 13)),
      ],
    ]);
  }

  Widget _buildShipmentTracking(
      BuildContext context, Map<String, dynamic> shipment) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final status = shipment['status']?.toString() ?? 'pending';
    final carrierName = shipment['carrier_name']?.toString();
    final trackingNumber = shipment['tracking_number']?.toString();
    final dispatchedAt = shipment['dispatched_at']?.toString();
    final deliveredAt = shipment['delivered_at']?.toString();
    final estFrom = shipment['estimated_delivery_from']?.toString();
    final estTo = shipment['estimated_delivery_to']?.toString();
    final trackingEvents = shipment['tracking_events'] as List? ?? [];

    final statusColor = _getShipmentStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Uicons.shippingFast, color: statusColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Shipment Tracking',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatShipmentStatus(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (carrierName != null)
            _buildShipmentRow(cs, Uicons.truckBox, 'Carrier', carrierName),
          if (trackingNumber != null) ...[
            const SizedBox(height: 10),
            _buildShipmentRow(
                cs, Uicons.hashtag, 'Tracking Number', trackingNumber),
          ],
          if (dispatchedAt != null) ...[
            const SizedBox(height: 10),
            _buildShipmentRow(
                cs, Uicons.shippingFast, 'Dispatched', _formatDate(dispatchedAt)),
          ],
          if (deliveredAt != null) ...[
            const SizedBox(height: 10),
            _buildShipmentRow(
                cs, Uicons.checkCircle, 'Delivered', _formatDate(deliveredAt)),
          ],
          if (estFrom != null || estTo != null) ...[
            const SizedBox(height: 10),
            _buildShipmentRow(cs, Uicons.clock, 'Est. Delivery',
                _formatDateRange(estFrom, estTo)),
          ],
          if (trackingEvents.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Tracking History',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            ...trackingEvents.asMap().entries.map((entry) {
              final i = entry.key;
              final event = entry.value as Map<String, dynamic>;
              final isLast = i == trackingEvents.length - 1;
              return _buildTrackingEventItem(event, isLast, cs, statusColor);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildShipmentRow(
      ColorScheme cs, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingEventItem(
    Map<String, dynamic> event,
    bool isLast,
    ColorScheme cs,
    Color accentColor,
  ) {
    final status = event['status']?.toString() ?? '';
    final location = event['location']?.toString();
    final notes = event['notes']?.toString();
    final createdAt = event['created_at']?.toString() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: cs.onSurface.withValues(alpha: 0.1),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatShipmentStatus(status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Uicons.mapPin,
                          size: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
                if (notes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    notes,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
        onTap: () => _showNotesDrawer(context, 'Accept Order',
            Uicons.check, Colors.green, 'Accept', (notes) {
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
        onTap: () => _showNotesDrawer(context, 'Start Processing',
            Uicons.boxOpen, Colors.orange, 'Confirm', (notes) {
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
        onTap: () => _showNotesDrawer(context, 'Ready to Ship',
            Uicons.truckBox, Colors.amber.shade700, 'Confirm', (notes) {
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
        onTap: () => _showDispatchDrawer(context, order.id),
      ));
    }

    if (status != 'cancelled' &&
        status != 'delivered' &&
        status != 'shipped') {
      buttons.add(_buildActionButton(
        context,
        label: 'Request Cancellation',
        icon: Uicons.ban,
        color: Colors.red,
        onTap: () => _showCancelDrawer(context, order.id),
      ));
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Actions',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
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
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
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
    final isSeller = message.senderRoleLabel?.toLowerCase().contains('seller') ??
        false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSeller
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                message.senderRoleLabel ?? 'Unknown',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12),
              ),
              if (message.isInternal) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('Internal',
                      style: TextStyle(fontSize: 10, color: Colors.orange)),
                ),
              ],
              const Spacer(),
              Text(_formatDate(message.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(message.message),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
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
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Drawer-based action panels ───

  void _showNotesDrawer(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    String confirmLabel,
    Function(String?) onConfirm,
  ) {
    final notesController = TextEditingController();
    _showSideDrawer(
      title: title,
      icon: icon,
      confirmLabel: confirmLabel,
      confirmColor: iconColor,
      children: [
        _DrawerField(
          controller: notesController,
          label: 'Notes',
          hint: 'Add notes (optional)',
          maxLines: 4,
        ),
      ],
      onConfirm: () {
        onConfirm(notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null);
      },
    );
  }

  void _showDispatchDrawer(BuildContext context, String orderId) {
    final carrierController = TextEditingController();
    final trackingController = TextEditingController();
    final trackingUrlController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    _showSideDrawer(
      title: 'Dispatch Order',
      icon: Uicons.shippingFast,
      confirmLabel: 'Dispatch',
      confirmColor: Colors.teal,
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              _DrawerField(
                controller: carrierController,
                label: 'Carrier Name *',
                hint: 'e.g. G4S, DHL, Xerin Express',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _DrawerField(
                controller: trackingController,
                label: 'Tracking Number *',
                hint: 'Enter tracking number',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _DrawerField(
                controller: trackingUrlController,
                label: 'Tracking URL',
                hint: 'https://...',
              ),
              const SizedBox(height: 16),
              _DrawerField(
                controller: locationController,
                label: 'Dispatch Location',
                hint: 'e.g. Dar es Salaam, Tanzania',
              ),
              const SizedBox(height: 16),
              _DrawerField(
                controller: notesController,
                label: 'Notes',
                hint: 'Add notes (optional)',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
      onConfirm: () {
        if (formKey.currentState?.validate() ?? false) {
          context.read<SellerCubit>().dispatchOrder(
                orderId,
                carrierName: carrierController.text.trim(),
                trackingNumber: trackingController.text.trim(),
                trackingUrl: trackingUrlController.text.trim().isNotEmpty
                    ? trackingUrlController.text.trim()
                    : null,
                location: locationController.text.trim().isNotEmpty
                    ? locationController.text.trim()
                    : null,
                notes: notesController.text.trim().isNotEmpty
                    ? notesController.text.trim()
                    : null,
              );
        }
      },
    );
  }

  void _showCancelDrawer(BuildContext context, String orderId) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    _showSideDrawer(
      title: 'Request Cancellation',
      icon: Uicons.ban,
      confirmLabel: 'Submit',
      confirmColor: Colors.red,
      children: [
        Form(
          key: formKey,
          child: _DrawerField(
            controller: reasonController,
            label: 'Reason *',
            hint: 'Why are you cancelling this order?',
            maxLines: 4,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ),
      ],
      onConfirm: () {
        if (formKey.currentState?.validate() ?? false) {
          context
              .read<SellerCubit>()
              .cancelOrder(orderId, reason: reasonController.text.trim());
        }
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'accepted':
        return Colors.indigo;
      case 'processing':
        return Colors.orange;
      case 'ready_to_ship':
        return Colors.amber.shade700;
      case 'shipped':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancellation_requested':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'new':
        return 'New';
      case 'accepted':
        return 'Accepted';
      case 'processing':
        return 'Processing';
      case 'ready_to_ship':
        return 'Ready to Ship';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancellation_requested':
        return 'Cancellation Requested';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  String _formatOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        return status
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  String _formatShipmentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'ready_for_dispatch':
        return 'Ready for Dispatch';
      case 'dispatched':
        return 'Dispatched';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  Color _getShipmentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'dispatched':
      case 'in_transit':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.blue;
      case 'ready_for_dispatch':
        return Colors.amber.shade700;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
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
    if (f.isEmpty) return 'Until $t';
    if (t.isEmpty) return 'From $f';
    return '$f - $t';
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

// ─── Reusable side drawer for order actions ───

class _SideActionDrawer extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final Color confirmColor;

  const _SideActionDrawer({
    required this.title,
    required this.icon,
    required this.children,
    required this.onConfirm,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: cs.surface,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.5 : 0.15),
                      blurRadius: 30,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context, cs),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              ...children,
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      _buildFooter(context, cs),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: confirmColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: confirmColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Uicons.crossSmall,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: confirmColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  confirmLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _DrawerField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }
}
