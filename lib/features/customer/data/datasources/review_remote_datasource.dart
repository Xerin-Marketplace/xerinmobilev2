import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/review_model.dart';

class ReviewRemoteDataSource {
  final ApiClient _client;

  const ReviewRemoteDataSource(this._client);

  Future<ReviewListResponse> getProductReviews(String productId, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.get(
        ApiConstants.productReviews(productId),
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return ReviewListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<ReviewModel> createProductReview({
    required String productId,
    required String orderItemId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.productReviews(productId),
        data: {
          'order_item_id': orderItemId,
          'rating': rating,
          if (title != null) 'title': title,
          if (comment != null) 'comment': comment,
        },
      );
      return ReviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _client.delete(ApiConstants.reviewById(reviewId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<ReviewListResponse> getStoreReviews(String slug, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.get(
        ApiConstants.storeReviews(slug),
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return ReviewListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<ReviewModel> createStoreReview({
    required String slug,
    required int rating,
    String? title,
    String? comment,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.storeReviews(slug),
        data: {
          'rating': rating,
          if (title != null) 'title': title,
          if (comment != null) 'comment': comment,
        },
      );
      return ReviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ReviewModel>> getSellerReviews() async {
    try {
      final response = await _client.get(ApiConstants.sellerReviews);
      final data = response.data;
      final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
      return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<ReviewModel> sellerReplyReview({required String reviewId, required String reply}) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerReviewReply(reviewId),
        data: {'reply': reply},
      );
      return ReviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> reportReview({required String reviewId, required String reason}) async {
    try {
      await _client.post(
        ApiConstants.sellerReviewReport(reviewId),
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ReviewModel>> getAdminReviews({String? status}) async {
    try {
      final response = await _client.get(
        ApiConstants.adminReviews,
        queryParameters: status != null ? {'status': status} : null,
      );
      final data = response.data;
      final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
      return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> adminModerateReview({required String reviewId, required String status, String? reason}) async {
    try {
      await _client.patch(
        ApiConstants.adminReviewModerate(reviewId),
        data: {
          'status': status,
          if (reason != null) 'moderation_reason': reason,
        },
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
