import 'package:equatable/equatable.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminActionLoading extends AdminState {
  const AdminActionLoading();
}

// Dashboard overview
class AdminDashboardLoaded extends AdminState {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> pendingSellers;
  final List<Map<String, dynamic>> pendingProducts;
  final List<Map<String, dynamic>> businessCategories;
  final List<Map<String, dynamic>> productCategories;
  final List<Map<String, dynamic>> brands;
  final List<Map<String, dynamic>> sellers;
  final String? errorMessage;

  const AdminDashboardLoaded({
    this.users = const [],
    this.pendingSellers = const [],
    this.pendingProducts = const [],
    this.businessCategories = const [],
    this.productCategories = const [],
    this.brands = const [],
    this.sellers = const [],
    this.errorMessage,
  });

  int get totalUsers => users.length;
  int get totalSellers => sellers.length;
  int get totalPendingSellers => pendingSellers.length;
  int get totalPendingProducts => pendingProducts.length;
  int get totalCategories => productCategories.length;
  int get totalBrands => brands.length;

  AdminDashboardLoaded copyWith({
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? pendingSellers,
    List<Map<String, dynamic>>? pendingProducts,
    List<Map<String, dynamic>>? businessCategories,
    List<Map<String, dynamic>>? productCategories,
    List<Map<String, dynamic>>? brands,
    List<Map<String, dynamic>>? sellers,
    String? errorMessage,
  }) =>
      AdminDashboardLoaded(
        users: users ?? this.users,
        pendingSellers: pendingSellers ?? this.pendingSellers,
        pendingProducts: pendingProducts ?? this.pendingProducts,
        businessCategories: businessCategories ?? this.businessCategories,
        productCategories: productCategories ?? this.productCategories,
        brands: brands ?? this.brands,
        sellers: sellers ?? this.sellers,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        users, pendingSellers, pendingProducts,
        businessCategories, productCategories, brands, sellers, errorMessage,
      ];
}

class AdminActionSuccess extends AdminState {
  final String message;
  const AdminActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminActionError extends AdminState {
  final String message;
  const AdminActionError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminError extends AdminState {
  final String message;
  const AdminError({required this.message});

  @override
  List<Object?> get props => [message];
}
