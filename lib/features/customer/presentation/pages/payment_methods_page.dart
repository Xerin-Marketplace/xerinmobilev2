import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../../../../core/theme/uicons.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

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
    _PaymentOption(
      id: 'cash_on_delivery',
      label: 'Cash on Delivery',
      subtitle: 'Pay when the logistics company delivers your local order.',
      icon: Uicons.shippingFast,
      color: Color(0xFF3B82F6),
      providers: [],
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
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                itemCount: _paymentOptions.length,
                itemBuilder: (context, index) {
                  final option = _paymentOptions[index];
                  return _buildOptionCard(option, colorScheme, isDark);
                },
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
