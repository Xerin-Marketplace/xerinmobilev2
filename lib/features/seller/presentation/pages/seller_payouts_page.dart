import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/datasources/seller_remote_datasource.dart';
import '../../data/models/seller_models.dart';

class SellerPayoutsPage extends StatefulWidget {
  const SellerPayoutsPage({super.key});

  @override
  State<SellerPayoutsPage> createState() => _SellerPayoutsPageState();
}

class _SellerPayoutsPageState extends State<SellerPayoutsPage> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  int _currentPage = 1;
  PaginatedSellerPayouts _payouts = const PaginatedSellerPayouts();
  SellerWalletModel? _wallet;
  List<PayoutAccountModel> _payoutAccounts = [];
  List<SellerPayoutModel> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final ds = sl<SellerRemoteDataSource>();
      _wallet = await ds.getWallet();
      _payoutAccounts = await ds.getPayoutAccounts();
      _payouts = await ds.getPayouts(page: _currentPage);
      _applyFilters();
      setState(() { _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadPage(int page) async {
    if (page < 1 || page > _payouts.totalPages) return;
    setState(() => _currentPage = page);
    try {
      final ds = sl<SellerRemoteDataSource>();
      _payouts = await ds.getPayouts(page: page);
      _applyFilters();
      setState(() {});
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = _payouts.results.where((p) {
        final matchesSearch = q.isEmpty ||
            p.amount.toString().contains(q) ||
            (p.providerReference?.toLowerCase().contains(q) ?? false) ||
            (p.sellerNote?.toLowerCase().contains(q) ?? false);
        final matchesStatus = _statusFilter == 'all' || p.status == _statusFilter;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  double get _pendingOnPage =>
      _payouts.results.where((p) => p.status == 'pending').fold(0.0, (s, p) => s + p.amount);

  double get _completedOnPage =>
      _payouts.results.where((p) => p.status == 'completed').fold(0.0, (s, p) => s + p.amount);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Payout Requests')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(cs)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      _buildHeader(cs),
                      const SizedBox(height: 16),
                      _buildBalanceCards(cs),
                      const SizedBox(height: 24),
                      _buildRequestForm(cs),
                      const SizedBox(height: 28),
                      _buildHistorySection(cs),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Uicons.circleExclamation, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _loadData,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payout Requests', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('Request settlement of available seller funds to a verified payout account and follow each request from pending through completion.',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _loadData,
            icon: Icon(Uicons.refresh, size: 16, color: cs.primary),
            label: Text('Refresh', style: TextStyle(fontSize: 13, color: cs.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCards(ColorScheme cs) {
    final wallet = _wallet;
    return Column(
      children: [
        _balanceCard(cs, 'Available Balance', 'TSh ${_fmt(wallet?.availableBalance ?? 0)}', null),
        const SizedBox(height: 8),
        _balanceCard(cs, 'Reserved Balance', 'TSh ${_fmt(wallet?.reservedBalance ?? 0)}', null),
        const SizedBox(height: 8),
        _balanceCard(cs, 'Pending on this page', 'TSh ${_fmt(_pendingOnPage)}', const Color(0xFFF59E0B)),
        const SizedBox(height: 8),
        _balanceCard(cs, 'Completed on this page', 'TSh ${_fmt(_completedOnPage)}', const Color(0xFF22C55E)),
      ],
    );
  }

  Widget _balanceCard(ColorScheme cs, String label, String value, Color? accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
          ),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent ?? cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildRequestForm(ColorScheme cs) {
    final available = _wallet?.availableBalance ?? 0;
    final activeAccounts = _payoutAccounts.where((a) => a.isActive && (a.verificationStatus == 'verified' || a.verificationStatus == null)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request Payout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('Only active and verified accounts can receive payouts.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 16),

          if (activeAccounts.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Uicons.circleExclamation, size: 16, color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('No active verified payout accounts. Add one in KYC settings.',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)))),
                ],
              ),
            ),
          ] else ...[
            _PayoutRequestForm(
              accounts: activeAccounts,
              availableBalance: available,
              onSubmit: ({required String payoutAccountId, required double amount, String? note}) {
                context.read<SellerCubit>().requestPayout(
                  payoutAccountId: payoutAccountId,
                  amount: amount,
                  note: note,
                );
                _loadData();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payout History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('Pagination is backend-controlled. Search and status filters apply to the current page.',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 16),

        // Search + filter
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Filter current page...',
                  hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  prefixIcon: Icon(Uicons.search, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: cs.onSurface.withValues(alpha: 0.04),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PopupMenuButton<String>(
                initialValue: _statusFilter,
                onSelected: (v) { setState(() => _statusFilter = v); _applyFilters(); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_statusLabel(_statusFilter), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                    ],
                  ),
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'all', child: Text('All statuses', style: TextStyle(fontSize: 14))),
                  PopupMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(fontSize: 14))),
                  PopupMenuItem(value: 'approved', child: Text('Approved', style: TextStyle(fontSize: 14))),
                  PopupMenuItem(value: 'processing', child: Text('Processing', style: TextStyle(fontSize: 14))),
                  PopupMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(fontSize: 14))),
                  PopupMenuItem(value: 'rejected', child: Text('Rejected', style: TextStyle(fontSize: 14))),
                  PopupMenuItem(value: 'cancelled', child: Text('Cancelled', style: TextStyle(fontSize: 14))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Payout list
        if (_filtered.isEmpty)
          _buildEmptyState(cs)
        else
          ..._filtered.map((p) => _buildPayoutTile(cs, p)),

        // Pagination
        if (_payouts.totalPages > 1) ...[
          const SizedBox(height: 16),
          _buildPagination(cs),
        ],

        const SizedBox(height: 12),
        // Showing count
        if (_payouts.results.isNotEmpty)
          Text('Showing ${(_payouts.page - 1) * _payouts.pageSize + 1}-${(_payouts.page - 1) * _payouts.pageSize + _payouts.results.length} of ${_payouts.total}',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            Icon(Uicons.sackDollar, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No payout requests found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Eligible seller payout requests will appear here.',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutTile(ColorScheme cs, SellerPayoutModel payout) {
    final statusColor = _getStatusColor(payout.status);
    final account = _payoutAccounts.where((a) => a.id == payout.payoutAccountId).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: amount + status
          Row(
            children: [
              Text('TSh ${_fmt(payout.amount)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(payout.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              if (payout.status == 'pending') ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmCancel(payout.id),
                  child: Icon(Uicons.ban, size: 16, color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Account info
          if (account != null)
            Text('${account.provider} \u00b7 ${account.accountName} \u00b7 \u2022\u2022\u2022\u2022\u2022${account.accountNumber.length > 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 6),
          // Dates
          Row(
            children: [
              Text('Requested: ${_formatDate(payout.requestedAt)}',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              if (payout.processedAt != null) ...[
                const SizedBox(width: 12),
                Text('Processed: ${_formatDate(payout.processedAt!)}',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ],
          ),
          if (payout.completedAt != null) ...[
            const SizedBox(height: 2),
            Text('Completed: ${_formatDate(payout.completedAt!)}',
              style: TextStyle(fontSize: 11, color: const Color(0xFF22C55E).withValues(alpha: 0.6))),
          ],
          if (payout.providerReference != null) ...[
            const SizedBox(height: 4),
            Text('Provider Ref: ${payout.providerReference}',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3), fontFamily: 'monospace')),
          ],
          if (payout.sellerNote != null && payout.sellerNote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Note: ${payout.sellerNote}',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
          icon: Icon(Icons.chevron_left, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
        ),
        Text('Page $_currentPage of ${_payouts.totalPages}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
        IconButton(
          onPressed: _currentPage < _payouts.totalPages ? () => _loadPage(_currentPage + 1) : null,
          icon: Icon(Icons.chevron_right, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  void _confirmCancel(String id) {
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
            onPressed: () { Navigator.pop(ctx); context.read<SellerCubit>().cancelPayout(id); _loadData(); },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  String _statusLabel(String s) {
    switch (s) {
      case 'all': return 'All statuses';
      case 'pending': return 'Pending';
      case 'approved': return 'Approved';
      case 'processing': return 'Processing';
      case 'completed': return 'Completed';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      default: return 'All statuses';
    }
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

// ─── Payout Request Form ───
class _PayoutRequestForm extends StatefulWidget {
  final List<PayoutAccountModel> accounts;
  final double availableBalance;
  final void Function({required String payoutAccountId, required double amount, String? note}) onSubmit;

  const _PayoutRequestForm({required this.accounts, required this.availableBalance, required this.onSubmit});

  @override
  State<_PayoutRequestForm> createState() => _PayoutRequestFormState();
}

class _PayoutRequestFormState extends State<_PayoutRequestForm> {
  late String _selectedAccountId;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
    _amountController.clear();
    _noteController.clear();
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account selector
          _label(cs, 'Payout account *'),
          DropdownButtonFormField<String>(
            initialValue: _selectedAccountId,
            decoration: _input(cs, 'Select account'),
            items: widget.accounts.map((a) {
              final masked = a.accountNumber.length > 4
                  ? '\u2022\u2022\u2022\u2022\u2022${a.accountNumber.substring(a.accountNumber.length - 4)}'
                  : a.accountNumber;
              return DropdownMenuItem(
                value: a.id,
                child: Text('${a.provider} \u00b7 ${a.accountName} \u00b7 $masked', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedAccountId = v!),
          ),
          // Account detail
          const SizedBox(height: 8),
          _buildAccountDetail(cs),
          const SizedBox(height: 16),

          // Amount
          _label(cs, 'Amount (TZS) *'),
          TextFormField(
            controller: _amountController,
            decoration: _input(cs, 'Enter payout amount', suffix: 'TZS'),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final amt = double.tryParse(v.trim());
              if (amt == null || amt <= 0) return 'Enter a valid amount';
              if (amt > widget.availableBalance) return 'Exceeds available balance';
              return null;
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Available: TSh ${_fmt(widget.availableBalance)}',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _amountController.text = widget.availableBalance.toStringAsFixed(0);
                },
                child: Text('Use full available balance',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Note
          _label(cs, 'Seller note'),
          TextFormField(
            controller: _noteController,
            decoration: _input(cs, 'Optional payout note...'),
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text('Optional note attached to this payout request.',
            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
          const SizedBox(height: 16),

          // Submit
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                  : const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Text('The backend validates the Finance minimum payout amount, available wallet balance, account ownership and verification status when you submit the request.',
            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildAccountDetail(ColorScheme cs) {
    final account = widget.accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
    if (account == null) return const SizedBox.shrink();
    final masked = account.accountNumber.length > 4
        ? '\u2022\u2022\u2022\u2022\u2022${account.accountNumber.substring(account.accountNumber.length - 4)}'
        : account.accountNumber;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(account.accountType == 'bank' ? Uicons.bank : Uicons.smartphone, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(account.provider, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${account.accountName} \u00b7 $masked',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 6),
          Row(
            children: [
              if (account.verificationStatus == 'verified' || account.verificationStatus == null) ...[
                Icon(Uicons.circleCheck, size: 12, color: const Color(0xFF22C55E)),
                const SizedBox(width: 4),
                Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E))),
              ],
              if (account.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.primary)),
                ),
              ],
            ],
          ),
        ],
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

  String _fmt(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
