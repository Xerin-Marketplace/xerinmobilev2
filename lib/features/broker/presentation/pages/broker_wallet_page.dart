import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';
import '../../data/models/broker_models.dart';

const _mawingaPrimary = Color(0xFF6D28D9);

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: const Text('Broker Finance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
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
            return _buildContent(context, state, cs);
          }
          if (state is BrokerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Uicons.triangleWarning, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<BrokerCubit>().loadWallet(),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, BrokerWalletLoaded state, ColorScheme cs) {
    final wallet = state.wallet;
    final accounts = state.payoutAccounts;
    final payouts = state.payouts;
    final transactions = state.walletTransactions;

    return RefreshIndicator(
      onRefresh: () => context.read<BrokerCubit>().loadWallet(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _infoBanner(cs),
          const SizedBox(height: 16),
          _balanceCard(cs, wallet),
          const SizedBox(height: 20),
          _sectionTitle('Payout accounts', cs),
          const SizedBox(height: 4),
          Text('Mobile money or bank account must be verified by Admin.',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 10),
          _payoutAccountsSection(context, cs, accounts),
          const SizedBox(height: 20),
          _withdrawalSection(context, cs, wallet, accounts),
          const SizedBox(height: 20),
          _sectionTitle('Payout history', cs),
          const SizedBox(height: 10),
          _payoutHistory(cs, payouts),
          const SizedBox(height: 20),
          _sectionTitle('Wallet ledger', cs),
          const SizedBox(height: 10),
          _walletLedger(cs, transactions),
        ],
      ),
    );
  }

  Widget _infoBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mawingaPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _mawingaPrimary.withValues(alpha: 0.12)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Uicons.circleInfo, size: 18, color: _mawingaPrimary),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Only commission released from escrow is withdrawable. Payout funds are reserved until Admin completes or rejects the request.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.6), height: 1.4),
        )),
      ]),
    );
  }

  Widget _balanceCard(ColorScheme cs, BrokerWalletModel wallet) {
    final balances = [
      ('Pending', wallet.pendingBalance, const Color(0xFFF59E0B), Uicons.clock),
      ('Available', wallet.availableBalance, const Color(0xFF22C55E), Uicons.wallet),
      ('Reserved', wallet.reservedBalance, const Color(0xFF3B82F6), Uicons.lock),
      ('Paid out', wallet.paidOutBalance, const Color(0xFF6D28D9), Uicons.checkCircle),
      ('Reversed', wallet.reversedBalance, const Color(0xFFEF4444), Uicons.arrowTrendDown),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        ...balances.map((b) => _balanceRow(cs, b.$1, b.$2, b.$3, b.$4)),
        if (wallet.isFrozen)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Uicons.lock, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 8),
              const Text('Wallet is frozen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
            ]),
          ),
      ]),
    );
  }

  Widget _balanceRow(ColorScheme cs, String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface))),
        Text('TSh $value',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface)),
      ]),
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _payoutAccountsSection(BuildContext context, ColorScheme cs, List<BrokerPayoutAccountModel> accounts) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const SizedBox(),
        GestureDetector(
          onTap: () => _showAddAccountSheet(context, cs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _mawingaPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Uicons.plus, size: 15, color: _mawingaPrimary),
              const SizedBox(width: 5),
              Text('Add account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _mawingaPrimary)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      if (accounts.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(children: [
            Icon(Uicons.creditCard, size: 36, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('No payout account yet.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
            const SizedBox(height: 4),
            Text('Add a mobile money or bank account to withdraw funds.',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)), textAlign: TextAlign.center),
          ]),
        )
      else
        ...accounts.map((a) => _payoutAccountCard(cs, a)),
    ]);
  }

  Widget _payoutAccountCard(ColorScheme cs, BrokerPayoutAccountModel account) {
    final isVerified = account.verificationStatus == 'verified';
    final isPending = account.verificationStatus == 'pending';
    final statusColor = isVerified ? const Color(0xFF22C55E) : isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (account.accountType == 'bank' ? const Color(0xFF3B82F6) : _mawingaPrimary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            account.accountType == 'bank' ? Uicons.bank : Uicons.smartphone,
            size: 20, color: account.accountType == 'bank' ? const Color(0xFF3B82F6) : _mawingaPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(account.provider, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 2),
          Text(account.accountNumber, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          if (account.isDefault)
            const SizedBox(height: 4),
          if (account.isDefault)
            Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _mawingaPrimary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(account.verificationStatus,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
        ),
      ]),
    );
  }

  Widget _withdrawalSection(BuildContext context, ColorScheme cs, BrokerWalletModel wallet, List<BrokerPayoutAccountModel> accounts) {
    final verifiedAccounts = accounts.where((a) => a.verificationStatus == 'verified').toList();
    final canWithdraw = verifiedAccounts.isNotEmpty && double.tryParse(wallet.availableBalance) != null && double.parse(wallet.availableBalance) > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Uicons.sackDollar, size: 20, color: _mawingaPrimary),
          const SizedBox(width: 8),
          Text('Request withdrawal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
        ]),
        const SizedBox(height: 4),
        Text('Available balance: TSh ${wallet.availableBalance}',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 16),
        if (!canWithdraw) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              Icon(Uicons.circleInfo, size: 24, color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                verifiedAccounts.isEmpty
                    ? 'You need a verified payout account to request withdrawals.'
                    : 'No available balance to withdraw.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ]),
          ),
        ] else
          _withdrawalForm(context, cs, wallet, verifiedAccounts),
      ]),
    );
  }

  Widget _withdrawalForm(BuildContext context, ColorScheme cs, BrokerWalletModel wallet, List<BrokerPayoutAccountModel> verifiedAccounts) {
    String? selectedAccountId = verifiedAccounts.firstWhere((a) => a.isDefault, orElse: () => verifiedAccounts.first).id;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    return StatefulBuilder(builder: (context, setState) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Select verified payout account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedAccountId,
              isExpanded: true,
              items: verifiedAccounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Row(children: [
                  Icon(a.accountType == 'bank' ? Uicons.bank : Uicons.smartphone, size: 16, color: _mawingaPrimary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${a.provider} — ${a.accountNumber}',
                      style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              )).toList(),
              onChanged: (v) => setState(() => selectedAccountId = v),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 8),
        TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixText: 'TSh ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        const SizedBox(height: 14),
        Text('Optional note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 8),
        TextField(
          controller: noteCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Add a note (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (amountCtrl.text.isEmpty) {
                NotificationService().warning('Please enter an amount');
                return;
              }
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null || amount <= 0) {
                NotificationService().warning('Please enter a valid amount');
                return;
              }
              context.read<BrokerCubit>().requestPayout(
                payoutAccountId: selectedAccountId!,
                amount: amountCtrl.text.trim(),
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: _mawingaPrimary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Request payout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]);
    });
  }

  Widget _payoutHistory(ColorScheme cs, List<Map<String, dynamic>> payouts) {
    if (payouts.isEmpty) {
      return _emptyState(cs, Uicons.receipt, 'No payouts yet.', 'Your payout requests will appear here.');
    }

    return Column(children: payouts.map((p) {
      final status = p['status']?.toString() ?? 'pending';
      final amount = p['amount']?.toString() ?? '0';
      final createdAt = p['created_at']?.toString() ?? '';
      final statusColor = {
        'pending': const Color(0xFFF59E0B), 'completed': const Color(0xFF22C55E),
        'rejected': const Color(0xFFEF4444), 'cancelled': const Color(0xFF9CA3AF),
      }[status] ?? const Color(0xFF9CA3AF);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Uicons.sackDollar, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TSh $amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text(_formatDate(createdAt), style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ]),
      );
    }).toList());
  }

  Widget _walletLedger(ColorScheme cs, List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return _emptyState(cs, Uicons.wallet, 'No wallet transactions yet.', 'Commission credits and payouts will appear here.');
    }

    return Column(children: transactions.map((t) {
      final type = t['transaction_type']?.toString() ?? t['type']?.toString() ?? '';
      final amount = t['amount']?.toString() ?? '0';
      final desc = t['description']?.toString() ?? type;
      final createdAt = t['created_at']?.toString() ?? '';
      final isCredit = type.contains('credit') || type.contains('commission');
      final color = isCredit ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(isCredit ? Uicons.arrowTrendUp : Uicons.arrowTrendDown, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(desc, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(_formatDate(createdAt), style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          ])),
          Text('${isCredit ? '+' : '-'}TSh $amount',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ]),
      );
    }).toList());
  }

  Widget _emptyState(ColorScheme cs, IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Icon(icon, size: 36, color: cs.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)), textAlign: TextAlign.center),
      ]),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  void _showAddAccountSheet(BuildContext context, ColorScheme cs) {
    final typeCtrl = ValueNotifier('mobile_money');
    final providerCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface, borderRadius: BorderRadius.circular(24),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('Add Payout Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const SizedBox(height: 16),
            Text('Account type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: typeCtrl,
              builder: (context, type, _) => Row(children: [
                Expanded(child: _accountTypeOption(cs, 'mobile_money', 'Mobile Money', Uicons.smartphone, type == 'mobile_money', () => typeCtrl.value = 'mobile_money')),
                const SizedBox(width: 10),
                Expanded(child: _accountTypeOption(cs, 'bank', 'Bank', Uicons.bank, type == 'bank', () => typeCtrl.value = 'bank')),
              ]),
            ),
            const SizedBox(height: 14),
            _sheetField(cs, 'Provider (e.g. M-Pesa, CRDB)', providerCtrl),
            const SizedBox(height: 12),
            _sheetField(cs, 'Account name', nameCtrl),
            const SizedBox(height: 12),
            _sheetField(cs, 'Account number', numberCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (providerCtrl.text.isEmpty || nameCtrl.text.isEmpty || numberCtrl.text.isEmpty) {
                    NotificationService().warning('Please fill all fields');
                    return;
                  }
                  context.read<BrokerCubit>().createPayoutAccount(
                    accountType: typeCtrl.value,
                    provider: providerCtrl.text.trim(),
                    accountName: nameCtrl.text.trim(),
                    accountNumber: numberCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _mawingaPrimary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _accountTypeOption(ColorScheme cs, String value, String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _mawingaPrimary.withValues(alpha: 0.08) : cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _mawingaPrimary : cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: isSelected ? _mawingaPrimary : cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? _mawingaPrimary : cs.onSurface.withValues(alpha: 0.5))),
        ]),
      ),
    );
  }

  Widget _sheetField(ColorScheme cs, String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    ]);
  }
}
