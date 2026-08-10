import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/seller_order_detail_model.dart';
import '../models/seller_inventory_model.dart';

class SellerOrdersInventoryDataSource {
  final ApiClient _client;

  const SellerOrdersInventoryDataSource(this._client);

  // ─── Seller Orders ───

  Future<SellerOrderSummary> getOrderSummary() async {
    try {
      final response = await _client.get(ApiConstants.sellerOrdersSummary);
      return SellerOrderSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> listOrders({
    String? status,
    String? search,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.sellerOrders,
        queryParameters: {
          if (status != null) 'status': status,
          if (search != null) 'search': search,
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
          'page': page,
          'page_size': pageSize,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>? ?? [])
          .map((e) => SellerOrderDetail.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'total': (data['total'] as num?)?.toInt() ?? 0,
        'page': (data['page'] as num?)?.toInt() ?? 1,
        'page_size': (data['page_size'] as num?)?.toInt() ?? 20,
        'results': results,
      };
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderDetail> getOrder(String orderId) async {
    try {
      final response = await _client.get(ApiConstants.sellerOrderById(orderId));
      return SellerOrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderDetail> acceptOrder(String orderId, {String? notes}) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerOrderAccept(orderId),
        data: {if (notes != null) 'notes': notes},
      );
      return SellerOrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderDetail> startProcessing(String orderId, {String? notes}) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerOrderStartProcessing(orderId),
        data: {if (notes != null) 'notes': notes},
      );
      return SellerOrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderDetail> markReadyToShip(String orderId, {String? notes}) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerOrderReadyToShip(orderId),
        data: {if (notes != null) 'notes': notes},
      );
      return SellerOrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderDetail> dispatchOrder({
    required String orderId,
    required String carrierName,
    required String trackingNumber,
    String? trackingUrl,
    String? location,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerOrderDispatch(orderId),
        data: {
          'carrier_name': carrierName,
          'tracking_number': trackingNumber,
          if (trackingUrl != null) 'tracking_url': trackingUrl,
          if (location != null) 'location': location,
          if (notes != null) 'notes': notes,
        },
      );
      return SellerOrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerOrderDetail> requestCancellation({
    required String orderId,
    required String reason,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerOrderRequestCancellation(orderId),
        data: {
          'reason': reason,
          if (notes != null) 'notes': notes,
        },
      );
      return SellerOrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Seller Inventory ───

  Future<Map<String, dynamic>> listInventory({
    String? search,
    bool? lowStock,
    bool? outOfStock,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.sellerInventory,
        queryParameters: {
          if (search != null) 'search': search,
          if (lowStock != null) 'low_stock': lowStock,
          if (outOfStock != null) 'out_of_stock': outOfStock,
          'page': page,
          'page_size': pageSize,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>? ?? [])
          .map((e) => SellerInventoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'total': (data['total'] as num?)?.toInt() ?? 0,
        'page': (data['page'] as num?)?.toInt() ?? 1,
        'page_size': (data['page_size'] as num?)?.toInt() ?? 20,
        'results': results,
      };
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerInventorySummary> getInventorySummary() async {
    try {
      final response = await _client.get(ApiConstants.sellerInventorySummary);
      return SellerInventorySummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerInventoryItemModel>> getLowStock() async {
    try {
      final response = await _client.get(ApiConstants.sellerInventoryLowStock);
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => SellerInventoryItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerInventoryMovement>> getInventoryHistory({
    String? inventoryId,
    String? movementType,
    int limit = 100,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.sellerInventoryHistory,
        queryParameters: {
          if (inventoryId != null) 'inventory_id': inventoryId,
          if (movementType != null) 'movement_type': movementType,
          'limit': limit,
        },
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => SellerInventoryMovement.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerInventoryItemModel> updateInventorySettings({
    required String inventoryId,
    int? lowStockThreshold,
    String? warehouseLocation,
    String? restockDate,
  }) async {
    try {
      final response = await _client.patch(
        ApiConstants.sellerInventoryById(inventoryId),
        data: {
          if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
          if (warehouseLocation != null) 'warehouse_location': warehouseLocation,
          if (restockDate != null) 'restock_date': restockDate,
        },
      );
      return SellerInventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerInventoryItemModel> adjustInventory({
    required String inventoryId,
    required int adjustment,
    String reason = 'adjustment',
    String? reference,
    String? note,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerInventoryAdjust(inventoryId),
        data: {
          'adjustment': adjustment,
          'reason': reason,
          if (reference != null) 'reference': reference,
          if (note != null) 'note': note,
        },
      );
      return SellerInventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SellerInventoryItemModel> restockInventory({
    required String inventoryId,
    required int quantity,
    String? warehouseLocation,
    String? reference,
    String? note,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.sellerInventoryRestock(inventoryId),
        data: {
          'quantity': quantity,
          if (warehouseLocation != null) 'warehouse_location': warehouseLocation,
          if (reference != null) 'reference': reference,
          if (note != null) 'note': note,
        },
      );
      return SellerInventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  // ─── Delivery Integration ───

  Future<DeliveryQuoteModel> getDeliveryQuote({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> dropoff,
    String currency = 'TZS',
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.deliveryQuote,
        data: {
          'pickup': pickup,
          'dropoff': dropoff,
          'currency': currency,
        },
      );
      return DeliveryQuoteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<DeliveryJobModel> getDeliveryStatus(String sellerOrderId) async {
    try {
      final response = await _client.get(ApiConstants.deliveryBySellerOrder(sellerOrderId));
      return DeliveryJobModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<DeliveryJobModel> requestDelivery(String sellerOrderId) async {
    try {
      final response = await _client.post(ApiConstants.deliveryRequest(sellerOrderId));
      return DeliveryJobModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
