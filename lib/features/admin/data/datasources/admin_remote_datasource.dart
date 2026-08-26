import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/admin_models.dart';

class AdminRemoteDataSource {
  final ApiClient _client;

  const AdminRemoteDataSource(this._client);

  // ─── Dashboard ───
  Future<AdminDashboardSummaryModel> getDashboardSummary({
    String period = '30d',
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardSummary,
        queryParameters: {'period': period},
      );
      return AdminDashboardSummaryModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardOrdersModel> getDashboardOrders({
    String period = '30d',
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardOrders,
        queryParameters: {'period': period},
      );
      return AdminDashboardOrdersModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardSellersModel> getDashboardSellers() async {
    try {
      final response =
          await _client.get(ApiConstants.adminDashboardSellers);
      return AdminDashboardSellersModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardProductsModel> getDashboardProducts() async {
    try {
      final response =
          await _client.get(ApiConstants.adminDashboardProducts);
      return AdminDashboardProductsModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardCustomersModel> getDashboardCustomers() async {
    try {
      final response =
          await _client.get(ApiConstants.adminDashboardCustomers);
      return AdminDashboardCustomersModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardPaymentsModel> getDashboardPayments() async {
    try {
      final response =
          await _client.get(ApiConstants.adminDashboardPayments);
      return AdminDashboardPaymentsModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminDashboardRefundsModel> getDashboardRefunds() async {
    try {
      final response = await _client.get(ApiConstants.adminDashboardRefunds);
      return AdminDashboardRefundsModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminSystemAlertModel>> getAlerts({
    bool? resolved,
    int limit = 50,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardAlerts,
        queryParameters: {
          if (resolved != null) 'resolved': resolved,
          'limit': limit,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              AdminSystemAlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> resolveAlert(String alertId) async {
    try {
      await _client.patch(
          ApiConstants.adminDashboardAlertResolve(alertId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminActivityLogModel>> getActivityLogs({
    int limit = 100,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminDashboardActivityLogs,
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              AdminActivityLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Sellers ───
  Future<List<AdminSellerModel>> getAllSellers() async {
    try {
      final response = await _client.get(ApiConstants.adminSellers);
      final data = response.data;
      if (data is List) {
        return data
            .map((e) =>
                AdminSellerModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final list = data['results'] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              AdminSellerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminSellerModel>> getPendingSellers() async {
    try {
      final response =
          await _client.get(ApiConstants.adminSellersPending);
      final data = response.data;
      if (data is List) {
        return data
            .map((e) =>
                AdminSellerModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final list = data['results'] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              AdminSellerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminSellerModel> startSellerReview(String sellerId) async {
    try {
      final response = await _client.post(
        ApiConstants.adminStartSellerReview(sellerId),
      );
      return AdminSellerModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminSellerModel> approveSeller(String sellerId) async {
    try {
      final response = await _client.post(
        ApiConstants.adminApproveSellerById(sellerId),
      );
      return AdminSellerModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminSellerModel> rejectSeller(
      String sellerId, String reason) async {
    try {
      final formData = FormData.fromMap({'reason': reason});
      final response = await _client.post(
        ApiConstants.adminRejectSellerById(sellerId),
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return AdminSellerModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminSellerDocumentModel>> getSellerDocuments(
      String sellerId) async {
    try {
      final response =
          await _client.get(ApiConstants.adminSellerDocs(sellerId));
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => AdminSellerDocumentModel.fromJson(
                e as Map<String, dynamic>))
            .toList();
      }
      final list = data['results'] as List<dynamic>? ?? [];
      return list
          .map((e) => AdminSellerDocumentModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Products ───
  Future<List<Map<String, dynamic>>> getPendingProducts() async {
    try {
      final response =
          await _client.get(ApiConstants.adminProductsPending);
      final list = response.data as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> approveProduct(String productId) async {
    try {
      final response = await _client.post(
        ApiConstants.adminApproveProduct(productId),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> rejectProduct(
      String productId, String reason) async {
    try {
      final formData = FormData.fromMap({'reason': reason});
      final response = await _client.post(
        ApiConstants.adminRejectProduct(productId),
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Users ───
  Future<PaginatedAdminUsers> getUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? statusFilter,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminUsers,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (statusFilter != null && statusFilter.isNotEmpty)
            'status_filter': statusFilter,
        },
      );
      return PaginatedAdminUsers.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminUserModel> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.adminUsers,
        data: data,
      );
      return AdminUserModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminUserModel> updateUser(
      String userId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.adminUserById(userId),
        data: data,
      );
      return AdminUserModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _client.delete(ApiConstants.adminUserById(userId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminUserModel> createAdmin(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.adminCreateAdmin,
        data: data,
      );
      return AdminUserModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Wallets ───
  Future<List<AdminWalletModel>> getAllWallets() async {
    try {
      final response = await _client.get(ApiConstants.adminWallets);
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              AdminWalletModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminPayoutModel>> getAllPayouts() async {
    try {
      final response = await _client.get(ApiConstants.adminPayouts);
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              AdminPayoutModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminPayoutModel> updatePayout(
      String payoutId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.adminUpdatePayout(payoutId),
        data: data,
      );
      return AdminPayoutModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminWalletModel> adjustWallet(
      String sellerId, double amount, String reason) async {
    try {
      final response = await _client.post(
        ApiConstants.adminWalletAdjustment(sellerId),
        data: {'amount': amount, 'reason': reason},
      );
      return AdminWalletModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Refunds ───
  Future<List<AdminRefundModel>> getAllRefunds({
    String? refundStatus,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.adminRefunds,
        queryParameters: {
          if (refundStatus != null) 'refund_status': refundStatus,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              AdminRefundModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminRefundModel> reviewRefund(String refundId,
      {String? note}) async {
    try {
      final response = await _client.post(
        ApiConstants.reviewRefund(refundId),
        data: {'note': note},
      );
      return AdminRefundModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminRefundModel> approveRefund(String refundId,
      {String? note}) async {
    try {
      final response = await _client.post(
        ApiConstants.approveRefund(refundId),
        data: {'note': note},
      );
      return AdminRefundModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminRefundModel> rejectRefund(String refundId,
      {String? note}) async {
    try {
      final response = await _client.post(
        ApiConstants.rejectRefund(refundId),
        data: {'note': note},
      );
      return AdminRefundModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminRefundModel> processRefund(String refundId,
      {String? note, String? providerReference}) async {
    try {
      final response = await _client.post(
        ApiConstants.processRefund(refundId),
        data: {
          'note': note,
          'provider_reference': providerReference,
        },
      );
      return AdminRefundModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Reviews ───
  Future<List<AdminReviewModel>> getAllReviews() async {
    try {
      final response = await _client.get(ApiConstants.adminReviews);
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => AdminReviewModel.fromJson(
                e as Map<String, dynamic>))
            .toList();
      }
      final list = data['results'] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              AdminReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminReviewModel> moderateReview(
      String reviewId, String status) async {
    try {
      final response = await _client.patch(
        ApiConstants.adminReviewModerate(reviewId),
        data: {'status': status},
      );
      return AdminReviewModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Orders ───
  Future<Map<String, dynamic>> getAllOrders({
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
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Analytics ───
  Future<AdminAnalyticsOverviewModel> getAnalyticsOverview() async {
    try {
      final response =
          await _client.get(ApiConstants.analyticsAdminOverview);
      return AdminAnalyticsOverviewModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminAnalyticsSalesPointModel>> getAnalyticsSales() async {
    try {
      final response =
          await _client.get(ApiConstants.analyticsAdminSales);
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => AdminAnalyticsSalesPointModel.fromJson(
                e as Map<String, dynamic>))
            .toList();
      }
      final list = data['results'] as List<dynamic>? ?? [];
      return list
          .map((e) => AdminAnalyticsSalesPointModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminAnalyticsSellerRankingModel>>
      getAnalyticsSellers() async {
    try {
      final response =
          await _client.get(ApiConstants.analyticsAdminSellers);
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => AdminAnalyticsSellerRankingModel.fromJson(
                e as Map<String, dynamic>))
            .toList();
      }
      final list = data['results'] as List<dynamic>? ?? [];
      return list
          .map((e) => AdminAnalyticsSellerRankingModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminAnalyticsProductRankingModel>>
      getAnalyticsProducts() async {
    try {
      final response =
          await _client.get(ApiConstants.analyticsAdminProducts);
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => AdminAnalyticsProductRankingModel.fromJson(
                e as Map<String, dynamic>))
            .toList();
      }
      final list = data['results'] as List<dynamic>? ?? [];
      return list
          .map((e) => AdminAnalyticsProductRankingModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Roles & Permissions ────────────────────────────────────

  Future<List<AdminRoleModel>> getRoles() async {
    try {
      final response = await _client.get(ApiConstants.adminRoles);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => AdminRoleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AdminPermissionModel>> getAllPermissions() async {
    try {
      final response = await _client.get(ApiConstants.adminPermissions);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => AdminPermissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminRolePermissionsModel> getRolePermissions(String roleId) async {
    try {
      final response =
          await _client.get(ApiConstants.adminRolePermissions(roleId));
      return AdminRolePermissionsModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminRolePermissionsModel> updateRolePermissions(
      String roleId, List<String> permissionCodes) async {
    try {
      final response = await _client.put(
        ApiConstants.adminRolePermissions(roleId),
        data: {'permission_codes': permissionCodes},
      );
      return AdminRolePermissionsModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminUserPermissionsModel> getUserPermissions(String userId) async {
    try {
      final response =
          await _client.get(ApiConstants.adminUserPermissions(userId));
      return AdminUserPermissionsModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<AdminUserPermissionsModel> assignUserPermissions(
      String userId, List<String> permissionCodes) async {
    try {
      final response = await _client.post(
        ApiConstants.adminUserPermissions(userId),
        data: {'permission_codes': permissionCodes},
      );
      return AdminUserPermissionsModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
