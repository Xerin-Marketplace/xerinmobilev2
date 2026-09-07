import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../shared/widgets/guest_auth_gate.dart';
import '../../../../../core/currency/currency_cubit.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import '../../utils/price_formatter.dart';
import '../../../data/models/cart_model.dart';

class CustomerCartPage extends StatefulWidget {
  const CustomerCartPage({super.key});

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  final _promoCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();
  bool _applyingPromo = false;
  bool _applyingCoupon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartCubit>().loadCart();
      }
    });
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (GuestAuthGate.isGuest) {
      return GuestAuthGate(
        title: 'Sign In to View Cart',
        message: 'Your cart is waiting. Sign in to review items and proceed to checkout.',
        child: const SizedBox.shrink(),
      );
    }

    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (context, currencyState) {
        return BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            if (state is CartLoading || state is CartInitial) {
              return Center(child: CircularProgressIndicator(color: cs.primary));
            }
            if (state is CartError) {
              return _buildError(state, cs);
            }
            if (state is CartEmpty) {
              return _buildEmpty(cs);
            }
            if (state is CartLoaded) {
              return _buildCartContent(state.cart, state.isRefreshing, cs, currencyState);
            }
            return _buildEmpty(cs);
          },
        );
      },
    );
  }

  // ===================== EMPTY =====================

  Widget _buildEmpty(ColorScheme cs) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 56, color: cs.onSurface.withValues(alpha: 0.15)),
              const SizedBox(height: 16),
              Text('Your cart is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 4),
              Text('Browse products and add them to your cart', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary, elevation: 0),
                child: const Text('Browse Products'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== ERROR =====================

  Widget _buildError(CartError state, ColorScheme cs) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 40, color: cs.error.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(state.message.replaceAll('ServerException: ', ''), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<CartCubit>().loadCart(),
                style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== CART CONTENT =====================

  Widget _buildCartContent(CartModel cart, bool isRefreshing, ColorScheme cs, CurrencyState currencyState) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<CartCubit>().loadCart(),
        color: cs.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title
            Text('Cart & Promotions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text('Prices and stock are revalidated by the backend before checkout.',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: isRefreshing
                      ? CircularProgressIndicator(strokeWidth: 2, color: cs.primary)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Currency selector
            _buildCurrencyBar(cs, currencyState),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRefreshing ? null : () => context.read<CartCubit>().validateCart(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh Price & Stock', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmClearCart(cs),
                    icon: Icon(Icons.delete_sweep_outlined, size: 16, color: cs.error),
                    label: Text('Clear Cart', style: TextStyle(fontSize: 12, color: cs.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cart items
            ...cart.items.map((item) => _buildCartItem(item, cs)),

            // Validation messages
            if (cart.validationMessages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_outlined, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          const Text('Validation notices', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...cart.validationMessages.map((msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('• $msg', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                      )),
                    ],
                  ),
                ),
              )
            else
              const SizedBox.shrink(),

            const SizedBox(height: 20),

            // Seller Promotions
            _buildSectionCard(
              cs,
              icon: Icons.local_offer_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Seller Promotions',
              subtitle: 'Seller-funded discounts apply only to eligible products. Xerin marketplace commission remains separate from the seller discount.',
              child: cart.promotionCode != null
                  ? _buildActiveCode(cs, cart.promotionCode!, 'promotion', () => context.read<CartCubit>().removePromotion())
                  : _buildCodeInput(cs, _promoCtrl, 'Enter seller promo code', 'Apply Promotion', _applyingPromo, (code) async {
                      setState(() => _applyingPromo = true);
                      await context.read<CartCubit>().applyPromotion(code);
                      if (mounted) setState(() => _applyingPromo = false);
                      _promoCtrl.clear();
                    }),
            ),

            const SizedBox(height: 12),

            // Platform Coupon
            _buildSectionCard(
              cs,
              icon: Icons.confirmation_num_outlined,
              iconColor: const Color(0xFF3B82F6),
              title: 'Platform Coupon',
              subtitle: 'Platform/admin coupons are separate from seller-funded promotions.',
              child: cart.couponCode != null
                  ? _buildActiveCode(cs, cart.couponCode!, 'coupon', () => context.read<CartCubit>().removeCoupon())
                  : _buildCodeInput(cs, _couponCtrl, 'Enter platform coupon code', 'Apply Coupon', _applyingCoupon, (code) async {
                      setState(() => _applyingCoupon = true);
                      await context.read<CartCubit>().applyCoupon(code);
                      if (mounted) setState(() => _applyingCoupon = false);
                      _couponCtrl.clear();
                    }),
            ),

            const SizedBox(height: 20),

            // Order Summary
            _buildOrderSummary(cart, cs),

            const SizedBox(height: 16),

            // Continue to Delivery
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppConstants.checkoutRoute),
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('Continue to Delivery', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
              ],
            ),
          ),
        ),
    );
  }

  // ===================== CART ITEM =====================

  Widget _buildCartItem(CartItemModel item, ColorScheme cs) {
    final imageUrl = item.product?.thumbnailUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(width: 48, height: 48, color: cs.onSurface.withValues(alpha: 0.06)))
                      : Container(width: 48, height: 48, color: cs.onSurface.withValues(alpha: 0.06), child: Icon(Icons.image_outlined, size: 20, color: cs.onSurface.withValues(alpha: 0.2))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product?.name ?? 'Product',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('Backend-priced cart item',
                        style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Price + qty + subtotal
            Row(
              children: [
                // Customer price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Price', style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.3))),
                      Text(PriceFormatter.format(context, item.unitPrice, approximate: true), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    ],
                  ),
                ),
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _qtyBtn(Icons.remove, () => context.read<CartCubit>().updateQuantity(itemId: item.id, quantity: item.quantity - 1), cs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('${item.quantity}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                      ),
                      _qtyBtn(Icons.add, () => context.read<CartCubit>().updateQuantity(itemId: item.id, quantity: item.quantity + 1), cs),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Subtotal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Subtotal', style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.3))),
                      Text(PriceFormatter.format(context, item.unitPrice * item.quantity, approximate: true), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Remove
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.read<CartCubit>().removeItem(item.id),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14, color: cs.error),
                    const SizedBox(width: 4),
                    Text('Remove', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.error)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
      ),
    );
  }

  // ===================== SECTION CARD =====================

  Widget _buildSectionCard(
    ColorScheme cs, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface))),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4), height: 1.4)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // ===================== CODE INPUT =====================

  Widget _buildCodeInput(
    ColorScheme cs,
    TextEditingController ctrl,
    String hint,
    String buttonLabel,
    bool isApplying,
    Future<void> Function(String) onApply,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: ElevatedButton(
          onPressed: isApplying ? null : () {
            final code = ctrl.text.trim();
            if (code.isEmpty) return;
            onApply(code);
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: isApplying
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(buttonLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
          ),
        ),
      ],
    );
  }

  // ===================== ACTIVE CODE =====================

  Widget _buildActiveCode(ColorScheme cs, String code, String type, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: const Color(0xFF22C55E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$code applied', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E))),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Text('Remove', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.error)),
          ),
        ],
      ),
    );
  }

  // ===================== ORDER SUMMARY =====================

  Widget _buildOrderSummary(CartModel cart, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Order Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Backend-calculated totals', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
            const SizedBox(height: 14),
            // Product subtotal
            _summaryRow(cs, 'Product subtotal', PriceFormatter.format(context, cart.subtotal, approximate: true)),
            if (cart.promotionDiscountAmount > 0)
              _summaryRow(cs, 'Seller promotion', '- ${PriceFormatter.format(context, cart.promotionDiscountAmount, approximate: true)}', isDiscount: true),
            if (cart.couponDiscountAmount > 0)
              _summaryRow(cs, 'Coupon discount', '- ${PriceFormatter.format(context, cart.couponDiscountAmount, approximate: true)}', isDiscount: true),
            const Divider(height: 20),
            // Cart total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cart total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                Text(PriceFormatter.format(context, cart.total, approximate: true), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary)),
              ],
            ),
            const SizedBox(height: 10),
            // Shipping note
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Shipping is calculated at delivery selection.',
                      style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(ColorScheme cs, String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isDiscount ? FontWeight.w600 : FontWeight.w500, color: isDiscount ? const Color(0xFF22C55E) : cs.onSurface)),
        ],
      ),
    );
  }

  // ===================== CURRENCY BAR =====================

  Widget _buildCurrencyBar(ColorScheme cs, CurrencyState state) {
    final currencies = state is CurrencyLoaded ? state.currencies : <DisplayCurrencyModel>[];
    final selectedCode = state is CurrencyLoaded ? state.selectedCurrency : 'TZS';
    final selected = currencies.where((c) => c.code == selectedCode).firstOrNull;
    final symbol = selected?.symbol ?? 'TSh';
    final name = selected?.name ?? 'Tanzanian Shilling';
    final isBase = selected?.isBase ?? true;

    return GestureDetector(
      onTap: currencies.isEmpty ? null : () => _showCurrencyPicker(context, currencies, selectedCode, cs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.currency_exchange, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display Currency',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                  Text('$symbol $name',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                ],
              ),
            ),
            if (!isBase)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Converted',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            Icon(Icons.expand_more, size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, List<DisplayCurrencyModel> currencies, String selected, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Select Currency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const SizedBox(height: 4),
              Text('Prices will be converted from TZS using backend rates',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 12),
              ...currencies.map((c) {
                final isSelected = c.code == selected;
                return ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(c.symbol,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? cs.primary : cs.onSurface),
                      ),
                    ),
                  ),
                  title: Text(c.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  subtitle: Text('${c.code} · 1 TZS = ${c.rateToTzs > 0 ? (1 / c.rateToTzs).toStringAsFixed(c.decimalPlaces) : '1.0'} ${c.code}'),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: cs.primary, size: 22)
                      : null,
                  onTap: () {
                    context.read<CurrencyCubit>().selectCurrency(c.code);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ===================== CLEAR CART CONFIRM =====================

  void _confirmClearCart(ColorScheme cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?', style: TextStyle(fontSize: 16)),
        content: Text('This will remove all items from your cart.', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CartCubit>().clearCart();
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
