import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../data/datasources/seller_remote_datasource.dart';
import '../../data/models/seller_kyc_model.dart';
import '../../data/models/seller_order_model.dart';
import '../../data/models/seller_wallet_model.dart';
import '../../data/models/store_gallery_image_model.dart';
import '../../data/models/store_opening_hour_model.dart';
import 'seller_state.dart';

class SellerCubit extends Cubit<SellerState> {
  final SellerRemoteDataSource _dataSource;
  final Logger _logger;

  SellerCubit({
    required SellerRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const SellerInitial());

  Future<void> loadDashboard() async {
    if (state is SellerLoading) return;
    emit(const SellerLoading());

    final results = await Future.wait([
      _dataSource.getSellerAnalyticsOverview().then<dynamic>((v) => v).catchError((e) {
        _logger.e('Analytics overview error: $e');
        return null;
      }),
      _dataSource.getSellerAnalyticsSales().then<dynamic>((v) => v).catchError((e) {
        _logger.e('Analytics sales error: $e');
        return null;
      }),
      _dataSource.getSellerAnalyticsProducts(limit: 5).then<dynamic>((v) => v).catchError((e) {
        _logger.e('Analytics products error: $e');
        return null;
      }),
      _dataSource.getSellerOrderSummary().then<dynamic>((v) => v).catchError((e) {
        _logger.e('Order summary error: $e');
        return null;
      }),
      _dataSource.getSellerOrders(page: 1, pageSize: 5).then<dynamic>((v) => v).catchError((e) {
        _logger.e('Seller orders error: $e');
        return null;
      }),
      _dataSource.getKycStatus().then<dynamic>((v) => v).catchError((e) {
        _logger.e('KYC status error: $e');
        return null;
      }),
    ]);

    final analyticsOverview = results[0] is Map<String, dynamic> ? results[0] as Map<String, dynamic> : null;
    final analyticsSales = results[1] is List<Map<String, dynamic>> ? results[1] as List<Map<String, dynamic>> : <Map<String, dynamic>>[];
    final analyticsProducts = results[2] is List<Map<String, dynamic>> ? results[2] as List<Map<String, dynamic>> : <Map<String, dynamic>>[];
    final orderSummary = results[3] is Map<String, dynamic> ? results[3] as Map<String, dynamic> : null;
    final recentOrders = results[4] is List<SellerOrderModel> ? results[4] as List<SellerOrderModel> : <SellerOrderModel>[];
    final kycStatus = results[5] is SellerKycStatusModel ? results[5] as SellerKycStatusModel : null;

    _logger.i(
      '✅ Seller dashboard loaded — orders: ${recentOrders.length}, '
      'analyticsSales: ${analyticsSales.length}, '
      'kyc: ${kycStatus?.sellerStatus ?? "unknown"}',
    );

    emit(SellerDashboardLoaded(
      orders: recentOrders,
      kycStatus: kycStatus,
      analyticsOverview: analyticsOverview,
      analyticsSales: analyticsSales,
      analyticsProducts: analyticsProducts,
      orderSummary: orderSummary,
    ));
  }

  Future<void> loadProfileAndStore() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final profile = await _dataSource.getMyProfile();
      final store = await _dataSource.getMyStore();
      emit(current.copyWith(profile: profile, store: store));
    } on ServerException catch (e) {
      _logger.e('Profile/store error: ${e.message}');
    }
  }

  Future<void> loadProductsTab() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final products = await _dataSource.getMyProducts(limit: 50);
      emit(current.copyWith(products: products));
    } on ServerException catch (e) {
      _logger.e('Products error: ${e.message}');
    }
  }

  Future<void> loadOrdersTab() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final orders = await _dataSource.getMyOrders(pageSize: 50);
      emit(current.copyWith(orders: orders));
    } on ServerException catch (e) {
      _logger.e('Orders error: ${e.message}');
    }
  }

  Future<void> loadInventoryTab() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final inventory = await _dataSource.getMyInventory();
      final lowStock = await _dataSource.getLowStock();
      emit(current.copyWith(inventory: inventory, lowStockItems: lowStock));
    } on ServerException catch (e) {
      _logger.e('Inventory error: ${e.message}');
    }
  }

  Future<void> loadWalletData() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final wallet = await _dataSource.getMyWallet();
      final walletTx = await _dataSource.getWalletTransactions();
      final walletPayouts = await _dataSource.getMyPayouts();
      final payouts = await _dataSource.getPayoutAccounts(pageSize: 50);
      emit(current.copyWith(
        wallet: SellerWalletModel.fromJson(wallet),
        walletTransactions: walletTx.map((e) => WalletTransactionModel.fromJson(e)).toList(),
        walletPayouts: walletPayouts.map((e) => WalletPayoutModel.fromJson(e)).toList(),
        payoutAccounts: payouts,
      ));
    } on ServerException catch (e) {
      _logger.e('Wallet error: ${e.message}');
    }
  }

  Future<void> refreshProducts() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final products = await _dataSource.getMyProducts(limit: 50);
      emit(current.copyWith(products: products));
    } on ServerException catch (e) {
      _logger.e('Refresh products error: ${e.message}');
    }
  }

  Future<void> refreshOrders() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final orders = await _dataSource.getMyOrders(pageSize: 50);
      emit(current.copyWith(orders: orders));
    } on ServerException catch (e) {
      _logger.e('Refresh orders error: ${e.message}');
    }
  }

  Future<void> refreshInventory() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final inventory = await _dataSource.getMyInventory();
      final lowStock = await _dataSource.getLowStock();
      emit(current.copyWith(inventory: inventory, lowStockItems: lowStock));
    } on ServerException catch (e) {
      _logger.e('Refresh inventory error: ${e.message}');
    }
  }

  Future<void> refreshKyc() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final kycStatus = await _dataSource.getKycStatus();
      emit(current.copyWith(kycStatus: kycStatus));
    } on ServerException catch (e) {
      _logger.e('Refresh KYC error: ${e.message}');
    }
  }

  Future<void> submitKycDocuments({
    File? tinFile,
    File? businessProfileFile,
    File? businessRegistrationFile,
  }) async {
    emit(const SellerActionLoading());
    try {
      if (tinFile != null) {
        await _dataSource.uploadKycDocument(
            documentType: 'tin', file: tinFile);
      }
      if (businessProfileFile != null) {
        await _dataSource.uploadKycDocument(
            documentType: 'business_profile', file: businessProfileFile);
      }
      if (businessRegistrationFile != null) {
        await _dataSource.uploadKycDocument(
            documentType: 'business_registration',
            file: businessRegistrationFile);
      }
      emit(const SellerActionSuccess(
          message: 'KYC documents submitted successfully'));
      await refreshKyc();
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> refreshPayouts() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final payouts = await _dataSource.getPayoutAccounts(pageSize: 50);
      emit(current.copyWith(payoutAccounts: payouts));
    } on ServerException catch (e) {
      _logger.e('Refresh payouts error: ${e.message}');
    }
  }

  Future<void> refreshWallet() async {
    final current = state;
    if (current is! SellerDashboardLoaded) return;
    try {
      final walletJson = await _dataSource.getMyWallet();
      final wallet = SellerWalletModel.fromJson(walletJson);
      final txList = await _dataSource.getWalletTransactions();
      final txns = txList.map((e) => WalletTransactionModel.fromJson(e)).toList();
      final payoutList = await _dataSource.getMyPayouts();
      final payouts = payoutList.map((e) => WalletPayoutModel.fromJson(e)).toList();
      emit(current.copyWith(
        wallet: wallet,
        walletTransactions: txns,
        walletPayouts: payouts,
      ));
    } on ServerException catch (e) {
      _logger.e('Refresh wallet error: ${e.message}');
    }
  }

  Future<void> requestPayout({
    required String payoutAccountId,
    required double amount,
    String? note,
  }) async {
    final current = state is SellerDashboardLoaded ? state as SellerDashboardLoaded : null;
    emit(const SellerActionLoading());
    try {
      await _dataSource.requestPayout(
        payoutAccountId: payoutAccountId,
        amount: amount,
        note: note,
      );
      emit(const SellerActionSuccess(message: 'Payout requested successfully'));
      if (current != null) {
        await _refreshWalletFromState(current);
      }
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> cancelPayout(String payoutId) async {
    final current = state is SellerDashboardLoaded ? state as SellerDashboardLoaded : null;
    emit(const SellerActionLoading());
    try {
      await _dataSource.cancelPayout(payoutId);
      emit(const SellerActionSuccess(message: 'Payout cancelled'));
      if (current != null) {
        await _refreshWalletFromState(current);
      }
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> _refreshWalletFromState(SellerDashboardLoaded current) async {
    try {
      final walletJson = await _dataSource.getMyWallet();
      final wallet = SellerWalletModel.fromJson(walletJson);
      final txList = await _dataSource.getWalletTransactions();
      final txns = txList.map((e) => WalletTransactionModel.fromJson(e)).toList();
      final payoutList = await _dataSource.getMyPayouts();
      final payouts = payoutList.map((e) => WalletPayoutModel.fromJson(e)).toList();
      emit(current.copyWith(
        wallet: wallet,
        walletTransactions: txns,
        walletPayouts: payouts,
      ));
    } on ServerException catch (e) {
      _logger.e('Refresh wallet from state error: ${e.message}');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status, {String? notes}) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.updateOrderStatus(orderId, status, notes: notes);
      emit(const SellerActionSuccess(message: 'Order status updated'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.createProduct(data);
      emit(const SellerActionSuccess(message: 'Product created successfully'));
      await refreshProducts();
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.updateProduct(productId, data);
      emit(const SellerActionSuccess(message: 'Product updated successfully'));
      await refreshProducts();
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> deleteProduct(String productId) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.deleteProduct(productId);
      emit(const SellerActionSuccess(message: 'Product deleted successfully'));
      await refreshProducts();
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> updateInventory(String inventoryId, Map<String, dynamic> data) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.updateInventory(inventoryId, data);
      emit(const SellerActionSuccess(message: 'Inventory updated successfully'));
      await refreshInventory();
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> createPayoutAccount({
    required String accountType,
    required String provider,
    required String accountName,
    required String accountNumber,
    String currency = 'TZS',
    bool isDefault = false,
  }) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.createPayoutAccount(
        accountType: accountType,
        provider: provider,
        accountName: accountName,
        accountNumber: accountNumber,
        currency: currency,
        isDefault: isDefault,
      );
      emit(const SellerActionSuccess(message: 'Payout account added'));
      await refreshPayouts();
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> deletePayoutAccount(String accountId) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.deletePayoutAccount(accountId);
      emit(const SellerActionSuccess(message: 'Payout account removed'));
      await refreshPayouts();
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> updateStore(Map<String, dynamic> data) async {
    emit(const SellerActionLoading());
    try {
      final store = await _dataSource.updateMyStore(data);
      final current = state;
      if (current is SellerDashboardLoaded) {
        emit(current.copyWith(store: store));
      }
      emit(const SellerActionSuccess(message: 'Store updated successfully'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> uploadStoreLogo(File file) async {
    emit(const SellerActionLoading());
    try {
      final store = await _dataSource.uploadStoreLogo(file);
      final current = state;
      if (current is SellerDashboardLoaded) {
        emit(current.copyWith(store: store));
      }
      emit(const SellerActionSuccess(message: 'Logo uploaded successfully'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> uploadStoreBanner(File file) async {
    emit(const SellerActionLoading());
    try {
      final store = await _dataSource.uploadStoreBanner(file);
      final current = state;
      if (current is SellerDashboardLoaded) {
        emit(current.copyWith(store: store));
      }
      emit(const SellerActionSuccess(message: 'Banner uploaded successfully'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<List<StoreGalleryImageModel>> getGalleryImages() async {
    try {
      return await _dataSource.getGalleryImages();
    } on ServerException catch (e) {
      _logger.e('Gallery images error: ${e.message}');
      return [];
    }
  }

  Future<void> uploadGalleryImage({
    required File file,
    String? caption,
    int displayOrder = 0,
  }) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.uploadGalleryImage(
        file: file,
        caption: caption,
        displayOrder: displayOrder,
      );
      emit(const SellerActionSuccess(message: 'Gallery image uploaded'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> updateGalleryImage(
      String imageId, Map<String, dynamic> data) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.updateGalleryImage(imageId, data);
      emit(const SellerActionSuccess(message: 'Gallery image updated'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> deleteGalleryImage(String imageId) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.deleteGalleryImage(imageId);
      emit(const SellerActionSuccess(message: 'Gallery image deleted'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<List<StoreOpeningHourModel>> getOpeningHours() async {
    try {
      return await _dataSource.getOpeningHours();
    } on ServerException catch (e) {
      _logger.e('Opening hours error: ${e.message}');
      return [];
    }
  }

  Future<void> createOpeningHour(Map<String, dynamic> data) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.createOpeningHour(data);
      emit(const SellerActionSuccess(message: 'Opening hour added'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> updateOpeningHour(
      String hourId, Map<String, dynamic> data) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.updateOpeningHour(hourId, data);
      emit(const SellerActionSuccess(message: 'Opening hour updated'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> deleteOpeningHour(String hourId) async {
    emit(const SellerActionLoading());
    try {
      await _dataSource.deleteOpeningHour(hourId);
      emit(const SellerActionSuccess(message: 'Opening hour removed'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    emit(const SellerActionLoading());
    try {
      final profile = await _dataSource.updateMyProfile(data);
      final current = state;
      if (current is SellerDashboardLoaded) {
        emit(current.copyWith(profile: profile));
      }
      emit(const SellerActionSuccess(message: 'Profile updated successfully'));
    } on ServerException catch (e) {
      emit(SellerActionError(message: e.message));
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      return await _dataSource.getCategories();
    } catch (e) {
      _logger.e('Categories error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      return await _dataSource.getBrands();
    } catch (e) {
      _logger.e('Brands error: $e');
      return [];
    }
  }
}
