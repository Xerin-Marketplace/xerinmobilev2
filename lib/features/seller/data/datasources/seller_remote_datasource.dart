import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/seller_models.dart';

class SellerRemoteDataSource {
  final ApiClient _client;

  const SellerRemoteDataSource(this._client);

  // ─── Seller Profile ───
  Future<SellerModel> getSellerMe() async {
    try {
      final response = await _client.get(ApiConstants.sellerProfile);
      return SellerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerModel> updateSellerMe(Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(ApiConstants.sellerProfile, data: data);
      return SellerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerModel> registerSeller(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(ApiConstants.sellerRegister, data: data);
      return SellerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerBusinessProfileModel> getBusinessProfile() async {
    try {
      final response = await _client.get(ApiConstants.sellerBusinessProfile);
      return SellerBusinessProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerBusinessProfileModel> updateBusinessProfile(Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(ApiConstants.sellerBusinessProfile, data: data);
      return SellerBusinessProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<BusinessCategoryModel>> getBusinessCategories() async {
    try {
      final response = await _client.get(ApiConstants.businessCategories);
      final data = response.data;
      final list = data is List ? data : [];
      return list.map((e) => BusinessCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Dashboard ───
  Future<SellerDashboardPerformanceModel> getDashboardPerformance() async {
    try {
      final response = await _client.get(ApiConstants.sellerDashboard);
      return SellerDashboardPerformanceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Pricing Preview ───
  Future<SellerPricingPreviewModel> previewPricing(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(ApiConstants.sellerPricingPreview, data: data);
      return SellerPricingPreviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── KYC ───
  Future<List<SellerKycDocumentModel>> getKycDocuments() async {
    try {
      final response = await _client.get(ApiConstants.sellerKycDocuments);
      final data = response.data;
      if (data is List) {
        return data.map((e) => SellerKycDocumentModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map) {
        final results = data['results'] as List? ?? [];
        return results.map((e) => SellerKycDocumentModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerKycStatusModel> getKycStatus() async {
    try {
      final response = await _client.get(ApiConstants.sellerKycStatus);
      return SellerKycStatusModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerKycDocumentModel> uploadKycDocument({
    required String documentType,
    required String filePath,
    String? fileName,
    String? mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'document_type': documentType,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _client.post(
        ApiConstants.sellerKycDocuments,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return SellerKycDocumentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Payout Accounts ───
  Future<List<PayoutAccountModel>> getPayoutAccounts() async {
    try {
      final response = await _client.get(ApiConstants.sellerPayoutAccounts);
      final data = response.data;
      if (data is List) {
        return data.map((e) => PayoutAccountModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map) {
        final results = data['results'] as List? ?? [];
        return results.map((e) => PayoutAccountModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PayoutAccountModel> createPayoutAccount(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(ApiConstants.sellerPayoutAccounts, data: data);
      return PayoutAccountModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deletePayoutAccount(String id) async {
    try {
      await _client.delete(ApiConstants.sellerPayoutAccountById(id));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Seller Orders ───
  Future<SellerOrderSummaryModel> getOrderSummary() async {
    try {
      final response = await _client.get(ApiConstants.sellerOrdersSummary);
      return SellerOrderSummaryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderListResponse> getOrders({
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
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (status != null && status.isNotEmpty) params['status'] = status;
      final response = await _client.get(ApiConstants.sellerOrders, queryParameters: params);
      return SellerOrderListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderModel> getOrder(String id) async {
    try {
      final response = await _client.get(ApiConstants.sellerOrderById(id));
      return SellerOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderModel> acceptOrder(String id, {String? notes}) async {
    try {
      final response = await _client.post(ApiConstants.sellerOrderAccept(id), data: {'notes': notes});
      return SellerOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderModel> startProcessing(String id, {String? notes}) async {
    try {
      final response = await _client.post(ApiConstants.sellerOrderStartProcessing(id), data: {'notes': notes});
      return SellerOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderModel> readyToShip(String id, {String? notes}) async {
    try {
      final response = await _client.post(ApiConstants.sellerOrderReadyToShip(id), data: {'notes': notes});
      return SellerOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderModel> dispatchOrder(String id, {
    required String carrierName,
    required String trackingNumber,
    String? trackingUrl,
    String? location,
    String? notes,
  }) async {
    try {
      final response = await _client.post(ApiConstants.sellerOrderDispatch(id), data: {
        'carrier_name': carrierName,
        'tracking_number': trackingNumber,
        'tracking_url': trackingUrl,
        'location': location,
        'notes': notes,
      });
      return SellerOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderModel> cancelOrder(String id, {required String reason, String? notes}) async {
    try {
      final response = await _client.post(ApiConstants.sellerOrderRequestCancellation(id), data: {
        'reason': reason,
        'notes': notes,
      });
      return SellerOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerOrderMessageModel>> getOrderMessages(String id) async {
    try {
      final response = await _client.get(ApiConstants.sellerOrderMessages(id));
      final data = response.data;
      final list = data is List ? data : [];
      return list.map((e) => SellerOrderMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderMessageModel> sendOrderMessage(String id, {
    required String message,
    bool isInternal = false,
  }) async {
    try {
      final response = await _client.post(ApiConstants.sellerOrderMessages(id), data: {
        'message': message,
        'is_internal': isInternal,
      });
      return SellerOrderMessageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Seller Inventory ───
  Future<SellerInventoryListResponse> getInventory({
    String? search,
    bool? lowStock,
    bool? outOfStock,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (lowStock == true) params['low_stock'] = true;
      if (outOfStock == true) params['out_of_stock'] = true;
      final response = await _client.get(ApiConstants.sellerInventory, queryParameters: params);
      return SellerInventoryListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerInventorySummaryModel> getInventorySummary() async {
    try {
      final response = await _client.get(ApiConstants.sellerInventorySummary);
      return SellerInventorySummaryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerInventoryItemModel>> getLowStockInventory() async {
    try {
      final response = await _client.get(ApiConstants.sellerInventoryLowStock);
      final data = response.data;
      final list = data is List ? data : [];
      return list.map((e) => SellerInventoryItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerInventoryMovementModel>> getInventoryHistory({
    String? inventoryId,
    String? movementType,
    int limit = 100,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (inventoryId != null) params['inventory_id'] = inventoryId;
      if (movementType != null) params['movement_type'] = movementType;
      final response = await _client.get(ApiConstants.sellerInventoryHistory, queryParameters: params);
      final data = response.data;
      final list = data is List ? data : [];
      return list.map((e) => SellerInventoryMovementModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerInventoryItemModel> updateInventorySettings(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(ApiConstants.sellerInventoryById(id), data: data);
      return SellerInventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerInventoryItemModel> adjustInventory(String id, {
    required int adjustment,
    required String reason,
    String? reference,
    String? note,
  }) async {
    try {
      final response = await _client.post(ApiConstants.sellerInventoryAdjust(id), data: {
        'adjustment': adjustment,
        'reason': reason,
        'reference': reference,
        'note': note,
      });
      return SellerInventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerInventoryItemModel> restockInventory(String id, {
    required int quantity,
    String? warehouseLocation,
    String? reference,
    String? note,
  }) async {
    try {
      final response = await _client.post(ApiConstants.sellerInventoryRestock(id), data: {
        'quantity': quantity,
        'warehouse_location': warehouseLocation,
        'reference': reference,
        'note': note,
      });
      return SellerInventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Wallet ───
  Future<SellerWalletModel> getWallet() async {
    try {
      final response = await _client.get(ApiConstants.myWallet);
      return SellerWalletModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PaginatedWalletTransactions> getWalletTransactions({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.get(ApiConstants.myWalletTransactions, queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      return PaginatedWalletTransactions.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<PaginatedSellerPayouts> getPayouts({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.get(ApiConstants.myWalletPayouts, queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      return PaginatedSellerPayouts.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerPayoutModel> requestPayout({
    required String payoutAccountId,
    required double amount,
    String? note,
  }) async {
    try {
      final response = await _client.post(ApiConstants.requestPayout, data: {
        'payout_account_id': payoutAccountId,
        'amount': amount,
        'note': note,
      });
      return SellerPayoutModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerPayoutModel> cancelPayout(String payoutId) async {
    try {
      final response = await _client.post(ApiConstants.cancelPayout(payoutId));
      return SellerPayoutModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerEarningsSummaryModel> getEarningsSummary() async {
    try {
      final response = await _client.get(ApiConstants.sellerEarningsSummary);
      return SellerEarningsSummaryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Analytics ───
  Future<SellerAnalyticsOverviewModel> getAnalyticsOverview() async {
    try {
      final response = await _client.get(ApiConstants.analyticsSellerOverview);
      return SellerAnalyticsOverviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AnalyticsSeriesPointModel>> getAnalyticsSales() async {
    try {
      final response = await _client.get(ApiConstants.analyticsSellerSales);
      final data = response.data;
      final list = data is List ? data : [];
      return list.map((e) => AnalyticsSeriesPointModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<AnalyticsRankingRowModel>> getAnalyticsProducts({int limit = 20}) async {
    try {
      final response = await _client.get(ApiConstants.analyticsSellerProducts, queryParameters: {'limit': limit});
      final data = response.data;
      final list = data is List ? data : [];
      return list.map((e) => AnalyticsRankingRowModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Seller Store ───
  Future<Map<String, dynamic>> getStore() async {
    try {
      final response = await _client.get(ApiConstants.sellerStore);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updateStore(Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(ApiConstants.sellerStore, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> uploadStoreLogo(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _client.post(
        ApiConstants.sellerStoreLogo,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> uploadStoreBanner(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _client.post(
        ApiConstants.sellerStoreBanner,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
