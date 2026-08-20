import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/inventory_model.dart';
import '../models/seller_kyc_model.dart';
import '../models/seller_order_model.dart';
import '../models/seller_payout_model.dart';
import '../models/seller_profile_model.dart';
import '../models/store_gallery_image_model.dart';
import '../models/store_model.dart';
import '../models/store_opening_hour_model.dart';

class SellerRemoteDataSource {
  final ApiClient _client;

  const SellerRemoteDataSource(this._client);

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
  // SELLER PROFILE
  // =========================

  Future<SellerProfileModel> getMyProfile() async {
    try {
      final response = await _client.get(ApiConstants.sellerProfile);
      return SellerProfileModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerProfileModel> updateMyProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.sellerProfile,
        data: data,
      );
      return SellerProfileModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerProfileModel> getBusinessProfile() async {
    try {
      final response = await _client.get(ApiConstants.sellerBusinessProfile);
      return SellerProfileModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerProfileModel> updateBusinessProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.sellerBusinessProfile,
        data: data,
      );
      return SellerProfileModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // KYC DOCUMENTS
  // =========================

  Future<SellerKycStatusModel> getKycStatus() async {
    try {
      final response = await _client.get(ApiConstants.sellerKycStatus);
      return SellerKycStatusModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerKycDocumentModel>> getKycDocuments({
    int page = 1,
    int pageSize = 10,
    String? documentType,
    String? statusFilter,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.sellerKycDocuments,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (documentType != null) 'document_type': documentType,
          if (statusFilter != null) 'status_filter': statusFilter,
        },
      );
      final list = _extractList(response.data);
      return list
          .map((e) =>
              SellerKycDocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerKycDocumentModel> uploadKycDocument({
    required String documentType,
    required File file,
  }) async {
    try {
      final formData = FormData.fromMap({
        'document_type': documentType,
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await _client.post(
        ApiConstants.sellerKycDocuments,
        data: formData,
      );
      return SellerKycDocumentModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerKycDocumentModel>> uploadBulkKycDocuments({
    required File tinFile,
    required File businessProfileFile,
    required File businessRegistrationFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'tin_file': await MultipartFile.fromFile(tinFile.path),
        'business_profile_file':
            await MultipartFile.fromFile(businessProfileFile.path),
        'business_registration_file':
            await MultipartFile.fromFile(businessRegistrationFile.path),
      });
      final response = await _client.post(
        ApiConstants.sellerKycBulkUpload,
        data: formData,
      );
      final list = _extractList(response.data);
      return list
          .map((e) =>
              SellerKycDocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // PAYOUT ACCOUNTS
  // =========================

  Future<SellerPayoutAccountModel> createPayoutAccount({
    required String accountType,
    required String provider,
    required String accountName,
    required String accountNumber,
    String currency = 'TZS',
    bool isDefault = false,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerPayoutAccounts,
        data: {
          'account_type': accountType,
          'provider': provider,
          'account_name': accountName,
          'account_number': accountNumber,
          'currency': currency,
          'is_default': isDefault,
        },
      );
      return SellerPayoutAccountModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerPayoutAccountModel>> getPayoutAccounts({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.sellerPayoutAccounts,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      final list = _extractList(response.data);
      return list
          .map((e) =>
              SellerPayoutAccountModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deletePayoutAccount(String accountId) async {
    try {
      await _client.delete(ApiConstants.sellerPayoutAccountById(accountId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // STORE
  // =========================

  Future<StoreModel> getMyStore() async {
    try {
      final response = await _client.get(ApiConstants.myStore);
      return StoreModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<StoreModel> updateMyStore(Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.myStore,
        data: data,
      );
      return StoreModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<StoreModel> uploadStoreLogo(File file) async {
    try {
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(file.path),
      });
      final response = await _client.post(
        ApiConstants.myStoreLogo,
        data: formData,
      );
      return StoreModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<StoreModel> uploadStoreBanner(File file) async {
    try {
      final formData = FormData.fromMap({
        'banner': await MultipartFile.fromFile(file.path),
      });
      final response = await _client.post(
        ApiConstants.myStoreBanner,
        data: formData,
      );
      return StoreModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // STORE GALLERY
  // =========================

  Future<StoreGalleryImageModel> uploadGalleryImage({
    required File file,
    String? caption,
    int displayOrder = 0,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path),
        if (caption != null) 'caption': caption,
        'display_order': displayOrder,
      });
      final response = await _client.post(
        ApiConstants.myStoreGallery,
        data: formData,
      );
      return StoreGalleryImageModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<StoreGalleryImageModel>> getGalleryImages() async {
    try {
      final response = await _client.get(ApiConstants.myStoreGallery);
      final list = _extractList(response.data);
      return list
          .map((e) => StoreGalleryImageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<StoreGalleryImageModel> updateGalleryImage(
      String imageId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.myStoreGalleryImageById(imageId),
        data: data,
      );
      return StoreGalleryImageModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteGalleryImage(String imageId) async {
    try {
      await _client.delete(ApiConstants.myStoreGalleryImageById(imageId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // STORE OPENING HOURS
  // =========================

  Future<StoreOpeningHourModel> createOpeningHour(
      Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.myStoreOpeningHours,
        data: data,
      );
      return StoreOpeningHourModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<StoreOpeningHourModel>> getOpeningHours() async {
    try {
      final response = await _client.get(ApiConstants.myStoreOpeningHours);
      final list = _extractList(response.data);
      return list
          .map((e) => StoreOpeningHourModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<StoreOpeningHourModel> updateOpeningHour(
      String hourId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.myStoreOpeningHourById(hourId),
        data: data,
      );
      return StoreOpeningHourModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteOpeningHour(String hourId) async {
    try {
      await _client.delete(ApiConstants.myStoreOpeningHourById(hourId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // INVENTORY
  // =========================

  Future<List<InventoryModel>> getMyInventory() async {
    try {
      final response = await _client.get(ApiConstants.myInventory);
      final list = _extractList(response.data);
      return list
          .map((e) => InventoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<InventoryModel>> getLowStock() async {
    try {
      final response = await _client.get(ApiConstants.lowStockInventory);
      final list = _extractList(response.data);
      return list
          .map((e) => InventoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<InventoryModel> getInventoryByProduct(String productId) async {
    try {
      final response =
          await _client.get(ApiConstants.inventoryByProduct(productId));
      return InventoryModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<InventoryModel> updateInventory(
      String inventoryId, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        ApiConstants.inventoryById(inventoryId),
        data: data,
      );
      return InventoryModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<InventoryModel> createInventory(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.inventory,
        data: data,
      );
      return InventoryModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // PRODUCTS (seller's own)
  // =========================

  Future<List<Map<String, dynamic>>> getMyProducts({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.myProducts,
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.products,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updateProduct(
      String productId, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        ApiConstants.productById(productId),
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _client.delete(ApiConstants.productById(productId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // ORDERS (seller's own)
  // =========================

  Future<List<SellerOrderModel>> getMyOrders({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.myOrders,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final list = _extractList(response.data);
      return list
          .map((e) => SellerOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getSellerOrderSummary() async {
    try {
      final response = await _client.get(ApiConstants.sellerOrdersSummary);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerOrderModel>> getSellerOrders({
    int page = 1,
    int pageSize = 5,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.sellerOrders,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final list = _extractList(response.data);
      return list
          .map((e) => SellerOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderModel> getOrderById(String orderId) async {
    try {
      final response = await _client.get(ApiConstants.orderById(orderId));
      return SellerOrderModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderModel> updateOrderStatus(
      String orderId, String status, {String? notes}) async {
    try {
      final response = await _client.patch(
        ApiConstants.orderStatus(orderId),
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
        },
      );
      return SellerOrderModel.fromJson(
          response.data as Map<String, dynamic>);
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
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (_) {
      // Fallback: try product categories (public endpoint)
      try {
        final response = await _client.get(ApiConstants.productCategories);
        final list = _extractList(response.data);
        return list.cast<Map<String, dynamic>>();
      } on DioException catch (e) {
        throw ServerException(_client.getErrorMessage(e));
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client.get(ApiConstants.productCategories);
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      final response = await _client.get(ApiConstants.productBrands);
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // WALLET
  // =========================

  Future<Map<String, dynamic>> getMyWallet() async {
    try {
      final response = await _client.get(ApiConstants.myWallet);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions() async {
    try {
      final response = await _client.get(ApiConstants.myWalletTransactions);
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> requestPayout({
    required String payoutAccountId,
    required double amount,
    String? note,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.myWalletPayouts,
        data: {
          'payout_account_id': payoutAccountId,
          'amount': amount,
          if (note != null) 'note': note,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getMyPayouts() async {
    try {
      final response = await _client.get(ApiConstants.myWalletPayouts);
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> cancelPayout(String payoutId) async {
    try {
      final response = await _client.post(ApiConstants.cancelPayout(payoutId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // COMMISSIONS & EARNINGS
  // =========================

  Future<Map<String, dynamic>> getEarningsSummary() async {
    try {
      final response = await _client.get(ApiConstants.sellerEarningsSummary);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getOrderCommissions(String orderId) async {
    try {
      final response = await _client.get(ApiConstants.orderCommissions(orderId));
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // ANALYTICS
  // =========================

  Future<Map<String, dynamic>> getSellerAnalyticsOverview({
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.analyticsSellerOverview,
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

  Future<List<Map<String, dynamic>>> getSellerAnalyticsSales({
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.analyticsSellerSales,
        queryParameters: {
          if (startAt != null) 'start_at': startAt.toIso8601String(),
          if (endAt != null) 'end_at': endAt.toIso8601String(),
        },
      );
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getSellerAnalyticsProducts({
    DateTime? startAt,
    DateTime? endAt,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.analyticsSellerProducts,
        queryParameters: {
          'limit': limit,
          if (startAt != null) 'start_at': startAt.toIso8601String(),
          if (endAt != null) 'end_at': endAt.toIso8601String(),
        },
      );
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // SHIPPING
  // =========================

  Future<List<Map<String, dynamic>>> getShippingZones({bool activeOnly = true}) async {
    try {
      final response = await _client.get(
        ApiConstants.shippingZones,
        queryParameters: {'active_only': activeOnly},
      );
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getShippingMethods() async {
    try {
      final response = await _client.get(ApiConstants.shippingMethods);
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getShippingQuote({
    required String addressId,
    required double subtotal,
    double weightKg = 0,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.shippingQuote,
        data: {
          'address_id': addressId,
          'subtotal': subtotal,
          'weight_kg': weightKg,
        },
      );
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // =========================
  // SHIPMENTS
  // =========================

  Future<List<Map<String, dynamic>>> getSellerShipments() async {
    try {
      final response = await _client.get(ApiConstants.sellerShipments);
      final list = _extractList(response.data);
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getShipmentById(String shipmentId) async {
    try {
      final response = await _client.get(ApiConstants.shipmentById(shipmentId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updateShipmentStatus(
      String shipmentId, {
    required String status,
    String? location,
    String? notes,
    String? trackingNumber,
    String? carrierName,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.shipmentEvent(shipmentId),
        data: {
          'status': status,
          if (location != null) 'location': location,
          if (notes != null) 'notes': notes,
          if (trackingNumber != null) 'tracking_number': trackingNumber,
          if (carrierName != null) 'carrier_name': carrierName,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
