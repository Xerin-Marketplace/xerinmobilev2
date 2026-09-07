import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../cubit/delivery_verification_cubit.dart';
import '../cubit/delivery_verification_state.dart';
import '../../data/models/order_model.dart';
import '../../data/models/delivery_proof_model.dart';

class DeliveryProtectionPage extends StatefulWidget {
  const DeliveryProtectionPage({super.key});

  @override
  State<DeliveryProtectionPage> createState() => _DeliveryProtectionPageState();
}

class _DeliveryProtectionPageState extends State<DeliveryProtectionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().loadAll();
      context.read<DeliveryVerificationCubit>().loadProofs();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery & Protection'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Confirm Delivery'),
            Tab(text: 'Pickup Confirmations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ConfirmDeliveryTab(),
          _PickupConfirmationsTab(),
        ],
      ),
    );
  }
}

// =====================
// HELPERS
// =====================

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'delivered':
    case 'completed':
    case 'verified':
    case 'approved':
      return const Color(0xFF22C55E);
    case 'shipped':
    case 'dispatched':
      return const Color(0xFF8B5CF6);
    case 'disputed':
    case 'cancelled':
    case 'failed':
      return const Color(0xFFE53935);
    case 'pending':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF9CA3AF);
  }
}

String _fmtDate(String iso) {
  if (iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso);
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}, $h:$m';
  } catch (_) {
    return iso;
  }
}

String _fmtDateShort(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso);
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return iso;
  }
}

String _humanize(String s) =>
    s.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

Widget _emptyState(ColorScheme cs, IconData icon, String title, String subtitle) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

// =====================
// TAB 1: Confirm Delivery
// =====================

class _ConfirmDeliveryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        final orders = state is CustomerLoaded ? state.orders : <OrderModel>[];
        final deliverable = orders.where((o) {
          final s = o.status.toLowerCase();
          return s == 'delivered' || s == 'shipped' || s == 'completed';
        }).toList();
        final pendingConfirm = deliverable.where((o) =>
            o.status.toLowerCase() == 'delivered' || o.status.toLowerCase() == 'completed').length;

        if (orders.isEmpty) {
          return _emptyState(cs, Icons.local_shipping_outlined,
            'No orders yet', 'Your delivered orders will appear here for confirmation.');
        }

        return RefreshIndicator(
          onRefresh: () => context.read<CustomerCubit>().loadAll(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$pendingConfirm',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF22C55E)),
                            ),
                            Text('Pending confirmation',
                              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${deliverable.length}',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.primary),
                            ),
                            Text('In delivery',
                              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Confirm receipt to release seller payment.',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 12),

              if (deliverable.isEmpty)
                _emptyState(cs, Icons.check_circle_outline,
                  'No deliveries pending', 'Orders will appear here once they reach delivery stage.')
              else
                ...deliverable.map((o) => _DeliveryConfirmCard(order: o)),
            ],
          ),
        );
      },
    );
  }
}

class _DeliveryConfirmCard extends StatefulWidget {
  final OrderModel order;

  const _DeliveryConfirmCard({required this.order});

  @override
  State<_DeliveryConfirmCard> createState() => _DeliveryConfirmCardState();
}

class _DeliveryConfirmCardState extends State<_DeliveryConfirmCard> {
  bool _approving = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final o = widget.order;
    final color = _statusColor(o.status);
    final isDelivered = o.status.toLowerCase() == 'delivered' || o.status.toLowerCase() == 'completed';
    final shipment = o.primaryShipment;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppConstants.orderTrackingRoute, extra: {'order': o}),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(isDelivered ? Icons.check_circle_outline : Icons.local_shipping_outlined, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ${o.orderRef}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text('${_fmtDateShort(o.createdAt)} · ${o.displayStatus}',
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(o.displayStatus,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                    ),
                  ),
                ],
              ),

              // Items preview
              if (o.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.items.map((i) => i.productName).take(2).join(', '),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            if (o.items.length > 1)
                              Text('+${o.items.length - 1} more item${o.items.length - 1 > 1 ? 's' : ''}',
                                style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3)),
                              ),
                          ],
                        ),
                      ),
                      Text('${o.itemCount} items',
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
              ],

              // Shipment info
              if (shipment != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(shipment.carrierName ?? 'Xerin Express',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                    if (shipment.trackingNumber != null)
                      Text('#${shipment.trackingNumber}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
                      ),
                  ],
                ),
              ],

              // ETA
              if (o.estimatedDeliveryRange != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(width: 6),
                    Text('ETA: ${o.estimatedDeliveryRange}',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ],

              // Total
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                  Text(o.formattedTotal,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                ],
              ),

              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppConstants.orderTrackingRoute, extra: {'order': o}),
                      icon: const Icon(Icons.location_on_outlined, size: 16),
                      label: const Text('Track', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _approving ? null : () async {
                        setState(() => _approving = true);
                        final success = await context.read<CustomerCubit>().approveReceipt(o.id);
                        if (context.mounted) {
                          setState(() => _approving = false);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Receipt confirmed! Seller payment released.'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            context.read<CustomerCubit>().loadAll();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to confirm receipt. Try again.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      icon: _approving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(_approving ? 'Confirming...' : 'Confirm Receipt', style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================
// TAB 2: Pickup Confirmations
// =====================

class _PickupConfirmationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<DeliveryVerificationCubit, DeliveryVerificationState>(
      builder: (context, state) {
        if (state is DeliveryVerificationLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DeliveryVerificationError) {
          return _emptyState(cs, Icons.error_outline, 'Something went wrong', state.message);
        }
        if (state is DeliveryVerificationLoaded) {
          if (state.proofs.isEmpty) {
            return _emptyState(cs, Icons.mark_email_read_outlined,
              'No pickup confirmations', 'Delivery proofs from logistics will appear here.');
          }

          final verified = state.proofs.where((p) =>
              p.status.toLowerCase() == 'verified' || p.status.toLowerCase() == 'approved').length;
          final pending = state.proofs.where((p) => p.status.toLowerCase() == 'pending').length;
          final disputed = state.proofs.where((p) => p.status.toLowerCase() == 'disputed').length;

          return RefreshIndicator(
            onRefresh: () => context.read<DeliveryVerificationCubit>().loadProofs(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(child: _summaryStat('$verified', 'Verified', const Color(0xFF22C55E), cs)),
                        Expanded(child: _summaryStat('$pending', 'Pending', const Color(0xFFF59E0B), cs)),
                        Expanded(child: _summaryStat('$disputed', 'Disputed', const Color(0xFFE53935), cs)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Delivery proofs submitted by logistics team.',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 12),

                ...state.proofs.map((p) => _ProofCard(proof: p)),
              ],
            ),
          );
        }
        return _emptyState(cs, Icons.mark_email_read_outlined,
          'No pickup confirmations', 'Delivery proofs from logistics will appear here.');
      },
    );
  }

  Widget _summaryStat(String count, String label, Color color, ColorScheme cs) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }
}

