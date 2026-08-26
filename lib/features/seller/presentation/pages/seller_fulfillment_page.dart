import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/pickup_location_model.dart';
import '../../presentation/cubit/seller_cubit.dart';

class SellerFulfillmentPage extends StatefulWidget {
  const SellerFulfillmentPage({super.key});

  @override
  State<SellerFulfillmentPage> createState() => _SellerFulfillmentPageState();
}

class _SellerFulfillmentPageState extends State<SellerFulfillmentPage> {
  String? _statusFilter;

  static const _statusOptions = [
    {'value': null, 'label': 'All'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'pickup_scheduled', 'label': 'Pickup Scheduled'},
    {'value': 'picked_up', 'label': 'Picked Up'},
    {'value': 'in_transit', 'label': 'In Transit'},
    {'value': 'delivered', 'label': 'Delivered'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadFulfillments();
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
        title: const Text('Fulfillment'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryBar(cs),
            _buildFilterChips(cs),
            Expanded(
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
                  if (state is SellerFulfillmentsLoaded) {
                    if (state.fulfillments.isEmpty) {
                      return _buildEmpty(cs);
                    }
                    return RefreshIndicator(
                      onRefresh: () => context
                          .read<SellerCubit>()
                          .loadFulfillments(status: _statusFilter),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.fulfillments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _FulfillmentCard(
                          fulfillment: state.fulfillments[index],
                          onTap: () => context.push(
                            '/seller-fulfillment-detail',
                            extra: {
                              'sellerOrderId':
                                  state.fulfillments[index].sellerOrderId,
                            },
                          ),
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

  Widget _buildSummaryBar(ColorScheme cs) {
    return BlocBuilder<SellerCubit, SellerState>(
      builder: (context, state) {
        if (state is SellerFulfillmentsLoaded && state.summary != null) {
          final s = state.summary!;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.03),
              border: Border(
                bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                _summaryItem(cs, 'Pending', s['pending']?.toString() ?? '0'),
                _summaryItem(cs, 'In Transit', s['in_transit']?.toString() ?? '0'),
                _summaryItem(cs, 'Delivered', s['delivered']?.toString() ?? '0'),
                _summaryItem(cs, 'Cancelled', s['cancelled']?.toString() ?? '0'),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _summaryItem(ColorScheme cs, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
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
                  context.read<SellerCubit>().loadFulfillments(status: value);
                },
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
            Icon(Uicons.box,
                size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No Fulfillments',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Fulfillment records will appear here when orders are processed.',
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

class _FulfillmentCard extends StatelessWidget {
  final SellerFulfillmentModel fulfillment;
  final VoidCallback onTap;

  const _FulfillmentCard({required this.fulfillment, required this.onTap});

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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(fulfillment.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fulfillment.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(fulfillment.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (fulfillment.trackingNumber != null)
                    Text(
                      fulfillment.trackingNumber!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (fulfillment.pickupLocationLabel != null) ...[
                Row(
                  children: [
                    Icon(Uicons.mapMarker,
                        size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fulfillment.pickupLocationLabel!,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (fulfillment.pickupAddress != null)
                Text(
                  fulfillment.pickupAddress!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Uicons.clock,
                      size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(fulfillment.createdAt),
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                  if (fulfillment.carrier != null) ...[
                    const Spacer(),
                    Text(
                      fulfillment.carrier!,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
