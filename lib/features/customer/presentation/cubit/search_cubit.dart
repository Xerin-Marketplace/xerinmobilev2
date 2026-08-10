import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/search_remote_datasource.dart';
import '../../data/models/search_model.dart';
import '../../data/models/product_model.dart';

abstract class SearchState {
  const SearchState();
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<ProductModel> results;
  final int total;
  final String query;

  const SearchLoaded({
    required this.results,
    this.total = 0,
    this.query = '',
  });
}

class SearchSuggestionsLoaded extends SearchState {
  final List<String> suggestions;
  const SearchSuggestionsLoaded(this.suggestions);
}

class SearchTrendingLoaded extends SearchState {
  final List<TrendingSearchItem> trending;
  const SearchTrendingLoaded(this.trending);
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
}

class SearchCubit extends Cubit<SearchState> {
  final SearchRemoteDataSource _dataSource;
  final Logger _logger;

  SearchCubit({
    required SearchRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const SearchInitial());

  Future<void> search({
    String query = '',
    String? categoryId,
    String? sellerId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    String sort = 'relevance',
    int page = 1,
  }) async {
    emit(const SearchLoading());
    try {
      final result = await _dataSource.searchProducts(
        query: query,
        categoryId: categoryId,
        sellerId: sellerId,
        brandId: brandId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        inStock: inStock,
        sort: sort,
        page: page,
      );
      emit(SearchLoaded(results: result.results, total: result.total, query: query));
    } catch (e) {
      _logger.e('❌ Search failed: $e');
      emit(SearchError(e.toString()));
    }
  }

  Future<void> getSuggestions(String query) async {
    try {
      final result = await _dataSource.getSuggestions(query);
      emit(SearchSuggestionsLoaded(result.suggestions));
    } catch (e) {
      _logger.e('❌ Suggestions failed: $e');
    }
  }

  Future<void> loadTrending() async {
    try {
      final trending = await _dataSource.getTrendingSearches();
      emit(SearchTrendingLoaded(trending));
    } catch (e) {
      _logger.e('❌ Trending failed: $e');
    }
  }

  Future<void> recordView({required String productId, String? searchQuery}) async {
    try {
      await _dataSource.recordProductView(
        productId: productId,
        searchQuery: searchQuery,
      );
    } catch (e) {
      _logger.e('❌ Failed to record view: $e');
    }
  }

  Future<List<ProductModel>> getRelatedProducts(String productId) async {
    try {
      final result = await _dataSource.getRelatedProducts(productId);
      return result.results;
    } catch (e) {
      _logger.e('❌ Failed to load related: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getRecommendations({int limit = 20}) async {
    try {
      final result = await _dataSource.getRecommendations(limit: limit);
      return result.results;
    } catch (e) {
      _logger.e('❌ Failed to load recommendations: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getRecentlyViewed({int limit = 20}) async {
    try {
      final result = await _dataSource.getRecentlyViewed(limit: limit);
      return result.results;
    } catch (e) {
      _logger.e('❌ Failed to load recently viewed: $e');
      return [];
    }
  }
}
