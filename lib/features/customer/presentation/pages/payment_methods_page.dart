import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/payment_method_model.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().refreshPaymentMethods();
    });
  }

  static const _paymentOptions = [
    _PaymentOption(
      id: 'mobile_money',
      label: 'Mobile Money',
      subtitle: 'Pay securely using your preferred mobile network.',
      icon: Icons.phone_android,
      color: Color(0xFF22C55E),
      providers: ['M-Pesa', 'Airtel Money', 'Mixx by Yas', 'HaloPesa'],
    ),
    _PaymentOption(
      id: 'card',
      label: 'Card Payment',
      subtitle: 'Pay securely using Visa or Mastercard through AzamPay.',
      icon: Icons.credit_card,
      color: Color(0xFFF59E0B),
      providers: ['azampay'],
    ),
  ];

  List<PaymentMethodModel> _filterMethods(List<PaymentMethodModel> all) {
    if (_activeFilter == 'all') return all;
    if (_activeFilter == 'saved') return all;
    return all.where((m) => m.type == _activeFilter).toList();
  }

  List<_PaymentOption> _filterOptions() {
    if (_activeFilter == 'all') return _paymentOptions;
    return _paymentOptions.where((o) => o.id == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(colorScheme, isDark),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colorScheme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<CustomerCubit>().refreshPaymentMethods(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSavedMethodsSection(colorScheme, isDark),
                      if (_activeFilter == 'all' || _activeFilter == 'saved') ...[
                        const SizedBox(height: 28),
                        Text('Available Payment Options',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                        ),
                        const SizedBox(height: 14),
                        ..._filterOptions().map((option) => _buildOptionCard(option, colorScheme, isDark)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, size: 22, color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Text('Payment Methods',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ColorScheme cs, bool isDark) {
    return Drawer(
      child: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          final methods = state is CustomerLoaded ? state.paymentMethods : <PaymentMethodModel>[];
          final mobileCount = methods.where((m) => m.type == 'mobile_money').length;
          final cardCount = methods.where((m) => m.type == 'card').length;
          final bankCount = methods.where((m) => m.type == 'bank').length;

          return Column(
            children: [
              _buildDrawerHeader(cs),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _buildDrawerSectionLabel('Filter by Type', cs),
                    const SizedBox(height: 6),
                    _buildDrawerItem(
                      icon: Icons.list,
                      label: 'All Methods',
                      count: methods.length,
                      color: cs.primary,
                      isSelected: _activeFilter == 'all',
                      onTap: () => _selectFilter('all', cs),
                    ),
                    _buildDrawerItem(
                      icon: Icons.bookmark_border,
                      label: 'Saved Methods',
                      count: methods.length,
                      color: const Color(0xFF8B5CF6),
                      isSelected: _activeFilter == 'saved',
                      onTap: () => _selectFilter('saved', cs),
                    ),
                    _buildDrawerItem(
                      icon: Icons.phone_android,
                      label: 'Mobile Money',
                      count: mobileCount,
                      color: const Color(0xFF22C55E),
                      isSelected: _activeFilter == 'mobile_money',
                      onTap: () => _selectFilter('mobile_money', cs),
                    ),
                    _buildDrawerItem(
                      icon: Icons.credit_card,
                      label: 'Card Payment',
                      count: cardCount,
                      color: const Color(0xFFF59E0B),
                      isSelected: _activeFilter == 'card',
                      onTap: () => _selectFilter('card', cs),
                    ),
                    _buildDrawerItem(
                      icon: Icons.account_balance,
                      label: 'Bank Account',
                      count: bankCount,
                      color: const Color(0xFF3B82F6),
                      isSelected: _activeFilter == 'bank',
                      onTap: () => _selectFilter('bank', cs),
                    ),
                    const SizedBox(height: 20),
                    _buildDrawerSectionLabel('Quick Actions', cs),
                    const SizedBox(height: 6),
                    _buildDrawerActionItem(
                      icon: Icons.security,
                      label: 'Payment Security',
                      color: const Color(0xFF22C55E),
                      onTap: () {},
                    ),
                    _buildDrawerActionItem(
                      icon: Icons.receipt_long,
                      label: 'Transaction History',
                      color: const Color(0xFF3B82F6),
                      onTap: () => context.push('/customer/orders'),
                    ),
                    _buildDrawerActionItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      color: const Color(0xFFF59E0B),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              _buildDrawerFooter(cs),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader(ColorScheme cs) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primary,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Payment Methods',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text('Manage your payment options',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionLabel(String label, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.35), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (count > 0)
                Text('$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      child: Text('Payments are encrypted & secure',
        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
      ),
    );
  }

  void _selectFilter(String filter, ColorScheme cs) {
    setState(() => _activeFilter = filter);
    Navigator.of(context).pop();
  }

  Widget _buildSavedMethodsSection(ColorScheme cs, bool isDark) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        final allMethods = state is CustomerLoaded ? state.paymentMethods : <PaymentMethodModel>[];
        final methods = _filterMethods(allMethods);

        if (allMethods.isEmpty || methods.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(allMethods.isEmpty ? 'No saved payment methods' : 'No methods in this category',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saved Methods',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                Text('${methods.length}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...methods.map((m) => _buildSavedMethodItem(m, cs)),
          ],
        );
      },
    );
  }

  Widget _buildSavedMethodItem(PaymentMethodModel method, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(_typeIcon(method.type), color: _typeColor(method.type), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(method.typeLabel,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      Text('Default',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
                      ),
                    ],
                  ],
                ),
                Text(method.provider,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                Text(method.maskedNumber,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4), fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'mobile_money':
        return const Color(0xFF22C55E);
      case 'card':
        return const Color(0xFFF59E0B);
      case 'bank':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'mobile_money':
        return Icons.phone_android;
      case 'card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.credit_card;
    }
  }

  Widget _buildOptionCard(_PaymentOption option, ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(option.icon, color: option.color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    Text(option.subtitle,
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (option.providers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Available Providers',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: option.providers.map((p) => _buildProviderChip(p, option.color, cs)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderChip(String name, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(name,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _PaymentOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> providers;

  const _PaymentOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.providers,
  });
}
