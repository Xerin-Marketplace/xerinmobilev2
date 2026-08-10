import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/admin_dashboard_model.dart';

class AdminDashboardDataSource {
  final ApiClient _client;

  const AdminDashboardDataSource(this._client);

  Future<AdminDashboardSummary> getSummary({String period = '30d'}) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardSummary,
        queryParameters: {'period': period},
      );
      return AdminDashboardSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardSales> getSales({String period = '30d'}) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardSales,
        queryParameters: {'period': period},
      );
      return AdminDashboardSales.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getOrders({String period = '30d'}) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardOrders,
        queryParameters: {'period': period},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardSellers> getSellers() async {
    try {
      final response = await _client.get(ApiConstants.adminDashboardSellers);
      return AdminDashboardSellers.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardProducts> getProducts() async {
    try {
      final response = await _client.get(ApiConstants.adminDashboardProducts);
      return AdminDashboardProducts.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardCustomers> getCustomers() async {
    try {
      final response = await _client.get(ApiConstants.adminDashboardCustomers);
      return AdminDashboardCustomers.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardPayments> getPayments() async {
    try {
      final response = await _client.get(ApiConstants.adminDashboardPayments);
      return AdminDashboardPayments.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardRefunds> getRefunds() async {
    try {
      final response = await _client.get(ApiConstants.adminDashboardRefunds);
      return AdminDashboardRefunds.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardDelivery> getDelivery() async {
    try {
      final response = await _client.get(ApiConstants.adminDashboardDelivery);
      return AdminDashboardDelivery.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardNotifications> getNotifications() async {
    try {
      final response = await _client.get(ApiConstants.adminDashboardNotifications);
      return AdminDashboardNotifications.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getSearch({int limit = 10}) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardSearch,
        queryParameters: {'limit': limit},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminSystemAlert>> getAlerts({bool? resolved, int limit = 50}) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardAlerts,
        queryParameters: {
          if (resolved != null) 'resolved': resolved,
          'limit': limit,
        },
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => AdminSystemAlert.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> resolveAlert(String alertId) async {
    try {
      await _client.patch(ApiConstants.adminDashboardAlertResolve(alertId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminActivityLog>> getActivityLogs({int limit = 100}) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardActivityLogs,
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => AdminActivityLog.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
