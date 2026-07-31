import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../data/datasources/seller_remote_datasource.dart';
import '../../data/models/inventory_model.dart';
import '../../data/models/seller_kyc_model.dart';
import '../../data/models/seller_order_model.dart';
import '../../data/models/seller_payout_model.dart';
import '../../data/models/seller_profile_model.dart';
import '../../data/models/store_gallery_image_model.dart';
import '../../data/models/store_model.dart';
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
    emit(const SellerLoading());

    final profileFuture = _dataSource.getMyProfile().then<dynamic>((v) => v).catchError((e) {
      _logger.e('Seller profile error: $e');
      return null;
    });
    final storeFuture = _dataSource.getMyStore().then<dynamic>((v) => v).catchError((e) {
      _logger.e('Store error: $e');
      return null;
    });
    final ordersFuture = _dataSource.getMyOrders(pageSize: 50).then<dynamic>((v) => v).catchError((e) {
      _logger.e('Orders error: $e');
      return null;
    });
    final productsFuture = _dataSource.getMyProducts(limit: 50).then<dynamic>((v) => v).catchError((e) {
      _logger.e('Products error: $e');
      return null;
    });
    final inventoryFuture = _dataSource.getMyInventory().then<dynamic>((v) => v).catchError((e) {
      _logger.e('Inventory error: $e');
      return null;
    });
    final lowStockFuture = _dataSource.getLowStock().then<dynamic>((v) => v).catchError((e) {
      _logger.e('Low stock error: $e');
      return null;
    });
    final kycFuture = _dataSource.getKycStatus().then<dynamic>((v) => v).catchError((e) {
      _logger.e('KYC status error: $e');
      return null;
    });
    final payoutsFuture = _dataSource.getPayoutAccounts(pageSize: 50).then<dynamic>((v) => v).catchError((e) {
      _logger.e('Payouts error: $e');
      return null;
    });

    final results = await Future.wait([
      profileFuture, storeFuture, ordersFuture, productsFuture,
      inventoryFuture, lowStockFuture, kycFuture, payoutsFuture,
    ]);

    final profile = results[0] is SellerProfileModel ? results[0] as SellerProfileModel : null;
    final store = results[1] is StoreModel ? results[1] as StoreModel : null;
    final orders = results[2] is List<SellerOrderModel> ? results[2] as List<SellerOrderModel> : <SellerOrderModel>[];
    final products = results[3] is List<Map<String, dynamic>> ? results[3] as List<Map<String, dynamic>> : <Map<String, dynamic>>[];
    final inventory = results[4] is List<InventoryModel> ? results[4] as List<InventoryModel> : <InventoryModel>[];
    final lowStock = results[5] is List<InventoryModel> ? results[5] as List<InventoryModel> : <InventoryModel>[];
    final kycStatus = results[6] is SellerKycStatusModel ? results[6] as SellerKycStatusModel : null;
    final payouts = results[7] is List<SellerPayoutAccountModel> ? results[7] as List<SellerPayoutAccountModel> : <SellerPayoutAccountModel>[];

    _logger.i(
      '✅ Seller dashboard loaded — profile: ${profile?.businessName ?? "none"}, '
      'orders: ${orders.length}, products: ${products.length}, '
      'inventory: ${inventory.length}, lowStock: ${lowStock.length}',
    );

    emit(SellerDashboardLoaded(
      profile: profile,
      store: store,
      orders: orders,
      products: products,
      inventory: inventory,
      lowStockItems: lowStock,
      kycStatus: kycStatus,
      payoutAccounts: payouts,
    ));
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
