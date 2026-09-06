import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/category_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final ProductRemoteDataSource _productDs;
  final CustomerRemoteDataSource _customerDs;
  final AuthRemoteDataSource _authDs;
  final Logger _logger;

  HomeCubit({
    required ProductRemoteDataSource productDataSource,
    required CustomerRemoteDataSource customerDataSource,
    required AuthRemoteDataSource authDataSource,
    required this._logger,
  })  : _productDs = productDataSource,
        _customerDs = customerDataSource,
        _authDs = authDataSource,
        super(const HomeInitial());

  Future<void> loadHome() async {
    emit(const HomeLoading());

    final userFuture = _authDs.getMyProfile().then<dynamic>((v) => v).catchError((_) => null);
    final catFuture = _productDs.getCategories().then<dynamic>((v) => v).catchError((_) => null);
    final prodFuture = _productDs.getProducts(limit: 10).then<dynamic>((v) => v).catchError((_) => null);
    final orderFuture = _customerDs.getOrders(pageSize: 10).then<dynamic>((v) => v).catchError((_) => null);
    final countryFuture = _productDs.getCountryOptions().then<dynamic>((v) => v).catchError((_) => null);

    final results = await Future.wait([userFuture, catFuture, prodFuture, orderFuture, countryFuture]);

    final user = results[0] is UserModel ? results[0] as UserModel : null;
    final categories = results[1] is List ? (results[1] as List).whereType<CategoryModel>().toList() : <CategoryModel>[];
    final featured = results[2] is List ? (results[2] as List).whereType<ProductModel>().toList() : <ProductModel>[];
    final orders = results[3] is List ? (results[3] as List).whereType<OrderModel>().toList() : <OrderModel>[];
    final countries = results[4] is List ? (results[4] as List).whereType<Map<String, String>>().toList() : <Map<String, String>>[];

    _logger.i(
      '✅ Home loaded — user: ${user?.fullName ?? "guest"}, '
      'categories: ${categories.length}, '
      'featured: ${featured.length}, '
      'orders: ${orders.length}',
    );

    emit(HomeLoaded(
      user: user,
      categories: categories,
      featuredProducts: featured,
      orders: orders,
      countries: countries,
    ));
  }

  Future<void> searchProducts(String query) async {
    final current = state;
    if (current is! HomeLoaded) return;
    if (query.isEmpty) {
      emit(current.copyWith(searchResults: [], isSearching: false));
      return;
    }
    emit(current.copyWith(isSearching: true));
    try {
      final results = await _productDs.getProducts(search: query, limit: 30);
      _logger.i('🔍 Search "$query" → ${results.length} results');
      if (isClosed) return;
      final refreshed = state is HomeLoaded ? state as HomeLoaded : current;
      emit(refreshed.copyWith(searchResults: results, isSearching: false));
    } on ServerException catch (e) {
      _logger.e('❌ Search error: ${e.message}');
      if (isClosed) return;
      emit(current.copyWith(isSearching: false));
    } catch (_) {
      if (isClosed) return;
      emit(current.copyWith(isSearching: false));
    }
  }

  Future<void> loadByCategory(String categoryId) async {
    final current = state;
    if (current is! HomeLoaded) return;
    emit(current.copyWith(isSearching: true));
    try {
      final results = await _productDs.getProducts(
          categoryId: categoryId, limit: 30);
      _logger.i('📂 Category $categoryId → ${results.length} products');
      if (isClosed) return;
      final refreshed = state is HomeLoaded ? state as HomeLoaded : current;
      emit(refreshed.copyWith(searchResults: results, isSearching: false));
    } catch (_) {
      if (isClosed) return;
      emit(current.copyWith(isSearching: false));
    }
  }
}
