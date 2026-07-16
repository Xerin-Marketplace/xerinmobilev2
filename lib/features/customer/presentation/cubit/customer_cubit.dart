import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/models/address_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/payment_method_model.dart';
import 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRemoteDataSource _dataSource;
  final Logger _logger;

  CustomerCubit({
    required CustomerRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const CustomerInitial());

  Future<void> loadAll() async {
    emit(const CustomerLoading());
    try {
      final ordersFuture = _dataSource.getOrders(limit: 50).then<dynamic>((v) => v).catchError((e) => null);
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
    final current = state;
    if (current is! CustomerLoaded) return;
    try {
      final orders = await _dataSource.getOrders(limit: 50);
      emit(current.copyWith(orders: orders));
    } on ServerException catch (e) {
      _logger.e('❌ Failed to refresh orders: ${e.message}');
    } catch (e) {
      _logger.e('❌ Failed to refresh orders: $e');
    }
  }

  Future<void> refreshAddresses() async {
    final current = state;
    if (current is! CustomerLoaded) return;
    try {
      final addresses = await _dataSource.getAddresses();
      emit(current.copyWith(addresses: addresses));
    } on ServerException catch (e) {
      _logger.e('❌ Failed to refresh addresses: ${e.message}');
    } catch (e) {
      _logger.e('❌ Failed to refresh addresses: $e');
    }
  }

  Future<void> refreshPaymentMethods() async {
    final current = state;
    if (current is! CustomerLoaded) return;
    try {
      final methods = await _dataSource.getPaymentMethods();
      emit(current.copyWith(paymentMethods: methods));
    } on ServerException catch (e) {
      _logger.e('❌ Failed to refresh payment methods: ${e.message}');
    } catch (e) {
      _logger.e('❌ Failed to refresh payment methods: $e');
    }
  }

  Future<void> refreshNotifications() async {
    final current = state;
    if (current is! CustomerLoaded) return;
    try {
      final notifications = await _dataSource.getNotifications();
      emit(current.copyWith(notifications: notifications));
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
    required String addressId,
    required String paymentMethodId,
    String? notes,
  }) async {
    emit(const CustomerActionInProgress());
    try {
      final order = await _dataSource.createOrder(
        addressId: addressId,
        paymentMethodId: paymentMethodId,
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
}
