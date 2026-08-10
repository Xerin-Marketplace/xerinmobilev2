import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/promotion_model.dart';

class PromotionRemoteDataSource {
  final ApiClient _client;

  const PromotionRemoteDataSource(this._client);

  Future<List<PromotionModel>> getAvailablePromotions() async {
    try {
      final response = await _client.get(ApiConstants.promotionsAvailable);
      final data = response.data;
      final list = data is List ? data : [];
      return list.map((e) => PromotionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PromotionApplyResult> applyPromotion({required String code, required double subtotal}) async {
    try {
      final response = await _client.post(
        ApiConstants.promotionsApply,
        data: {'code': code, 'subtotal': subtotal},
      );
      return PromotionApplyResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<CampaignModel>> getCampaigns({bool activeOnly = true}) async {
    try {
      final response = await _client.get(
        ApiConstants.campaigns,
        queryParameters: {'active_only': activeOnly},
      );
      final data = response.data;
      final list = data is List ? data : [];
      return list.map((e) => CampaignModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<PromotionModel>> getSellerPromotions() async {
    try {
      final response = await _client.get(ApiConstants.sellerPromotions);
      final data = response.data;
      final list = data is List ? data : [];
      return list.map((e) => PromotionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PromotionModel> createSellerPromotion(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(ApiConstants.sellerPromotions, data: data);
      return PromotionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PromotionModel> updateSellerPromotion({required String promotionId, required Map<String, dynamic> data}) async {
    try {
      final response = await _client.patch(ApiConstants.sellerPromotionById(promotionId), data: data);
      return PromotionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteSellerPromotion(String promotionId) async {
    try {
      await _client.delete(ApiConstants.sellerPromotionById(promotionId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
