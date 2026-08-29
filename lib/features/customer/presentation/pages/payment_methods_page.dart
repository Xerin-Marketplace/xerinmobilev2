import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                      const SizedBox(height: 28),
                      Text('Available Payment Options',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: 14),
                      ..._paymentOptions.map((option) => _buildOptionCard(option, colorScheme, isDark)),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          BackIconButton(
            onTap: () => context.pop(),
            color: cs.primary,
          ),
          const SizedBox(width: 16),
          Text('Payment Methods',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ],
      ),
    );
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

        final methods = state is CustomerLoaded ? state.paymentMethods : <PaymentMethodModel>[];

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
