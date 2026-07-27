import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/address_model.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../models/payment_method_model.dart';

class CustomerRemoteDataSource {
  final ApiClient _client;

  const CustomerRemoteDataSource(this._client);

  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _client.get(ApiConstants.addresses);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else if (data is Map && data['data'] != null) {
        list = data['data'] as List;
      } else {
        list = [];
      }
      return list
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AddressModel> createAddress({
    required String country,
    required String region,
    required String city,
    required String street,
    String? postalCode,
    bool isDefault = false,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.addresses,
        data: {
          'country': country,
          'region': region,
          'city': city,
          'street': street,
          'postal_code': ?postalCode,
          'is_default': isDefault,
        },
      );
      return AddressModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AddressModel> updateAddress({
    required String addressId,
    required String country,
    required String region,
    required String city,
    required String street,
    String? postalCode,
    bool isDefault = false,
  }) async {
    try {
      final response = await _client.patch(
        ApiConstants.addressById(addressId),
        data: {
          'country': country,
          'region': region,
          'city': city,
          'street': street,
          'postal_code': ?postalCode,
          'is_default': isDefault,
        },
      );
      return AddressModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _client.delete(ApiConstants.addressById(addressId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<OrderModel>> getOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.myOrders,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null) 'status': status,
        },
      );
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['results'] != null) {
        list = data['results'] as List;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else if (data is Map && data['data'] != null) {
        list = data['data'] as List;
      } else {
        list = [];
      }
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await _client.get(ApiConstants.orderById(orderId));
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      final response = await _client.get(ApiConstants.paymentMethods);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else if (data is Map && data['data'] != null) {
        list = data['data'] as List;
      } else {
        list = [];
      }
      return list
          .map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PaymentMethodModel> createPaymentMethod({
    required String type,
    required String provider,
    required String accountName,
    required String accountNumber,
    String? expiryDate,
    bool isDefault = false,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.paymentMethods,
        data: {
          'type': type,
          'provider': provider,
          'account_name': accountName,
          'account_number': accountNumber,
          'expiry_date': ?expiryDate,
          'is_default': isDefault,
        },
      );
      return PaymentMethodModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _client.delete(ApiConstants.paymentMethodById(paymentMethodId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<OrderModel> createOrder({
    String? shippingAddressId,
    String? couponCode,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.orders,
        data: {
          if (shippingAddressId != null) 'shipping_address_id': shippingAddressId,
          if (couponCode != null) 'coupon_code': couponCode,
          if (notes != null) 'notes': notes,
        },
      );
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<NotificationModel>> getNotifications({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.notifications,
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else if (data is Map && data['data'] != null) {
        list = data['data'] as List;
      } else {
        list = [];
      }
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _client.patch(
        '${ApiConstants.notifications}/$notificationId/read',
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _client.post('${ApiConstants.notifications}/read-all');
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
