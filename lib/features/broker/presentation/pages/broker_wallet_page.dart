import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';
import '../../data/models/broker_models.dart';

class BrokerWalletPage extends StatefulWidget {
  const BrokerWalletPage({super.key});

  @override
  State<BrokerWalletPage> createState() => _BrokerWalletPageState();
}

class _BrokerWalletPageState extends State<BrokerWalletPage> {
  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Payouts')),
      body: BlocConsumer<BrokerCubit, BrokerState>(
        listener: (context, state) {
          if (state is BrokerActionSuccess) {
            NotificationService().success(state.message);
          } else if (state is BrokerError) {
            NotificationService().error(state.message);
          }
        },
        builder: (context, state) {
          if (state is BrokerLoading || state is BrokerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BrokerWalletLoaded) {
            return _buildWallet(context, state, colorScheme);
          }
          if (state is BrokerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<BrokerCubit>().loadWallet(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildWallet(
    BuildContext context,
    BrokerWalletLoaded state,
    ColorScheme colorScheme,
  ) {
    final wallet = state.wallet;
    final commission = state.commissionSummary;
    final accounts = state.payoutAccounts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Balance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${wallet.currency} ${wallet.availableBalance}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _balanceItem('Pending', wallet.pendingBalance),
                    ),
                    Expanded(
                      child: _balanceItem('Reserved', wallet.reservedBalance),
                    ),
                    Expanded(
                      child: _balanceItem('Paid Out', wallet.paidOutBalance),
                    ),
                  ],
                ),
                if (wallet.isFrozen) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Uicons.lock, color: Colors.red.shade200, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Wallet is frozen',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (commission != null) ...[
            const SizedBox(height: 20),
            Text(
              'Commission Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _summaryCard(context, 'Pending', commission.pendingAmount,
                    commission.currency, colorScheme),
                _summaryCard(context, 'Available', commission.availableAmount,
                    commission.currency, colorScheme),
                _summaryCard(context, 'Reversed', commission.reversedAmount,
                    commission.currency, colorScheme),
                _summaryCard(context, 'Lifetime', commission.lifetimeCommission,
                    commission.currency, colorScheme),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payout Accounts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () => _showAddAccountDialog(context, colorScheme),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Uicons.plus, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (accounts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No payout accounts yet. Add one to request payouts.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...accounts.map((account) => _payoutAccountCard(
                context, account, colorScheme)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _balanceItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(BuildContext context, String title, String value,
      String currency, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$currency $value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payoutAccountCard(
    BuildContext context,
    BrokerPayoutAccountModel account,
    ColorScheme colorScheme,
  ) {
    final isVerified = account.verificationStatus == 'verified';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            account.accountType == 'bank' ? Uicons.bank : Uicons.smartphone,
            size: 24,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.provider,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  account.accountNumber,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              account.verificationStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isVerified ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, ColorScheme colorScheme) {
    final typeCtrl = TextEditingController(text: 'mobile_money');
    final providerCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payout Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: 'mobile_money',
                decoration: const InputDecoration(labelText: 'Account Type'),
                items: const [
                  DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                ],
                onChanged: (v) => typeCtrl.text = v ?? 'mobile_money',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: providerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Provider (e.g. M-Pesa, CRDB)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (providerCtrl.text.isEmpty ||
                  nameCtrl.text.isEmpty ||
                  numberCtrl.text.isEmpty) {
                NotificationService().warning('Please fill all fields');
                return;
              }
              context.read<BrokerCubit>().createPayoutAccount(
                    accountType: typeCtrl.text,
                    provider: providerCtrl.text.trim(),
                    accountName: nameCtrl.text.trim(),
                    accountNumber: numberCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
