import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';
import '../../../admin/data/models/admin_dashboard_model.dart';

class NotificationRemoteDataSource {
  final ApiClient _client;

  const NotificationRemoteDataSource(this._client);

  Future<List<NotificationModel>> getNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.get(
        ApiConstants.notifications,
        queryParameters: {'page': page, 'page_size': pageSize},
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
      return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<NotificationSummary> getSummary() async {
    try {
      final response = await _client.get(ApiConstants.notificationsSummary);
      return NotificationSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.post(ApiConstants.notificationRead(notificationId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _client.post(ApiConstants.notificationsReadAll);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.delete(ApiConstants.notificationById(notificationId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<NotificationPreferenceModel> getPreferences() async {
    try {
      final response = await _client.get(ApiConstants.notificationPreferences);
      return NotificationPreferenceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<NotificationPreferenceModel> updatePreferences(NotificationPreferenceModel prefs) async {
    try {
      final response = await _client.put(
        ApiConstants.notificationPreferences,
        data: prefs.toJson(),
      );
      return NotificationPreferenceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    try {
      await _client.post(
        ApiConstants.notificationDeviceTokens,
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> unregisterDeviceToken(String tokenId) async {
    try {
      await _client.delete(ApiConstants.notificationDeviceTokenById(tokenId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
