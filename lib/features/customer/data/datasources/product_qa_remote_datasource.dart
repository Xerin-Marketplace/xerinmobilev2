import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/product_qa_model.dart';

class ProductQaRemoteDataSource {
  final ApiClient _client;

  const ProductQaRemoteDataSource(this._client);

  Future<ProductQuestionListResponse> getQuestions(String productId, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.get(
        ApiConstants.productQuestions(productId),
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return ProductQuestionListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<ProductQuestionModel> askQuestion({
    required String productId,
    required String question,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.productQuestions(productId),
        data: {'question': question},
      );
      return ProductQuestionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductAnswerModel>> getAnswers(String questionId) async {
    try {
      final response = await _client.get(ApiConstants.questionAnswers(questionId));
      final data = response.data;
      final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
      return list.map((e) => ProductAnswerModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<ProductAnswerModel> answerQuestion({
    required String questionId,
    required String answer,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.questionAnswers(questionId),
        data: {'answer': answer},
      );
      return ProductAnswerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> voteQuestionHelpful(String questionId) async {
    try {
      await _client.post(ApiConstants.questionHelpful(questionId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> voteAnswerHelpful(String answerId) async {
    try {
      await _client.post(ApiConstants.answerHelpful(answerId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> reportQuestion({required String questionId, required String reason}) async {
    try {
      await _client.post(
        ApiConstants.questionReport(questionId),
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductQuestionModel>> getSellerQuestions() async {
    try {
      final response = await _client.get(ApiConstants.sellerQuestions);
      final data = response.data;
      final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
      return list.map((e) => ProductQuestionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<ProductAnswerModel> sellerAnswerQuestion({
    required String questionId,
    required String answer,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerAnswerQuestion(questionId),
        data: {'answer': answer},
      );
      return ProductAnswerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
