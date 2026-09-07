import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../cubit/customer_cubit.dart';
import '../../data/models/payment_model.dart';

class MyPaymentsPage extends StatefulWidget {
  const MyPaymentsPage({super.key});

  @override
  State<MyPaymentsPage> createState() => _MyPaymentsPageState();
}

class _MyPaymentsPageState extends State<MyPaymentsPage> {
  List<PaymentModel> _payments = [];
  bool _loading = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final _searchCtrl = TextEditingController();
  final _filters = ['All', 'Completed', 'Pending', 'Failed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _loading = true);
    final payments = await context.read<CustomerCubit>().getMyPayments(pageSize: 100);
    if (mounted) {
      setState(() {
        _payments = payments;
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF22C55E);
      case 'pending':
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFE53935);
      case 'cancelled':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '${d.day}/${d.month}/${d.year}, $h:$m';
    } catch (_) {
      return iso;
    }
  }

  String _humanize(String s) =>
      s.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

  List<PaymentModel> get _filtered {
    var result = _payments;
    if (_selectedFilter != 'All') {
      result = result.where((p) => p.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        if (p.providerTransactionId?.toLowerCase().contains(q) == true) return true;
        if (p.orderId.toLowerCase().contains(q)) return true;
        if (p.id.toLowerCase().contains(q)) return true;
        if (p.status.toLowerCase().contains(q)) return true;
        return false;
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = _payments.where((p) => p.status.toLowerCase() == 'completed').length;
    final needsAttention = _payments.where((p) {
      final s = p.status.toLowerCase();
      return s == 'failed' || s == 'cancelled' || s == 'pending';
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payments'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPayments,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subtitle
          Text('Review buyer payment activity and receipts.',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(child: _statCard('Visible records', '${_payments.length}', cs)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Completed', '$completed', cs, color: const Color(0xFF22C55E))),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Needs attention', '$needsAttention', cs, color: const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 16),

          // Search + filter
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search payment or order...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((f) {
                final isSelected = f == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(f, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Payment count
          Text('${_filtered.length} payment records',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 8),

          // Payment list
          if (_loading && _payments.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_filtered.isEmpty)
            _buildEmpty(cs)
          else
            ..._filtered.map((p) => _buildPaymentCard(p, cs)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, ColorScheme cs, {Color? color}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color ?? cs.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment, ColorScheme cs) {
    final color = _statusColor(payment.status);
    final isCompleted = payment.status.toLowerCase() == 'completed';
    final ref = payment.providerTransactionId ?? payment.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(payment.formattedAmount,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(payment.status,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reference
            Text('Reference: $ref',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 4),

            // Created date
            Text('Created ${_formatDate(payment.createdAt)}',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
            ),

            // Method + provider
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_android, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(_humanize(payment.method),
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 12),
                if (payment.provider != null) ...[
                  Icon(Icons.account_balance_wallet_outlined, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(width: 4),
                  Text(payment.provider!,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ],
            ),

            // Failure reason
            if (payment.failureReason != null && payment.failureReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Payment issue: ${payment.failureReason}',
                        style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Paid date
            if (isCompleted && payment.paidAt != null) ...[
              const SizedBox(height: 6),
              Text('Paid ${_formatDate(payment.paidAt)}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E)),
              ),
            ],

            if (!isCompleted) ...[
              const SizedBox(height: 6),
              Text('Not marked paid',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)),
              ),
            ],

            // Actions
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewOrder(payment, cs),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('View Order', style: TextStyle(fontSize: 12)),
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _reviewPayment(payment),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Review', style: TextStyle(fontSize: 12)),
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

  void _viewOrder(PaymentModel payment, ColorScheme cs) async {
    final cubit = context.read<CustomerCubit>();
    final order = await cubit.getOrderById(payment.orderId);
    if (mounted && order != null) {
      context.push(AppConstants.orderDetailRoute, extra: {'order': order});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load order'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _reviewPayment(PaymentModel payment) {
    context.push(AppConstants.paymentProcessingRoute, extra: {'paymentId': payment.id});
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.receipt_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('No payments found', style: TextStyle(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}
