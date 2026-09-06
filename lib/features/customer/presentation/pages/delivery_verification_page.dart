import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/models/delivery_proof_model.dart';
import '../../presentation/cubit/delivery_verification_cubit.dart';
import '../../presentation/cubit/delivery_verification_state.dart';

class DeliveryVerificationPage extends StatefulWidget {
  const DeliveryVerificationPage({super.key});

  @override
  State<DeliveryVerificationPage> createState() =>
      _DeliveryVerificationPageState();
}

class _DeliveryVerificationPageState extends State<DeliveryVerificationPage> {
  @override
  void initState() {
    super.initState();
    context.read<DeliveryVerificationCubit>().loadProofs();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Delivery Verification'),
      ),
      body: SafeArea(
        child: BlocConsumer<DeliveryVerificationCubit,
            DeliveryVerificationState>(
          listener: (context, state) {
            if (state is DeliveryVerificationError) {
              NotificationService().error(state.message);
            }
            if (state is DeliveryVerificationActionSuccess) {
              NotificationService().success(state.message);
            }
          },
          builder: (context, state) {
            if (state is DeliveryVerificationLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DeliveryVerificationLoaded) {
              if (state.proofs.isEmpty) {
                return _buildEmpty(cs);
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<DeliveryVerificationCubit>().loadProofs(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.proofs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _ProofCard(
                    proof: state.proofs[index],
                  ),
                ),
              );
            }
            return _buildEmpty(cs);
          },
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
            Text('No Delivery Proofs',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Delivery verification proofs will appear here when your orders are delivered.',
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

class _ProofCard extends StatelessWidget {
  final DeliveryProofModel proof;

  const _ProofCard({required this.proof});

  Color _statusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending_verification':
        return Colors.orange;
      case 'disputed':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  proof.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(proof.status),
                  ),
                ),
                const Spacer(),
                if (proof.photoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      proof.photoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: cs.onSurface.withValues(alpha: 0.06),
                        child: Icon(Icons.broken_image_outlined,
                            size: 24,
                            color: cs.onSurface.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Recipient: ${proof.recipientName}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Distance from destination: ${proof.distanceFromDestinationMeters}m',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            if (proof.verifiedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Verified: ${_formatDate(proof.verifiedAt!)}',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
            if (proof.disputedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Disputed: ${_formatDate(proof.disputedAt!)}',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
            if (proof.status == 'pending_verification' ||
                proof.status == 'verified') ...[
              const SizedBox(height: 12),
              if (proof.status == 'pending_verification')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDisputeDialog(context, proof.id),
                    icon: const Icon(Icons.error_outline, size: 16),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                    label: const Text('Dispute Delivery'),
                  ),
                ),
              if (proof.status == 'verified' && proof.disputedAt == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDisputeDialog(context, proof.id),
                    icon: const Icon(Icons.error_outline, size: 16),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                    label: const Text('Report Issue'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  void _showDisputeDialog(BuildContext context, String proofId) {
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispute Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Additional notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<DeliveryVerificationCubit>().disputeProof(
                    proofId,
                    reasonCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  );
            },
            child: const Text('Submit Dispute'),
          ),
        ],
      ),
    );
  }
}
