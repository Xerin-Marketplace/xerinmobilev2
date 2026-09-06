import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../shared/widgets/guest_auth_gate.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import '../../../data/models/cart_model.dart';

class CustomerCartPage extends StatefulWidget {
  const CustomerCartPage({super.key});

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartCubit>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (GuestAuthGate.isGuest) {
      return GuestAuthGate(
        title: 'Sign In to View Cart',
        message: 'Your cart is waiting. Sign in to review items and proceed to checkout.',
        child: const SizedBox.shrink(),
      );
    }

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state is CartLoading || state is CartInitial) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        if (state is CartError) {
          return _buildError(state, colorScheme);
        }

        if (state is CartEmpty) {
          return _buildEmpty(colorScheme);
        }

        if (state is CartLoaded) {
          return _buildCartContent(state.cart, state.isRefreshing, colorScheme);
        }

        return _buildEmpty(colorScheme);
      },
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse products and add them to your cart',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(CartError state, ColorScheme colorScheme) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<CartCubit>().loadCart(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartContent(
      CartModel cart, bool isRefreshing, ColorScheme colorScheme) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'My Cart',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (isRefreshing) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cart.itemCount} items',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: cart.items.map((item) {
                      return _buildCartItem(item, colorScheme);
                    }).toList(),
                  ),
                  if (cart.couponCode != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Coupon: ${cart.couponCode}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.read<CartCubit>().removeCoupon(),
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildCheckoutBar(cart, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item, ColorScheme colorScheme) {
    final imageUrl = item.product?.thumbnailUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.name ?? 'Product',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.formattedTotal,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _quantityButton(
                Icons.remove,
                () => context.read<CartCubit>().updateQuantity(itemId: item.id, quantity: item.quantity - 1),
                colorScheme,
              ),
              const SizedBox(width: 8),
              Text(
                '${item.quantity}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              _quantityButton(
                Icons.add,
                () => context.read<CartCubit>().updateQuantity(itemId: item.id, quantity: item.quantity + 1),
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showItemDetails(CartItemModel item, ColorScheme colorScheme) {
    final product = item.product;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product != null && product.images.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.thumbnailUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: colorScheme.onSurface.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  product?.name ?? 'Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  item.formattedPrice,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text('Qty: ${item.quantity}',
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                if (product?.description != null && product!.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(product.description!,
                    style: TextStyle(fontSize: 13, height: 1.5, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          context.read<CartCubit>().removeItem(item.id);
                          Navigator.pop(context);
                        },
                        child: Text('Remove', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutBar(CartModel cart, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.06))),
      ),
      child: Column(
        children: [
          if (cart.discountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                Text(cart.formattedSubtotal, style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount', style: TextStyle(fontSize: 14, color: colorScheme.primary)),
                Text('- ${cart.formattedDiscount}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.6))),
              Text(cart.formattedTotal, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => context.push(AppConstants.checkoutRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.6)),
    );
  }
}
