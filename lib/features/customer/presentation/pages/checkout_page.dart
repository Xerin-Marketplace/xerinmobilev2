import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/address_model.dart';
import '../../data/models/cart_model.dart';
import '../../../../core/theme/uicons.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  String? _selectedAddressId;
  String _selectedPaymentMethod = 'mobile_money';
  String _selectedMnoProvider = 'mpesa';
  bool _isProcessing = false;
  bool _isFetchingLocation = false;
  String? _locationStatusText;

  static const _mnoProviders = [
    {'value': 'mpesa', 'label': 'M-Pesa', 'color': Color(0xFFE53935), 'short': 'M-PESA'},
    {'value': 'airtel', 'label': 'Airtel Money', 'color': Color(0xFFE53935), 'short': 'AIRTEL'},
    {'value': 'tigo', 'label': 'Tigo Pesa', 'color': Color(0xFF0066B3), 'short': 'TIGO'},
    {'value': 'halopesa', 'label': 'Halo Pesa', 'color': Color(0xFF00A651), 'short': 'HALO'},
    {'value': 'azampesa', 'label': 'Azam Pesa', 'color': Color(0xFFE94B1B), 'short': 'AZAM'},
  ];

  static const _paymentTypes = [
    {'value': 'mobile_money', 'label': 'Mobile Money', 'icon': Uicons.mobile, 'color': Color(0xFF22C55E), 'subtitle': 'Pay via MNO'},
    {'value': 'card', 'label': 'Card', 'icon': Uicons.creditCard, 'color': Color(0xFFF59E0B), 'subtitle': 'Visa / Mastercard'},
    {'value': 'cash_on_delivery', 'label': 'Cash on Delivery', 'icon': Uicons.shippingFast, 'color': Color(0xFF3B82F6), 'subtitle': 'Pay on arrival'},
  ];

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
    _phoneController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'TZS $formatted';
  }

  Future<void> _acquireLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationStatusText = null;
    });
    try {
      final location = await GetIt.instance<LocationService>().getCurrentLocation();
      setState(() {
        _isFetchingLocation = false;
        _locationStatusText = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
      });
      if (mounted) {
        NotificationService().success('Location acquired successfully');
      }
    } catch (e) {
      setState(() {
        _isFetchingLocation = false;
        _locationStatusText = null;
      });
      if (mounted) {
        NotificationService().error(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      NotificationService().warning('Please select a delivery address');
      return;
    }

    if (_selectedPaymentMethod == 'mobile_money' && _phoneController.text.trim().isEmpty) {
      NotificationService().warning('Please enter your phone number');
      return;
    }

    setState(() => _isProcessing = true);

    final cubit = context.read<CustomerCubit>();

    await cubit.placeOrderAndPay(
      shippingAddressId: _selectedAddressId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      provider: _selectedPaymentMethod == 'mobile_money' ? _selectedMnoProvider : null,
      phoneNumber: _selectedPaymentMethod == 'mobile_money' ? _phoneController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final state = cubit.state;

    if (state is PaymentFailed) {
      NotificationService().error(state.message);
      return;
    }

    if (state is PaymentSuccess) {
      context.read<CartCubit>().clearCart();
      NotificationService().success('Order placed successfully!');

      if (state.checkoutUrl != null) {
        context.go('/payment-processing?payment_id=${state.paymentId}&order_id=${state.orderId}&checkout_url=${Uri.encodeComponent(state.checkoutUrl!)}');
      } else if (state.paymentId.isNotEmpty) {
        context.go('/payment-processing?payment_id=${state.paymentId}&order_id=${state.orderId}');
      } else {
        context.go('/');
      }
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
            final isLoading = state is CustomerLoading;

            if (isLoading && addresses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_selectedAddressId == null && addresses.isNotEmpty) {
              final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull;
              _selectedAddressId = (defaultAddr ?? addresses.first).id;
            }

            return Stack(
              children: [
                Column(
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
                                    Icon(Uicons.shoppingCart, size: 72, color: colorScheme.onSurface.withValues(alpha: 0.2)),
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
                              // Order Items
                              _buildSectionCard(
                                title: 'Order Items',
                                icon: Uicons.shoppingBag,
                                cs: colorScheme,
                                child: Column(
                                  children: cartItems.map((item) => _buildCartItemRow(item, colorScheme)).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Delivery Details
                              _buildSectionCard(
                                title: 'Delivery Details',
                                icon: Uicons.truckBox,
                                cs: colorScheme,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Recipient info
                                    _buildTextField('Recipient Name', _recipientNameController, colorScheme),
                                    const SizedBox(height: 10),
                                    _buildTextField('Recipient Phone', _recipientPhoneController, colorScheme,
                                        keyboardType: TextInputType.phone),
                                    const SizedBox(height: 16),

                                    // Address selection
                                    Text('Select Address',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                                    ),
                                    const SizedBox(height: 10),
                                    if (addresses.isEmpty)
                                      _buildEmptyState('No addresses', 'Add an address to continue', Uicons.mapMarker, colorScheme)
                                    else
                                      ...addresses.map((addr) => _buildAddressSelector(addr, colorScheme, isDark)),

                                    const SizedBox(height: 16),

                                    // Use Current Location
                                    _buildUseLocationButton(colorScheme),
                                    if (_locationStatusText != null) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E).withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Uicons.location, color: Color(0xFF22C55E), size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text('GPS: $_locationStatusText',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF22C55E)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Payment Method
                              _buildSectionCard(
                                title: 'Payment Method',
                                icon: Uicons.creditCard,
                                cs: colorScheme,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ..._paymentTypes.map((type) => _buildPaymentOption(type, colorScheme, isDark)),
                                    if (_selectedPaymentMethod == 'mobile_money') ...[
                                      const SizedBox(height: 16),
                                      Text('Select Provider',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildMnoProviderGrid(colorScheme, isDark),
                                      const SizedBox(height: 16),
                                      _buildPhoneInput(colorScheme),
                                    ],
                                    if (_selectedPaymentMethod == 'card') ...[
                                      const SizedBox(height: 12),
                                      _buildCardInfoBanner(colorScheme),
                                    ],
                                    if (_selectedPaymentMethod == 'cash_on_delivery') ...[
                                      const SizedBox(height: 12),
                                      _buildCodInfoBanner(colorScheme),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Order Notes
                              _buildSectionCard(
                                title: 'Order Notes',
                                icon: Uicons.note,
                                cs: colorScheme,
                                child: TextField(
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
                              ),
                              const SizedBox(height: 16),

                              // Order Summary
                              _buildSectionCard(
                                title: 'Order Summary',
                                icon: Uicons.receipt,
                                cs: colorScheme,
                                child: _buildSummaryContent(cartTotal, colorScheme),
                              ),
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
                            height: 56,
                            child: _buildPlaceOrderButton(colorScheme, cartTotal),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_isProcessing)
                  _buildProcessingOverlay(colorScheme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton(ColorScheme cs, double cartTotal) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _placeOrder,
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: _isProcessing
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Processing...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Uicons.lock, size: 18),
                const SizedBox(width: 8),
                Text('Pay ${_formatCurrency(cartTotal)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
    );
  }

  Widget _buildProcessingOverlay(ColorScheme cs) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: 20),
              Text('Processing Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Text('Please wait while we confirm your payment...',
                style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMnoProviderGrid(ColorScheme cs, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.8,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: _mnoProviders.map((provider) {
        final isSelected = _selectedMnoProvider == provider['value'];
        final color = provider['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _selectedMnoProvider = provider['value'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.08) : (isDark ? const Color(0xFF1E1E1E) : cs.surface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : cs.onSurface.withValues(alpha: 0.08),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(height: 6),
                Text(provider['short'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryContent(double cartTotal, ColorScheme cs) {
    return Column(
      children: [
        _summaryRow('Subtotal', _formatCurrency(cartTotal), cs),
        const SizedBox(height: 8),
        _summaryRow('Shipping', 'Calculated at checkout', cs),
        const SizedBox(height: 8),
        _summaryRow('Tax', 'Included', cs),
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Uicons.shield, color: cs.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buyer Protection',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary),
                    ),
                    const SizedBox(height: 2),
                    Text('Your payment is held securely until you confirm delivery.',
                      style: TextStyle(fontSize: 11, height: 1.4, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput(ColorScheme cs) {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        hintText: 'e.g. 0712345678',
        hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
        prefixIcon: const Icon(Uicons.phone, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildCardInfoBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Uicons.circleInfo, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('You will be redirected to AzamPay\'s secure checkout page to enter your card details.',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodInfoBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Uicons.shippingFast, color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Pay with cash when your order is delivered. Please have the exact amount ready.',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ColorScheme cs,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.brightness == Brightness.dark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, ColorScheme cs, {TextInputType? keyboardType}) {
    return TextField(
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildUseLocationButton(ColorScheme cs) {
    return GestureDetector(
      onTap: _isFetchingLocation ? null : _acquireLocation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isFetchingLocation)
              SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.9)),
                ),
              )
            else
              const Icon(Uicons.location, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              _isFetchingLocation ? 'Detecting location...' : 'Use My Current Location',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemRow(CartItemModel item, ColorScheme cs) {
    final imageUrl = item.product?.thumbnailUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                      errorBuilder: (_, __, ___) => Icon(Uicons.box, color: cs.primary.withValues(alpha: 0.4), size: 22)),
                  )
                : Icon(Uicons.box, color: cs.primary.withValues(alpha: 0.4), size: 22),
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

  Widget _buildPaymentOption(Map<String, dynamic> type, ColorScheme cs, bool isDark) {
    final isSelected = _selectedPaymentMethod == type['value'];
    final color = type['color'] as Color;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = type['value'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : (isDark ? const Color(0xFF1E1E1E) : cs.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : cs.onSurface.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(type['icon'] as IconData, color: isSelected ? color : cs.onSurface.withValues(alpha: 0.4), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type['label'] as String,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isSelected ? color : cs.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(type['subtitle'] as String,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? color : cs.onSurface.withValues(alpha: 0.2), width: 2),
              ),
              child: isSelected
                  ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)))
                  : null,
            ),
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

  Widget _buildAddressSelector(AddressModel address, ColorScheme cs, bool isDark) {
    final isSelected = _selectedAddressId == address.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = address.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.03) : (isDark ? const Color(0xFF1E1E1E) : cs.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
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
              child: const Icon(Uicons.mapPin, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (address.label != null && address.label!.isNotEmpty) ...[
                    Text(address.label!,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(address.street, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(address.fullAddress, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.2), width: 2),
              ),
              child: isSelected
                  ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)))
                  : null,
            ),
          ],
        ),
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
