import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/search_model.dart';

class SearchRemoteDataSource {
  final ApiClient _client;

  const SearchRemoteDataSource(this._client);

  Future<ProductSearchResult> searchProducts({
    String query = '',
    String? categoryId,
    String? sellerId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    String sort = 'relevance',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.searchProducts,
        queryParameters: {
          'q': query,
          if (categoryId != null) 'category_id': categoryId,
          if (sellerId != null) 'seller_id': sellerId,
          if (brandId != null) 'brand_id': brandId,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          if (inStock != null) 'in_stock': inStock,
          'sort': sort,
          'page': page,
          'page_size': pageSize,
        },
      );
      return ProductSearchResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<SearchSuggestionResult> getSuggestions(String query, {int limit = 8}) async {
    try {
      final response = await _client.get(
        ApiConstants.searchSuggestions,
        queryParameters: {'q': query, 'limit': limit},
      );
      return SearchSuggestionResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<TrendingSearchItem>> getTrendingSearches({int limit = 10}) async {
    try {
      final response = await _client.get(
        ApiConstants.searchTrending,
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => TrendingSearchItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> recordProductView({
    required String productId,
    String? sessionId,
    String source = 'mobile',
    String? searchQuery,
  }) async {
    try {
      await _client.post(
        ApiConstants.productView(productId),
        data: {
          if (sessionId != null) 'session_id': sessionId,
          'source': source,
          if (searchQuery != null) 'search_query': searchQuery,
        },
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<RecommendationResult> getRelatedProducts(String productId, {int limit = 12}) async {
    try {
      final response = await _client.get(
        ApiConstants.relatedProductsBySearch(productId),
        queryParameters: {'limit': limit},
      );
      return RecommendationResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<RecommendationResult> getRecommendations({int limit = 20}) async {
    try {
      final response = await _client.get(
        ApiConstants.recommendations,
        queryParameters: {'limit': limit},
      );
      return RecommendationResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<RecommendationResult> getRecentlyViewed({int limit = 20}) async {
    try {
      final response = await _client.get(
        ApiConstants.recommendationsRecentlyViewed,
        queryParameters: {'limit': limit},
      );
      return RecommendationResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerSearchAnalyticsItem>> getSellerSearchAnalytics({int limit = 20}) async {
    try {
      final response = await _client.get(
        ApiConstants.sellerSearchAnalytics,
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => SellerSearchAnalyticsItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<SellerProductPerformanceItem>> getSellerProductPerformance({int limit = 50}) async {
    try {
      final response = await _client.get(
        ApiConstants.sellerProductPerformance,
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => SellerProductPerformanceItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
