import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerReturnsPage extends StatefulWidget {
  const SellerReturnsPage({super.key});

  @override
  State<SellerReturnsPage> createState() => _SellerReturnsPageState();
}

class _SellerReturnsPageState extends State<SellerReturnsPage> {
  late final SellerCubit _cubit;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _filterStatus;
  RefundModel? _processingRefund;

  static const _statuses = [
    {'label': 'All', 'value': null},
    {'label': 'Requested', 'value': 'requested'},
    {'label': 'Under Review', 'value': 'under_review'},
    {'label': 'Approved', 'value': 'approved'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Rejected', 'value': 'rejected'},
  ];

  @override
  void initState() {
    super.initState();
    _cubit = sl<SellerCubit>();
    _cubit.loadReturns();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _openProcessDrawer(RefundModel refund) {
    setState(() => _processingRefund = refund);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: cs.surface,
        endDrawer: _processingRefund != null
            ? _ProcessReturnDrawer(
                refund: _processingRefund!,
                onSubmit: ({required String action, String? note, String? providerReference}) {
                  Navigator.of(context).pop();
                  switch (action) {
                    case 'review':
                      _cubit.reviewReturn(_processingRefund!.id, note: note);
                      break;
                    case 'approve':
                      _cubit.approveReturn(_processingRefund!.id, note: note);
                      break;
                    case 'reject':
                      _cubit.rejectReturn(_processingRefund!.id, note: note);
                      break;
                    case 'process':
                      _cubit.processReturn(_processingRefund!.id,
                          providerReference: providerReference, note: note);
                      break;
                  }
                },
              )
            : null,
        drawerScrimColor: Colors.black54,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Uicons.angleLeft, size: 20),
                    ),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Uicons.rotateLeft, size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Text('Returns',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _statuses.map((s) {
                    final isSelected = _filterStatus == s['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s['label']!),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _filterStatus = s['value']);
                          _cubit.loadReturns(status: _filterStatus);
                        },
                        selectedColor: cs.primary.withValues(alpha: 0.15),
                        checkmarkColor: cs.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: BlocConsumer<SellerCubit, SellerState>(
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
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
                    }
                    if (state is SellerError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.message, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _cubit.loadReturns(status: _filterStatus),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state is SellerReturnsLoaded) {
                      if (state.refunds.isEmpty) {
                        return Center(
                          child: Text('No return requests',
                            style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.4)),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () => _cubit.loadReturns(status: _filterStatus),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: state.refunds.length,
                          itemBuilder: (context, index) => _buildRefundCard(state.refunds[index], cs),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefundCard(RefundModel refund, ColorScheme cs) {
    final statusColor = _getStatusColor(refund.status);
    final reasonLabel = _formatReason(refund.reason);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Uicons.rotateLeft, size: 18, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatMoney(refund.totalAmount, refund.currency),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(reasonLabel,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatStatus(refund.status),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (refund.reasonDetails != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(refund.reasonDetails!,
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6), height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Uicons.box, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text('${refund.items.length} item${refund.items.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                const SizedBox(width: 12),
                Icon(Uicons.clock, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(_formatDate(refund.requestedAt),
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                const Spacer(),
                if (_canAct(refund.status))
                  TextButton(
                    onPressed: () => _openProcessDrawer(refund),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(_getActionLabel(refund.status),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canAct(String status) {
    return status == 'requested' || status == 'under_review' || status == 'approved';
  }

  String _getActionLabel(String status) {
    switch (status) {
      case 'requested': return 'Review';
      case 'under_review': return 'Approve';
      case 'approved': return 'Process';
      default: return 'View';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'requested': return Colors.amber.shade700;
      case 'under_review': return Colors.blue;
      case 'approved': return Colors.teal;
      case 'processing': return Colors.orange;
      case 'rejected':
      case 'failed': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String _formatReason(String reason) {
    return reason.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
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
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _ProcessReturnDrawer extends StatefulWidget {
  final RefundModel refund;
  final void Function({required String action, String? note, String? providerReference}) onSubmit;

  const _ProcessReturnDrawer({required this.refund, required this.onSubmit});

  @override
  State<_ProcessReturnDrawer> createState() => _ProcessReturnDrawerState();
}

class _ProcessReturnDrawerState extends State<_ProcessReturnDrawer> {
  late final TextEditingController _noteController;
  late final TextEditingController _providerRefController;
  bool _isSubmitting = false;

  late String _action;
  late String _actionLabel;

  static const _actionMap = {
    'requested': {'action': 'review', 'label': 'Review Return'},
    'under_review': {'action': 'approve', 'label': 'Approve Return'},
    'approved': {'action': 'process', 'label': 'Process Refund'},
  };

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _providerRefController = TextEditingController();
    final info = _actionMap[widget.refund.status] ?? {'action': 'review', 'label': 'Review Return'};
    _action = info['action']!;
    _actionLabel = info['label']!;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _providerRefController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, String hint, ColorScheme cs, {String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    widget.onSubmit(
      action: _action,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      providerReference: _providerRefController.text.trim().isNotEmpty ? _providerRefController.text.trim() : null,
    );
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final refund = widget.refund;
    final isReject = _action == 'reject';

    return Drawer(
      width: 360,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Uicons.rotateLeft, size: 20, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(_actionLabel,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Uicons.xmark, size: 18),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Refund Amount',
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${refund.currency} ${refund.totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text('Reason: ${refund.reason.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}',
                          style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 4),
                        Text('Items: ${refund.items.length}',
                          style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_action == 'process')
                    TextFormField(
                      controller: _providerRefController,
                      decoration: _fieldDecoration(
                        'Provider Reference',
                        'e.g. MPESA-ABC123',
                        cs,
                        helper: 'Transaction reference from payment provider',
                      ),
                    ),
                  if (_action == 'process') const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: _fieldDecoration(
                      'Note',
                      'Optional',
                      cs,
                      helper: 'Add a note about this action',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (_action == 'approve') ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () {
                          setState(() {
                            _action = 'reject';
                            _actionLabel = 'Reject Return';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject Instead'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isReject)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () {
                          setState(() {
                            _action = 'approve';
                            _actionLabel = 'Approve Return';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Approve Instead'),
                      ),
                    ),
                  if (isReject) const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReject ? Colors.red : cs.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isReject ? 'Reject' : _action == 'review' ? 'Review' : _action == 'approve' ? 'Approve' : 'Process'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
