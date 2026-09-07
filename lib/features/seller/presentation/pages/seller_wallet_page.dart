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
  int _tabIndex = 0;
  List<PayoutAccountModel> _payoutAccounts = [];

  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings & Wallet')),
      body: BlocConsumer<SellerCubit, SellerState>(
        listener: (context, state) {
          if (state is SellerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFEF4444)),
            );
          }
          if (state is SellerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFF22C55E)),
            );
          }
        },
        builder: (context, state) {
          if (state is SellerLoading || state is SellerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SellerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Uicons.circleExclamation, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => context.read<SellerCubit>().loadWallet(),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }
          if (state is SellerWalletLoaded) {
            _payoutAccounts = state.payoutAccounts;
            return RefreshIndicator(
              onRefresh: () => context.read<SellerCubit>().loadWallet(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Header
                  Text('Earnings & Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text('Track your marketplace earnings, Xerin commission, held funds and available balance. Financial values shown here come directly from the seller commission and wallet APIs.',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: 16),

                  // Refresh button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.read<SellerCubit>().loadWallet(),
                      icon: Icon(Uicons.refresh, size: 16, color: cs.primary),
                      label: Text('Refresh', style: TextStyle(fontSize: 13, color: cs.primary)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Earnings cards
                  _buildEarningsSection(cs, state),
                  const SizedBox(height: 24),

                  // Settlement balances
                  _buildSettlementSection(cs, state.wallet),
                  const SizedBox(height: 24),

                  // How settlement works
                  _buildSettlementInfo(cs),
                  const SizedBox(height: 24),

                  // Request payout
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _payoutAccounts.isEmpty ? null : () => _showPayoutSheet(context),
                      icon: Icon(Uicons.sackDollar, size: 18),
                      label: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tabs
                  Row(
                    children: [
                      _buildTab(cs, 'Transactions', 0),
                      _buildTab(cs, 'Payouts', 1),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_tabIndex == 0)
                    _buildTransactions(cs, state.transactions)
                  else
                    _buildPayouts(cs, state.payouts),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEarningsSection(ColorScheme cs, SellerWalletLoaded state) {
    final e = state.earnings;
    final gross = e?.grossSales ?? 0;
    final commission = e?.commissionDeducted ?? 0;
    final net = e?.netEarnings ?? 0;
    final count = e?.transactionCount ?? 0;
    final walletExposure = state.wallet.pendingBalance + state.wallet.availableBalance + state.wallet.reservedBalance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEarningCard(cs, 'Gross Sales', 'TSh ${_fmt(gross)}', '$count commission records', null),
        const SizedBox(height: 8),
        _buildEarningCard(cs, 'Xerin Commission', 'TSh ${_fmt(commission)}', 'Marketplace commission deducted', const Color(0xFFEF4444)),
        const SizedBox(height: 8),
        _buildEarningCard(cs, 'Net Earnings', 'TSh ${_fmt(net)}', 'Seller entitlement before settlement movement', const Color(0xFF22C55E)),
        const SizedBox(height: 8),
        _buildEarningCard(cs, 'Wallet Exposure', 'TSh ${_fmt(walletExposure)}', 'Pending + available + reserved', null),
      ],
    );
  }

  Widget _buildEarningCard(ColorScheme cs, String title, String value, String subtitle, Color? accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent ?? cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementSection(ColorScheme cs, SellerWalletModel wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settlement Balances', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('These balances come from the seller wallet ledger and represent different stages of settlement.',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 12),
        _buildBalanceRow(cs, 'Pending', 'TSh ${_fmt(wallet.pendingBalance)}', 'Seller funds not yet available', const Color(0xFFF59E0B)),
        const SizedBox(height: 8),
        _buildBalanceRow(cs, 'Available', 'TSh ${_fmt(wallet.availableBalance)}', 'Eligible for payout', const Color(0xFF22C55E)),
        const SizedBox(height: 8),
        _buildBalanceRow(cs, 'Reserved', 'TSh ${_fmt(wallet.reservedBalance)}', 'Reserved for payout/settlement', const Color(0xFF3B82F6)),
        const SizedBox(height: 8),
        _buildBalanceRow(cs, 'Paid Out', 'TSh ${_fmt(wallet.paidOutBalance)}', 'Completed seller payouts', null),
        const SizedBox(height: 8),
        _buildBalanceRow(cs, 'Refunded', 'TSh ${_fmt(wallet.refundedBalance)}', 'Amounts reversed/refunded', const Color(0xFFEF4444)),
        const SizedBox(height: 8),
        _buildBalanceRow(cs, 'Debt', 'TSh ${_fmt(wallet.debtBalance)}', 'Outstanding seller liability', const Color(0xFFEF4444)),
        if (wallet.isFrozen) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Uicons.lock, size: 14, color: const Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Text('Wallet Frozen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBalanceRow(ColorScheme cs, String label, String value, String subtitle, Color? accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accent ?? cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildSettlementInfo(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How settlement works', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 12),
          _buildStep(cs, '1', 'Sale is recorded', 'Commission records preserve gross sale, Xerin commission and seller net earnings.'),
          const SizedBox(height: 10),
          _buildStep(cs, '2', 'Funds remain pending', 'Eligible seller funds remain pending until the payment/escrow workflow releases them.'),
          const SizedBox(height: 10),
          _buildStep(cs, '3', 'Funds become available', 'Released funds move into Available Balance and can later be requested as payout.'),
          const SizedBox(height: 12),
          Text('Customer-payment-to-escrow allocation is intentionally completed during the Customer payment phase. Until then, some wallet balances can remain zero even when historical commission records exist.',
            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildStep(ColorScheme cs, String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(ColorScheme cs, String label, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? cs.primary : Colors.transparent, width: 2)),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.4))),
        ),
      ),
    );
  }

  Widget _buildTransactions(ColorScheme cs, PaginatedWalletTransactions transactions) {
    if (transactions.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No transactions yet', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))),
        ),
      );
    }
    return Column(
      children: transactions.results.map((tx) => _buildTransactionTile(cs, tx)).toList(),
    );
  }

  Widget _buildTransactionTile(ColorScheme cs, SellerWalletTransactionModel tx) {
    final isCredit = tx.amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(isCredit ? Uicons.arrowTrendUp : Uicons.arrowTrendDown, size: 18,
            color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatTxType(tx.transactionType), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                Text(_formatDate(tx.createdAt), style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Text('${isCredit ? '+' : ''}${_fmt(tx.amount)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
              color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
        ],
      ),
    );
  }

  Widget _buildPayouts(ColorScheme cs, PaginatedSellerPayouts payouts) {
    if (payouts.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No payout requests yet', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))),
        ),
      );
    }
    return Column(
      children: payouts.results.map((p) => _buildPayoutTile(cs, p)).toList(),
    );
  }

  Widget _buildPayoutTile(ColorScheme cs, SellerPayoutModel payout) {
    final statusColor = _getPayoutStatusColor(payout.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(Uicons.sackDollar, size: 18, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TSh ${_fmt(payout.amount)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                Text(_formatDate(payout.requestedAt), style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(payout.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          if (payout.status == 'pending') ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmCancelPayout(payout.id),
              child: Icon(Uicons.ban, size: 16, color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancelPayout(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Payout?'),
        content: const Text('Are you sure you want to cancel this payout request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { Navigator.pop(ctx); context.read<SellerCubit>().cancelPayout(id); },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPayoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PayoutRequestSheet(
        accounts: _payoutAccounts,
        onSubmit: ({required String payoutAccountId, required double amount, String? note}) {
          Navigator.pop(ctx);
          context.read<SellerCubit>().requestPayout(payoutAccountId: payoutAccountId, amount: amount, note: note);
        },
      ),
    );
  }

  Color _getPayoutStatusColor(String status) {
    switch (status) {
      case 'completed': return const Color(0xFF22C55E);
      case 'pending': return const Color(0xFFF59E0B);
      case 'approved': return const Color(0xFF3B82F6);
      case 'processing': return const Color(0xFFF97316);
      case 'rejected':
      case 'failed': return const Color(0xFFEF4444);
      case 'cancelled': return const Color(0xFF9CA3AF);
      default: return const Color(0xFF9CA3AF);
    }
  }

  String _formatTxType(String type) {
    return type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String _fmt(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
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

// ─── Payout Request Sheet ───
class _PayoutRequestSheet extends StatefulWidget {
  final List<PayoutAccountModel> accounts;
  final void Function({required String payoutAccountId, required double amount, String? note}) onSubmit;

  const _PayoutRequestSheet({required this.accounts, required this.onSubmit});

  @override
  State<_PayoutRequestSheet> createState() => _PayoutRequestSheetState();
}

class _PayoutRequestSheetState extends State<_PayoutRequestSheet> {
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
    _selectedAccountId = widget.accounts.firstWhere((a) => a.isDefault, orElse: () => widget.accounts.first).id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request Payout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                        const SizedBox(height: 2),
                        Text('Withdraw from your available balance', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Uicons.crossSmall, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(cs, 'Payout account'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAccountId,
                        decoration: _input(cs, 'Select account'),
                        items: widget.accounts.map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.provider} - ${a.accountNumber}'),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedAccountId = v!),
                      ),
                      const SizedBox(height: 4),
                      Text('Where to send the money', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
                      const SizedBox(height: 16),
                      _label(cs, 'Amount *'),
                      TextFormField(
                        controller: _amountController,
                        decoration: _input(cs, 'e.g. 50000', suffix: 'TZS'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 4),
                      Text('Amount to withdraw from your balance', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
                      const SizedBox(height: 16),
                      _label(cs, 'Note (optional)'),
                      TextFormField(
                        controller: _noteController,
                        decoration: _input(cs, 'Add a note for your records'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                          : const Text('Request', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _label(ColorScheme cs, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
    );
  }

  InputDecoration _input(ColorScheme cs, String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
      suffixText: suffix,
      filled: true,
      fillColor: cs.onSurface.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
