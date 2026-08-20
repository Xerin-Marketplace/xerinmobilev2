import 'package:equatable/equatable.dart';

import '../../data/models/inventory_model.dart';
import '../../data/models/seller_kyc_model.dart';
import '../../data/models/seller_order_model.dart';
import '../../data/models/seller_payout_model.dart';
import '../../data/models/seller_profile_model.dart';
import '../../data/models/seller_wallet_model.dart';
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
  final SellerWalletModel? wallet;
  final List<WalletTransactionModel> walletTransactions;
  final List<WalletPayoutModel> walletPayouts;
  final Map<String, dynamic>? analyticsOverview;
  final List<Map<String, dynamic>> analyticsSales;
  final List<Map<String, dynamic>> analyticsProducts;
  final Map<String, dynamic>? orderSummary;
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
    this.wallet,
    this.walletTransactions = const [],
    this.walletPayouts = const [],
    this.analyticsOverview,
    this.analyticsSales = const [],
    this.analyticsProducts = const [],
    this.orderSummary,
    this.errorMessage,
  });

  int get totalProducts {
    if (analyticsOverview != null) return _pi((analyticsOverview!['counts'] as Map?)?['products']);
    return products.length;
  }
  int get totalOrders {
    if (orderSummary != null) return _pi(orderSummary!['total_orders']);
    if (analyticsOverview != null) return _pi((analyticsOverview!['counts'] as Map?)?['orders']);
    return orders.length;
  }
  int get pendingOrders =>
      orders.where((o) => o.status == 'pending').length;
  int get completedOrders =>
      orders.where((o) => o.status == 'delivered').length;
  double get totalRevenue {
    if (analyticsOverview != null) {
      final money = analyticsOverview!['money'] as Map<String, dynamic>?;
      return _pd(money?['gross_sales']);
    }
    return orders.where((o) => o.status == 'delivered').fold(0.0, (sum, o) => sum + o.total);
  }
  double get avgOrderValue {
    if (analyticsOverview != null) return _pd(analyticsOverview!['average_order_value']);
    return totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
  }
  double get netEarnings {
    if (analyticsOverview != null) {
      final money = analyticsOverview!['money'] as Map<String, dynamic>?;
      return _pd(money?['seller_net_earnings']);
    }
    return wallet?.availableBalance ?? 0.0;
  }
  double get commissionPaid {
    if (analyticsOverview != null) {
      final money = analyticsOverview!['money'] as Map<String, dynamic>?;
      return _pd(money?['commission_revenue']);
    }
    return 0.0;
  }
  double get pendingWalletBalance {
    if (analyticsOverview != null) return _pd(analyticsOverview!['pending_wallet_balance']);
    return wallet?.pendingBalance ?? 0.0;
  }
  double get availableWalletBalance {
    if (analyticsOverview != null) return _pd(analyticsOverview!['available_wallet_balance']);
    return wallet?.availableBalance ?? 0.0;
  }
  int get newOrders {
    if (orderSummary != null) return _pi(orderSummary!['new_orders']);
    return orders.where((o) => o.status == 'pending' || o.status == 'new').length;
  }
  int get processingOrders {
    if (orderSummary != null) return _pi(orderSummary!['processing_orders']);
    return orders.where((o) => o.status == 'processing').length;
  }
  int get deliveredOrders {
    if (orderSummary != null) return _pi(orderSummary!['delivered_orders']);
    return completedOrders;
  }
  int get readyToShipOrders {
    if (orderSummary != null) return _pi(orderSummary!['ready_to_ship_orders']);
    return 0;
  }
  int get unitsSold {
    if (orderSummary != null) return _pi(orderSummary!['units_sold']);
    if (analyticsOverview != null) {
      final counts = analyticsOverview!['counts'] as Map<String, dynamic>?;
      return _pi(counts?['units_sold']);
    }
    return orders.where((o) => o.status == 'delivered').fold(0, (sum, o) => sum + o.items.fold(0, (s, i) => s + i.quantity));
  }
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
    SellerWalletModel? wallet,
    List<WalletTransactionModel>? walletTransactions,
    List<WalletPayoutModel>? walletPayouts,
    Map<String, dynamic>? analyticsOverview,
    List<Map<String, dynamic>>? analyticsSales,
    List<Map<String, dynamic>>? analyticsProducts,
    Map<String, dynamic>? orderSummary,
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
        wallet: wallet ?? this.wallet,
        walletTransactions: walletTransactions ?? this.walletTransactions,
        walletPayouts: walletPayouts ?? this.walletPayouts,
        analyticsOverview: analyticsOverview ?? this.analyticsOverview,
        analyticsSales: analyticsSales ?? this.analyticsSales,
        analyticsProducts: analyticsProducts ?? this.analyticsProducts,
        orderSummary: orderSummary ?? this.orderSummary,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        profile, store, orders, products, inventory,
        lowStockItems, kycStatus, payoutAccounts, wallet,
        walletTransactions, walletPayouts, analyticsOverview,
        analyticsSales, analyticsProducts, orderSummary, errorMessage,
      ];
}

double _pd(dynamic v) { if (v == null) return 0.0; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0.0; return 0.0; }
int _pi(dynamic v) { if (v == null) return 0; if (v is num) return v.toInt(); if (v is String) return int.tryParse(v) ?? 0; return 0; }

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
