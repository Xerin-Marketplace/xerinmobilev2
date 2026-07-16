import 'package:equatable/equatable.dart';

import '../../data/models/inventory_model.dart';
import '../../data/models/seller_kyc_model.dart';
import '../../data/models/seller_order_model.dart';
import '../../data/models/seller_payout_model.dart';
import '../../data/models/seller_profile_model.dart';
import '../../data/models/store_model.dart';

abstract class SellerState extends Equatable {
  const SellerState();
  @override
  List<Object?> get props => [];
}

class SellerInitial extends SellerState {
  const SellerInitial();
}

class SellerLoading extends SellerState {
  const SellerLoading();
}

class SellerDashboardLoaded extends SellerState {
  final SellerProfileModel? profile;
  final StoreModel? store;
  final List<SellerOrderModel> orders;
  final List<Map<String, dynamic>> products;
  final List<InventoryModel> inventory;
  final List<InventoryModel> lowStockItems;
  final SellerKycStatusModel? kycStatus;
  final List<SellerPayoutAccountModel> payoutAccounts;
  final String? errorMessage;

  const SellerDashboardLoaded({
    this.profile,
    this.store,
    this.orders = const [],
    this.products = const [],
    this.inventory = const [],
    this.lowStockItems = const [],
    this.kycStatus,
    this.payoutAccounts = const [],
    this.errorMessage,
  });

  int get totalProducts => products.length;
  int get totalOrders => orders.length;
  int get pendingOrders =>
      orders.where((o) => o.status == 'pending').length;
  int get completedOrders =>
      orders.where((o) => o.status == 'delivered').length;
  double get totalRevenue =>
      orders.where((o) => o.status == 'delivered').fold(0.0, (sum, o) => sum + o.total);
  int get lowStockCount => lowStockItems.length;

  SellerDashboardLoaded copyWith({
    SellerProfileModel? profile,
    StoreModel? store,
    List<SellerOrderModel>? orders,
    List<Map<String, dynamic>>? products,
    List<InventoryModel>? inventory,
    List<InventoryModel>? lowStockItems,
    SellerKycStatusModel? kycStatus,
    List<SellerPayoutAccountModel>? payoutAccounts,
    String? errorMessage,
  }) =>
      SellerDashboardLoaded(
        profile: profile ?? this.profile,
        store: store ?? this.store,
        orders: orders ?? this.orders,
        products: products ?? this.products,
        inventory: inventory ?? this.inventory,
        lowStockItems: lowStockItems ?? this.lowStockItems,
        kycStatus: kycStatus ?? this.kycStatus,
        payoutAccounts: payoutAccounts ?? this.payoutAccounts,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        profile, store, orders, products, inventory,
        lowStockItems, kycStatus, payoutAccounts, errorMessage,
      ];
}

class SellerError extends SellerState {
  final String message;
  const SellerError({required this.message});
  @override
  List<Object?> get props => [message];
}

class SellerActionLoading extends SellerState {
  const SellerActionLoading();
}

class SellerActionSuccess extends SellerState {
  final String message;
  const SellerActionSuccess({required this.message});
  @override
  List<Object?> get props => [message];
}

class SellerActionError extends SellerState {
  final String message;
  const SellerActionError({required this.message});
  @override
  List<Object?> get props => [message];
}
