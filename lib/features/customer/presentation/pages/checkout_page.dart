import 'dart:ui';

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
  bool _isProcessing = false;
  bool _isFetchingLocation = false;
  String? _locationStatusText;

  String _deliveryMode = 'local';
  bool _isDetectingMode = false;
  Map<String, dynamic>? _detectedMode;

  List<Map<String, dynamic>> _logisticsCompanies = [];
  String? _selectedCompanyId;
  bool _isLoadingLogistics = false;

  List<Map<String, dynamic>> _pricingOptions = [];
  Map<String, dynamic>? _selectedRate;
  bool _isLoadingPricing = false;

  Map<String, dynamic>? _frozenQuote;
  bool _isFreezingQuote = false;

  String? _appliedCouponCode;

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

  double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  double get _shippingAmount {
    if (_frozenQuote != null) return _parsePrice(_frozenQuote!['delivery_amount']);
    if (_selectedRate != null) return _parsePrice(_selectedRate!['delivery_amount']);
    return 0.0;
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
      if (mounted) NotificationService().success('Location acquired successfully');
    } catch (e) {
      setState(() {
        _isFetchingLocation = false;
        _locationStatusText = null;
      });
      if (mounted) NotificationService().error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _detectDeliveryMode() async {
    if (_selectedAddressId == null) return;
    setState(() => _isDetectingMode = true);
    try {
      final result = await context.read<CustomerCubit>().detectDeliveryMode(_selectedAddressId!);
      setState(() {
        _detectedMode = result;
        _isDetectingMode = false;
        final mode = result?['delivery_mode'] as String?;
        if (mode != null && mode != _deliveryMode) {
          _deliveryMode = mode;
          _logisticsCompanies = [];
          _selectedCompanyId = null;
          _pricingOptions = [];
          _selectedRate = null;
          _frozenQuote = null;
        }
      });
      if (mounted && result != null) _fetchEligibleLogistics();
    } catch (e) {
      setState(() => _isDetectingMode = false);
      if (mounted) NotificationService().error('Failed to detect delivery mode: $e');
    }
  }

  Future<void> _fetchEligibleLogistics() async {
    if (_selectedAddressId == null) return;
    setState(() => _isLoadingLogistics = true);
    try {
      final result = await context.read<CustomerCubit>().getEligibleLogistics(
        addressId: _selectedAddressId!,
        deliveryMode: _deliveryMode,
      );
      final companies = <Map<String, dynamic>>[];
      if (result != null) {
        final rawResults = result['results'];
        if (rawResults is List) {
          companies.addAll(rawResults.cast<Map<String, dynamic>>());
        }
      }
      setState(() {
        _logisticsCompanies = companies;
        _isLoadingLogistics = false;
        if (companies.isNotEmpty && _selectedCompanyId == null) {
          _selectedCompanyId = companies.first['logistics_company_id']?.toString();
          _fetchMultiSellerPricing();
        }
      });
    } catch (e) {
      setState(() => _isLoadingLogistics = false);
      if (mounted) NotificationService().error('Failed to load logistics companies: $e');
    }
  }

  Future<void> _fetchMultiSellerPricing() async {
    if (_selectedAddressId == null || _selectedCompanyId == null) return;
    setState(() {
      _isLoadingPricing = true;
      _pricingOptions = [];
      _selectedRate = null;
      _frozenQuote = null;
    });
    try {
      final result = await context.read<CustomerCubit>().getMultiSellerPricing(
        addressId: _selectedAddressId!,
        logisticsCompanyId: _selectedCompanyId!,
        deliveryMode: _deliveryMode,
      );
      final options = <Map<String, dynamic>>[];
      if (result != null) {
        final rawOptions = result['options'];
        if (rawOptions is List) {
          options.addAll(rawOptions.cast<Map<String, dynamic>>());
        }
      }
      setState(() {
        _pricingOptions = options;
        _isLoadingPricing = false;
      });
    } catch (e) {
      setState(() => _isLoadingPricing = false);
      if (mounted) NotificationService().error('Failed to load pricing: $e');
    }
  }

  Future<void> _freezeQuote() async {
    if (_selectedAddressId == null || _selectedCompanyId == null || _selectedRate == null) return;
    final rateId = _selectedRate!['rate_id']?.toString();
    if (rateId == null) return;
    setState(() => _isFreezingQuote = true);
    try {
      final result = await context.read<CustomerCubit>().freezeDeliveryQuote(
        addressId: _selectedAddressId!,
        logisticsCompanyId: _selectedCompanyId!,
        rateId: rateId,
        deliveryMode: _deliveryMode,
      );
      setState(() {
        _frozenQuote = result;
        _isFreezingQuote = false;
      });
    } catch (e) {
      setState(() => _isFreezingQuote = false);
      if (mounted) NotificationService().error('Failed to lock delivery quote: $e');
    }
  }

  void _onCompanyChanged(String companyId) {
    setState(() {
      _selectedCompanyId = companyId;
      _pricingOptions = [];
      _selectedRate = null;
      _frozenQuote = null;
    });
    _fetchMultiSellerPricing();
  }

  void _onRateSelected(Map<String, dynamic> rate) {
    setState(() {
      _selectedRate = rate;
      _frozenQuote = null;
    });
    _freezeQuote();
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      NotificationService().warning('Please select a delivery address');
      return;
    }
    if (_selectedRate == null) {
      NotificationService().warning('Please select a delivery service');
      return;
    }
    if (_frozenQuote == null) {
      NotificationService().warning('Please wait for the delivery quote to lock');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      NotificationService().warning('Please enter your mobile money number');
      return;
    }

    setState(() => _isProcessing = true);

    final cubit = context.read<CustomerCubit>();
    final rateId = _selectedRate!['rate_id']?.toString();
    final quoteId = _frozenQuote!['id']?.toString();

    await cubit.placeOrderAndPay(
      shippingAddressId: _selectedAddressId!,
      shippingRateId: rateId,
      deliveryQuoteId: quoteId,
      deliveryMode: _deliveryMode,
      couponCode: _appliedCouponCode,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      phoneNumber: _phoneController.text.trim(),
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
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            final addresses = state is CustomerLoaded ? state.addresses : <AddressModel>[];
            final isLoading = state is CustomerLoading;

            if (isLoading && addresses.isEmpty) {
              return _buildLoadingState(colorScheme);
            }

            if (_selectedAddressId == null && addresses.isNotEmpty) {
              final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull;
              final addr = defaultAddr ?? addresses.first;
              _selectedAddressId = addr.id;
              if (_recipientNameController.text.isEmpty && addr.recipientName != null) {
                _recipientNameController.text = addr.recipientName!;
              }
              if (_recipientPhoneController.text.isEmpty && addr.recipientPhone != null) {
                _recipientPhoneController.text = addr.recipientPhone!;
              }
              _detectDeliveryMode();
            }

            if (cartItems.isEmpty) {
              return _buildEmptyCart(colorScheme);
            }

            return _buildCheckoutSheet(
              colorScheme,
              isDark,
              cartItems,
              cartTotal,
              addresses,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Column(
      children: [
        _buildHeader(cs),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildEmptyCart(ColorScheme cs) {
    return Column(
      children: [
        _buildHeader(cs),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Uicons.shoppingCart, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text('Your cart is empty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 8),
                Text('Add items to checkout',
                  style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    final cartState = context.watch<CartCubit>().state;
    final itemCount = cartState is CartLoaded ? cartState.cart.items.length : 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          BackIconButton(
            onTap: () => context.pop(),
            color: cs.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Checkout',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$itemCount',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary),
                      ),
                    ),
                  ],
                ),
                Text('Review and complete your order',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSheet(
    ColorScheme cs,
    bool isDark,
    List<CartItemModel> cartItems,
    double cartTotal,
    List<AddressModel> addresses,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      _buildItemsSection(cs, isDark, cartItems),
                      const SizedBox(height: 12),
                      _buildDeliverySection(cs, isDark, addresses),
                      const SizedBox(height: 12),
                      _buildDeliveryModeSection(cs, isDark),
                      const SizedBox(height: 12),
                      _buildLogisticsSection(cs, isDark),
                      const SizedBox(height: 12),
                      _buildPaymentSection(cs, isDark),
                      const SizedBox(height: 12),
                      _buildNotesSection(cs, isDark),
                      const SizedBox(height: 12),
                      _buildSummarySection(cs, isDark, cartTotal),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(cs, isDark, cartTotal),
          ],
        ),
        if (_isProcessing) _buildProcessingOverlay(cs),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    IconData? icon,
    required ColorScheme cs,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildItemsSection(ColorScheme cs, bool isDark, List<CartItemModel> cartItems) {
    return _buildSection(
      title: 'Order Items',
      icon: Uicons.shoppingBag,
      cs: cs,
      isDark: isDark,
      child: Column(
        children: cartItems.map((item) => _buildCartItemRow(item, cs)).toList(),
      ),
    );
  }

  Widget _buildDeliverySection(ColorScheme cs, bool isDark, List<AddressModel> addresses) {
    final selectedAddr = addresses.where((a) => a.id == _selectedAddressId).firstOrNull;
    return _buildSection(
      title: 'Delivery Details',
      icon: Uicons.truckBox,
      cs: cs,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedAddr != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withValues(alpha: 0.15), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Uicons.mapPin, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedAddr.label != null && selectedAddr.label!.isNotEmpty) ...[
                          Text(selectedAddr.label!,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(selectedAddr.street,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(selectedAddr.fullAddress,
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showAddressPicker(cs, isDark, addresses),
              child: Text('Change address',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
              ),
            ),
          ] else if (addresses.isEmpty) ...[
            _buildEmptyState('No addresses', 'Add an address to continue', Uicons.mapMarker, cs)
          ] else ...[
            ...addresses.map((addr) => _buildAddressSelector(addr, cs, isDark)),
          ],
          const SizedBox(height: 16),
          _buildTextField('Recipient Name', _recipientNameController, cs),
          const SizedBox(height: 10),
          _buildTextField('Recipient Phone', _recipientPhoneController, cs, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildUseLocationButton(cs),
          if (_locationStatusText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Uicons.location, color: Color(0xFF22C55E), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Location: $_locationStatusText',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddressPicker(ColorScheme cs, bool isDark, List<AddressModel> addresses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Select Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const SizedBox(height: 16),
              ...addresses.map((addr) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAddressId = addr.id;
                    if (addr.recipientName != null && _recipientNameController.text.isEmpty) {
                      _recipientNameController.text = addr.recipientName!;
                    }
                    if (addr.recipientPhone != null && _recipientPhoneController.text.isEmpty) {
                      _recipientPhoneController.text = addr.recipientPhone!;
                    }
                    _logisticsCompanies = [];
                    _selectedCompanyId = null;
                    _pricingOptions = [];
                    _selectedRate = null;
                    _frozenQuote = null;
                  });
                  _detectDeliveryMode();
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedAddressId == addr.id
                      ? cs.primary.withValues(alpha: 0.04)
                      : (isDark ? const Color(0xFF222222) : cs.surface),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedAddressId == addr.id ? cs.primary : cs.onSurface.withValues(alpha: 0.06),
                      width: _selectedAddressId == addr.id ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Uicons.mapPin, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (addr.label != null && addr.label!.isNotEmpty) ...[
                              Text(addr.label!,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(addr.street,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(addr.fullAddress,
                              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildRadioDot(_selectedAddressId == addr.id, cs.primary),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryModeSection(ColorScheme cs, bool isDark) {
    final isCrossBorder = _deliveryMode == 'international';
    return _buildSection(
      title: 'Delivery Route',
      cs: cs,
      isDark: isDark,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCrossBorder
            ? const Color(0xFF3B82F6).withValues(alpha: 0.06)
            : cs.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCrossBorder
              ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
              : cs.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCrossBorder
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                  : cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCrossBorder ? Uicons.globe : Uicons.mapPin,
                color: isCrossBorder ? const Color(0xFF3B82F6) : cs.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isDetectingMode)
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                        ),
                        const SizedBox(width: 8),
                        Text('Detecting delivery route...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    )
                  else ...[
                    Text(
                      isCrossBorder ? 'International / Cross-border' : 'Domestic / Local',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCrossBorder
                        ? 'Products ship from a different country'
                        : 'All products ship within the same country',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                    if (_detectedMode != null && _detectedMode!['origins'] is List && (_detectedMode!['origins'] as List).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${(_detectedMode!['origins'] as List).length} store route${(_detectedMode!['origins'] as List).length == 1 ? '' : 's'} detected',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsSection(ColorScheme cs, bool isDark) {
    return _buildSection(
      title: 'Delivery Service',
      cs: cs,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingLogistics) ...[
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          ] else if (_logisticsCompanies.isEmpty) ...[
            _buildEmptyState(
              'No logistics available',
              _selectedAddressId == null ? 'Select an address first' : 'No companies cover this route',
              Uicons.truckBox,
              cs,
            ),
          ] else ...[
            Text('Logistics Company',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 10),
            ..._logisticsCompanies.map((company) => _buildLogisticsCompanyCard(company, cs, isDark)),
            if (_selectedCompanyId != null) ...[
              const SizedBox(height: 16),
              Text('Delivery Options',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 10),
              if (_isLoadingPricing)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (_pricingOptions.isEmpty)
                _buildEmptyState('No pricing available', 'Try another logistics company', Uicons.wallet, cs)
              else
                ..._pricingOptions.map((option) => _buildPricingOption(option, cs, isDark)),
              if (_frozenQuote != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Uicons.badgeCheck, color: Color(0xFF22C55E), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Delivery quote locked',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedRate != null && _isFreezingQuote)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLogisticsCompanyCard(Map<String, dynamic> company, ColorScheme cs, bool isDark) {
    final isSelected = _selectedCompanyId == company['logistics_company_id']?.toString();
    final name = company['name'] as String? ?? 'Logistics Company';
    final coveredSellers = company['covered_seller_count'] as int? ?? 0;
    final totalSellers = company['seller_count'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _onCompanyChanged(company['logistics_company_id']?.toString() ?? ''),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.04) : (isDark ? const Color(0xFF222222) : cs.surface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Uicons.truckBox, color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.4), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? cs.primary : cs.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text('Covers $coveredSellers of $totalSellers sellers',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            _buildRadioDot(isSelected, cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingOption(Map<String, dynamic> option, ColorScheme cs, bool isDark) {
    final isSelected = _selectedRate?['rate_id'] == option['rate_id'];
    final methodName = option['method_name'] as String? ?? 'Delivery';
    final amount = _parsePrice(option['delivery_amount']);
    final minDays = option['min_delivery_days'] as int? ?? 1;
    final maxDays = option['max_delivery_days'] as int? ?? 7;
    final isFree = amount == 0;

    return GestureDetector(
      onTap: () => _onRateSelected(option),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.04) : (isDark ? const Color(0xFF222222) : cs.surface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(methodName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? cs.primary : cs.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text('$minDays-$maxDays business days',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(isFree ? 'FREE' : _formatCurrency(amount),
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: isFree ? const Color(0xFF22C55E) : cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            _buildRadioDot(isSelected, cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(ColorScheme cs, bool isDark) {
    return _buildSection(
      title: 'Payment Method',
      cs: cs,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Uicons.mobile, color: Color(0xFF22C55E), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mobile Money',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF22C55E)),
                      ),
                      const SizedBox(height: 2),
                      Text('Pay via M-Pesa, Airtel Money, HaloPesa or Mixx',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                const Icon(Uicons.badgeCheck, color: Color(0xFF22C55E), size: 20),
              ],
            ),
          ),
          _buildPhoneInput(cs),
        ],
      ),
    );
  }

  Widget _buildNotesSection(ColorScheme cs, bool isDark) {
    return _buildSection(
      title: 'Order Notes',
      icon: Uicons.note,
      cs: cs,
      isDark: isDark,
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Any special instructions for delivery...',
          hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
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
      ),
    );
  }

  Widget _buildSummarySection(ColorScheme cs, bool isDark, double cartTotal) {
    return _buildSection(
      title: 'Order Summary',
      icon: Uicons.receipt,
      cs: cs,
      isDark: isDark,
      child: _buildSummaryContent(cartTotal, cs),
    );
  }

  Widget _buildBottomBar(ColorScheme cs, bool isDark, double cartTotal) {
    final total = cartTotal + _shippingAmount;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Uicons.shield, size: 16, color: cs.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text('Secure Payment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                Text(_formatCurrency(total),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          Text('Pay ${_formatCurrency(total)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
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

  Widget _buildProcessingOverlay(ColorScheme cs) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
                const SizedBox(height: 24),
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
      ),
      ),
    );
  }

  Widget _buildSummaryContent(double cartTotal, ColorScheme cs) {
    final shipping = _shippingAmount;
    final discount = cartTotal - (context.read<CartCubit>().state is CartLoaded ? (context.read<CartCubit>().state as CartLoaded).cart.total : cartTotal);
    final grandTotal = cartTotal + shipping - (discount > 0 ? discount : 0);
    return Column(
      children: [
        _summaryRow('Subtotal', _formatCurrency(cartTotal), cs),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _summaryRow('Discount', '- ${_formatCurrency(discount)}', cs, color: const Color(0xFF22C55E)),
        ],
        const SizedBox(height: 8),
        _summaryRow('Shipping', _selectedRate == null ? 'Select a service' : _formatCurrency(shipping), cs),
        const SizedBox(height: 8),
        _summaryRow('Tax', 'Included', cs),
        const SizedBox(height: 12),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text(_formatCurrency(grandTotal),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Money Number',
            labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            hintText: 'e.g. 0712345678',
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
            prefixIcon: const Icon(Uicons.phone, size: 20),
            prefixText: '+255 ',
            prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
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
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Uicons.circleInfo, color: Color(0xFF22C55E), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Enter your mobile money number. We\'ll detect the provider automatically.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ],
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
                width: 20,
                height: 20,
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
            width: 48,
            height: 48,
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

  Widget _buildRadioDot(bool isSelected, Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.2), width: 2),
      ),
      child: isSelected
          ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)))
          : null,
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
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
      onTap: () {
        setState(() {
          _selectedAddressId = address.id;
          _logisticsCompanies = [];
          _selectedCompanyId = null;
          _pricingOptions = [];
          _selectedRate = null;
          _frozenQuote = null;
        });
        _detectDeliveryMode();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.04) : (isDark ? const Color(0xFF222222) : cs.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
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
            _buildRadioDot(isSelected, cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme cs, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? cs.onSurface)),
      ],
    );
  }
}
