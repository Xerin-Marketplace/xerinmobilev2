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
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.paymentsInitiate,
        data: {
          'order_id': orderId,
          'method': method,
          if (provider != null) 'provider': provider,
          if (phoneNumber != null) 'phone_number': phoneNumber,
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
}
