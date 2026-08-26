import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/delivery_proof_model.dart';

class DeliveryVerificationRemoteDataSource {
  final ApiClient _client;

  const DeliveryVerificationRemoteDataSource(this._client);

  Future<List<DeliveryProofModel>> getMyDeliveryProofs() async {
    try {
      final response =
          await _client.get(ApiConstants.deliveryVerificationMy);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['results'] != null) {
        list = data['results'] as List;
      } else {
        list = [];
      }
      return list
          .map((e) =>
              DeliveryProofModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<DeliveryProofModel> disputeDeliveryProof(
      String proofId, String reason, {String? notes}) async {
    try {
      final body = <String, dynamic>{'reason': reason};
      if (notes != null) body['notes'] = notes;
      final response = await _client.post(
        ApiConstants.deliveryVerificationDispute(proofId),
        data: body,
      );
      return DeliveryProofModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
