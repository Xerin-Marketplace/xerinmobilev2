import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/logistics_models.dart';
import '../../presentation/cubit/logistics_cubit.dart';
import '../../presentation/cubit/logistics_state.dart';

class LogisticsShipmentsPage extends StatefulWidget {
  const LogisticsShipmentsPage({super.key});

  @override
  State<LogisticsShipmentsPage> createState() =>
      _LogisticsShipmentsPageState();
}

class _LogisticsShipmentsPageState extends State<LogisticsShipmentsPage> {
  String? _statusFilter;

  static const _statusOptions = [
    {'value': null, 'label': 'All'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'assigned', 'label': 'Assigned'},
    {'value': 'picked_up', 'label': 'Picked Up'},
    {'value': 'in_transit', 'label': 'In Transit'},
    {'value': 'delivered', 'label': 'Delivered'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<LogisticsCubit>().loadShipments();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Shipments'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterChips(cs),
            Expanded(
              child: BlocConsumer<LogisticsCubit, LogisticsState>(
                listener: (context, state) {
                  if (state is LogisticsError) {
                    NotificationService().error(state.message);
                  }
                  if (state is LogisticsActionSuccess) {
                    NotificationService().success(state.message);
                  }
                },
                builder: (context, state) {
                  if (state is LogisticsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is LogisticsShipmentsLoaded) {
                    if (state.shipments.isEmpty) {
                      return _buildEmpty(cs);
                    }
                    return RefreshIndicator(
                      onRefresh: () => context
                          .read<LogisticsCubit>()
                          .loadShipments(status: _statusFilter),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.shipments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _ShipmentCard(
                          shipment: state.shipments[index],
                        ),
                      ),
                    );
                  }
                  return _buildEmpty(cs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((opt) {
            final value = opt['value'];
            final isSelected = _statusFilter == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(opt['label']!),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _statusFilter = value);
                  context
                      .read<LogisticsCubit>()
                      .loadShipments(status: value);
                },
                selectedColor: cs.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.truckBox,
                size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No Shipments',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Shipments assigned to your company will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final LogisticsShipmentModel shipment;

  const _ShipmentCard({required this.shipment});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'in_transit':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(shipment.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    shipment.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(shipment.status),
                    ),
                  ),
                ),
                const Spacer(),
                if (shipment.trackingNumber != null)
                  Text(
                    '#${shipment.trackingNumber}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (shipment.customerName != null)
              _row(cs, Uicons.user, 'Customer', shipment.customerName!),
            if (shipment.sellerName != null) ...[
              const SizedBox(height: 6),
              _row(cs, Uicons.storeAlt, 'Seller', shipment.sellerName!),
            ],
            if (shipment.pickupAddress != null) ...[
              const SizedBox(height: 6),
              _row(cs, Uicons.mapMarker, 'Pickup', shipment.pickupAddress!),
            ],
            if (shipment.deliveryAddress != null) ...[
              const SizedBox(height: 6),
              _row(cs, Uicons.mapPin, 'Delivery', shipment.deliveryAddress!),
            ],
            if (shipment.status == 'assigned' ||
                shipment.status == 'pending') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => context
                      .read<LogisticsCubit>()
                      .arrivedForPickup(shipment.id),
                  icon: const Icon(Uicons.check, size: 16),
                  label: const Text('Arrived for Pickup'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(
      ColorScheme cs, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