class _ProofCard extends StatelessWidget {
  final DeliveryProofModel proof;

  const _ProofCard({required this.proof});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(proof.status);
    final isDisputed = proof.status.toLowerCase() == 'disputed';
    final isVerified = proof.status.toLowerCase() == 'verified' || proof.status.toLowerCase() == 'approved';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                    isVerified ? Icons.verified_outlined : (isDisputed ? Icons.report_problem_outlined : Icons.mark_email_read_outlined),
                    size: 20, color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Proof #${proof.id.substring(0, 8)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      if (proof.createdAt.isNotEmpty)
                        Text(_fmtDate(proof.createdAt),
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(_humanize(proof.status),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  ),
                ),
              ],
            ),

            // Recipient info
            if (proof.recipientName.isNotEmpty) ...[
              const SizedBox(height: 12),
              _infoRow(cs, Icons.person_outline, 'Recipient', proof.recipientName),
            ],

            // Phone last 4
            if (proof.recipientPhoneLast4 != null && proof.recipientPhoneLast4!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(cs, Icons.phone_outlined, 'Phone', '****${proof.recipientPhoneLast4}'),
            ],

            // Distance
            if (proof.distanceFromDestinationMeters != '0' && proof.distanceFromDestinationMeters.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(cs, Icons.straighten_outlined, 'Distance', '${proof.distanceFromDestinationMeters}m from destination'),
            ],

            // Settlement status
            if (proof.settlementStatus.isNotEmpty && proof.settlementStatus != 'pending') ...[
              const SizedBox(height: 6),
              _infoRow(cs, Icons.account_balance_wallet_outlined, 'Settlement', _humanize(proof.settlementStatus)),
            ],

            // Notes
            if (proof.notes != null && proof.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(proof.notes!,
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ],

            // Dispute info
            if (isDisputed && proof.disputeReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dispute reason: ${proof.disputeReason}',
                      style: TextStyle(fontSize: 12, color: const Color(0xFFE53935)),
                    ),
                    if (proof.disputeNotes != null && proof.disputeNotes!.isNotEmpty)
                      Text(proof.disputeNotes!,
                        style: TextStyle(fontSize: 11, color: const Color(0xFFE53935).withValues(alpha: 0.7)),
                      ),
                  ],
                ),
              ),
            ],

            // Verified at
            if (isVerified && proof.verifiedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: const Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  Text('Verified ${_fmtDate(proof.verifiedAt!)}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E)),
                  ),
                ],
              ),
            ],

            // Events timeline
            if (proof.events.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Timeline',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 6),
              ...proof.events.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF9CA3AF), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_humanize(e.eventType),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface),
                          ),
                          if (e.description != null && e.description!.isNotEmpty)
                            Text(e.description!,
                              style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
                            ),
                          if (e.createdAt.isNotEmpty)
                            Text(_fmtDate(e.createdAt),
                              style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<CustomerCubit>().getOrderById(proof.orderId).then((order) {
                        if (order != null && context.mounted) {
                          context.push(AppConstants.orderTrackingRoute, extra: {'order': order});
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not load order'), duration: Duration(seconds: 2)),
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: const Text('View Order', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (!isDisputed && !isVerified) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDisputeDialog(context, proof.id),
                      icon: Icon(Icons.report_problem_outlined, size: 16, color: cs.error),
                      label: Text('Dispute', style: TextStyle(fontSize: 12, color: cs.error)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ColorScheme cs, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
        const SizedBox(width: 6),
        Text('$label: ',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
        ),
        Expanded(
          child: Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showDisputeDialog(BuildContext context, String proofId) {
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispute Delivery Proof', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tell us what went wrong with this delivery confirmation.',
              style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                hintText: 'e.g. Package not received',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Additional details',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<DeliveryVerificationCubit>().disputeProof(
                proofId,
                reasonCtrl.text.trim(),
                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              );
            },
            child: const Text('Submit Dispute'),
          ),
        ],
      ),
    );
  }
}
