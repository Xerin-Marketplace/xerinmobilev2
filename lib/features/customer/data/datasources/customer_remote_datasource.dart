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
    try {
      final response = await _client.post(
        ApiConstants.addresses,
        data: {
          'country': country,
          'region': region,
          'city': city,
          'street': street,
          'postal_code': postalCode,
          'is_default': isDefault,
          if (label != null) 'label': label,
          if (recipientName != null) 'recipient_name': recipientName,
          if (recipientPhone != null) 'recipient_phone': recipientPhone,
          if (district != null) 'district': district,
          if (ward != null) 'ward': ward,
          if (landmark != null) 'landmark': landmark,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
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
    try {
      final response = await _client.patch(
        ApiConstants.addressById(addressId),
        data: {
          'country': country,
          'region': region,
          'city': city,
          'street': street,
          'postal_code': postalCode,
          'is_default': isDefault,
          if (label != null) 'label': label,
          if (recipientName != null) 'recipient_name': recipientName,
          if (recipientPhone != null) 'recipient_phone': recipientPhone,
          if (district != null) 'district': district,
          if (ward != null) 'ward': ward,
          if (landmark != null) 'landmark': landmark,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
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
    required String shippingAddressId,
    required String shippingRateId,
    String? couponCode,
    String? promotionCode,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.orders,
        data: {
          'shipping_address_id': shippingAddressId,
          'shipping_rate_id': shippingRateId,
          if (couponCode != null) 'coupon_code': couponCode,
          if (promotionCode != null) 'promotion_code': promotionCode,
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

  // =========================
  // REFUNDS (customer)
  // =========================

  Future<Map<String, dynamic>> requestRefund({
    required String orderId,
    required String reason,
    required List<Map<String, dynamic>> items,
    String? reasonDetails,
    bool refundShipping = false,
    bool refundTax = false,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.refunds,
        data: {
          'order_id': orderId,
          'reason': reason,
          'items': items,
          'refund_shipping': refundShipping,
          'refund_tax': refundTax,
          'idempotency_key': idempotencyKey,
          if (reasonDetails != null) 'reason_details': reasonDetails,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getMyRefunds() async {
    try {
      final response = await _client.get(ApiConstants.refunds);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else {
        list = [];
      }
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getRefundById(String refundId) async {
    try {
      final response = await _client.get(ApiConstants.refundById(refundId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> cancelRefund(String refundId) async {
    try {
      final response = await _client.post(ApiConstants.cancelRefund(refundId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // SHIPPING QUOTES
  // =========================

  Future<List<Map<String, dynamic>>> getShippingQuote({
    required String addressId,
    required double subtotal,
    double weightKg = 0,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.shippingQuote,
        data: {
          'address_id': addressId,
          'subtotal': subtotal,
          'weight_kg': weightKg,
        },
      );
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['options'] != null) {
        list = data['options'] as List;
      } else {
        list = [];
      }
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // ORDER DETAIL & ESCROW
  // =========================

  Future<Map<String, dynamic>> getCustomerOrderDetail(String orderId) async {
    try {
      final response = await _client.get(ApiConstants.orderCustomerDetail(orderId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getEscrowStatus(String orderId) async {
    try {
      final response = await _client.get(ApiConstants.orderEscrow(orderId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> approveReceipt(String orderId, {String? note}) async {
    try {
      final response = await _client.post(
        ApiConstants.orderApproveReceipt(orderId),
        data: {if (note != null) 'note': note},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getOrderWorkflow(String orderId) async {
    try {
      final response = await _client.get(ApiConstants.orderWorkflow(orderId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // NOTIFICATION SUMMARY & PREFERENCES
  // =========================

  Future<Map<String, dynamic>> getNotificationSummary() async {
    try {
      final response = await _client.get(ApiConstants.notificationsSummary);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await _client.get(ApiConstants.notificationPreferences);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    try {
      await _client.patch(
        ApiConstants.notificationPreferences,
        data: preferences,
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // CHANGE PASSWORD
  // =========================

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.post(
        ApiConstants.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // SHIPMENTS (customer)
  // =========================

  Future<List<Map<String, dynamic>>> getMyShipments() async {
    try {
      final response = await _client.get(ApiConstants.myShipments);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else {
        list = [];
      }
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getShipmentById(String shipmentId) async {
    try {
      final response = await _client.get(ApiConstants.shipmentById(shipmentId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
