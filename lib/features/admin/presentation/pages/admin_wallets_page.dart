import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/security/admin_access.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';
import '../../data/models/admin_models.dart';

class AdminWalletsPage extends StatefulWidget {
  const AdminWalletsPage({super.key});

  @override
  State<AdminWalletsPage> createState() => _AdminWalletsPageState();
}

class _AdminWalletsPageState extends State<AdminWalletsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<AdminCubit>().loadWallets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & Payouts'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<AdminCubit>().loadWallets(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wallets'),
            Tab(text: 'Payouts'),
          ],
        ),
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
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
          if (state is AdminWalletsLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _walletsTab(context, state),
                _payoutsTab(context, state),
              ],
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
                    onPressed: () => context.read<AdminCubit>().loadWallets(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!_isReloading) {
            _isReloading = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AdminCubit>().loadWallets();
              _isReloading = false;
            });
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _walletsTab(BuildContext context, AdminWalletsLoaded state) {
    if (state.wallets.isEmpty) {
      return const Center(child: Text('No wallets found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.wallets.length,
      itemBuilder: (context, index) =>
          _walletCard(context, state.wallets[index]),
    );
  }

  Widget _walletCard(BuildContext context, AdminWalletModel wallet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Uicons.wallet, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text('Seller: ${wallet.sellerId.substring(0, 8)}...',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _balanceRow('Available', wallet.availableBalance, wallet.currency, Colors.green),
            _balanceRow('Pending', wallet.pendingBalance, wallet.currency, Colors.orange),
            _balanceRow('Total Earnings', wallet.totalEarnings, wallet.currency, Colors.blue),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Uicons.pen, size: 16),
              label: const Text('Adjust Balance'),
 onPressed: AdminAccess.canAccessItem(
                      GetIt.instance<TokenStorage>().currentUser,
                      'wallets.adjust')
                  ? () => _showAdjustDialog(context, wallet)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceRow(String label, double amount, String currency, Color color) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text('$currency $formatted',
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _payoutsTab(BuildContext context, AdminWalletsLoaded state) {
    if (state.payouts.isEmpty) {
      return const Center(child: Text('No payouts found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.payouts.length,
      itemBuilder: (context, index) =>
          _payoutCard(context, state.payouts[index]),
    );
  }

  Widget _payoutCard(BuildContext context, AdminPayoutModel payout) {
    final color = _payoutStatusColor(payout.status);
    final formatted = payout.amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text('${payout.currency} $formatted',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Seller: ${payout.sellerId.substring(0, 8)}...',
                style: const TextStyle(fontSize: 12)),
            if (payout.note != null)
              Text('Note: ${payout.note}', style: const TextStyle(fontSize: 12)),
            if (payout.requestedAt != null)
              Text('Requested: ${payout.requestedAt!.substring(0, 10)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_humanize(payout.status),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
        trailing: payout.status == 'pending' &&
                AdminAccess.canAccessItem(
                    GetIt.instance<TokenStorage>().currentUser,
                    'payouts.approve')
            ? PopupMenuButton<String>(
                onSelected: (action) =>
                    _showPayoutActionDialog(context, payout, action),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'approve', child: Text('Approve')),
                  PopupMenuItem(value: 'processing', child: Text('Mark Processing')),
                  PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                  PopupMenuItem(value: 'rejected', child: Text('Reject')),
                ],
              )
            : null,
      ),
    );
  }

  void _showPayoutActionDialog(
      BuildContext context, AdminPayoutModel payout, String action) {
    final noteController = TextEditingController();
    final refController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${_humanize(action)} Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (action == 'completed')
              TextField(
                controller: refController,
                decoration: const InputDecoration(
                  labelText: 'Provider Reference',
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
              context.read<AdminCubit>().updatePayout(payout.id, {
                'status': action,
                'note': noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
                'provider_reference': refController.text.trim().isEmpty
                    ? null
                    : refController.text.trim(),
              });
            },
            child: Text(_humanize(action)),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, AdminWalletModel wallet) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adjust Wallet Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (+/-)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<AdminCubit>().adjustWallet(
                    wallet.sellerId,
                    amount,
                    reasonController.text.trim(),
                  );
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }

  Color _payoutStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _humanize(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
