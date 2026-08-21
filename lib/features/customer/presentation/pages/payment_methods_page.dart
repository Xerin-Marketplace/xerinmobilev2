import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/payment_method_model.dart';
import '../../../../core/theme/uicons.dart';

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
      context.read<CustomerCubit>().deletePaymentMethod(method.id);
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
                        Navigator.pop(ctx);
                        context.read<CustomerCubit>().addPaymentMethod(
                          type: selectedType,
                          provider: providerCtrl.text.trim(),
                          accountName: nameCtrl.text.trim(),
                          accountNumber: numberCtrl.text.trim(),
                          isDefault: false,
                        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            final methods = state is CustomerLoaded ? state.paymentMethods : <PaymentMethodModel>[];
            final isLoading = state is CustomerLoading;

            return Column(
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
                if (isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (methods.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Uicons.creditCardXmark, size: 72, color: colorScheme.onSurface.withValues(alpha: 0.2)),
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
                      itemCount: methods.length,
                      itemBuilder: (context, index) {
                        final method = methods[index];
                        return _buildMethodCard(method, colorScheme, isDark);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: colorScheme.primary,
        child: const Icon(Uicons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethodModel method, ColorScheme colorScheme, bool isDark) {
    IconData icon;
    Color color;
    switch (method.type) {
      case 'mobile_money':
        icon = Uicons.mobile;
        color = const Color(0xFF22C55E);
        break;
      case 'bank':
        icon = Uicons.accountBalance;
        color = const Color(0xFF3B82F6);
        break;
      case 'card':
        icon = Uicons.creditCard;
        color = const Color(0xFFF59E0B);
        break;
      default:
        icon = Uicons.creditCard;
        color = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: method.isDefault
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.onSurface.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
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
              Icon(Uicons.checkCircle,
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
                icon: Icon(Uicons.trash, size: 16, color: const Color(0xFFE53935)),
                label: Text('Remove', style: TextStyle(fontSize: 12, color: const Color(0xFFE53935))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
