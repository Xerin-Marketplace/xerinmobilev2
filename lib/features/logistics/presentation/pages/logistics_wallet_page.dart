import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/logistics_models.dart';
import '../../presentation/cubit/logistics_cubit.dart';
import '../../presentation/cubit/logistics_state.dart';

class LogisticsWalletPage extends StatefulWidget {
  const LogisticsWalletPage({super.key});

  @override
  State<LogisticsWalletPage> createState() => _LogisticsWalletPageState();
}

class _LogisticsWalletPageState extends State<LogisticsWalletPage> {
  @override
  void initState() {
    super.initState();
    context.read<LogisticsCubit>().loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Wallet'),
      ),
      body: SafeArea(
        child: BlocConsumer<LogisticsCubit, LogisticsState>(
          listener: (context, state) {
            if (state is LogisticsError) {
              NotificationService().error(state.message);
            }
          },
          builder: (context, state) {
            if (state is LogisticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LogisticsWalletLoaded) {
              return _buildContent(state.wallet, state.transactions, cs);
            }
            return Center(
              child: Text('Loading...',
                  style:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
      LogisticsWalletModel wallet, List<Map<String, dynamic>> txns, ColorScheme cs) {
    return RefreshIndicator(
      onRefresh: () => context.read<LogisticsCubit>().loadWallet(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Balance',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    '${wallet.balance} ${wallet.currency}',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  if (wallet.pendingPayouts != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Pending Payouts: ',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white70)),
                        Text('${wallet.pendingPayouts} ${wallet.currency}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Transactions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            if (txns.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No transactions yet',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4))),
                ),
              )
            else
              ...txns.map((txn) => _TxnCard(txn, cs)),
          ],
        ),
      ),
    );
  }

  Widget _TxnCard(Map<String, dynamic> txn, ColorScheme cs) {
    final type = txn['type']?.toString() ?? '';
    final amount = txn['amount']?.toString() ?? '0';
    final description = txn['description']?.toString() ?? '';
    final createdAt = txn['created_at']?.toString() ?? '';
    final isCredit = type == 'credit' || type == 'earning';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isCredit ? Colors.green : Colors.red)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isCredit ? Uicons.plus : Uicons.minus,
            color: isCredit ? Colors.green : Colors.red,
            size: 18,
          ),
        ),
        title: Text(description,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        subtitle: Text(createdAt,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        trailing: Text(
          '${isCredit ? '+' : '-'}$amount',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
