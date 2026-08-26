import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/models/address_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/models/payment_model.dart';
import 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRemoteDataSource _dataSource;
  final PaymentRemoteDataSource _paymentDataSource;
  final Logger _logger;

  CustomerCubit({
    required CustomerRemoteDataSource dataSource,
    required PaymentRemoteDataSource paymentDataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _paymentDataSource = paymentDataSource,
        _logger = logger,
        super(const CustomerInitial());

  Future<void> loadAll() async {
    emit(const CustomerLoading());
    try {
      final ordersFuture = _dataSource.getOrders(pageSize: 50).then<dynamic>((v) => v).catchError((e) => null);
      final addressesFuture = _dataSource.getAddresses().then<dynamic>((v) => v).catchError((e) => null);
      final paymentsFuture = _dataSource.getPaymentMethods().then<dynamic>((v) => v).catchError((e) => null);
      final notifFuture = _dataSource.getNotifications().then<dynamic>((v) => v).catchError((e) => null);

      final results = await Future.wait([ordersFuture, addressesFuture, paymentsFuture, notifFuture]);

      final orders = results[0] is List ? (results[0] as List).whereType<OrderModel>().toList() : <OrderModel>[];
      final addresses = results[1] is List ? (results[1] as List).whereType<AddressModel>().toList() : <AddressModel>[];
      final paymentMethods = results[2] is List ? (results[2] as List).whereType<PaymentMethodModel>().toList() : <PaymentMethodModel>[];
      final notifications = results[3] is List ? (results[3] as List).whereType<NotificationModel>().toList() : <NotificationModel>[];

      _logger.i(
        '✅ Customer data loaded — orders: ${orders.length}, '
        'addresses: ${addresses.length}, '
        'payments: ${paymentMethods.length}, '
        'notifications: ${notifications.length}',
      );

      emit(CustomerLoaded(
        orders: orders,
        addresses: addresses,
        paymentMethods: paymentMethods,
        notifications: notifications,
      ));
    } catch (e) {
      _logger.e('❌ Failed to load customer data: $e');
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> refreshOrders() async {
    try {
      final orders = await _dataSource.getOrders(pageSize: 50);
      final current = state;
      if (current is CustomerLoaded) {
        emit(current.copyWith(orders: orders));
      } else {
        emit(CustomerLoaded(orders: orders));
      }
    } on ServerException catch (e) {
      _logger.e('❌ Failed to refresh orders: ${e.message}');
    } catch (e) {
      _logger.e('❌ Failed to refresh orders: $e');
    }
  }

  Future<void> refreshAddresses() async {
    try {
      final addresses = await _dataSource.getAddresses();
      final current = state;
      if (current is CustomerLoaded) {
        emit(current.copyWith(addresses: addresses));
      } else {
        final prev = current is CustomerLoaded ? current : null;
        emit(CustomerLoaded(
          orders: prev?.orders ?? [],
          addresses: addresses,
          paymentMethods: prev?.paymentMethods ?? [],
          notifications: prev?.notifications ?? [],
        ));
      }
    } on ServerException catch (e) {
      _logger.e('❌ Failed to refresh addresses: ${e.message}');
    } catch (e) {
      _logger.e('❌ Failed to refresh addresses: $e');
    }
  }

  Future<void> refreshPaymentMethods() async {
    try {
      final methods = await _dataSource.getPaymentMethods();
      final current = state;
      if (current is CustomerLoaded) {
        emit(current.copyWith(paymentMethods: methods));
      } else {
        emit(CustomerLoaded(paymentMethods: methods));
      }
    } on ServerException catch (e) {
      _logger.e('❌ Failed to refresh payment methods: ${e.message}');
    } catch (e) {
      _logger.e('❌ Failed to refresh payment methods: $e');
    }
  }

  Future<void> refreshNotifications() async {
    try {
      final notifications = await _dataSource.getNotifications();
      final current = state;
      if (current is CustomerLoaded) {
        emit(current.copyWith(notifications: notifications));
      } else {
        emit(CustomerLoaded(notifications: notifications));
      }
    } on ServerException catch (e) {
      _logger.e('❌ Failed to refresh notifications: ${e.message}');
    } catch (e) {
      _logger.e('❌ Failed to refresh notifications: $e');
    }
  }

  Future<void> addAddress({
    required String country,
    required String region,
    required String city,
    required String street,
    String? postalCode,
    String? label,
    String? recipientName,
    String? recipientPhone,
    String? district,
    String? ward,
    String? landmark,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    emit(const CustomerActionInProgress());
    try {
      final address = await _dataSource.createAddress(
        country: country,
        region: region,
        city: city,
        street: street,
        postalCode: postalCode,
        label: label,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        district: district,
        ward: ward,
        landmark: landmark,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      _logger.i('✅ Address added: ${address.id}');
      await refreshAddresses();
      emit(const CustomerActionSuccess('Address added successfully'));
    } on ServerException catch (e) {
      emit(CustomerActionError(e.message));
    } catch (e) {
      emit(CustomerActionError('Failed to add address: $e'));
    }
  }

  Future<void> updateAddress({
    required String addressId,
    required String country,
    required String region,
    required String city,
    required String street,
    String? postalCode,
    String? label,
    String? recipientName,
    String? recipientPhone,
    String? district,
    String? ward,
    String? landmark,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    emit(const CustomerActionInProgress());
    try {
      await _dataSource.updateAddress(
        addressId: addressId,
        country: country,
        region: region,
        city: city,
        street: street,
        postalCode: postalCode,
        label: label,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        district: district,
        ward: ward,
        landmark: landmark,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      _logger.i('✅ Address updated: $addressId');
      await refreshAddresses();
      emit(const CustomerActionSuccess('Address updated successfully'));
    } on ServerException catch (e) {
      emit(CustomerActionError(e.message));
    } catch (e) {
      emit(CustomerActionError('Failed to update address: $e'));
    }
  }

  Future<void> deleteAddress(String addressId) async {
    emit(const CustomerActionInProgress());
    try {
      await _dataSource.deleteAddress(addressId);
      _logger.i('✅ Address deleted: $addressId');
      await refreshAddresses();
      emit(const CustomerActionSuccess('Address deleted successfully'));
    } on ServerException catch (e) {
      emit(CustomerActionError(e.message));
    } catch (e) {
      emit(CustomerActionError('Failed to delete address: $e'));
    }
  }

  Future<void> addPaymentMethod({
    required String type,
    required String provider,
    required String accountName,
    required String accountNumber,
    String? expiryDate,
    bool isDefault = false,
  }) async {
    emit(const CustomerActionInProgress());
    try {
      await _dataSource.createPaymentMethod(
        type: type,
        provider: provider,
        accountName: accountName,
        accountNumber: accountNumber,
        expiryDate: expiryDate,
        isDefault: isDefault,
      );
      _logger.i('✅ Payment method added: $provider');
      await refreshPaymentMethods();
      emit(const CustomerActionSuccess('Payment method added successfully'));
    } on ServerException catch (e) {
      emit(CustomerActionError(e.message));
    } catch (e) {
      emit(CustomerActionError('Failed to add payment method: $e'));
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    emit(const CustomerActionInProgress());
    try {
      await _dataSource.deletePaymentMethod(paymentMethodId);
      _logger.i('✅ Payment method deleted: $paymentMethodId');
      await refreshPaymentMethods();
      emit(const CustomerActionSuccess('Payment method removed successfully'));
    } on ServerException catch (e) {
      emit(CustomerActionError(e.message));
    } catch (e) {
      emit(CustomerActionError('Failed to remove payment method: $e'));
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    final current = state;
    if (current is! CustomerLoaded) return;
    try {
      await _dataSource.markNotificationRead(notificationId);
      final updated = current.notifications.map((n) {
        if (n.id == notificationId) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      emit(current.copyWith(notifications: updated));
    } on ServerException catch (e) {
      _logger.e('❌ Failed to mark notification read: ${e.message}');
    } catch (e) {
      _logger.e('❌ Failed to mark notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    final current = state;
    if (current is! CustomerLoaded) return;
    try {
      await _dataSource.markAllNotificationsRead();
      final updated = current.notifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      emit(current.copyWith(notifications: updated));
      _logger.i('✅ All notifications marked as read');
    } on ServerException catch (e) {
      _logger.e('❌ Failed to mark all notifications: ${e.message}');
    } catch (e) {
      _logger.e('❌ Failed to mark all notifications: $e');
    }
  }

  Future<bool> placeOrder({
    required String shippingAddressId,
    required String shippingRateId,
    String? couponCode,
    String? promotionCode,
    String? notes,
  }) async {
    emit(const CustomerActionInProgress());
    try {
      final order = await _dataSource.createOrder(
        shippingAddressId: shippingAddressId,
        shippingRateId: shippingRateId,
        couponCode: couponCode,
        promotionCode: promotionCode,
        notes: notes,
      );
      _logger.i('✅ Order placed: ${order.id}');
      await refreshOrders();
      emit(const CustomerActionSuccess('Order placed successfully!'));
      return true;
    } on ServerException catch (e) {
      emit(CustomerActionError(e.message));
      return false;
    } catch (e) {
      emit(CustomerActionError('Failed to place order: $e'));
      return false;
    }
  }

  // =========================
  // PAYMENT FLOW
  // =========================

  Future<PaymentModel?> placeOrderAndPay({
    required String shippingAddressId,
    required String shippingRateId,
    String? couponCode,
    String? promotionCode,
    String? notes,
    required String paymentMethod,
    String? provider,
    String? phoneNumber,
    String? successUrl,
    String? failureUrl,
  }) async {
    emit(const PaymentInProgress(message: 'Placing your order...'));
    try {
      final order = await _dataSource.createOrder(
        shippingAddressId: shippingAddressId,
        shippingRateId: shippingRateId,
        couponCode: couponCode,
        promotionCode: promotionCode,
        notes: notes,
      );
      _logger.i('✅ Order placed: ${order.id}');

      if (paymentMethod == 'cash_on_delivery') {
        await refreshOrders();
        emit(PaymentSuccess(
          paymentId: '',
          orderId: order.id,
          method: paymentMethod,
        ));
        return null;
      }

      emit(const PaymentInProgress(message: 'Initiating payment...'));
      final payment = await _paymentDataSource.initiatePayment(
        orderId: order.id,
        method: paymentMethod,
        provider: provider,
        phoneNumber: phoneNumber,
        successUrl: successUrl,
        failureUrl: failureUrl,
      );
      _logger.i('✅ Payment initiated: ${payment.id}, status: ${payment.status}');

      await refreshOrders();

      String? checkoutUrl;
      if (payment.providerResponse != null) {
        checkoutUrl = payment.providerResponse!['checkout_url'] as String?;
      }

      if (payment.isCompleted) {
        emit(PaymentSuccess(
          paymentId: payment.id,
          orderId: order.id,
          method: paymentMethod,
        ));
      } else if (payment.isProcessing || payment.isPending) {
        if (checkoutUrl != null) {
          emit(PaymentSuccess(
            paymentId: payment.id,
            orderId: order.id,
            method: paymentMethod,
            checkoutUrl: checkoutUrl,
          ));
        } else {
          emit(PaymentSuccess(
            paymentId: payment.id,
            orderId: order.id,
            method: paymentMethod,
          ));
        }
      } else if (payment.isFailed) {
        emit(const PaymentFailed('Payment was rejected by the provider'));
      } else {
        emit(PaymentSuccess(
          paymentId: payment.id,
          orderId: order.id,
          method: paymentMethod,
          checkoutUrl: checkoutUrl,
        ));
      }

      return payment;
    } on ServerException catch (e) {
      _logger.e('❌ Payment failed: ${e.message}');
      emit(PaymentFailed(e.message));
      return null;
    } catch (e) {
      _logger.e('❌ Payment unexpected error: $e');
      emit(PaymentFailed('Failed to process payment: $e'));
      return null;
    }
  }

  Future<PaymentModel?> checkPaymentStatus(String paymentId) async {
    try {
      final payment = await _paymentDataSource.getPayment(paymentId);
      emit(PaymentStatusUpdated(paymentId: paymentId, status: payment.status));
      return payment;
    } on ServerException catch (e) {
      _logger.e('❌ Payment status check failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('❌ Payment status check error: $e');
      return null;
    }
  }

  Future<PaymentModel?> pollPaymentStatus({
    required String paymentId,
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 20,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);
      final payment = await checkPaymentStatus(paymentId);
      if (payment == null) continue;
      if (payment.isCompleted) {
        emit(PaymentSuccess(
          paymentId: payment.id,
          orderId: payment.orderId,
          method: payment.method,
        ));
        return payment;
      }
      if (payment.isFailed || payment.isCancelled) {
        emit(PaymentFailed(payment.status == 'cancelled'
            ? 'Payment was cancelled'
            : 'Payment failed'));
        return payment;
      }
    }
    return null;
  }

  // =========================
  // PAYMENT RETRY & VERIFY
  // =========================

  Future<PaymentModel?> retryPayment({
    required String paymentId,
    String? provider,
    String? phoneNumber,
    String? successUrl,
    String? failureUrl,
  }) async {
    emit(const PaymentInProgress(message: 'Retrying payment...'));
    try {
      final payment = await _paymentDataSource.retryPayment(
        paymentId: paymentId,
        provider: provider,
        phoneNumber: phoneNumber,
        successUrl: successUrl,
        failureUrl: failureUrl,
      );
      _logger.i('✅ Payment retried: ${payment.id}, status: ${payment.status}');
      String? checkoutUrl;
      if (payment.providerResponse != null) {
        checkoutUrl = payment.providerResponse!['checkout_url'] as String?;
      }
      if (payment.isCompleted) {
        emit(PaymentSuccess(
          paymentId: payment.id,
          orderId: payment.orderId,
          method: payment.method,
        ));
      } else if (payment.isProcessing || payment.isPending) {
        emit(PaymentSuccess(
          paymentId: payment.id,
          orderId: payment.orderId,
          method: payment.method,
          checkoutUrl: checkoutUrl,
        ));
      } else if (payment.isFailed) {
        emit(const PaymentFailed('Payment was rejected by the provider'));
      } else {
        emit(PaymentSuccess(
          paymentId: payment.id,
          orderId: payment.orderId,
          method: payment.method,
          checkoutUrl: checkoutUrl,
        ));
      }
      return payment;
    } on ServerException catch (e) {
      _logger.e('❌ Payment retry failed: ${e.message}');
      emit(PaymentFailed(e.message));
      return null;
    } catch (e) {
      _logger.e('❌ Payment retry error: $e');
      emit(PaymentFailed('Failed to retry payment: $e'));
      return null;
    }
  }

  Future<PaymentModel?> verifyPaymentStatus(String paymentId) async {
    try {
      final payment = await _paymentDataSource.verifyPaymentStatus(paymentId);
      _logger.i('✅ Payment verified: ${payment.id}, status: ${payment.status}');
      emit(PaymentStatusUpdated(paymentId: payment.id, status: payment.status));
      if (payment.isCompleted) {
        emit(PaymentSuccess(
          paymentId: payment.id,
          orderId: payment.orderId,
          method: payment.method,
        ));
      } else if (payment.isFailed || payment.isCancelled) {
        emit(PaymentFailed(payment.status == 'cancelled'
            ? 'Payment was cancelled'
            : 'Payment failed'));
      }
      return payment;
    } on ServerException catch (e) {
      _logger.e('❌ Payment verify failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('❌ Payment verify error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrderPaymentState(String orderId) async {
    try {
      return await _paymentDataSource.getOrderPaymentState(orderId);
    } on ServerException catch (e) {
      _logger.e('❌ Order payment state failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('❌ Order payment state error: $e');
      return null;
    }
  }

  // =========================
  // SHIPPING QUOTES
  // =========================

  Future<List<Map<String, dynamic>>> fetchShippingQuotes({
    required String addressId,
    required double subtotal,
    double weightKg = 0,
  }) async {
    try {
      return await _dataSource.getShippingQuote(
        addressId: addressId,
        subtotal: subtotal,
        weightKg: weightKg,
      );
    } on ServerException catch (e) {
      _logger.e('❌ Shipping quotes failed: ${e.message}');
      return [];
    } catch (e) {
      _logger.e('❌ Shipping quotes error: $e');
      return [];
    }
  }

  // =========================
  // ORDER DETAIL & ESCROW
  // =========================

  Future<Map<String, dynamic>?> getCustomerOrderDetail(String orderId) async {
    try {
      return await _dataSource.getCustomerOrderDetail(orderId);
    } on ServerException catch (e) {
      _logger.e('❌ Customer order detail failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('❌ Customer order detail error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getEscrowStatus(String orderId) async {
    try {
      return await _dataSource.getEscrowStatus(orderId);
    } on ServerException catch (e) {
      _logger.e('❌ Escrow status failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('❌ Escrow status error: $e');
      return null;
    }
  }

  Future<bool> approveReceipt(String orderId, {String? note}) async {
    emit(const CustomerActionInProgress());
    try {
      await _dataSource.approveReceipt(orderId, note: note);
      _logger.i('✅ Receipt approved: $orderId');
      emit(const CustomerActionSuccess('Receipt confirmed successfully'));
      return true;
    } on ServerException catch (e) {
      emit(CustomerActionError(e.message));
      return false;
    } catch (e) {
      emit(CustomerActionError('Failed to approve receipt: $e'));
      return false;
    }
  }

  Future<Map<String, dynamic>?> getOrderWorkflow(String orderId) async {
    try {
      return await _dataSource.getOrderWorkflow(orderId);
    } on ServerException catch (e) {
      _logger.e('❌ Order workflow failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('❌ Order workflow error: $e');
      return null;
    }
  }

  // =========================
  // NOTIFICATION SUMMARY & PREFERENCES
  // =========================

  Future<Map<String, dynamic>?> getNotificationSummary() async {
    try {
      return await _dataSource.getNotificationSummary();
    } on ServerException catch (e) {
      _logger.e('❌ Notification summary failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('❌ Notification summary error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    try {
      return await _dataSource.getNotificationPreferences();
    } on ServerException catch (e) {
      _logger.e('❌ Notification preferences failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('❌ Notification preferences error: $e');
      return null;
    }
  }

  Future<bool> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    emit(const CustomerActionInProgress());
    try {
      await _dataSource.updateNotificationPreferences(preferences);
      _logger.i('✅ Notification preferences updated');
      emit(const CustomerActionSuccess('Notification preferences updated'));
      return true;
    } on ServerException catch (e) {
      emit(CustomerActionError(e.message));
      return false;
    } catch (e) {
      emit(CustomerActionError('Failed to update preferences: $e'));
      return false;
    }
  }

  // =========================
  // CHANGE PASSWORD
  // =========================

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(const CustomerActionInProgress());
    try {
      await _dataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _logger.i('✅ Password changed');
      emit(const CustomerActionSuccess('Password changed successfully'));
      return true;
    } on ServerException catch (e) {
      emit(CustomerActionError(e.message));
      return false;
    } catch (e) {
      emit(CustomerActionError('Failed to change password: $e'));
      return false;
    }
  }
}
