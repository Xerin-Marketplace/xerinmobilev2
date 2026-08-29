import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerWalletPage extends StatefulWidget {
  const SellerWalletPage({super.key});

  @override
  State<SellerWalletPage> createState() => _SellerWalletPageState();
}

class _SellerWalletPageState extends State<SellerWalletPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tabIndex = 0;
  List<PayoutAccountModel> _payoutAccounts = [];

  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadWallet();
  }

  void _openPayoutDrawer() {
    if (_payoutAccounts.isEmpty) return;
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: cs.surface,
      endDrawer: _PayoutRequestDrawer(
        accounts: _payoutAccounts,
        onSubmit: ({
          required String payoutAccountId,
          required double amount,
          String? note,
        }) {
          Navigator.of(context).pop();
          context.read<SellerCubit>().requestPayout(
                payoutAccountId: payoutAccountId,
                amount: amount,
                note: note,
              );
        },
      ),
      drawerScrimColor: Colors.black54,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Uicons.sackDollar, size: 20, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Wallet & Payouts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                ],
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is SellerWalletLoaded) {
                    _payoutAccounts = state.payoutAccounts;
                    return RefreshIndicator(
                      onRefresh: () => context.read<SellerCubit>().loadWallet(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        children: [
                          _buildBalanceCard(context, state.wallet),
                          if (state.earnings != null) ...[
                            const SizedBox(height: 16),
                            _buildEarningsCard(context, state.earnings!),
                          ],
                          const SizedBox(height: 16),
                          _buildRequestPayoutButton(context, state.payoutAccounts),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildTab('Transactions', 0),
                              _buildTab('Payouts', 1),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_tabIndex == 0)
                            _buildTransactions(context, state.transactions)
                          else
                            _buildPayouts(context, state.payouts),
                        ],
                      ),
                    );
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
                            onPressed: () => context.read<SellerCubit>().loadWallet(),
                            child: const Text('Retry'),
                          ),
                        ],
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
    );
  }

  Widget _buildBalanceCard(BuildContext context, SellerWalletModel wallet) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            _formatMoney(wallet.availableBalance, wallet.currency),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBalanceChip('Pending', _formatMoney(wallet.pendingBalance, wallet.currency)),
              const SizedBox(width: 12),
              _buildBalanceChip('Reserved', _formatMoney(wallet.reservedBalance, wallet.currency)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBalanceChip('Paid Out', _formatMoney(wallet.paidOutBalance, wallet.currency)),
              const SizedBox(width: 12),
              _buildBalanceChip('Refunded', _formatMoney(wallet.refundedBalance, wallet.currency)),
            ],
          ),
          if (wallet.isFrozen) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Uicons.lock, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Wallet Frozen', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceChip(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context, SellerEarningsSummaryModel earnings) {
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
          Text('Earnings Summary', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRow('Gross Sales', _formatMoney(earnings.grossSales, earnings.currency)),
          _buildRow('Commission Deducted', _formatMoney(earnings.commissionDeducted, earnings.currency)),
          _buildRow('Net Earnings', _formatMoney(earnings.netEarnings, earnings.currency)),
          _buildRow('Transactions', '${earnings.transactionCount}'),
        ],
      ),
    );
  }

  Widget _buildRequestPayoutButton(BuildContext context, List<PayoutAccountModel> accounts) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: accounts.isEmpty ? null : _openPayoutDrawer,
        icon: const Icon(Uicons.sackDollar, size: 20),
        label: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _tabIndex == index;
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : theme.hintColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactions(BuildContext context, PaginatedWalletTransactions transactions) {
    if (transactions.results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      children: transactions.results.map((tx) => _buildTransactionTile(context, tx)).toList(),
    );
  }

  Widget _buildTransactionTile(BuildContext context, SellerWalletTransactionModel tx) {
    final isCredit = tx.amount > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCredit ? Uicons.arrowTrendUp : Uicons.arrowTrendDown,
          color: isCredit ? Colors.green : Colors.red,
        ),
        title: Text(_formatTxType(tx.transactionType), style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(_formatDate(tx.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Text(
          '${isCredit ? '+' : ''}${_formatMoney(tx.amount, tx.currency)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildPayouts(BuildContext context, PaginatedSellerPayouts payouts) {
    if (payouts.results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No payout requests yet', style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      children: payouts.results.map((p) => _buildPayoutTile(context, p)).toList(),
    );
  }

  Widget _buildPayoutTile(BuildContext context, SellerPayoutModel payout) {
    final statusColor = _getPayoutStatusColor(payout.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Uicons.sackDollar, color: statusColor),
        title: Text(_formatMoney(payout.amount, payout.currency), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_formatDate(payout.requestedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payout.status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
            if (payout.status == 'pending') ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Uicons.ban, size: 18, color: Colors.red),
                onPressed: () => _confirmCancelPayout(context, payout.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmCancelPayout(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Payout?'),
        content: const Text('Are you sure you want to cancel this payout request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SellerCubit>().cancelPayout(id);
            },
            child: const Text('Yes, Cancel'),
          ),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getPayoutStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.amber;
      case 'approved': return Colors.blue;
      case 'processing': return Colors.orange;
      case 'rejected':
      case 'failed': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _formatTxType(String type) {
    return type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
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
}

class _PayoutRequestDrawer extends StatefulWidget {
  final List<PayoutAccountModel> accounts;
  final void Function({
    required String payoutAccountId,
    required double amount,
    String? note,
  }) onSubmit;

  const _PayoutRequestDrawer({
    required this.accounts,
    required this.onSubmit,
  });

  @override
  State<_PayoutRequestDrawer> createState() => _PayoutRequestDrawerState();
}

class _PayoutRequestDrawerState extends State<_PayoutRequestDrawer> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _selectedAccountId;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _selectedAccountId = widget.accounts.firstWhere(
      (a) => a.isDefault,
      orElse: () => widget.accounts.first,
    ).id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, String hint, ColorScheme cs, {String? suffixText, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      suffixText: suffixText,
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    widget.onSubmit(
      payoutAccountId: _selectedAccountId,
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      width: 360,
      child: Form(
        key: _formKey,
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
                      child: Icon(Uicons.sackDollar, size: 20, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Text('Request Payout',
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
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAccountId,
                      decoration: _fieldDecoration(
                        'Payout Account',
                        'Select account',
                        cs,
                        helper: 'Where to send the money',
                      ),
                      items: widget.accounts.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.provider} - ${a.accountNumber}'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedAccountId = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: _fieldDecoration(
                        'Amount',
                        'e.g. 50000',
                        cs,
                        suffixText: 'TZS',
                        helper: 'Amount to withdraw from your balance',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: _fieldDecoration(
                        'Note',
                        'Optional',
                        cs,
                        helper: 'Add a note for your records',
                      ),
                      maxLines: 2,
                    ),
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
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Request'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
