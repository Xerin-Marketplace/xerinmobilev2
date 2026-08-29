import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/uicons.dart';
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
      icon: Uicons.mobile,
      color: Color(0xFF22C55E),
      providers: ['M-Pesa', 'Airtel Money', 'Mixx by Yas', 'HaloPesa'],
    ),
    _PaymentOption(
      id: 'card',
      label: 'Card Payment',
      subtitle: 'Pay securely using Visa or Mastercard through AzamPay.',
      icon: Uicons.creditCard,
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
      backgroundColor: colorScheme.surface,
      drawer: _buildDrawer(colorScheme, isDark),
      drawerScrimColor: Colors.black54,
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
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Uicons.grid, size: 22, color: cs.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('Payment Methods',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          const Spacer(),
          BlocBuilder<CustomerCubit, CustomerState>(
            builder: (context, state) {
              final count = state is CustomerLoaded ? state.paymentMethods.length : 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$count',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ColorScheme cs, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(0), bottomRight: Radius.circular(0)),
      ),
      width: 300,
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
                      icon: Uicons.grid,
                      label: 'All Methods',
                      count: methods.length,
                      color: cs.primary,
                      isSelected: _activeFilter == 'all',
                      onTap: () => _selectFilter('all', cs),
                    ),
                    _buildDrawerItem(
                      icon: Uicons.bookmark,
                      label: 'Saved Methods',
                      count: methods.length,
                      color: const Color(0xFF8B5CF6),
                      isSelected: _activeFilter == 'saved',
                      onTap: () => _selectFilter('saved', cs),
                    ),
                    _buildDrawerItem(
                      icon: Uicons.mobile,
                      label: 'Mobile Money',
                      count: mobileCount,
                      color: const Color(0xFF22C55E),
                      isSelected: _activeFilter == 'mobile_money',
                      onTap: () => _selectFilter('mobile_money', cs),
                    ),
                    _buildDrawerItem(
                      icon: Uicons.creditCard,
                      label: 'Card Payment',
                      count: cardCount,
                      color: const Color(0xFFF59E0B),
                      isSelected: _activeFilter == 'card',
                      onTap: () => _selectFilter('card', cs),
                    ),
                    _buildDrawerItem(
                      icon: Uicons.bank,
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
                      icon: Uicons.shieldCheck,
                      label: 'Payment Security',
                      color: const Color(0xFF22C55E),
                      onTap: () {},
                    ),
                    _buildDrawerActionItem(
                      icon: Uicons.receipt,
                      label: 'Transaction History',
                      color: const Color(0xFF3B82F6),
                      onTap: () => context.push('/customer/orders'),
                    ),
                    _buildDrawerActionItem(
                      icon: Uicons.circleQuestion,
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
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.15), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Uicons.creditCard, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 12),
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
          Positioned(
            top: 16,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.2),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Uicons.xmark, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isSelected ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
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
              Icon(Uicons.arrowForwardIos, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
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
      child: Row(
        children: [
          Icon(Uicons.lock, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Payments are encrypted & secure',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ),
        ],
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

        if (allMethods.isEmpty && _activeFilter != 'all') {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Uicons.creditCard, color: cs.primary, size: 26),
                ),
                const SizedBox(height: 16),
                Text('No saved payment methods',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text('Your saved payment methods will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          );
        }

        if (methods.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Uicons.filter, color: cs.primary, size: 26),
                ),
                const SizedBox(height: 16),
                Text('No methods in this category',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text('Try selecting a different filter from the sidebar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          );
        }

        if (allMethods.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Uicons.creditCard, color: cs.primary, size: 26),
                ),
                const SizedBox(height: 16),
                Text('No saved payment methods',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text('Your saved payment methods will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
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
            ...methods.map((m) => _buildSavedMethodCard(m, cs, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildSavedMethodCard(PaymentMethodModel method, ColorScheme cs, bool isDark) {
    final color = _typeColor(method.type);
    final icon = _typeIcon(method.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(method.typeLabel,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Default',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(method.provider,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 2),
                  Text(method.maskedNumber,
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4), fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        return Uicons.mobile;
      case 'card':
        return Uicons.creditCard;
      case 'bank':
        return Uicons.accountBalanceWallet;
      default:
        return Uicons.creditCard;
    }
  }

  Widget _buildOptionCard(_PaymentOption option, ColorScheme cs, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: option.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(option.icon, color: option.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.label,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(option.subtitle,
                        style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (option.providers.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
              const SizedBox(height: 14),
              Text('Available Providers',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: option.providers.map((p) => _buildProviderChip(p, option.color, cs)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderChip(String name, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(name,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
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
