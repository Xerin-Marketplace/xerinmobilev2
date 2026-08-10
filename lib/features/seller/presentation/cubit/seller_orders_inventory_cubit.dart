import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/seller_orders_inventory_datasource.dart';
import '../../data/models/seller_order_detail_model.dart';
import '../../data/models/seller_inventory_model.dart';

abstract class SellerOrdersInventoryState {
  const SellerOrdersInventoryState();
}

class SellerOrdersInventoryInitial extends SellerOrdersInventoryState {
  const SellerOrdersInventoryInitial();
}

class SellerOrdersLoading extends SellerOrdersInventoryState {
  const SellerOrdersLoading();
}

class SellerOrdersSummaryLoaded extends SellerOrdersInventoryState {
  final SellerOrderSummary summary;
  const SellerOrdersSummaryLoaded(this.summary);
}

class SellerOrdersListLoaded extends SellerOrdersInventoryState {
  final List<SellerOrderDetail> orders;
  final int total;

  const SellerOrdersListLoaded({required this.orders, this.total = 0});
}

class SellerOrderDetailLoaded extends SellerOrdersInventoryState {
  final SellerOrderDetail order;
  const SellerOrderDetailLoaded(this.order);
}

class SellerOrderActionSuccess extends SellerOrdersInventoryState {
  final SellerOrderDetail order;
  final String message;
  const SellerOrderActionSuccess(this.order, this.message);
}

class SellerInventoryLoading extends SellerOrdersInventoryState {
  const SellerInventoryLoading();
}

class SellerInventorySummaryLoaded extends SellerOrdersInventoryState {
  final SellerInventorySummary summary;
  const SellerInventorySummaryLoaded(this.summary);
}

class SellerInventoryListLoaded extends SellerOrdersInventoryState {
  final List<SellerInventoryItemModel> items;
  final int total;

  const SellerInventoryListLoaded({required this.items, this.total = 0});
}

class SellerInventoryLowStockLoaded extends SellerOrdersInventoryState {
  final List<SellerInventoryItemModel> items;
  const SellerInventoryLowStockLoaded(this.items);
}

class SellerInventoryHistoryLoaded extends SellerOrdersInventoryState {
  final List<SellerInventoryMovement> movements;
  const SellerInventoryHistoryLoaded(this.movements);
}

class SellerInventoryActionSuccess extends SellerOrdersInventoryState {
  final SellerInventoryItemModel item;
  final String message;
  const SellerInventoryActionSuccess(this.item, this.message);
}

class DeliveryQuoteLoaded extends SellerOrdersInventoryState {
  final DeliveryQuoteModel quote;
  const DeliveryQuoteLoaded(this.quote);
}

class DeliveryJobLoaded extends SellerOrdersInventoryState {
  final DeliveryJobModel job;
  const DeliveryJobLoaded(this.job);
}

class SellerOrdersInventoryError extends SellerOrdersInventoryState {
  final String message;
  const SellerOrdersInventoryError(this.message);
}

class SellerOrdersInventoryCubit extends Cubit<SellerOrdersInventoryState> {
  final SellerOrdersInventoryDataSource _dataSource;
  final Logger _logger;

