import 'product_model.dart';

class ProductSearchResult {
  final int total;
  final int page;
  final int pageSize;
  final List<ProductModel> results;

  const ProductSearchResult({
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.results = const [],
  });

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return ProductSearchResult(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      results: list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SearchSuggestionResult {
  final List<String> suggestions;

  const SearchSuggestionResult({this.suggestions = const []});

  factory SearchSuggestionResult.fromJson(Map<String, dynamic> json) {
    return SearchSuggestionResult(
      suggestions: (json['suggestions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class TrendingSearchItem {
  final String term;
  final int searchCount;

  const TrendingSearchItem({this.term = '', this.searchCount = 0});

  factory TrendingSearchItem.fromJson(Map<String, dynamic> json) {
    return TrendingSearchItem(
      term: json['term'] as String? ?? '',
      searchCount: (json['search_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class RecommendationResult {
  final int total;
  final List<ProductModel> results;

  const RecommendationResult({this.total = 0, this.results = const []});

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return RecommendationResult(
      total: (json['total'] as num?)?.toInt() ?? 0,
      results: list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SellerSearchAnalyticsItem {
  final String query;
  final int searches;
  final int productViews;

  const SellerSearchAnalyticsItem({
    this.query = '',
    this.searches = 0,
    this.productViews = 0,
  });

  factory SellerSearchAnalyticsItem.fromJson(Map<String, dynamic> json) {
    return SellerSearchAnalyticsItem(
      query: json['query'] as String? ?? '',
      searches: (json['searches'] as num?)?.toInt() ?? 0,
      productViews: (json['product_views'] as num?)?.toInt() ?? 0,
    );
  }
}

class SellerProductPerformanceItem {
  final String productId;
  final String productName;
  final int views;

  const SellerProductPerformanceItem({
    required this.productId,
    required this.productName,
    this.views = 0,
  });

  factory SellerProductPerformanceItem.fromJson(Map<String, dynamic> json) {
    return SellerProductPerformanceItem(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? '',
      views: (json['views'] as num?)?.toInt() ?? 0,
    );
  }
}
