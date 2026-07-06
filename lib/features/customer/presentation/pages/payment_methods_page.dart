import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../../data/models/payment_method_model.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final List<PaymentMethodModel> _methods = [];

  @override
  void initState() {
    super.initState();
    _methods.addAll(_sampleMethods);
  }

  void _deleteMethod(PaymentMethodModel method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: Text('Remove ${method.provider} ${method.maskedNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() => _methods.remove(method));
    }
  }

  void _showAddSheet() {
    final providerCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    String selectedType = 'mobile_money';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Add Payment Method',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 20),
                Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _typeChip('Mobile Money', 'mobile_money', selectedType, cs, (v) => setSheetState(() => selectedType = v)),
                    const SizedBox(width: 10),
                    _typeChip('Bank Account', 'bank', selectedType, cs, (v) => setSheetState(() => selectedType = v)),
                    const SizedBox(width: 10),
                    _typeChip('Card', 'card', selectedType, cs, (v) => setSheetState(() => selectedType = v)),
                  ],
                ),
                const SizedBox(height: 16),
                _sheetField('Provider (e.g. M-Pesa, CRDB)', providerCtrl, cs),
                const SizedBox(height: 12),
                _sheetField('Account Name', nameCtrl, cs),
                const SizedBox(height: 12),
                _sheetField('Account Number', numberCtrl, cs, keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (providerCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty && numberCtrl.text.isNotEmpty) {
                        final method = PaymentMethodModel(
                          id: DateTime.now().toString(),
                          type: selectedType,
                          provider: providerCtrl.text.trim(),
                          accountName: nameCtrl.text.trim(),
                          accountNumber: numberCtrl.text.trim(),
                          isDefault: _methods.isEmpty,
                        );
                        setState(() => _methods.add(method));
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary, foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Add Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _typeChip(String label, String value, String selected, ColorScheme cs, ValueChanged<String> onTap) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController controller, ColorScheme cs, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  BackIconButton(
                    onTap: () => context.pop(),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text('Payment Methods',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            if (_methods.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card_off_rounded, size: 72, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('No payment methods',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text('Add a payment method for faster checkout',
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _methods.length,
                  itemBuilder: (context, index) {
                    final method = _methods[index];
                    return _buildMethodCard(method, colorScheme);
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethodModel method, ColorScheme colorScheme) {
    IconData icon;
    Color color;
    switch (method.type) {
      case 'mobile_money':
        icon = Icons.phone_android_rounded;
        color = const Color(0xFF22C55E);
        break;
      case 'bank':
        icon = Icons.account_balance_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case 'card':
        icon = Icons.credit_card_rounded;
        color = const Color(0xFFF59E0B);
        break;
      default:
        icon = Icons.payment_rounded;
        color = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: method.isDefault
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
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
                    Row(
                      children: [
                        Text(method.provider,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                        ),
                        if (method.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${method.accountName} • ${method.maskedNumber}',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded,
                color: method.isDefault ? colorScheme.primary : Colors.transparent,
                size: 22,
              ),
            ],
          ),
          if (method.typeLabel == 'Card' && method.expiryDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Expires: ${method.expiryDate}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.06)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _deleteMethod(method),
                icon: Icon(Icons.delete_outline_rounded, size: 16, color: const Color(0xFFE53935)),
                label: Text('Remove', style: TextStyle(fontSize: 12, color: const Color(0xFFE53935))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<PaymentMethodModel> _sampleMethods = [
    PaymentMethodModel(id: '1', type: 'mobile_money', provider: 'M-Pesa', accountName: 'John Doe', accountNumber: '0712345678', isDefault: true),
    PaymentMethodModel(id: '2', type: 'mobile_money', provider: 'Tigo Pesa', accountName: 'John Doe', accountNumber: '0612345678'),
    PaymentMethodModel(id: '3', type: 'bank', provider: 'CRDB Bank', accountName: 'John Doe', accountNumber: '0151234567890'),
    PaymentMethodModel(id: '4', type: 'card', provider: 'Visa', accountName: 'John Doe', accountNumber: '4111111111111111', expiryDate: '12/27'),
  ];
}