  SellerOrdersInventoryCubit({
    required SellerOrdersInventoryDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const SellerOrdersInventoryInitial());

  // ─── Orders ───

  Future<void> loadOrderSummary() async {
    emit(const SellerOrdersLoading());
    try {
      final summary = await _dataSource.getOrderSummary();
      emit(SellerOrdersSummaryLoaded(summary));
    } catch (e) {
      _logger.e('❌ Failed to load order summary: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> listOrders({String? status, String? search, int page = 1}) async {
    emit(const SellerOrdersLoading());
    try {
      final result = await _dataSource.listOrders(status: status, search: search, page: page);
      emit(SellerOrdersListLoaded(
        orders: result['results'] as List<SellerOrderDetail>,
        total: result['total'] as int,
      ));
    } catch (e) {
      _logger.e('❌ Failed to load orders: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> getOrder(String orderId) async {
    emit(const SellerOrdersLoading());
    try {
      final order = await _dataSource.getOrder(orderId);
      emit(SellerOrderDetailLoaded(order));
    } catch (e) {
      _logger.e('❌ Failed to load order: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> acceptOrder(String orderId, {String? notes}) async {
    try {
      final order = await _dataSource.acceptOrder(orderId, notes: notes);
      emit(SellerOrderActionSuccess(order, 'Order accepted'));
    } catch (e) {
      _logger.e('❌ Failed to accept order: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> startProcessing(String orderId, {String? notes}) async {
    try {
      final order = await _dataSource.startProcessing(orderId, notes: notes);
      emit(SellerOrderActionSuccess(order, 'Order processing started'));
    } catch (e) {
      _logger.e('❌ Failed to start processing: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> markReadyToShip(String orderId, {String? notes}) async {
    try {
      final order = await _dataSource.markReadyToShip(orderId, notes: notes);
      emit(SellerOrderActionSuccess(order, 'Order ready to ship'));
    } catch (e) {
      _logger.e('❌ Failed to mark ready: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> dispatchOrder({
    required String orderId,
    required String carrierName,
    required String trackingNumber,
    String? trackingUrl,
    String? location,
    String? notes,
  }) async {
    try {
      final order = await _dataSource.dispatchOrder(
        orderId: orderId,
        carrierName: carrierName,
        trackingNumber: trackingNumber,
        trackingUrl: trackingUrl,
        location: location,
        notes: notes,
      );
      emit(SellerOrderActionSuccess(order, 'Order dispatched'));
    } catch (e) {
      _logger.e('❌ Failed to dispatch: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> requestCancellation({
    required String orderId,
    required String reason,
    String? notes,
  }) async {
    try {
      final order = await _dataSource.requestCancellation(
        orderId: orderId,
        reason: reason,
        notes: notes,
      );
      emit(SellerOrderActionSuccess(order, 'Cancellation requested'));
    } catch (e) {
      _logger.e('❌ Failed to request cancellation: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  // ─── Inventory ───

  Future<void> loadInventorySummary() async {
    emit(const SellerInventoryLoading());
    try {
      final summary = await _dataSource.getInventorySummary();
      emit(SellerInventorySummaryLoaded(summary));
    } catch (e) {
      _logger.e('❌ Failed to load inventory summary: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> listInventory({String? search, bool? lowStock, bool? outOfStock, int page = 1}) async {
    emit(const SellerInventoryLoading());
    try {
      final result = await _dataSource.listInventory(
        search: search,
        lowStock: lowStock,
        outOfStock: outOfStock,
        page: page,
      );
      emit(SellerInventoryListLoaded(
        items: result['results'] as List<SellerInventoryItemModel>,
        total: result['total'] as int,
      ));
    } catch (e) {
      _logger.e('❌ Failed to load inventory: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> loadLowStock() async {
    emit(const SellerInventoryLoading());
    try {
      final items = await _dataSource.getLowStock();
      emit(SellerInventoryLowStockLoaded(items));
    } catch (e) {
      _logger.e('❌ Failed to load low stock: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> loadInventoryHistory({String? inventoryId, String? movementType}) async {
    emit(const SellerInventoryLoading());
    try {
      final movements = await _dataSource.getInventoryHistory(
        inventoryId: inventoryId,
        movementType: movementType,
      );
      emit(SellerInventoryHistoryLoaded(movements));
    } catch (e) {
      _logger.e('❌ Failed to load history: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> adjustInventory({
    required String inventoryId,
    required int adjustment,
    String reason = 'adjustment',
    String? note,
  }) async {
    try {
      final item = await _dataSource.adjustInventory(
        inventoryId: inventoryId,
        adjustment: adjustment,
        reason: reason,
        note: note,
      );
      emit(SellerInventoryActionSuccess(item, 'Inventory adjusted'));
    } catch (e) {
      _logger.e('❌ Failed to adjust inventory: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> restockInventory({
    required String inventoryId,
    required int quantity,
    String? warehouseLocation,
    String? note,
  }) async {
    try {
      final item = await _dataSource.restockInventory(
        inventoryId: inventoryId,
        quantity: quantity,
        warehouseLocation: warehouseLocation,
        note: note,
      );
      emit(SellerInventoryActionSuccess(item, 'Inventory restocked'));
    } catch (e) {
      _logger.e('❌ Failed to restock: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> updateInventorySettings({
    required String inventoryId,
    int? lowStockThreshold,
    String? warehouseLocation,
  }) async {
    try {
      final item = await _dataSource.updateInventorySettings(
        inventoryId: inventoryId,
        lowStockThreshold: lowStockThreshold,
        warehouseLocation: warehouseLocation,
      );
      emit(SellerInventoryActionSuccess(item, 'Settings updated'));
    } catch (e) {
      _logger.e('❌ Failed to update settings: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  // ─── Delivery ───

  Future<void> getDeliveryQuote({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> dropoff,
    String currency = 'TZS',
  }) async {
    try {
      final quote = await _dataSource.getDeliveryQuote(
        pickup: pickup,
        dropoff: dropoff,
        currency: currency,
      );
      emit(DeliveryQuoteLoaded(quote));
    } catch (e) {
      _logger.e('❌ Failed to get delivery quote: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> getDeliveryStatus(String sellerOrderId) async {
    try {
      final job = await _dataSource.getDeliveryStatus(sellerOrderId);
      emit(DeliveryJobLoaded(job));
    } catch (e) {
      _logger.e('❌ Failed to get delivery status: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }

  Future<void> requestDelivery(String sellerOrderId) async {
    try {
      final job = await _dataSource.requestDelivery(sellerOrderId);
      emit(DeliveryJobLoaded(job));
      _logger.i('✅ Delivery requested');
    } catch (e) {
      _logger.e('❌ Failed to request delivery: $e');
      emit(SellerOrdersInventoryError(e.toString()));
    }
  }
}
