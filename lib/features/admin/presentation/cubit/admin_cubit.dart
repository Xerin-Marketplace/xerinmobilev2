import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminRemoteDataSource _dataSource;
  final Logger _logger;

  AdminCubit({
    required AdminRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const AdminInitial());

  Future<void> loadDashboard() async {
    emit(const AdminLoading());
    final results = await Future.wait([
      _dataSource.getUsers(pageSize: 100).then<dynamic>((v) => v).catchError((e) {
        _logger.e('Admin users error: $e');
        return null;
      }),
      _dataSource.getPendingSellers(pageSize: 100).then<dynamic>((v) => v).catchError((e) {
        _logger.e('Admin pending sellers error: $e');
        return null;
      }),
      _dataSource.getPendingProducts(pageSize: 100).then<dynamic>((v) => v).catchError((e) {
        _logger.e('Admin pending products error: $e');
        return null;
      }),
      _dataSource.getBusinessCategories().then<dynamic>((v) => v).catchError((e) {
        _logger.e('Admin business categories error: $e');
        return null;
      }),
      _dataSource.getProductCategories().then<dynamic>((v) => v).catchError((e) {
        _logger.e('Admin product categories error: $e');
        return null;
      }),
      _dataSource.getBrands().then<dynamic>((v) => v).catchError((e) {
        _logger.e('Admin brands error: $e');
        return null;
      }),
      _dataSource.getSellers(pageSize: 100).then<dynamic>((v) => v).catchError((e) {
        _logger.e('Admin sellers error: $e');
        return null;
      }),
    ]);

    final users = results[0] is List<Map<String, dynamic>>
        ? results[0] as List<Map<String, dynamic>>
        : <Map<String, dynamic>>[];
    final pendingSellers = results[1] is List<Map<String, dynamic>>
        ? results[1] as List<Map<String, dynamic>>
        : <Map<String, dynamic>>[];
    final pendingProducts = results[2] is List<Map<String, dynamic>>
        ? results[2] as List<Map<String, dynamic>>
        : <Map<String, dynamic>>[];
    final businessCategories = results[3] is List<Map<String, dynamic>>
        ? results[3] as List<Map<String, dynamic>>
        : <Map<String, dynamic>>[];
    final productCategories = results[4] is List<Map<String, dynamic>>
        ? results[4] as List<Map<String, dynamic>>
        : <Map<String, dynamic>>[];
    final brands = results[5] is List<Map<String, dynamic>>
        ? results[5] as List<Map<String, dynamic>>
        : <Map<String, dynamic>>[];
    final sellers = results[6] is List<Map<String, dynamic>>
        ? results[6] as List<Map<String, dynamic>>
        : <Map<String, dynamic>>[];

    _logger.i(
      '✅ Admin dashboard loaded — users: ${users.length}, '
      'sellers: ${sellers.length}, pendingSellers: ${pendingSellers.length}, '
      'pendingProducts: ${pendingProducts.length}',
    );

    emit(AdminDashboardLoaded(
      users: users,
      pendingSellers: pendingSellers,
      pendingProducts: pendingProducts,
      businessCategories: businessCategories,
      productCategories: productCategories,
      brands: brands,
      sellers: sellers,
    ));
  }

  // Users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      return await _dataSource.getUsers(pageSize: 100, search: query);
    } catch (e) {
      _logger.e('Search users error: $e');
      return [];
    }
  }

  Future<void> verifyUser(String id) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.updateUser(id, {'is_verified': true, 'status': 'active'});
      emit(const AdminActionSuccess(message: 'User verified successfully'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  Future<void> deleteUser(String id) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.deleteUser(id);
      emit(const AdminActionSuccess(message: 'User deleted successfully'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  Future<void> createAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.createAdmin(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
      emit(const AdminActionSuccess(message: 'Admin created successfully'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  // Sellers
  Future<void> registerSeller({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? businessName,
  }) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.registerSeller(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
        businessName: businessName,
      );
      emit(const AdminActionSuccess(message: 'Seller registered successfully'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  Future<void> approveSeller(String id) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.approveSeller(id);
      emit(const AdminActionSuccess(message: 'Seller approved successfully'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  Future<void> rejectSeller(String id, {String? reason}) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.rejectSeller(id, reason: reason);
      emit(const AdminActionSuccess(message: 'Seller rejected'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  // Products
  Future<void> approveProduct(String id) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.approveProduct(id);
      emit(const AdminActionSuccess(message: 'Product approved successfully'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  Future<void> rejectProduct(String id, {String? reason}) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.rejectProduct(id, reason: reason);
      emit(const AdminActionSuccess(message: 'Product rejected'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  // Categories
  Future<void> createProductCategory(String name, {String? description}) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.createProductCategory({
        'name': name,
        if (description != null) 'description': description,
      });
      emit(const AdminActionSuccess(message: 'Category created successfully'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  Future<void> deleteProductCategory(String id) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.deleteProductCategory(id);
      emit(const AdminActionSuccess(message: 'Category deleted'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  Future<void> createBusinessCategory(String name, {String? description}) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.createBusinessCategory({
        'name': name,
        if (description != null) 'description': description,
      });
      emit(const AdminActionSuccess(message: 'Business category created'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  Future<void> deleteBusinessCategory(String id) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.deleteBusinessCategory(id);
      emit(const AdminActionSuccess(message: 'Business category deleted'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  // Brands
  Future<void> createBrand(String name, {String? description}) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.createBrand({
        'name': name,
        if (description != null) 'description': description,
      });
      emit(const AdminActionSuccess(message: 'Brand created successfully'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }

  Future<void> deleteBrand(String id) async {
    emit(const AdminActionLoading());
    try {
      await _dataSource.deleteBrand(id);
      emit(const AdminActionSuccess(message: 'Brand deleted'));
      await loadDashboard();
    } on ServerException catch (e) {
      emit(AdminActionError(message: e.message));
    }
  }
}
