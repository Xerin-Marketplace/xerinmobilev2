import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/seller_remote_datasource.dart';
import '../../data/models/pickup_location_model.dart';
import '../../data/models/seller_models.dart';

// ─── States ───
abstract class SellerState {
  const SellerState();
}

class SellerInitial extends SellerState {
  const SellerInitial();
}

class SellerLoading extends SellerState {
  const SellerLoading();
}

class SellerDashboardLoaded extends SellerState {
  final SellerModel? seller;
  final SellerDashboardPerformanceModel dashboard;
  final SellerOrderSummaryModel? orderSummary;
  final SellerInventorySummaryModel? inventorySummary;
  final SellerWalletModel? wallet;
  final String? storeLogoUrl;
  final bool refreshing;

  const SellerDashboardLoaded({
    this.seller,
    required this.dashboard,
    this.orderSummary,
    this.inventorySummary,
    this.wallet,
    this.storeLogoUrl,
    this.refreshing = false,
  });

  SellerDashboardLoaded copyWith({
    SellerModel? seller,
    SellerDashboardPerformanceModel? dashboard,
    SellerOrderSummaryModel? orderSummary,
    SellerInventorySummaryModel? inventorySummary,
    SellerWalletModel? wallet,
    String? storeLogoUrl,
    bool? refreshing,
  }) {
    return SellerDashboardLoaded(
      seller: seller ?? this.seller,
      dashboard: dashboard ?? this.dashboard,
      orderSummary: orderSummary ?? this.orderSummary,
      inventorySummary: inventorySummary ?? this.inventorySummary,
      wallet: wallet ?? this.wallet,
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

class SellerOrdersLoaded extends SellerState {
  final SellerOrderListResponse orders;
  final SellerOrderSummaryModel? summary;
  final bool loadingMore;
  final bool hasMore;

  const SellerOrdersLoaded({
    required this.orders,
    this.summary,
    this.loadingMore = false,
    this.hasMore = false,
  });
}

class SellerOrderDetailLoaded extends SellerState {
  final SellerOrderModel order;
  final List<SellerOrderMessageModel> messages;
  final bool isLoadingMessages;

  const SellerOrderDetailLoaded({
    required this.order,
    this.messages = const [],
    this.isLoadingMessages = false,
  });
}

class SellerInventoryLoaded extends SellerState {
  final SellerInventoryListResponse inventory;
  final SellerInventorySummaryModel? summary;
  final bool loadingMore;
  final bool hasMore;

  const SellerInventoryLoaded({
    required this.inventory,
    this.summary,
    this.loadingMore = false,
    this.hasMore = false,
  });
}

class SellerWalletLoaded extends SellerState {
  final SellerWalletModel wallet;
  final PaginatedWalletTransactions transactions;
  final PaginatedSellerPayouts payouts;
  final SellerEarningsSummaryModel? earnings;
  final List<PayoutAccountModel> payoutAccounts;

  const SellerWalletLoaded({
    required this.wallet,
    this.transactions = const PaginatedWalletTransactions(),
    this.payouts = const PaginatedSellerPayouts(),
    this.earnings,
    this.payoutAccounts = const [],
  });
}

class SellerKycLoaded extends SellerState {
  final SellerKycStatusModel kycStatus;
  final List<SellerKycDocumentModel> documents;
  final List<PayoutAccountModel> payoutAccounts;

  const SellerKycLoaded({
    required this.kycStatus,
    this.documents = const [],
    this.payoutAccounts = const [],
  });
}

class SellerProfileLoaded extends SellerState {
  final SellerModel seller;
  final SellerBusinessProfileModel? profile;
  final List<BusinessCategoryModel> businessCategories;

  const SellerProfileLoaded({
    required this.seller,
    this.profile,
    this.businessCategories = const [],
  });
}

class SellerStoreLoaded extends SellerState {
  final Map<String, dynamic> store;

  const SellerStoreLoaded({required this.store});
}

class SellerAnalyticsLoaded extends SellerState {
  final SellerAnalyticsOverviewModel overview;
  final List<AnalyticsSeriesPointModel> sales;
  final List<AnalyticsRankingRowModel> products;

  const SellerAnalyticsLoaded({
    required this.overview,
    this.sales = const [],
    this.products = const [],
  });
}

class SellerActionSuccess extends SellerState {
  final String message;
  final SellerState? previousState;

  const SellerActionSuccess(this.message, [this.previousState]);
}

class SellerError extends SellerState {
  final String message;

  const SellerError(this.message);
}

class SellerPickupLocationsLoaded extends SellerState {
  final List<PickupLocationModel> locations;

  const SellerPickupLocationsLoaded(this.locations);
}

class SellerFulfillmentsLoaded extends SellerState {
  final List<SellerFulfillmentModel> fulfillments;
  final Map<String, dynamic>? summary;

  const SellerFulfillmentsLoaded(this.fulfillments, [this.summary]);
}

class SellerFulfillmentDetailLoaded extends SellerState {
  final SellerFulfillmentModel fulfillment;
  final List<FulfillmentTrackingEvent> tracking;

  const SellerFulfillmentDetailLoaded(this.fulfillment, this.tracking);
}

class SellerReturnsLoaded extends SellerState {
  final List<RefundModel> refunds;
  final String? filterStatus;

  const SellerReturnsLoaded(this.refunds, [this.filterStatus]);
}

// ─── Cubit ───
class SellerCubit extends Cubit<SellerState> {
  final SellerRemoteDataSource _dataSource;
  final Logger _logger;

  int _ordersPage = 1;
  int _inventoryPage = 1;
  bool _ordersHasMore = true;
  bool _inventoryHasMore = true;

  SellerCubit({
    required SellerRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const SellerInitial());

  Future<T?> _safeCall<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  // ─── Dashboard ───
  Future<void> loadDashboard({bool refresh = false}) async {
    if (!refresh) emit(const SellerLoading());
    try {
      final dashboard = await _dataSource.getDashboardPerformance();
      final seller = await _safeCall(() => _dataSource.getSellerMe());
      final orderSummary = await _safeCall(() => _dataSource.getOrderSummary());
      final inventorySummary = await _safeCall(() => _dataSource.getInventorySummary());
      final wallet = await _safeCall(() => _dataSource.getWallet());
      final store = await _safeCall(() => _dataSource.getStore());

      emit(SellerDashboardLoaded(
        seller: seller,
        dashboard: dashboard,
        orderSummary: orderSummary,
        inventorySummary: inventorySummary,
        wallet: wallet,
        storeLogoUrl: store?['logo_url'] as String?,
        refreshing: refresh,
      ));
    } catch (e) {
      _logger.e('SellerCubit.loadDashboard error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── Orders ───
  Future<void> loadOrders({String? search, String? status, bool reset = true}) async {
    if (reset) {
      _ordersPage = 1;
      _ordersHasMore = true;
    }
    try {
      final response = await _dataSource.getOrders(
        page: _ordersPage,
        search: search,
        status: status,
      );
      _ordersHasMore = _ordersPage * response.pageSize < response.total;

      SellerOrderSummaryModel? summary;
      if (reset) {
        summary = await _safeCall(() => _dataSource.getOrderSummary());
      }

      if (reset) {
        emit(SellerOrdersLoaded(
          orders: response,
          summary: summary,
          hasMore: _ordersHasMore,
        ));
      } else {
        final current = state;
        if (current is SellerOrdersLoaded) {
          final combined = SellerOrderListResponse(
            total: response.total,
            page: response.page,
            pageSize: response.pageSize,
            results: [...current.orders.results, ...response.results],
          );
          emit(SellerOrdersLoaded(
            orders: combined,
            summary: current.summary,
            hasMore: _ordersHasMore,
          ));
        }
      }
    } catch (e) {
      _logger.e('SellerCubit.loadOrders error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> loadMoreOrders({String? search, String? status}) async {
    final current = state;
    if (current is! SellerOrdersLoaded || current.loadingMore || !_ordersHasMore) return;
    _ordersPage++;
    emit(SellerOrdersLoaded(
      orders: current.orders,
      summary: current.summary,
      loadingMore: true,
      hasMore: _ordersHasMore,
    ));
    await loadOrders(search: search, status: status, reset: false);
  }

  // ─── Order Detail ───
  Future<void> loadOrderDetail(String id) async {
    try {
      final order = await _dataSource.getOrder(id);
      emit(SellerOrderDetailLoaded(order: order, isLoadingMessages: true));
      try {
        final messages = await _dataSource.getOrderMessages(id);
        final current = state;
        if (current is SellerOrderDetailLoaded) {
          emit(SellerOrderDetailLoaded(order: current.order, messages: messages));
        }
      } catch (e) {
        _logger.w('SellerCubit.loadOrderDetail messages error: $e');
        final current = state;
        if (current is SellerOrderDetailLoaded) {
          emit(SellerOrderDetailLoaded(order: current.order, messages: const []));
        }
      }
    } catch (e) {
      _logger.e('SellerCubit.loadOrderDetail error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> acceptOrder(String id, {String? notes}) async {
    try {
      final order = await _dataSource.acceptOrder(id, notes: notes);
      emit(SellerOrderDetailLoaded(order: order, messages: const []));
      await loadOrderMessages(id);
    } catch (e) {
      _logger.e('SellerCubit.acceptOrder error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> startProcessing(String id, {String? notes}) async {
    try {
      final order = await _dataSource.startProcessing(id, notes: notes);
      emit(SellerOrderDetailLoaded(order: order, messages: const []));
      await loadOrderMessages(id);
    } catch (e) {
      _logger.e('SellerCubit.startProcessing error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> readyToShip(String id, {String? notes}) async {
    try {
      final order = await _dataSource.readyToShip(id, notes: notes);
      emit(SellerOrderDetailLoaded(order: order, messages: const []));
      await loadOrderMessages(id);
    } catch (e) {
      _logger.e('SellerCubit.readyToShip error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> dispatchOrder(String id, {
    required String carrierName,
    required String trackingNumber,
    String? trackingUrl,
    String? location,
    String? notes,
  }) async {
    try {
      final order = await _dataSource.dispatchOrder(
        id,
        carrierName: carrierName,
        trackingNumber: trackingNumber,
        trackingUrl: trackingUrl,
        location: location,
        notes: notes,
      );
      emit(SellerOrderDetailLoaded(order: order, messages: const []));
      await loadOrderMessages(id);
    } catch (e) {
      _logger.e('SellerCubit.dispatchOrder error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> cancelOrder(String id, {required String reason, String? notes}) async {
    try {
      final order = await _dataSource.cancelOrder(id, reason: reason, notes: notes);
      emit(SellerOrderDetailLoaded(order: order, messages: const []));
      await loadOrderMessages(id);
    } catch (e) {
      _logger.e('SellerCubit.cancelOrder error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> loadOrderMessages(String id) async {
    try {
      final messages = await _dataSource.getOrderMessages(id);
      final current = state;
      if (current is SellerOrderDetailLoaded) {
        emit(SellerOrderDetailLoaded(order: current.order, messages: messages));
      }
    } catch (e) {
      _logger.w('SellerCubit.loadOrderMessages error: $e');
    }
  }

  Future<void> sendOrderMessage(String id, {required String message, bool isInternal = false}) async {
    try {
      await _dataSource.sendOrderMessage(id, message: message, isInternal: isInternal);
      await loadOrderMessages(id);
    } catch (e) {
      _logger.e('SellerCubit.sendOrderMessage error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── Inventory ───
  Future<void> loadInventory({String? search, bool? lowStock, bool? outOfStock, bool reset = true}) async {
    if (reset) {
      _inventoryPage = 1;
      _inventoryHasMore = true;
    }
    try {
      final response = await _dataSource.getInventory(
        page: _inventoryPage,
        search: search,
        lowStock: lowStock,
        outOfStock: outOfStock,
      );
      _inventoryHasMore = _inventoryPage * response.pageSize < response.total;

      SellerInventorySummaryModel? summary;
      if (reset) {
        summary = await _safeCall(() => _dataSource.getInventorySummary());
      }

      if (reset) {
        emit(SellerInventoryLoaded(
          inventory: response,
          summary: summary,
          hasMore: _inventoryHasMore,
        ));
      } else {
        final current = state;
        if (current is SellerInventoryLoaded) {
          final combined = SellerInventoryListResponse(
            total: response.total,
            page: response.page,
            pageSize: response.pageSize,
            results: [...current.inventory.results, ...response.results],
          );
          emit(SellerInventoryLoaded(
            inventory: combined,
            summary: current.summary,
            hasMore: _inventoryHasMore,
          ));
        }
      }
    } catch (e) {
      _logger.e('SellerCubit.loadInventory error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> loadMoreInventory({String? search, bool? lowStock, bool? outOfStock}) async {
    final current = state;
    if (current is! SellerInventoryLoaded || current.loadingMore || !_inventoryHasMore) return;
    _inventoryPage++;
    emit(SellerInventoryLoaded(
      inventory: current.inventory,
      summary: current.summary,
      loadingMore: true,
      hasMore: _inventoryHasMore,
    ));
    await loadInventory(search: search, lowStock: lowStock, outOfStock: outOfStock, reset: false);
  }

  Future<void> adjustInventory(String id, {required int adjustment, required String reason, String? reference, String? note}) async {
    try {
      await _dataSource.adjustInventory(id, adjustment: adjustment, reason: reason, reference: reference, note: note);
      emit(const SellerActionSuccess('Inventory adjusted successfully'));
    } catch (e) {
      _logger.e('SellerCubit.adjustInventory error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> restockInventory(String id, {required int quantity, String? warehouseLocation, String? reference, String? note}) async {
    try {
      await _dataSource.restockInventory(id, quantity: quantity, warehouseLocation: warehouseLocation, reference: reference, note: note);
      emit(const SellerActionSuccess('Inventory restocked successfully'));
    } catch (e) {
      _logger.e('SellerCubit.restockInventory error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> updateInventorySettings(String id, {int? lowStockThreshold, String? warehouseLocation}) async {
    try {
      final data = <String, dynamic>{};
      if (lowStockThreshold != null) data['low_stock_threshold'] = lowStockThreshold;
      if (warehouseLocation != null) data['warehouse_location'] = warehouseLocation;
      await _dataSource.updateInventorySettings(id, data);
      emit(const SellerActionSuccess('Inventory settings updated'));
    } catch (e) {
      _logger.e('SellerCubit.updateInventorySettings error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── Wallet ───
  Future<void> loadWallet() async {
    try {
      final wallet = await _dataSource.getWallet();
      final transactions = await _dataSource.getWalletTransactions();
      final payouts = await _dataSource.getPayouts();
      final earnings = await _safeCall(() => _dataSource.getEarningsSummary());
      final payoutAccounts = await _safeCall(() => _dataSource.getPayoutAccounts()) ?? [];

      emit(SellerWalletLoaded(
        wallet: wallet,
        transactions: transactions,
        payouts: payouts,
        earnings: earnings,
        payoutAccounts: payoutAccounts,
      ));
    } catch (e) {
      _logger.e('SellerCubit.loadWallet error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> requestPayout({required String payoutAccountId, required double amount, String? note}) async {
    try {
      await _dataSource.requestPayout(payoutAccountId: payoutAccountId, amount: amount, note: note);
      emit(const SellerActionSuccess('Payout requested successfully'));
      await loadWallet();
    } catch (e) {
      _logger.e('SellerCubit.requestPayout error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> cancelPayout(String payoutId) async {
    try {
      await _dataSource.cancelPayout(payoutId);
      emit(const SellerActionSuccess('Payout cancelled successfully'));
      await loadWallet();
    } catch (e) {
      _logger.e('SellerCubit.cancelPayout error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── KYC ───
  Future<void> loadKyc() async {
    try {
      final kycStatus = await _dataSource.getKycStatus();
      final documents = await _safeCall(() => _dataSource.getKycDocuments()) ?? [];
      final payoutAccounts = await _safeCall(() => _dataSource.getPayoutAccounts()) ?? [];

      emit(SellerKycLoaded(
        kycStatus: kycStatus,
        documents: documents,
        payoutAccounts: payoutAccounts,
      ));
    } catch (e) {
      _logger.e('SellerCubit.loadKyc error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> uploadKycDocument({required String documentType, required String filePath, String? fileName, String? mimeType}) async {
    try {
      await _dataSource.uploadKycDocument(documentType: documentType, filePath: filePath, fileName: fileName, mimeType: mimeType);
      emit(const SellerActionSuccess('KYC document uploaded successfully'));
      await loadKyc();
    } catch (e) {
      _logger.e('SellerCubit.uploadKycDocument error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> createPayoutAccount(Map<String, dynamic> data) async {
    try {
      await _dataSource.createPayoutAccount(data);
      emit(const SellerActionSuccess('Payout account created successfully'));
      await loadKyc();
    } catch (e) {
      _logger.e('SellerCubit.createPayoutAccount error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> deletePayoutAccount(String id) async {
    try {
      await _dataSource.deletePayoutAccount(id);
      emit(const SellerActionSuccess('Payout account deleted'));
      await loadKyc();
    } catch (e) {
      _logger.e('SellerCubit.deletePayoutAccount error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── Profile ───
  Future<void> loadProfile() async {
    try {
      final seller = await _dataSource.getSellerMe();
      final profile = await _safeCall(() => _dataSource.getBusinessProfile());
      final businessCategories = await _safeCall(() => _dataSource.getBusinessCategories()) ?? [];

      emit(SellerProfileLoaded(
        seller: seller,
        profile: profile,
        businessCategories: businessCategories,
      ));
    } catch (e) {
      _logger.e('SellerCubit.loadProfile error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> updateSellerMe(Map<String, dynamic> data) async {
    try {
      await _dataSource.updateSellerMe(data);
      emit(const SellerActionSuccess('Seller profile updated successfully'));
      await loadProfile();
    } catch (e) {
      _logger.e('SellerCubit.updateSellerMe error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> updateBusinessProfile(Map<String, dynamic> data) async {
    try {
      await _dataSource.updateBusinessProfile(data);
      emit(const SellerActionSuccess('Business profile updated successfully'));
      await loadProfile();
    } catch (e) {
      _logger.e('SellerCubit.updateBusinessProfile error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── Store ───
  Future<void> loadStore() async {
    try {
      final store = await _dataSource.getStore();
      emit(SellerStoreLoaded(store: store));
    } catch (e) {
      _logger.e('SellerCubit.loadStore error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> updateStore(Map<String, dynamic> data) async {
    try {
      await _dataSource.updateStore(data);
      emit(const SellerActionSuccess('Store updated successfully'));
      await loadStore();
    } catch (e) {
      _logger.e('SellerCubit.updateStore error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> uploadStoreLogo(String filePath) async {
    try {
      await _dataSource.uploadStoreLogo(filePath);
      emit(const SellerActionSuccess('Store logo uploaded successfully'));
      await loadStore();
    } catch (e) {
      _logger.e('SellerCubit.uploadStoreLogo error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> uploadStoreBanner(String filePath) async {
    try {
      await _dataSource.uploadStoreBanner(filePath);
      emit(const SellerActionSuccess('Store banner uploaded successfully'));
      await loadStore();
    } catch (e) {
      _logger.e('SellerCubit.uploadStoreBanner error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── Analytics ───
  Future<void> loadAnalytics() async {
    try {
      final overview = await _dataSource.getAnalyticsOverview();
      final sales = await _safeCall(() => _dataSource.getAnalyticsSales()) ?? [];
      final products = await _safeCall(() => _dataSource.getAnalyticsProducts()) ?? [];

      emit(SellerAnalyticsLoaded(
        overview: overview,
        sales: sales,
        products: products,
      ));
    } catch (e) {
      _logger.e('SellerCubit.loadAnalytics error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── Pricing Preview ───
  Future<SellerPricingPreviewModel?> previewPricing({
    required double sellerBasePrice,
    double? sellerSalePrice,
    required String categoryId,
    String? productId,
    String? currency,
  }) async {
    try {
      final data = <String, dynamic>{
        'seller_base_price': sellerBasePrice,
        'category_id': categoryId,
      };
      if (sellerSalePrice != null) data['seller_sale_price'] = sellerSalePrice;
      if (productId != null) data['product_id'] = productId;
      if (currency != null) data['currency'] = currency;
      return await _dataSource.previewPricing(data);
    } catch (e) {
      _logger.e('SellerCubit.previewPricing error: $e');
      return null;
    }
  }

  // ─── Pickup Locations ───
  Future<void> loadPickupLocations() async {
    emit(const SellerLoading());
    try {
      final locations = await _dataSource.getPickupLocations();
      emit(SellerPickupLocationsLoaded(locations));
    } catch (e) {
      _logger.e('SellerCubit.loadPickupLocations error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> createPickupLocation(Map<String, dynamic> data) async {
    try {
      await _dataSource.createPickupLocation(data);
      final locations = await _dataSource.getPickupLocations();
      emit(SellerPickupLocationsLoaded(locations));
      emit(const SellerActionSuccess('Pickup location created'));
    } catch (e) {
      _logger.e('SellerCubit.createPickupLocation error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> updatePickupLocation(
      String locationId, Map<String, dynamic> data) async {
    try {
      await _dataSource.updatePickupLocation(locationId, data);
      final locations = await _dataSource.getPickupLocations();
      emit(SellerPickupLocationsLoaded(locations));
      emit(const SellerActionSuccess('Pickup location updated'));
    } catch (e) {
      _logger.e('SellerCubit.updatePickupLocation error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> deletePickupLocation(String locationId) async {
    try {
      await _dataSource.deletePickupLocation(locationId);
      final locations = await _dataSource.getPickupLocations();
      emit(SellerPickupLocationsLoaded(locations));
      emit(const SellerActionSuccess('Pickup location deleted'));
    } catch (e) {
      _logger.e('SellerCubit.deletePickupLocation error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> setDefaultPickupLocation(String locationId) async {
    try {
      await _dataSource.setDefaultPickupLocation(locationId);
      final locations = await _dataSource.getPickupLocations();
      emit(SellerPickupLocationsLoaded(locations));
      emit(const SellerActionSuccess('Default pickup location set'));
    } catch (e) {
      _logger.e('SellerCubit.setDefaultPickupLocation error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── Fulfillment ───
  Future<void> loadFulfillments({String? status}) async {
    emit(const SellerLoading());
    try {
      final summary = await _dataSource.getFulfillmentSummary();
      final fulfillments =
          await _dataSource.getFulfillments(status: status);
      emit(SellerFulfillmentsLoaded(fulfillments, summary));
    } catch (e) {
      _logger.e('SellerCubit.loadFulfillments error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> loadFulfillmentDetail(String sellerOrderId) async {
    emit(const SellerLoading());
    try {
      final fulfillment =
          await _dataSource.getFulfillmentDetail(sellerOrderId);
      final tracking =
          await _dataSource.getFulfillmentTracking(sellerOrderId);
      emit(SellerFulfillmentDetailLoaded(fulfillment, tracking));
    } catch (e) {
      _logger.e('SellerCubit.loadFulfillmentDetail error: $e');
      emit(SellerError(e.toString()));
    }
  }

  // ─── Returns / Refunds ───
  Future<void> loadReturns({String? status}) async {
    emit(const SellerLoading());
    try {
      final refunds = await _dataSource.getRefunds(status: status);
      emit(SellerReturnsLoaded(refunds, status));
    } catch (e) {
      _logger.e('SellerCubit.loadReturns error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> reviewReturn(String refundId, {String? note}) async {
    try {
      await _dataSource.reviewRefund(refundId, note: note);
      emit(const SellerActionSuccess('Return request reviewed'));
      _reloadReturns();
    } catch (e) {
      _logger.e('SellerCubit.reviewReturn error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> approveReturn(String refundId, {String? note}) async {
    try {
      await _dataSource.approveRefund(refundId, note: note);
      emit(const SellerActionSuccess('Return approved'));
      _reloadReturns();
    } catch (e) {
      _logger.e('SellerCubit.approveReturn error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> rejectReturn(String refundId, {String? note}) async {
    try {
      await _dataSource.rejectRefund(refundId, note: note);
      emit(const SellerActionSuccess('Return rejected'));
      _reloadReturns();
    } catch (e) {
      _logger.e('SellerCubit.rejectReturn error: $e');
      emit(SellerError(e.toString()));
    }
  }

  Future<void> processReturn(String refundId, {String? providerReference, String? note}) async {
    try {
      await _dataSource.processRefund(refundId, providerReference: providerReference, note: note);
      emit(const SellerActionSuccess('Return processed'));
      _reloadReturns();
    } catch (e) {
      _logger.e('SellerCubit.processReturn error: $e');
      emit(SellerError(e.toString()));
    }
  }

  void _reloadReturns() {
    final current = state;
    String? status;
    if (current is SellerReturnsLoaded) status = current.filterStatus;
    loadReturns(status: status);
  }
}
