import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/logistics_models.dart';

class LogisticsRemoteDataSource {
  final ApiClient _client;

  const LogisticsRemoteDataSource(this._client);

  // ─── Dashboard ───
  Future<LogisticsDashboardModel> getDashboard() async {
    try {
      final response =
          await _client.get(ApiConstants.logisticsMeDashboard);
      return LogisticsDashboardModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<LogisticsAccountModel> getAccount() async {
    try {
      final response =
          await _client.get(ApiConstants.logisticsMeAccount);
      return LogisticsAccountModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Shipments ───
  Future<List<LogisticsShipmentModel>> getShipments({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (status != null) params['status'] = status;
      final response = await _client.get(
        ApiConstants.logisticsMeShipments,
        queryParameters: params,
      );
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
              LogisticsShipmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> arrivedForPickup(String shipmentId) async {
    try {
      final response = await _client.post(
        ApiConstants.logisticsMeShipmentArrivedForPickup(shipmentId),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Wallet ───
  Future<LogisticsWalletModel> getWallet() async {
    try {
      final response = await _client.get(ApiConstants.logisticsWalletMe);
      return LogisticsWalletModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.logisticsWalletMeTransactions,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['results'] != null) {
        list = data['results'] as List;
      } else {
        list = [];
      }
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Team ───
  Future<List<LogisticsTeamMemberModel>> getTeamMembers() async {
    try {
      final response = await _client.get(ApiConstants.logisticsMeUsers);
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
          .map((e) => LogisticsTeamMemberModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<LogisticsTeamMemberModel> updateTeamMember(
      String userId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.logisticsMeUserById(userId),
        data: data,
      );
      return LogisticsTeamMemberModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Pricing / Rates ───
  Future<List<LogisticsRateModel>> getRates() async {
    try {
      final response = await _client.get(ApiConstants.logisticsMeRates);
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
              LogisticsRateModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<LogisticsRateModel> updateRate(
      String rateId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.logisticsMeRateById(rateId),
        data: data,
      );
      return LogisticsRateModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Services ───
  Future<List<LogisticsServiceModel>> getServices() async {
    try {
      final response = await _client.get(ApiConstants.logisticsMeServices);
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
          .map((e) => LogisticsServiceModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<LogisticsServiceModel> updateService(
      String serviceId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.logisticsMeServiceById(serviceId),
        data: data,
      );
      return LogisticsServiceModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Integration ───
  Future<LogisticsIntegrationModel> getIntegration() async {
    try {
      final response =
          await _client.get(ApiConstants.logisticsMeIntegration);
      return LogisticsIntegrationModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getWebhookEvents() async {
    try {
      final response =
          await _client.get(ApiConstants.logisticsMeWebhookEvents);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['results'] != null) {
        list = data['results'] as List;
      } else {
        list = [];
      }
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Onboarding ───
  Future<LogisticsOnboardingModel> getOnboarding() async {
    try {
      final response =
          await _client.get(ApiConstants.logisticsMeOnboarding);
      return LogisticsOnboardingModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> submitOnboarding() async {
    try {
      await _client.post(ApiConstants.logisticsMeOnboardingSubmit);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Documents ───
  Future<List<Map<String, dynamic>>> getDocuments() async {
    try {
      final response = await _client.get(ApiConstants.logisticsMeDocuments);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['results'] != null) {
        list = data['results'] as List;
      } else {
        list = [];
      }
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getDocumentRequirements() async {
    try {
      final response = await _client
          .get(ApiConstants.logisticsMeDocumentsRequirements);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
