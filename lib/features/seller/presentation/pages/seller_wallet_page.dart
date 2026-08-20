import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../data/models/seller_wallet_model.dart';
import '../../data/models/seller_payout_model.dart';
import '../cubit/seller_cubit.dart';
import '../cubit/seller_state.dart';

class SellerWalletPage extends StatefulWidget {
  const SellerWalletPage({super.key});

  @override
  State<SellerWalletPage> createState() => _SellerWalletPageState();
}

class _SellerWalletPageState extends State<SellerWalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerCubit>().refreshWallet();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatPrice(double amount) {
    if (amount >= 1000000000) {
      return 'TSh ${(amount / 1000000000).toStringAsFixed(2)}B';
    } else if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return 'TSh ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  String _formatFull(double amount) {
    return 'TSh ${amount.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(String status, ColorScheme cs) {
    switch (status) {
      case 'completed':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'processing':
        return const Color(0xFF3B82F6);
      case 'rejected':
      case 'failed':
        return cs.error;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showRequestPayoutDialog(BuildContext context, SellerDashboardLoaded state) {
    if (state.wallet == null || state.wallet!.availableBalance <= 0) {
      NotificationService().warning('No available balance for payout');
      return;
    }
    if (state.payoutAccounts.isEmpty) {
      NotificationService().warning('Add a payout account first');
      return;
    }
    if (state.wallet!.isFrozen) {
      NotificationService().error('Wallet is frozen. Contact support.');
      return;
    }

    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedAccountId = state.payoutAccounts.first.id;
    final maxAmount = state.wallet!.availableBalance;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Payout'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available: ${_formatFull(maxAmount)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF22C55E)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Payout Account',
                  border: OutlineInputBorder(),
                ),
                items: state.payoutAccounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('${acc.provider} • ${acc.accountNumber}'),
                  );
                }).toList(),
                onChanged: (v) => selectedAccountId = v ?? selectedAccountId,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Amount (TSh)',
                  border: const OutlineInputBorder(),
                  hintText: 'Max: ${maxAmount.toStringAsFixed(0)}',
                  suffixText: 'TSh',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null || amount <= 0) {
                NotificationService().warning('Enter a valid amount');
                return;
              }
              if (amount > maxAmount) {
                NotificationService().error('Amount exceeds available balance');
                return;
              }
              Navigator.pop(dialogContext);
              context.read<SellerCubit>().requestPayout(
                payoutAccountId: selectedAccountId,
                amount: amount,
                note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
              );
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showCancelPayoutDialog(BuildContext context, WalletPayoutModel payout) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Payout'),
        content: Text('Cancel payout of ${_formatFull(payout.amount)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SellerCubit>().cancelPayout(payout.id);
            },
            child: const Text('Cancel Payout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<SellerCubit, SellerState>(
          builder: (context, state) {
            if (state is SellerLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final loaded = state is SellerDashboardLoaded ? state : null;
            final wallet = loaded?.wallet;
            final transactions = loaded?.walletTransactions ?? [];
            final payouts = loaded?.walletPayouts ?? [];

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            BackIconButton(
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppConstants.sellerDashboardRoute);
                                }
                              },
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'My Wallet',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => context.read<SellerCubit>().refreshWallet(),
                              icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Balance Card
                        if (wallet != null)
                          _buildBalanceCard(wallet, colorScheme, context, loaded!)
                        else
                          _buildNoWalletCard(colorScheme),
                      ],
                    ),
                  ),
                ),

                // Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: const TextStyle(fontSize: 13),
                        padding: const EdgeInsets.all(4),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Transactions'),
                          Tab(text: 'Payouts'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Tab content
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(wallet, colorScheme),
                      _buildTransactionsTab(transactions, colorScheme),
                      _buildPayoutsTab(payouts, colorScheme, context),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    SellerWalletModel wallet,
    ColorScheme colorScheme,
    BuildContext context,
    SellerDashboardLoaded state,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: wallet.isFrozen
              ? [Colors.grey.shade600, Colors.grey.shade800]
              : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (wallet.isFrozen ? Colors.grey : colorScheme.primary).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wallet.isFrozen ? Icons.ac_unit_rounded : Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                wallet.isFrozen ? 'Frozen Wallet' : 'Available Balance',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              Text(
                wallet.currency,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatFull(wallet.availableBalance),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalancePill(
                  'Pending',
                  _formatPrice(wallet.pendingBalance),
                  Icons.hourglass_top_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalancePill(
                  'Reserved',
                  _formatPrice(wallet.reservedBalance),
                  Icons.lock_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!wallet.isFrozen)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: wallet.availableBalance > 0
                    ? () => _showRequestPayoutDialog(context, state)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Request Payout',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalancePill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWalletCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.wallet_outlined, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Wallet not available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(SellerWalletModel? wallet, ColorScheme cs) {
    if (wallet == null) {
      return _buildEmptyState('No wallet data', Icons.wallet_outlined, cs);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDetailTile(
          'Pending Balance',
          _formatFull(wallet.pendingBalance),
          'Awaiting settlement period',
          Icons.hourglass_top_rounded,
          const Color(0xFFF59E0B),
          cs,
        ),
        _buildDetailTile(
          'Available Balance',
          _formatFull(wallet.availableBalance),
          'Ready for payout',
          Icons.check_circle_rounded,
          const Color(0xFF22C55E),
          cs,
        ),
        _buildDetailTile(
          'Reserved Balance',
          _formatFull(wallet.reservedBalance),
          'In payout processing',
          Icons.lock_outline_rounded,
          const Color(0xFF3B82F6),
          cs,
        ),
        _buildDetailTile(
          'Total Paid Out',
          _formatFull(wallet.paidOutBalance),
          'Lifetime payouts completed',
          Icons.account_balance_rounded,
          const Color(0xFF8B5CF6),
          cs,
        ),
        _buildDetailTile(
          'Refunded',
          _formatFull(wallet.refundedBalance),
          'Refunds processed',
          Icons.undo_rounded,
          Colors.grey,
          cs,
        ),
        if (wallet.debtBalance > 0)
          _buildDetailTile(
            'Debt Balance',
            _formatFull(wallet.debtBalance),
            'Recoverable from future sales',
            Icons.warning_amber_rounded,
            cs.error,
            cs,
          ),
        const SizedBox(height: 16),
        if (wallet.isFrozen)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.ac_unit_rounded, color: cs.error, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your wallet is frozen. Payouts are disabled. Contact support for assistance.',
                    style: TextStyle(fontSize: 13, color: cs.error),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Info',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Currency', wallet.currency, cs),
              _buildInfoRow('Created', _formatDate(wallet.createdAt), cs),
              if (wallet.updatedAt != null)
                _buildInfoRow('Last Updated', _formatDate(wallet.updatedAt), cs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(
    String title,
    String value,
    subtitle,
    IconData icon,
    Color color,
    ColorScheme cs,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(
    List<WalletTransactionModel> transactions,
    ColorScheme cs,
  ) {
    if (transactions.isEmpty) {
      return _buildEmptyState('No transactions yet', Icons.receipt_long_outlined, cs);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isCredit = tx.isCredit;
        final color = isCredit ? const Color(0xFF22C55E) : cs.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tx.typeIcon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.typeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (tx.description != null && tx.description!.isNotEmpty)
                      Text(
                        tx.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    Text(
                      _formatDate(tx.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : '-'}${_formatFull(tx.amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayoutsTab(
    List<WalletPayoutModel> payouts,
    ColorScheme cs,
    BuildContext context,
  ) {
    if (payouts.isEmpty) {
      return _buildEmptyState('No payout requests yet', Icons.payments_outlined, cs);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final p = payouts[index];
        final statusColor = _statusColor(p.status, cs);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.payments_rounded, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatFull(p.amount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Requested ${_formatDate(p.requestedAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (p.sellerNote != null && p.sellerNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Note: ${p.sellerNote}',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
              if (p.adminNote != null && p.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Admin: ${p.adminNote}',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
              if (p.canCancel) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showCancelPayoutDialog(context, p),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
