import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/helpers.dart';
import '../cubit/customer_cubit.dart';

class PaymentProcessingPage extends StatefulWidget {
  final String? paymentId;
  final String? orderId;
  final String? checkoutUrl;

  const PaymentProcessingPage({
    super.key,
    this.paymentId,
    this.orderId,
    this.checkoutUrl,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

enum _PaymentUIState { processing, success, failed }

class _PaymentProcessingPageState extends State<PaymentProcessingPage>
    with TickerProviderStateMixin {
  _PaymentUIState _uiState = _PaymentUIState.processing;
  String _statusMessage = 'Confirming your payment...';
  Timer? _pollTimer;
  int _attempts = 0;
  static const int _maxAttempts = 30;
  bool _isRetrying = false;

  late AnimationController _successController;
  late AnimationController _failController;
  late Animation<double> _successScale;
  late Animation<double> _failScale;

  @override
  void initState() {
    super.initState();

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _failController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _failScale = CurvedAnimation(
      parent: _failController,
      curve: Curves.easeOutBack,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPaymentFlow();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _successController.dispose();
    _failController.dispose();
    super.dispose();
  }

  void _startPaymentFlow() {
    if (widget.paymentId == null || widget.paymentId!.isEmpty) {
      // No payment ID - likely COD, show success immediately
      _onPaymentSuccess();
      return;
    }
    _pollPaymentStatus();
  }

  void _pollPaymentStatus() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _attempts++;
      if (_attempts > _maxAttempts) {
        timer.cancel();
        _onPaymentTimeout();
        return;
      }

      final cubit = context.read<CustomerCubit>();
      final payment = await cubit.verifyPaymentStatus(widget.paymentId!);

      if (!mounted) return;

      if (payment == null) return;

      if (payment.isCompleted) {
        timer.cancel();
        _onPaymentSuccess();
      } else if (payment.isFailed) {
        timer.cancel();
        _onPaymentFailed('Payment was declined. Please try again.');
      } else if (payment.isCancelled) {
        timer.cancel();
        _onPaymentFailed('Payment was cancelled.');
      }
    });
  }

  void _onPaymentSuccess() {
    setState(() {
      _uiState = _PaymentUIState.success;
      _statusMessage = 'Payment Successful!';
    });
    _successController.forward();
    NotificationService().success('Payment completed successfully!');
  }

  void _onPaymentFailed(String message) {
    setState(() {
      _uiState = _PaymentUIState.failed;
      _statusMessage = message;
    });
    _failController.forward();
    NotificationService().error(message);
  }

  void _onPaymentTimeout() {
    setState(() {
      _uiState = _PaymentUIState.failed;
      _statusMessage = 'Payment confirmation timed out. Check your order history for updates.';
    });
    _failController.forward();
  }

  Future<void> _retryPayment() async {
    if (widget.paymentId == null || widget.paymentId!.isEmpty) return;
    setState(() {
      _isRetrying = true;
      _uiState = _PaymentUIState.processing;
      _statusMessage = 'Retrying payment...';
      _attempts = 0;
    });
    final cubit = context.read<CustomerCubit>();
    final payment = await cubit.retryPayment(paymentId: widget.paymentId!);
    if (!mounted) return;
    setState(() => _isRetrying = false);
    if (payment == null) {
      _onPaymentFailed('Retry failed. Please try again later.');
      return;
    }
    if (payment.isCompleted) {
      _onPaymentSuccess();
    } else if (payment.isFailed || payment.isCancelled) {
      _onPaymentFailed('Payment was declined. Please try again.');
    } else {
      _pollPaymentStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.go('/'),
                  child: Icon(Icons.arrow_back, size: 22, color: cs.onSurface),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildContent(cs, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, bool isDark) {
    switch (_uiState) {
      case _PaymentUIState.processing:
        return _buildProcessingState(cs);
      case _PaymentUIState.success:
        return _buildSuccessState(cs);
      case _PaymentUIState.failed:
        return _buildFailedState(cs);
    }
  }

  Widget _buildProcessingState(ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 56, height: 56,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 28),
        Text('Processing Payment',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 10),
        Text(_statusMessage,
          style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5)),
          textAlign: TextAlign.center,
        ),
        if (widget.paymentId != null && widget.paymentId!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Payment ID: ${widget.paymentId!.substring(0, 8)}...',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3), fontFamily: 'monospace'),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessState(ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _successScale,
          child: const Icon(
            Icons.check_circle,
            color: Color(0xFF22C55E),
            size: 72,
          ),
        ),
        const SizedBox(height: 28),
        Text('Payment Successful!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 10),
        Text(
          'Your order has been placed and payment confirmed. You will receive a confirmation shortly.',
          style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5)),
          textAlign: TextAlign.center,
        ),
        if (widget.orderId != null && widget.orderId!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Order Ref: ${formatOrderRef(widget.orderId!)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
          ),
        ],
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Continue Shopping',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/order-history'),
          child: Text('View My Orders',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState(ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _failScale,
          child: const Icon(
            Icons.cancel,
            color: Color(0xFFEF4444),
            size: 72,
          ),
        ),
        const SizedBox(height: 28),
        Text('Payment Failed',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 10),
        Text(_statusMessage,
          style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isRetrying ? null : _retryPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isRetrying
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Retrying...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                )
              : const Text('Retry Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/'),
          child: Text('Back to Home',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}
