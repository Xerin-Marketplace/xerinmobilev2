import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/broker_models.dart';

class BrokerRemoteDataSource {
  final ApiClient _client;

  const BrokerRemoteDataSource(this._client);

  Future<BrokerModel> getBrokerMe() async {
    try {
      final response = await _client.get(ApiConstants.brokerMe);
      return BrokerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerModel> updateBrokerMe(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.patch(ApiConstants.brokerMe, data: data);
      return BrokerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerKycStatusModel> getKycStatus() async {
    try {
      final response = await _client.get(ApiConstants.brokerKycStatus);
      return BrokerKycStatusModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<BrokerKycDocumentModel>> getKycDocuments() async {
    try {
      final response = await _client.get(ApiConstants.brokerKycDocuments);
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final list = data['results'] as List<dynamic>;
        return list
            .map((e) =>
                BrokerKycDocumentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final list = data is List ? data : [];
      return list
          .map((e) =>
              BrokerKycDocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerModel> submitKyc() async {
    try {
      final response = await _client.post(ApiConstants.brokerSubmitKyc);
      return BrokerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerAnalyticsOverviewModel> getAnalyticsOverview(
      {int days = 30}) async {
    try {
      final response = await _client.get(
        ApiConstants.brokerAnalyticsOverview,
        queryParameters: {'days': days},
      );
      return BrokerAnalyticsOverviewModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<BrokerOpportunityModel>> getOpportunities() async {
    try {
      final response = await _client.get(ApiConstants.brokerOpportunities);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) =>
              BrokerOpportunityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<BrokerOpportunityModel>> getAcceptedOpportunities() async {
    try {
      final response =
          await _client.get(ApiConstants.brokerAcceptedOpportunities);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) =>
              BrokerOpportunityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> acceptOpportunity(String offerId) async {
    try {
      final response =
          await _client.post(ApiConstants.brokerAcceptOpportunity(offerId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> stopOpportunity(String offerId) async {
    try {
      await _client.delete(ApiConstants.brokerAcceptOpportunity(offerId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getReferralLink(String offerId) async {
    try {
      final response =
          await _client.get(ApiConstants.brokerOpportunityReferral(offerId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerCommissionSummaryModel> getCommissionSummary() async {
    try {
      final response = await _client.get(ApiConstants.brokerCommissionSummary);
      return BrokerCommissionSummaryModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerWalletModel> getWallet() async {
    try {
      final response = await _client.get(ApiConstants.brokerWallet);
      return BrokerWalletModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<BrokerPayoutAccountModel>> getPayoutAccounts() async {
    try {
      final response = await _client.get(ApiConstants.brokerPayoutAccounts);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) =>
              BrokerPayoutAccountModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerPayoutAccountModel> createPayoutAccount(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _client.post(ApiConstants.brokerPayoutAccounts, data: data);
      return BrokerPayoutAccountModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.post(ApiConstants.brokerPayouts, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<BrokerProductModel>> getProducts() async {
    try {
      final response = await _client.get(ApiConstants.brokerProducts);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => BrokerProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerProductModel> createProduct(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.post(ApiConstants.brokerProducts, data: data);
      return BrokerProductModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerProductModel> updateProduct(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _client.patch(ApiConstants.brokerProductById(id), data: data);
      return BrokerProductModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<BrokerProductModel> publishProduct(String id) async {
    try {
      final response = await _client.post(ApiConstants.brokerProductPublish(id));
      return BrokerProductModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> archiveProduct(String id) async {
    try {
      await _client.delete(ApiConstants.brokerProductById(id));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
