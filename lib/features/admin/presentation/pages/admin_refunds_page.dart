import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/security/admin_access.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';
import '../../data/models/admin_models.dart';

class AdminRefundsPage extends StatefulWidget {
  const AdminRefundsPage({super.key});

  @override
  State<AdminRefundsPage> createState() => _AdminRefundsPageState();
}

class _AdminRefundsPageState extends State<AdminRefundsPage> {
  String? _statusFilter;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadRefunds();
  }

  static const _statuses = [
    ('all', 'All'),
    ('requested', 'Requested'),
    ('under_review', 'Under Review'),
    ('approved', 'Approved'),
    ('rejected', 'Rejected'),
    ('processing', 'Processing'),
    ('completed', 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Management'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<AdminCubit>().loadRefunds(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statuses.map((s) {
            final isSelected = (_statusFilter ?? 'all') == s.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s.$2),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _statusFilter = s.$1 == 'all' ? null : s.$1;
                  });
                  context.read<AdminCubit>().loadRefunds(status: _statusFilter);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        }
        if (state is AdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminRefundsLoaded) {
          if (state.refunds.isEmpty) {
            return const Center(child: Text('No refunds found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.refunds.length,
            itemBuilder: (context, index) =>
                _refundCard(context, state.refunds[index]),
          );
        }
        if (state is AdminError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Uicons.triangleWarning, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<AdminCubit>().loadRefunds(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!_isReloading) {
          _isReloading = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AdminCubit>().loadRefunds(status: _statusFilter);
            _isReloading = false;
          });
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _refundCard(BuildContext context, AdminRefundModel refund) {
    final color = _statusColor(refund.status);
    final formatted = refund.amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${refund.currency} $formatted',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_humanize(refund.status),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Order: ${refund.orderId.substring(0, 8)}...',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (refund.reason != null)
              Text('Reason: ${refund.reason}', style: const TextStyle(fontSize: 12)),
            if (refund.note != null)
              Text('Note: ${refund.note}', style: const TextStyle(fontSize: 12)),
            if (refund.requestedAt != null)
              Text('Requested: ${refund.requestedAt!.substring(0, 10)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildActions(context, refund),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, AdminRefundModel refund) {
    final user = GetIt.instance<TokenStorage>().currentUser;
    final actions = <Widget>[];
    switch (refund.status) {
      case 'requested':
        if (AdminAccess.canAccessItem(user, 'refunds.review')) {
          actions.add(_actionBtn(context, 'Review', Colors.blue, () =>
              _showNoteDialog(context, 'Review Refund', (note) =>
                  context.read<AdminCubit>().reviewRefund(refund.id, note: note))));
        }
        if (AdminAccess.canAccessItem(user, 'refunds.reject')) {
          actions.add(_actionBtn(context, 'Reject', Colors.red, () =>
              _showNoteDialog(context, 'Reject Refund', (note) =>
                  context.read<AdminCubit>().rejectRefund(refund.id, note: note))));
        }
        break;
      case 'under_review':
        if (AdminAccess.canAccessItem(user, 'refunds.approve')) {
          actions.add(_actionBtn(context, 'Approve', Colors.green, () =>
              _showNoteDialog(context, 'Approve Refund', (note) =>
                  context.read<AdminCubit>().approveRefund(refund.id, note: note))));
        }
        if (AdminAccess.canAccessItem(user, 'refunds.reject')) {
          actions.add(_actionBtn(context, 'Reject', Colors.red, () =>
              _showNoteDialog(context, 'Reject Refund', (note) =>
                  context.read<AdminCubit>().rejectRefund(refund.id, note: note))));
        }
        break;
      case 'approved':
        if (AdminAccess.canAccessItem(user, 'refunds.process')) {
          actions.add(_actionBtn(context, 'Process', Colors.blue, () =>
              _showProcessDialog(context, refund.id)));
        }
        break;
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, children: actions);
  }

  Widget _actionBtn(BuildContext context, String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      onPressed: onTap,
      child: Text(label),
    );
  }

  void _showNoteDialog(BuildContext context, String title, Function(String?) onConfirm) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm(noteController.text.trim().isEmpty ? null : noteController.text.trim());
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showProcessDialog(BuildContext context, String refundId) {
    final noteController = TextEditingController();
    final refController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: refController,
              decoration: const InputDecoration(
                labelText: 'Provider Reference',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminCubit>().processRefund(refundId,
                  note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  providerReference: refController.text.trim().isEmpty ? null : refController.text.trim());
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'approved':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'under_review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _humanize(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
