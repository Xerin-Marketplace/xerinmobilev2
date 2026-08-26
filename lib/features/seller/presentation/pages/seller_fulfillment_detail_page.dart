import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/pickup_location_model.dart';
import '../../presentation/cubit/seller_cubit.dart';

class SellerFulfillmentDetailPage extends StatefulWidget {
  final String sellerOrderId;

  const SellerFulfillmentDetailPage({super.key, required this.sellerOrderId});

  @override
  State<SellerFulfillmentDetailPage> createState() =>
      _SellerFulfillmentDetailPageState();
}

class _SellerFulfillmentDetailPageState
    extends State<SellerFulfillmentDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadFulfillmentDetail(widget.sellerOrderId);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'pickup_scheduled':
        return Colors.blue;
      case 'picked_up':
        return Colors.indigo;
      case 'in_transit':
        return Colors.purple;
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Fulfillment Details'),
      ),
      body: SafeArea(
        child: BlocConsumer<SellerCubit, SellerState>(
          listener: (context, state) {
            if (state is SellerError) {
              NotificationService().error(state.message);
            }
          },
          builder: (context, state) {
            if (state is SellerLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SellerFulfillmentDetailLoaded) {
              final f = state.fulfillment;
              final tracking = state.tracking;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(f, cs),
                    const SizedBox(height: 16),
                    _buildInfoSection(f, cs),
                    const SizedBox(height: 16),
                    if (f.pickupInstructions != null) ...[
                      _buildSection(cs, 'Pickup Instructions',
                          f.pickupInstructions!),
                      const SizedBox(height: 16),
                    ],
                    _buildTrackingTimeline(tracking, cs),
                  ],
                ),
              );
            }
            return const Center(child: Text('Loading...'));
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(SellerFulfillmentModel f, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusColor(f.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            _statusIcon(f.status),
            size: 48,
            color: _statusColor(f.status),
          ),
          const SizedBox(height: 12),
          Text(
            f.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _statusColor(f.status),
            ),
          ),
          if (f.trackingNumber != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tracking: ${f.trackingNumber}',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Uicons.clock;
      case 'pickup_scheduled':
        return Uicons.mapMarker;
      case 'picked_up':
        return Uicons.box;
      case 'in_transit':
        return Uicons.truckBox;
      case 'delivered':
        return Uicons.checkCircle;
      case 'cancelled':
        return Uicons.circleXmark;
      default:
        return Uicons.box;
    }
  }

  Widget _buildInfoSection(SellerFulfillmentModel f, ColorScheme cs) {
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
            Text(
              'Pickup Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (f.pickupLocationLabel != null)
              _infoRow(cs, Uicons.mapMarker, 'Location', f.pickupLocationLabel!),
            if (f.pickupAddress != null)
              _infoRow(cs, Uicons.mapPin, 'Address', f.pickupAddress!),
            if (f.pickupContactName != null)
              _infoRow(cs, Uicons.user, 'Contact', f.pickupContactName!),
            if (f.pickupPhone != null)
              _infoRow(cs, Uicons.phone, 'Phone', f.pickupPhone!),
            if (f.carrier != null)
              _infoRow(cs, Uicons.truckBox, 'Carrier', f.carrier!),
            if (f.estimatedPickupAt != null)
              _infoRow(cs, Uicons.clock, 'Est. Pickup', _formatDateTime(f.estimatedPickupAt!)),
            if (f.pickedUpAt != null)
              _infoRow(cs, Uicons.box, 'Picked Up', _formatDateTime(f.pickedUpAt!)),
            if (f.dispatchedAt != null)
              _infoRow(cs, Uicons.truckBox, 'Dispatched', _formatDateTime(f.dispatchedAt!)),
            if (f.deliveredAt != null)
              _infoRow(cs, Uicons.checkCircle, 'Delivered', _formatDateTime(f.deliveredAt!)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ColorScheme cs, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
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
      ),
    );
  }

  Widget _buildSection(ColorScheme cs, String title, String content) {
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
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline(
      List<FulfillmentTrackingEvent> events, ColorScheme cs) {
    if (events.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No tracking events yet',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      );
    }

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
            Text(
              'Tracking History',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...events.asMap().entries.map((entry) {
              final i = entry.key;
              final event = entry.value;
              final isLast = i == events.length - 1;
              return _TimelineItem(
                event: event,
                isLast: isLast,
                color: _statusColor(event.status),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final FulfillmentTrackingEvent event;
  final bool isLast;
  final Color color;

  const _TimelineItem({
    required this.event,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: cs.onSurface.withValues(alpha: 0.1),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (event.description != null)
                  Text(
                    event.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                if (event.location != null)
                  Text(
                    event.location!,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                Text(
                  _formatDateTime(event.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
