import 'package:equatable/equatable.dart';

import '../../data/models/address_model.dart';
import '../../data/models/escrow_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/models/protection_claim_model.dart';
import '../../data/models/xerin_express_option_model.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {
  const CustomerInitial();
}

class CustomerLoading extends CustomerState {
  const CustomerLoading();
}

class CustomerLoaded extends CustomerState {
  final List<OrderModel> orders;
  final List<AddressModel> addresses;
  final List<PaymentMethodModel> paymentMethods;
  final List<NotificationModel> notifications;

  const CustomerLoaded({
    this.orders = const [],
    this.addresses = const [],
    this.paymentMethods = const [],
    this.notifications = const [],
  });

  int get totalOrders => orders.length;
  int get pendingOrders =>
      orders.where((o) => o.status == 'pending').length;
  int get deliveredOrders =>
      orders.where((o) => o.status == 'delivered').length;
  int get processingOrders =>
      orders.where((o) => o.status == 'processing' || o.status == 'shipped').length;
  int get cancelledOrders =>
      orders.where((o) => o.status == 'cancelled').length;
  double get totalSpent =>
      orders.where((o) => o.status == 'delivered').fold(0.0, (sum, o) => sum + o.total);
  double get avgOrderValue =>
      orders.isNotEmpty ? totalSpent / orders.length : 0.0;
  int get unreadNotifications =>
      notifications.where((n) => !n.isRead).length;
  AddressModel? get defaultAddress =>
      addresses.where((a) => a.isDefault).firstOrNull;
  PaymentMethodModel? get defaultPaymentMethod =>
      paymentMethods.where((p) => p.isDefault).firstOrNull;

  CustomerLoaded copyWith({
    List<OrderModel>? orders,
    List<AddressModel>? addresses,
    List<PaymentMethodModel>? paymentMethods,
    List<NotificationModel>? notifications,
  }) =>
      CustomerLoaded(
        orders: orders ?? this.orders,
        addresses: addresses ?? this.addresses,
        paymentMethods: paymentMethods ?? this.paymentMethods,
        notifications: notifications ?? this.notifications,
      );

  @override
  List<Object?> get props => [orders, addresses, paymentMethods, notifications];
}

class CustomerError extends CustomerState {
  final String message;
  const CustomerError(this.message);
  @override
  List<Object?> get props => [message];
}

class CustomerActionInProgress extends CustomerState {
  const CustomerActionInProgress();
}

class CustomerActionSuccess extends CustomerState {
  final String message;
  const CustomerActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class CustomerActionError extends CustomerState {
  final String message;
  const CustomerActionError(this.message);
  @override
  List<Object?> get props => [message];
}

// =========================
// PAYMENT STATES
// =========================

class PaymentInProgress extends CustomerState {
  final String message;
  const PaymentInProgress({this.message = 'Processing payment...'});
  @override
  List<Object?> get props => [message];
}

class PaymentSuccess extends CustomerState {
  final String paymentId;
  final String orderId;
  final String method;
  final String? checkoutUrl;
  const PaymentSuccess({
    required this.paymentId,
    required this.orderId,
    required this.method,
    this.checkoutUrl,
  });
  @override
  List<Object?> get props => [paymentId, orderId, method, checkoutUrl];
}

class PaymentFailed extends CustomerState {
  final String message;
  const PaymentFailed(this.message);
  @override
  List<Object?> get props => [message];
}

class PaymentStatusUpdated extends CustomerState {
  final String paymentId;
  final String status;
  const PaymentStatusUpdated({required this.paymentId, required this.status});
  @override
  List<Object?> get props => [paymentId, status];
}

// =========================
// ESCROW & PROTECTION STATES
// =========================

class EscrowLoaded extends CustomerState {
  final EscrowSummary escrow;
  const EscrowLoaded({required this.escrow});
  @override
  List<Object?> get props => [escrow];
}

class EscrowItemAccepted extends CustomerState {
  final EscrowSummary escrow;
  final String orderItemId;
  const EscrowItemAccepted({required this.escrow, required this.orderItemId});
  @override
  List<Object?> get props => [escrow, orderItemId];
}

class ProtectionClaimsLoaded extends CustomerState {
  final List<ProtectionClaim> claims;
  const ProtectionClaimsLoaded({required this.claims});
  @override
  List<Object?> get props => [claims];
}

class ProtectionClaimCreated extends CustomerState {
  final ProtectionClaim claim;
  const ProtectionClaimCreated({required this.claim});
  @override
  List<Object?> get props => [claim];
}

class OrderSellerMessagesLoaded extends CustomerState {
  final List<Map<String, dynamic>> messages;
  const OrderSellerMessagesLoaded({required this.messages});
  @override
  List<Object?> get props => [messages];
}

class OrderSellerMessageSent extends CustomerState {
  final Map<String, dynamic> message;
  const OrderSellerMessageSent({required this.message});
  @override
  List<Object?> get props => [message];
}

// =========================
// XERIN EXPRESS CHECKOUT STATES
// =========================

class XerinExpressOptionsLoaded extends CustomerState {
  final List<XerinExpressOption> options;
  const XerinExpressOptionsLoaded({required this.options});
  @override
  List<Object?> get props => [options];
}

class CheckoutConfigLoaded extends CustomerState {
  final Map<String, dynamic> config;
  const CheckoutConfigLoaded({required this.config});
  @override
  List<Object?> get props => [config];
}
