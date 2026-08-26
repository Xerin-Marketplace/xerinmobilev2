import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/admin_models.dart';

// ─── States ───
abstract class AdminState {
  const AdminState();
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminDashboardLoaded extends AdminState {
  final AdminDashboardSummaryModel summary;
  final AdminDashboardOrdersModel? orders;
  final AdminDashboardSellersModel? sellers;
  final AdminDashboardProductsModel? products;
  final AdminDashboardCustomersModel? customers;
  final AdminDashboardPaymentsModel? payments;
  final AdminDashboardRefundsModel? refunds;
  final List<AdminSystemAlertModel> alerts;
  final bool refreshing;

  const AdminDashboardLoaded({
    required this.summary,
    this.orders,
    this.sellers,
    this.products,
    this.customers,
    this.payments,
    this.refunds,
    this.alerts = const [],
    this.refreshing = false,
  });

  AdminDashboardLoaded copyWith({
    AdminDashboardSummaryModel? summary,
    AdminDashboardOrdersModel? orders,
    AdminDashboardSellersModel? sellers,
    AdminDashboardProductsModel? products,
    AdminDashboardCustomersModel? customers,
    AdminDashboardPaymentsModel? payments,
    AdminDashboardRefundsModel? refunds,
    List<AdminSystemAlertModel>? alerts,
    bool? refreshing,
  }) {
    return AdminDashboardLoaded(
      summary: summary ?? this.summary,
      orders: orders ?? this.orders,
      sellers: sellers ?? this.sellers,
      products: products ?? this.products,
      customers: customers ?? this.customers,
      payments: payments ?? this.payments,
      refunds: refunds ?? this.refunds,
      alerts: alerts ?? this.alerts,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

class AdminSellersLoaded extends AdminState {
  final List<AdminSellerModel> sellers;
  final bool loadingMore;
  final bool hasMore;

  const AdminSellersLoaded({
    this.sellers = const [],
    this.loadingMore = false,
    this.hasMore = true,
  });

  AdminSellersLoaded copyWith({
    List<AdminSellerModel>? sellers,
    bool? loadingMore,
    bool? hasMore,
  }) {
    return AdminSellersLoaded(
      sellers: sellers ?? this.sellers,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class AdminSellerDetailLoaded extends AdminState {
  final AdminSellerModel seller;
  final List<AdminSellerDocumentModel> documents;
  final bool documentsLoading;

  const AdminSellerDetailLoaded({
    required this.seller,
    this.documents = const [],
    this.documentsLoading = false,
  });
}

class AdminProductsPendingLoaded extends AdminState {
  final List<Map<String, dynamic>> products;

  const AdminProductsPendingLoaded({this.products = const []});
}

class AdminOrdersLoaded extends AdminState {
  final List<Map<String, dynamic>> orders;
  final int total;
  final int page;
  final int pageSize;
  final bool loadingMore;
  final String? statusFilter;

  const AdminOrdersLoaded({
    this.orders = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.loadingMore = false,
    this.statusFilter,
  });
}

class AdminUsersLoaded extends AdminState {
  final List<AdminUserModel> users;
  final int total;
  final int page;
  final int pageSize;
  final bool loadingMore;
  final String? searchQuery;
  final String? statusFilter;

  const AdminUsersLoaded({
    this.users = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.loadingMore = false,
    this.searchQuery,
    this.statusFilter,
  });
}

class AdminWalletsLoaded extends AdminState {
  final List<AdminWalletModel> wallets;
  final List<AdminPayoutModel> payouts;

  const AdminWalletsLoaded({
    this.wallets = const [],
    this.payouts = const [],
  });
}

class AdminRefundsLoaded extends AdminState {
  final List<AdminRefundModel> refunds;
  final String? statusFilter;

  const AdminRefundsLoaded({
    this.refunds = const [],
    this.statusFilter,
  });
}

class AdminReviewsLoaded extends AdminState {
  final List<AdminReviewModel> reviews;

  const AdminReviewsLoaded({this.reviews = const []});
}

class AdminAnalyticsLoaded extends AdminState {
  final AdminAnalyticsOverviewModel overview;
  final List<AdminAnalyticsSalesPointModel> sales;
  final List<AdminAnalyticsSellerRankingModel> sellers;
  final List<AdminAnalyticsProductRankingModel> products;

  const AdminAnalyticsLoaded({
    required this.overview,
    this.sales = const [],
    this.sellers = const [],
    this.products = const [],
  });
}

class AdminAlertsLoaded extends AdminState {
  final List<AdminSystemAlertModel> alerts;

  const AdminAlertsLoaded({this.alerts = const []});
}

class AdminActivityLogsLoaded extends AdminState {
  final List<AdminActivityLogModel> logs;

  const AdminActivityLogsLoaded({this.logs = const []});
}

class AdminActionSuccess extends AdminState {
  final String message;
  const AdminActionSuccess(this.message);
}

class AdminRolesLoaded extends AdminState {
  final List<AdminRoleModel> roles;
  final List<AdminPermissionModel> allPermissions;
  const AdminRolesLoaded({required this.roles, required this.allPermissions});
}

class AdminRolePermissionsLoaded extends AdminState {
  final AdminRolePermissionsModel rolePermissions;
  final List<AdminPermissionModel> allPermissions;
  const AdminRolePermissionsLoaded({
    required this.rolePermissions,
    required this.allPermissions,
  });
}

class AdminUserPermissionsLoaded extends AdminState {
  final AdminUserPermissionsModel userPermissions;
  final List<AdminPermissionModel> allPermissions;
  final String userName;
  const AdminUserPermissionsLoaded({
    required this.userPermissions,
    required this.allPermissions,
    required this.userName,
  });
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
}

// ─── Cubit ───
class AdminCubit extends Cubit<AdminState> {
  final AdminRemoteDataSource _dataSource;
  final Logger _logger;

  int _usersPage = 1;
  int _ordersPage = 1;
  bool _usersHasMore = true;
  bool _ordersHasMore = true;

  AdminCubit({
    required AdminRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const AdminInitial());

  Future<T?> _safeCall<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  // ─── Dashboard ───
  Future<void> loadDashboard({bool refresh = false}) async {
    if (!refresh) emit(const AdminLoading());
    try {
      final summary = await _dataSource.getDashboardSummary();
      final orders = await _safeCall(() => _dataSource.getDashboardOrders());
      final sellers = await _safeCall(() => _dataSource.getDashboardSellers());
      final products =
          await _safeCall(() => _dataSource.getDashboardProducts());
      final customers =
          await _safeCall(() => _dataSource.getDashboardCustomers());
      final payments =
          await _safeCall(() => _dataSource.getDashboardPayments());
      final refunds = await _safeCall(() => _dataSource.getDashboardRefunds());
      final alerts = await _safeCall(() => _dataSource.getAlerts(limit: 10)) ?? [];

      emit(AdminDashboardLoaded(
        summary: summary,
        orders: orders,
        sellers: sellers,
        products: products,
        customers: customers,
        payments: payments,
        refunds: refunds,
        alerts: alerts,
        refreshing: refresh,
      ));
    } catch (e) {
      _logger.e('AdminCubit.loadDashboard error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Sellers ───
  Future<void> loadSellers({bool pendingOnly = false}) async {
    emit(const AdminLoading());
    try {
      final sellers = pendingOnly
          ? await _dataSource.getPendingSellers()
          : await _dataSource.getAllSellers();
      emit(AdminSellersLoaded(sellers: sellers, hasMore: false));
    } catch (e) {
      _logger.e('AdminCubit.loadSellers error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> openSellerDetail(AdminSellerModel seller) async {
    emit(AdminSellerDetailLoaded(seller: seller, documentsLoading: true));
    try {
      AdminSellerModel current = seller;
      if (seller.status == 'under_review') {
        current = await _dataSource.startSellerReview(seller.id);
      }
      final documents =
          await _safeCall(() => _dataSource.getSellerDocuments(seller.id)) ?? [];
      emit(AdminSellerDetailLoaded(
          seller: current, documents: documents, documentsLoading: false));
    } catch (e) {
      _logger.e('AdminCubit.openSellerDetail error: $e');
      emit(AdminSellerDetailLoaded(
          seller: seller, documentsLoading: false));
    }
  }

  Future<void> approveSeller(String sellerId) async {
    try {
      await _dataSource.approveSeller(sellerId);
      emit(const AdminActionSuccess('Seller approved successfully'));
      await loadSellers();
    } catch (e) {
      _logger.e('AdminCubit.approveSeller error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> rejectSeller(String sellerId, String reason) async {
    try {
      await _dataSource.rejectSeller(sellerId, reason);
      emit(const AdminActionSuccess('Seller rejected'));
      await loadSellers();
    } catch (e) {
      _logger.e('AdminCubit.rejectSeller error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Products ───
  Future<void> loadPendingProducts() async {
    emit(const AdminLoading());
    try {
      final products = await _dataSource.getPendingProducts();
      emit(AdminProductsPendingLoaded(products: products));
    } catch (e) {
      _logger.e('AdminCubit.loadPendingProducts error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> approveProduct(String productId) async {
    try {
      await _dataSource.approveProduct(productId);
      emit(const AdminActionSuccess('Product approved'));
      await loadPendingProducts();
    } catch (e) {
      _logger.e('AdminCubit.approveProduct error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> rejectProduct(String productId, String reason) async {
    try {
      await _dataSource.rejectProduct(productId, reason);
      emit(const AdminActionSuccess('Product rejected'));
      await loadPendingProducts();
    } catch (e) {
      _logger.e('AdminCubit.rejectProduct error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Orders ───
  Future<void> loadOrders({
    bool reset = true,
    String? status,
  }) async {
    if (reset) {
      _ordersPage = 1;
      _ordersHasMore = true;
    }
    try {
      final data = await _dataSource.getAllOrders(
        page: _ordersPage,
        status: status,
      );
      final List results = data['results'] as List? ?? [];
      final total = data['total'] as int? ?? results.length;
      _ordersHasMore = _ordersPage * 20 < total;

      if (reset) {
        emit(AdminOrdersLoaded(
          orders: results.cast<Map<String, dynamic>>(),
          total: total,
          page: _ordersPage,
          statusFilter: status,
        ));
      } else {
        final current = state;
        if (current is AdminOrdersLoaded) {
          emit(current.copyWith(
            orders: [...current.orders, ...results.cast<Map<String, dynamic>>()],
            total: total,
            page: _ordersPage,
            loadingMore: false,
          ));
        }
      }
    } catch (e) {
      _logger.e('AdminCubit.loadOrders error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> loadMoreOrders() async {
    final current = state;
    if (current is AdminOrdersLoaded && !current.loadingMore && _ordersHasMore) {
      _ordersPage++;
      emit(current.copyWith(loadingMore: true));
      await loadOrders(reset: false, status: current.statusFilter);
    }
  }

  // ─── Users ───
  Future<void> loadUsers({
    bool reset = true,
    String? search,
    String? statusFilter,
  }) async {
    if (reset) {
      _usersPage = 1;
      _usersHasMore = true;
    }
    try {
      final result = await _dataSource.getUsers(
        page: _usersPage,
        search: search,
        statusFilter: statusFilter,
      );
      _usersHasMore = _usersPage * result.pageSize < result.total;

      if (reset) {
        emit(AdminUsersLoaded(
          users: result.results,
          total: result.total,
          page: result.page,
          pageSize: result.pageSize,
          searchQuery: search,
          statusFilter: statusFilter,
        ));
      } else {
        final current = state;
        if (current is AdminUsersLoaded) {
          emit(current.copyWith(
            users: [...current.users, ...result.results],
            total: result.total,
            page: result.page,
            loadingMore: false,
          ));
        }
      }
    } catch (e) {
      _logger.e('AdminCubit.loadUsers error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> loadMoreUsers() async {
    final current = state;
    if (current is AdminUsersLoaded && !current.loadingMore && _usersHasMore) {
      _usersPage++;
      emit(current.copyWith(loadingMore: true));
      await loadUsers(
        reset: false,
        search: current.searchQuery,
        statusFilter: current.statusFilter,
      );
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      await _dataSource.createUser(data);
      emit(const AdminActionSuccess('User created successfully'));
      await loadUsers();
    } catch (e) {
      _logger.e('AdminCubit.createUser error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _dataSource.updateUser(userId, data);
      emit(const AdminActionSuccess('User updated successfully'));
      await loadUsers();
    } catch (e) {
      _logger.e('AdminCubit.updateUser error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _dataSource.deleteUser(userId);
      emit(const AdminActionSuccess('User deleted successfully'));
      await loadUsers();
    } catch (e) {
      _logger.e('AdminCubit.deleteUser error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Wallets ───
  Future<void> loadWallets() async {
    emit(const AdminLoading());
    try {
      final wallets = await _dataSource.getAllWallets();
      final payouts = await _safeCall(() => _dataSource.getAllPayouts()) ?? [];
      emit(AdminWalletsLoaded(wallets: wallets, payouts: payouts));
    } catch (e) {
      _logger.e('AdminCubit.loadWallets error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updatePayout(String payoutId, Map<String, dynamic> data) async {
    try {
      await _dataSource.updatePayout(payoutId, data);
      emit(const AdminActionSuccess('Payout updated successfully'));
      await loadWallets();
    } catch (e) {
      _logger.e('AdminCubit.updatePayout error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> adjustWallet(
      String sellerId, double amount, String reason) async {
    try {
      await _dataSource.adjustWallet(sellerId, amount, reason);
      emit(const AdminActionSuccess('Wallet adjusted successfully'));
      await loadWallets();
    } catch (e) {
      _logger.e('AdminCubit.adjustWallet error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Refunds ───
  Future<void> loadRefunds({String? status}) async {
    emit(const AdminLoading());
    try {
      final refunds = await _dataSource.getAllRefunds(refundStatus: status);
      emit(AdminRefundsLoaded(refunds: refunds, statusFilter: status));
    } catch (e) {
      _logger.e('AdminCubit.loadRefunds error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> reviewRefund(String refundId, {String? note}) async {
    try {
      await _dataSource.reviewRefund(refundId, note: note);
      emit(const AdminActionSuccess('Refund under review'));
      final current = state;
      if (current is AdminRefundsLoaded) {
        await loadRefunds(status: current.statusFilter);
      }
    } catch (e) {
      _logger.e('AdminCubit.reviewRefund error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> approveRefund(String refundId, {String? note}) async {
    try {
      await _dataSource.approveRefund(refundId, note: note);
      emit(const AdminActionSuccess('Refund approved'));
      final current = state;
      if (current is AdminRefundsLoaded) {
        await loadRefunds(status: current.statusFilter);
      }
    } catch (e) {
      _logger.e('AdminCubit.approveRefund error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> rejectRefund(String refundId, {String? note}) async {
    try {
      await _dataSource.rejectRefund(refundId, note: note);
      emit(const AdminActionSuccess('Refund rejected'));
      final current = state;
      if (current is AdminRefundsLoaded) {
        await loadRefunds(status: current.statusFilter);
      }
    } catch (e) {
      _logger.e('AdminCubit.rejectRefund error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> processRefund(String refundId,
      {String? note, String? providerReference}) async {
    try {
      await _dataSource.processRefund(refundId,
          note: note, providerReference: providerReference);
      emit(const AdminActionSuccess('Refund processed'));
      final current = state;
      if (current is AdminRefundsLoaded) {
        await loadRefunds(status: current.statusFilter);
      }
    } catch (e) {
      _logger.e('AdminCubit.processRefund error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Reviews ───
  Future<void> loadReviews() async {
    emit(const AdminLoading());
    try {
      final reviews = await _dataSource.getAllReviews();
      emit(AdminReviewsLoaded(reviews: reviews));
    } catch (e) {
      _logger.e('AdminCubit.loadReviews error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> moderateReview(String reviewId, String status) async {
    try {
      await _dataSource.moderateReview(reviewId, status);
      emit(const AdminActionSuccess('Review moderated'));
      await loadReviews();
    } catch (e) {
      _logger.e('AdminCubit.moderateReview error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Analytics ───
  Future<void> loadAnalytics() async {
    emit(const AdminLoading());
    try {
      final overview = await _dataSource.getAnalyticsOverview();
      final sales = await _safeCall(() => _dataSource.getAnalyticsSales()) ?? [];
      final sellers =
          await _safeCall(() => _dataSource.getAnalyticsSellers()) ?? [];
      final products =
          await _safeCall(() => _dataSource.getAnalyticsProducts()) ?? [];
      emit(AdminAnalyticsLoaded(
        overview: overview,
        sales: sales,
        sellers: sellers,
        products: products,
      ));
    } catch (e) {
      _logger.e('AdminCubit.loadAnalytics error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Alerts ───
  Future<void> loadAlerts({bool? resolved}) async {
    emit(const AdminLoading());
    try {
      final alerts = await _dataSource.getAlerts(resolved: resolved);
      emit(AdminAlertsLoaded(alerts: alerts));
    } catch (e) {
      _logger.e('AdminCubit.loadAlerts error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> resolveAlert(String alertId) async {
    try {
      await _dataSource.resolveAlert(alertId);
      emit(const AdminActionSuccess('Alert resolved'));
      await loadAlerts();
    } catch (e) {
      _logger.e('AdminCubit.resolveAlert error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Activity Logs ───
  Future<void> loadActivityLogs({int limit = 100}) async {
    emit(const AdminLoading());
    try {
      final logs = await _dataSource.getActivityLogs(limit: limit);
      emit(AdminActivityLogsLoaded(logs: logs));
    } catch (e) {
      _logger.e('AdminCubit.loadActivityLogs error: $e');
      emit(AdminError(e.toString()));
    }
  }

  // ─── Roles & Permissions ───
  Future<void> loadRoles() async {
    emit(const AdminLoading());
    try {
      final roles = await _dataSource.getRoles();
      final allPermissions = await _dataSource.getAllPermissions();
      emit(AdminRolesLoaded(roles: roles, allPermissions: allPermissions));
    } catch (e) {
      _logger.e('AdminCubit.loadRoles error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> loadRolePermissions(String roleId) async {
    emit(const AdminLoading());
    try {
      final rolePermissions = await _dataSource.getRolePermissions(roleId);
      final allPermissions = await _dataSource.getAllPermissions();
      emit(AdminRolePermissionsLoaded(
        rolePermissions: rolePermissions,
        allPermissions: allPermissions,
      ));
    } catch (e) {
      _logger.e('AdminCubit.loadRolePermissions error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updateRolePermissions(
      String roleId, List<String> permissionCodes) async {
    try {
      await _dataSource.updateRolePermissions(roleId, permissionCodes);
      emit(const AdminActionSuccess('Role permissions updated'));
      await loadRolePermissions(roleId);
    } catch (e) {
      _logger.e('AdminCubit.updateRolePermissions error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> loadUserPermissions(
      String userId, String userName) async {
    emit(const AdminLoading());
    try {
      final userPermissions = await _dataSource.getUserPermissions(userId);
      final allPermissions = await _dataSource.getAllPermissions();
      emit(AdminUserPermissionsLoaded(
        userPermissions: userPermissions,
        allPermissions: allPermissions,
        userName: userName,
      ));
    } catch (e) {
      _logger.e('AdminCubit.loadUserPermissions error: $e');
      emit(AdminError(e.toString()));
    }
  }

  Future<void> assignUserPermissions(
      String userId, List<String> permissionCodes) async {
    try {
      await _dataSource.assignUserPermissions(userId, permissionCodes);
      emit(const AdminActionSuccess('User permissions updated'));
    } catch (e) {
      _logger.e('AdminCubit.assignUserPermissions error: $e');
      emit(AdminError(e.toString()));
    }
  }
}

// Extension to add copyWith to AdminOrdersLoaded
extension AdminOrdersLoadedCopyWith on AdminOrdersLoaded {
  AdminOrdersLoaded copyWith({
    List<Map<String, dynamic>>? orders,
    int? total,
    int? page,
    int? pageSize,
    bool? loadingMore,
    String? statusFilter,
  }) {
    return AdminOrdersLoaded(
      orders: orders ?? this.orders,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      loadingMore: loadingMore ?? this.loadingMore,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

// Extension to add copyWith to AdminUsersLoaded
extension AdminUsersLoadedCopyWith on AdminUsersLoaded {
  AdminUsersLoaded copyWith({
    List<AdminUserModel>? users,
    int? total,
    int? page,
    int? pageSize,
    bool? loadingMore,
    String? searchQuery,
    String? statusFilter,
  }) {
    return AdminUsersLoaded(
      users: users ?? this.users,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      loadingMore: loadingMore ?? this.loadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}
