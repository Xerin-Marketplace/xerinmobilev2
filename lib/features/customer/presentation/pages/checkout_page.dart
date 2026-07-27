import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/address_model.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/payment_method_model.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _notesController = TextEditingController();
  String? _selectedAddressId;
  String? _selectedPaymentMethodId;
  bool _isPlacing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().loadAll();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'TZS $formatted';
  }

  IconData _paymentIcon(String type) {
    switch (type) {
      case 'mobile_money': return Icons.phone_android_rounded;
      case 'bank': return Icons.account_balance_rounded;
      case 'card': return Icons.credit_card_rounded;
      default: return Icons.payment_rounded;
    }
  }

  Color _paymentColor(String type) {
    switch (type) {
      case 'mobile_money': return const Color(0xFF22C55E);
      case 'bank': return const Color(0xFF3B82F6);
      case 'card': return const Color(0xFFF59E0B);
      default: return const Color(0xFFF47524);
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address'), backgroundColor: Color(0xFFE53935)),
      );
      return;
    }
    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method'), backgroundColor: Color(0xFFE53935)),
      );
      return;
    }

    setState(() => _isPlacing = true);

    final success = await context.read<CustomerCubit>().placeOrder(
      shippingAddressId: _selectedAddressId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isPlacing = false);

    if (success) {
      context.read<CartCubit>().clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Color(0xFF22C55E),
          duration: Duration(seconds: 2),
        ),
      );
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Please try again.'), backgroundColor: Color(0xFFE53935)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartState = context.watch<CartCubit>().state;
    final cartItems = cartState is CartLoaded ? cartState.cart.items : <CartItemModel>[];
    final cartTotal = cartState is CartLoaded ? cartState.cart.total : 0.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            final addresses = state is CustomerLoaded ? state.addresses : <AddressModel>[];
            final paymentMethods = state is CustomerLoaded ? state.paymentMethods : <PaymentMethodModel>[];
            final isLoading = state is CustomerLoading;

            if (isLoading && addresses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_selectedAddressId == null && addresses.isNotEmpty) {
              final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull;
              _selectedAddressId = (defaultAddr ?? addresses.first).id;
            }
            if (_selectedPaymentMethodId == null && paymentMethods.isNotEmpty) {
              final defaultPm = paymentMethods.where((p) => p.isDefault).firstOrNull;
              _selectedPaymentMethodId = (defaultPm ?? paymentMethods.first).id;
            }

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
                      Text('Checkout',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cartItems.isEmpty) ...[
                          const SizedBox(height: 60),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 72, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text('Your cart is empty',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                ),
                                const SizedBox(height: 8),
                                Text('Add items to checkout',
                                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          _buildSectionHeader('Order Items', Icons.shopping_bag_rounded, colorScheme),
                          const SizedBox(height: 12),
                          ...cartItems.map((item) => _buildCartItemCard(item, colorScheme, isDark)),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Delivery Address', Icons.location_on_rounded, colorScheme),
                          const SizedBox(height: 12),
                          if (addresses.isEmpty)
                            _buildEmptyState('No addresses', 'Add an address to continue', Icons.location_off_rounded, colorScheme)
                          else
                            ...addresses.map((addr) => _buildAddressSelector(addr, colorScheme, isDark)),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Payment Method', Icons.payment_rounded, colorScheme),
                          const SizedBox(height: 12),
                          if (paymentMethods.isEmpty)
                            _buildEmptyState('No payment methods', 'Add a payment method to continue', Icons.credit_card_off_rounded, colorScheme)
                          else
                            ...paymentMethods.map((pm) => _buildPaymentSelector(pm, colorScheme, isDark)),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Order Notes (Optional)', Icons.note_outlined, colorScheme),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Any special instructions?',
                              hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Order Summary', Icons.receipt_long_rounded, colorScheme),
                          const SizedBox(height: 12),
                          _buildSummaryCard(cartTotal, colorScheme, isDark),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
                if (cartItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252525) : Colors.white,
                      border: Border(top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.06))),
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isPlacing ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: _isPlacing
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Place Order • ${_formatCurrency(cartTotal)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
      ],
    );
  }

  Widget _buildCartItemCard(CartItemModel item, ColorScheme cs, bool isDark) {
    final imageUrl = item.product?.thumbnailUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_outlined, color: cs.primary.withValues(alpha: 0.4), size: 22)),
                  )
                : Icon(Icons.inventory_2_outlined, color: cs.primary.withValues(alpha: 0.4), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product?.name ?? 'Product', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Qty: ${item.quantity}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Text(item.formattedTotal, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildAddressSelector(AddressModel address, ColorScheme cs, bool isDark) {
    final isSelected = _selectedAddressId == address.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = address.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.03) : (isDark ? const Color(0xFF252525) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.street, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(address.fullAddress, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.3), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSelector(PaymentMethodModel method, ColorScheme cs, bool isDark) {
    final isSelected = _selectedPaymentMethodId == method.id;
    final color = _paymentColor(method.type);

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethodId = method.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.03) : (isDark ? const Color(0xFF252525) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_paymentIcon(method.type), color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.provider, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text('${method.accountName} • ${method.maskedNumber}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.3), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double cartTotal, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', _formatCurrency(cartTotal), cs),
          const SizedBox(height: 8),
          _summaryRow('Shipping', 'TZS 0', cs),
          const SizedBox(height: 8),
          _summaryRow('Tax', 'TZS 0', cs),
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
              Text(_formatCurrency(cartTotal),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
      ],
    );
  }
}
