import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/payment_model.dart';

class PaymentRemoteDataSource {
  final ApiClient _client;

  const PaymentRemoteDataSource(this._client);

  Future<PaymentModel> initiatePayment({
    required String orderId,
    required String method,
    String? provider,
    String? phoneNumber,
    String? successUrl,
    String? failureUrl,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.paymentsInitiate,
        data: {
          'order_id': orderId,
          'method': method,
          if (provider != null) 'provider': provider,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (successUrl != null) 'success_url': successUrl,
          if (failureUrl != null) 'failure_url': failureUrl,
        },
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PaymentModel> getPayment(String paymentId) async {
    try {
      final response = await _client.get(ApiConstants.paymentById(paymentId));
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PaymentModel> paymentCallback({
    required String provider,
    required String transactionId,
    required String status,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.paymentCallbackByProvider(provider),
        data: {
          'provider': provider,
          'transaction_id': transactionId,
          'status': status,
          if (payload != null) 'payload': payload,
        },
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PaymentModel> retryPayment({
    required String paymentId,
    String? provider,
    String? phoneNumber,
    String? successUrl,
    String? failureUrl,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.paymentRetry(paymentId),
        data: {
          if (provider != null) 'provider': provider,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (successUrl != null) 'success_url': successUrl,
          if (failureUrl != null) 'failure_url': failureUrl,
        },
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PaymentModel> verifyPaymentStatus(String paymentId) async {
    try {
      final response = await _client.post(
        ApiConstants.paymentVerifyStatus(paymentId),
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getOrderPaymentState(String orderId) async {
    try {
      final response = await _client.get(
        ApiConstants.paymentOrderState(orderId),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<PaymentModel>> getMyPayments({
    int page = 1,
    int pageSize = 20,
    String? paymentStatus,
    String? method,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.paymentsMyPayments,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (paymentStatus != null) 'payment_status': paymentStatus,
          if (method != null) 'method': method,
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
      } else {
        list = [];
      }
      return list
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
