import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../data/datasources/recommendation_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../data/models/recommendation_model.dart';
import 'recommendation_state.dart';

class RecommendationCubit extends Cubit<RecommendationState> {
  final RecommendationRemoteDataSource _dataSource;
  final Logger _logger;

  RecommendationCubit({
    required RecommendationRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const RecommendationInitial());

  Future<void> loadAll() async {
    emit(const RecommendationLoading());
    try {
      final results = await Future.wait([
        _dataSource.getRecommendedProducts().catchError((_) => <RecommendedProductModel>[]),
        _dataSource.getTrendingProducts().catchError((_) => <ProductModel>[]),
        _dataSource.getFlashDeals().catchError((_) => <FlashDealModel>[]),
        _dataSource.getRecentlyViewed().catchError((_) => <ProductModel>[]),
        _dataSource.getNewArrivals().catchError((_) => <ProductModel>[]),
        _dataSource.getTopRated().catchError((_) => <ProductModel>[]),
        _dataSource.getBestSellers().catchError((_) => <ProductModel>[]),
        _dataSource.getStores().catchError((_) => <StoreModel>[]),
        _dataSource.getAvailableCoupons().catchError((_) => <CouponModel>[]),
      ]);

      emit(RecommendationLoaded(
        recommended: results[0] as List<RecommendedProductModel>,
        trending: results[1] as List<ProductModel>,
        flashDeals: results[2] as List<FlashDealModel>,
        recentlyViewed: results[3] as List<ProductModel>,
        newArrivals: results[4] as List<ProductModel>,
        topRated: results[5] as List<ProductModel>,
        bestSellers: results[6] as List<ProductModel>,
        stores: results[7] as List<StoreModel>,
        coupons: results[8] as List<CouponModel>,
      ));
      _logger.i('✅ Recommendation data loaded');
    } catch (e) {
      _logger.e('❌ Failed to load recommendations: $e');
      emit(RecommendationError(message: e.toString()));
    }
  }

  Future<void> loadRelatedProducts(String productId) async {
    emit(const RelatedProductsLoading());
    try {
      final products = await _dataSource.getRelatedProducts(productId);
      emit(RelatedProductsLoaded(products: products));
    } on ServerException catch (e) {
      _logger.e('❌ Related products: ${e.message}');
      emit(RelatedProductsLoaded(products: []));
    } catch (e) {
      _logger.e('❌ Related products: $e');
      emit(RelatedProductsLoaded(products: []));
    }
  }

  Future<void> loadStoreProducts(String slug) async {
    emit(const StoreProductsLoading());
    try {
      final products = await _dataSource.getStoreProducts(slug);
      final stores = await _dataSource.getStores();
      final store = stores.where((s) => s.slug == slug).firstOrNull;
      if (store != null) {
        emit(StoreProductsLoaded(store: store, products: products));
      } else {
        emit(StoreProductsLoaded(
          store: StoreModel(
            id: '', sellerId: '', name: slug, slug: slug,
          ),
          products: products,
        ));
      }
    } on ServerException catch (e) {
      _logger.e('❌ Store products: ${e.message}');
      emit(RecommendationError(message: e.message));
    } catch (e) {
      _logger.e('❌ Store products: $e');
      emit(RecommendationError(message: e.toString()));
    }
  }

  Future<void> refreshFlashDeals() async {
    final current = state;
    if (current is! RecommendationLoaded) return;
    emit(current.copyWith(isRefreshing: true));
    try {
      final deals = await _dataSource.getFlashDeals();
      if (isClosed) return;
      final refreshed = state is RecommendationLoaded
          ? state as RecommendationLoaded
          : current;
      emit(refreshed.copyWith(flashDeals: deals, isRefreshing: false));
    } catch (e) {
      _logger.e('❌ Flash deals refresh: $e');
      if (isClosed) return;
      emit(current.copyWith(isRefreshing: false));
    }
  }
}
