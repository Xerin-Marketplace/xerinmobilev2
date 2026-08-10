import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

class AdminRemoteDataSource {
  final ApiClient _client;

  const AdminRemoteDataSource(this._client);

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['items'] is List) return data['items'] as List;
      if (data['data'] is List) return data['data'] as List;
      if (data['results'] is List) return data['results'] as List;
    }
    return [];
  }

  // =========================
  // USERS
  // =========================

  Future<List<Map<String, dynamic>>> getUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminUsers,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null) 'search': search,
        },
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await _client.get(ApiConstants.adminUserById(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.adminUserById(id),
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _client.delete(ApiConstants.adminUserById(id));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> createAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.adminCreateAdmin,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // SELLERS
  // =========================

  Future<Map<String, dynamic>> registerSeller({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? businessName,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.registerSeller,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
          if (businessName != null) 'business_name': businessName,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getSellers({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminSellers,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSellers({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminSellersPending,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getSellerById(String id) async {
    try {
      final response = await _client.get(ApiConstants.adminSellerById(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> approveSeller(String id) async {
    try {
      final response = await _client.post(
        ApiConstants.adminApproveSellerById(id),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> rejectSeller(String id,
      {String? reason}) async {
    try {
      final response = await _client.post(
        ApiConstants.adminRejectSellerById(id),
        data: {if (reason != null) 'reason': reason},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // PRODUCTS
  // =========================

  Future<List<Map<String, dynamic>>> getPendingProducts({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminProductsPending,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> approveProduct(String id) async {
    try {
      final response = await _client.post(
        ApiConstants.adminApproveProduct(id),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> rejectProduct(String id,
      {String? reason}) async {
    try {
      final response = await _client.post(
        ApiConstants.adminRejectProduct(id),
        data: {if (reason != null) 'reason': reason},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // CATEGORIES & BRANDS
  // =========================

  Future<List<Map<String, dynamic>>> getBusinessCategories() async {
    try {
      final response = await _client.get(ApiConstants.adminBusinessCategories);
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> createBusinessCategory(
      Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.adminBusinessCategories,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteBusinessCategory(String id) async {
    try {
      await _client.delete(ApiConstants.adminBusinessCategoryById(id));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getProductCategories() async {
    try {
      final response = await _client.get(ApiConstants.adminProductCategories);
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> createProductCategory(
      Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.adminProductCategories,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteProductCategory(String id) async {
    try {
      await _client.delete(ApiConstants.adminProductCategoryById(id));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      final response = await _client.get(ApiConstants.adminBrands);
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> createBrand(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.adminBrands,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteBrand(String id) async {
    try {
      await _client.delete(ApiConstants.adminBrandById(id));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // HEALTH CHECK
  // =========================

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _client.get('/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // ANALYTICS (admin)
  // =========================

  Future<List<Map<String, dynamic>>> getAllOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminAllOrders,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null) 'status': status,
        },
      );
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
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

  Future<Map<String, dynamic>> getAdminAnalyticsOverview({
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.analyticsAdminOverview,
        queryParameters: {
          if (startAt != null) 'start_at': startAt.toIso8601String(),
          if (endAt != null) 'end_at': endAt.toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getAdminAnalyticsSales({
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.analyticsAdminSales,
        queryParameters: {
          if (startAt != null) 'start_at': startAt.toIso8601String(),
          if (endAt != null) 'end_at': endAt.toIso8601String(),
        },
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getAdminAnalyticsSellers({
    DateTime? startAt,
    DateTime? endAt,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.analyticsAdminSellers,
        queryParameters: {
          'limit': limit,
          if (startAt != null) 'start_at': startAt.toIso8601String(),
          if (endAt != null) 'end_at': endAt.toIso8601String(),
        },
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getAdminAnalyticsProducts({
    DateTime? startAt,
    DateTime? endAt,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.analyticsAdminProducts,
        queryParameters: {
          'limit': limit,
          if (startAt != null) 'start_at': startAt.toIso8601String(),
          if (endAt != null) 'end_at': endAt.toIso8601String(),
        },
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getAdminReconciliation({
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.analyticsAdminReconciliation,
        queryParameters: {
          if (startAt != null) 'start_at': startAt.toIso8601String(),
          if (endAt != null) 'end_at': endAt.toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // AUDIT LOGS
  // =========================

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? action,
    String? resourceType,
    String? severity,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.auditLogs,
        queryParameters: {
          if (action != null) 'action': action,
          if (resourceType != null) 'resource_type': resourceType,
          if (severity != null) 'severity': severity,
          'limit': limit,
          'offset': offset,
        },
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getAuditLogById(String auditId) async {
    try {
      final response = await _client.get('${ApiConstants.auditLogs}/$auditId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getSecurityEvents({
    String? eventType,
    String? severity,
    bool? resolved,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _client.get(
        '${ApiConstants.auditLogs}/security/events',
        queryParameters: {
          if (eventType != null) 'event_type': eventType,
          if (severity != null) 'severity': severity,
          if (resolved != null) 'resolved': resolved,
          'limit': limit,
          'offset': offset,
        },
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> resolveSecurityEvent(
      String eventId, {String? note}) async {
    try {
      final response = await _client.patch(
        '${ApiConstants.auditLogs}/security/events/$eventId/resolve',
        data: {if (note != null) 'note': note},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // REFUNDS (admin)
  // =========================

  Future<List<Map<String, dynamic>>> getAllRefunds({
    String? refundStatus,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminRefunds,
        queryParameters: {
          if (refundStatus != null) 'refund_status': refundStatus,
        },
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> reviewRefund(String refundId,
      {String? note}) async {
    try {
      final response = await _client.post(
        ApiConstants.reviewRefund(refundId),
        data: {if (note != null) 'note': note},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> approveRefund(String refundId,
      {String? note}) async {
    try {
      final response = await _client.post(
        ApiConstants.approveRefund(refundId),
        data: {if (note != null) 'note': note},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> rejectRefund(String refundId,
      {String? note}) async {
    try {
      final response = await _client.post(
        ApiConstants.rejectRefund(refundId),
        data: {if (note != null) 'note': note},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> processRefund(String refundId,
      {String? providerReference, String? note}) async {
    try {
      final response = await _client.post(
        ApiConstants.processRefund(refundId),
        data: {
          if (providerReference != null) 'provider_reference': providerReference,
          if (note != null) 'note': note,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // WALLETS (admin)
  // =========================

  Future<List<Map<String, dynamic>>> getAllWallets() async {
    try {
      final response = await _client.get(ApiConstants.adminWallets);
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getAllPayouts() async {
    try {
      final response = await _client.get(ApiConstants.adminPayouts);
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updatePayout(
      String payoutId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.adminUpdatePayout(payoutId),
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> adjustWallet(
      String sellerId, double amount, String reason) async {
    try {
      final response = await _client.post(
        ApiConstants.adminWalletAdjustment(sellerId),
        data: {'amount': amount, 'reason': reason},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // COMMISSIONS (admin)
  // =========================

  Future<List<Map<String, dynamic>>> getCommissionRules({
    bool activeOnly = false,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.commissionRules,
        queryParameters: {'active_only': activeOnly},
      );
      return _extractList(response.data).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> createCommissionRule(
      Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.commissionRules,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updateCommissionRule(
      String ruleId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.commissionRuleById(ruleId),
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
