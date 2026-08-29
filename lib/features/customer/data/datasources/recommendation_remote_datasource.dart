import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';
import '../models/recommendation_model.dart';

class RecommendationRemoteDataSource {
  final ApiClient _client;
  final Logger _logger;

  RecommendationRemoteDataSource(this._client, this._logger);

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) {
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } else if (data is Map) {
      final list = data['results'] ?? data['items'] ?? data['data'];
      if (list is List) {
        return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }

  Future<List<RecommendedProductModel>> getRecommendedProducts({
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.recommendedProducts,
        queryParameters: {'limit': limit},
      );
      return _parseList(
        response.data, RecommendedProductModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getRecommendedProducts: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductModel>> getTrendingProducts({
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.trendingProducts,
        queryParameters: {'limit': limit},
      );
      return _parseList(response.data, ProductModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getTrendingProducts: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<FlashDealModel>> getFlashDeals({
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.flashDeals,
        queryParameters: {'limit': limit},
      );
      return _parseList(response.data, FlashDealModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getFlashDeals: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductModel>> getRecentlyViewed({
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.recentlyViewed,
        queryParameters: {'limit': limit},
      );
      return _parseList(response.data, ProductModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getRecentlyViewed: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductModel>> getRelatedProducts(
    String productId, {
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.relatedByProduct(productId),
        queryParameters: {'limit': limit},
      );
      return _parseList(response.data, ProductModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getRelatedProducts: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductModel>> getNewArrivals({
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.newArrivals,
        queryParameters: {'limit': limit},
      );
      return _parseList(response.data, ProductModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getNewArrivals: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductModel>> getTopRated({
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.topRated,
        queryParameters: {'limit': limit},
      );
      return _parseList(response.data, ProductModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getTopRated: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductModel>> getBestSellers({
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.bestSellers,
        queryParameters: {'limit': limit},
      );
      return _parseList(response.data, ProductModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getBestSellers: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<StoreModel>> getStores({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.publicStores,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null) 'search': search,
        },
      );
      return _parseList(response.data, StoreModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getStores: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductModel>> getStoreProducts(String slug) async {
    try {
      final response = await _client.get(
        ApiConstants.storeProducts(slug),
      );
      return _parseList(response.data, ProductModel.fromJson);
    } on DioException catch (e) {
      _logger.e('❌ getStoreProducts: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<CouponModel>> getAvailableCoupons() async {
    try {
      final response = await _client.get('/cart/promotions/available');
      final list = response.data is List ? response.data as List : [];
      return list.map((e) {
        final json = e as Map<String, dynamic>;
        return CouponModel(
          id: json['promotion_id']?.toString() ?? '',
          code: json['code'] as String? ?? '',
          description: json['description'] as String? ?? json['name'] as String? ?? '',
          discountType: json['promotion_type'] as String? ?? 'percentage',
          discountValue: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
          minOrderAmount: double.tryParse(json['minimum_order_amount']?.toString() ?? '0') ?? 0.0,
          maxDiscountAmount: double.tryParse(json['maximum_discount_amount']?.toString() ?? '0') ?? 0.0,
        );
      }).toList();
    } on DioException catch (e) {
      _logger.e('❌ getAvailableCoupons: ${e.message}');
      return [];
    }
  }

  Future<CouponModel> validateCoupon(String code) async {
    try {
      final response = await _client.get(
        ApiConstants.couponValidate(code),
      );
      return CouponModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('❌ validateCoupon: ${e.message}');
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
