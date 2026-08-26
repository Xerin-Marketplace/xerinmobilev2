import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/support_model.dart';

class SupportRemoteDataSource {
  final ApiClient _client;

  const SupportRemoteDataSource(this._client);

  Future<List<SupportTicketModel>> getMyTickets({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.supportMyTickets,
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
      return list
          .map((e) => SupportTicketModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SupportTicketModel> getTicket(String ticketId) async {
    try {
      final response =
          await _client.get(ApiConstants.supportTicketById(ticketId));
      return SupportTicketModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SupportTicketModel> createTicket({
    required String subject,
    String? description,
    String? category,
    String priority = 'medium',
    String? orderId,
    String? sellerId,
    String? shipmentId,
  }) async {
    try {
      final body = <String, dynamic>{
        'subject': subject,
        'priority': priority,
        'channel': 'customer',
      };
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (orderId != null) body['order_id'] = orderId;
      if (sellerId != null) body['seller_id'] = sellerId;
      if (shipmentId != null) body['shipment_id'] = shipmentId;

      final response = await _client.post(
        ApiConstants.supportTickets,
        data: body,
      );
      return SupportTicketModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SupportTicketMessageModel> replyTicket({
    required String ticketId,
    required String message,
    String visibility = 'all',
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.supportTicketMessages(ticketId),
        data: {'message': message, 'visibility': visibility},
      );
      return SupportTicketMessageModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // Admin support ticket endpoints
  Future<List<SupportTicketModel>> adminGetAllTickets({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (search != null) params['search'] = search;
      if (status != null) params['status'] = status;

      final response = await _client.get(
        '/admin/support-tickets',
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
          .map((e) => SupportTicketModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SupportTicketModel> adminGetTicket(String ticketId) async {
    try {
      final response =
          await _client.get('/admin/support-tickets/$ticketId');
      return SupportTicketModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SupportTicketModel> adminUpdateTicket({
    required String ticketId,
    String? status,
    String? priority,
    String? assignedToId,
    String? resolutionNote,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (priority != null) body['priority'] = priority;
      if (assignedToId != null) body['assigned_to_id'] = assignedToId;
      if (resolutionNote != null) body['resolution_note'] = resolutionNote;

      final response = await _client.patch(
        '/admin/support-tickets/$ticketId',
        data: body,
      );
      return SupportTicketModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SupportTicketMessageModel> adminReplyTicket({
    required String ticketId,
    required String message,
    String visibility = 'all',
  }) async {
    try {
      final response = await _client.post(
        '/admin/support-tickets/$ticketId/messages',
        data: {'message': message, 'visibility': visibility},
      );
      return SupportTicketMessageModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
