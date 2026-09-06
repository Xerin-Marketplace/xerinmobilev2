import 'dart:math';

import '../../data/models/product_model.dart';
import '../../data/models/recommendation_model.dart';

/// Marketplace-grade product ranking engine inspired by Alibaba/Amazon.
///
/// Flow: Candidate Retrieval → Multi-signal Ranking → Diversification → Result
///
/// Scoring formula (0–100):
///   RELEVANCE       × 0.25
/// + SALES_SCORE     × 0.15
/// + CTR_SCORE       × 0.10
/// + CONVERSION      × 0.15
/// + RATING          × 0.08
/// + PRICE_SCORE     × 0.05
/// + STOCK_SCORE     × 0.05
/// + SELLER_SCORE    × 0.07
/// + FRESHNESS       × 0.03
/// + PERSONALIZATION × 0.07
class RecommendationEngine {
  final Random _random;

  RecommendationEngine({Random? random}) : _random = random ?? Random();

  /// Ranks [products] using the full multi-signal scoring algorithm.
  ///
  /// Parameters:
  /// - [searchQuery]: user's search text for relevance scoring
  /// - [trendingIds]: product IDs that are currently trending (from backend)
  /// - [bestSellerIds]: product IDs that are best sellers (sales proxy)
  /// - [topRatedIds]: product IDs that are top rated
  /// - [recentlyViewed]: products the user recently viewed (for personalization)
  /// - [stores]: store data for seller quality scoring
  /// - [recommendedScores]: map of productId → matchScore from backend recommendation
  /// - [selectedCategoryId]: currently selected category filter
  /// - [maxPerSeller]: diversification cap (max products per seller in top N)
  /// - [diversifyTopN]: number of top results to apply diversification to
  List<ProductModel> rank({
    required List<ProductModel> products,
    String? searchQuery,
    Set<String>? trendingIds,
    Set<String>? bestSellerIds,
    Set<String>? topRatedIds,
    List<ProductModel>? recentlyViewed,
    List<StoreModel>? stores,
    Map<String, double>? recommendedScores,
    String? selectedCategoryId,
    int maxPerSeller = 2,
    int diversifyTopN = 20,
  }) {
    if (products.length <= 1) return List.of(products);

    final now = DateTime.now();
    final affinityCategories =
        RecommendationEngine.extractCategoryIds(recentlyViewed ?? []);
    final affinityProductIds =
        (recentlyViewed ?? []).where((p) => p.id.isNotEmpty).map((p) => p.id).toSet();
    final sellerMap = <String, StoreModel>{};
    for (final s in stores ?? <StoreModel>[]) {
      if (s.sellerId.isNotEmpty) sellerMap[s.sellerId] = s;
    }

    // Compute category average price for price competitiveness
    final categoryPrices = <String, List<double>>{};
    for (final p in products) {
      final key = p.categoryId.isNotEmpty ? p.categoryId : (p.categoryName ?? '_');
      categoryPrices.putIfAbsent(key, () => []).add(p.price);
    }
    final categoryAvgPrice = <String, double>{};
    categoryPrices.forEach((key, prices) {
      categoryAvgPrice[key] =
          prices.reduce((a, b) => a + b) / prices.length;
    });

    // Score all products
    final scored = <_ScoredProduct>[];
    for (final product in products) {
      final score = _scoreProduct(
        product: product,
        now: now,
        searchQuery: searchQuery,
        trendingIds: trendingIds ?? {},
        bestSellerIds: bestSellerIds ?? {},
        topRatedIds: topRatedIds ?? {},
        affinityCategories: affinityCategories,
        affinityProductIds: affinityProductIds,
        sellerMap: sellerMap,
        recommendedScores: recommendedScores ?? {},
        categoryAvgPrice: categoryAvgPrice,
      );
      scored.add(_ScoredProduct(product, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Diversification: limit products per seller in top N
    var result = scored.map((s) => s.product).toList();
    if (maxPerSeller > 0 && result.length > diversifyTopN) {
      result = _diversify(result, maxPerSeller, diversifyTopN);
    }

    return result;
  }

  double _scoreProduct({
    required ProductModel product,
    required DateTime now,
    String? searchQuery,
    required Set<String> trendingIds,
    required Set<String> bestSellerIds,
    required Set<String> topRatedIds,
    required Set<String> affinityCategories,
    required Set<String> affinityProductIds,
    required Map<String, StoreModel> sellerMap,
    required Map<String, double> recommendedScores,
    required Map<String, double> categoryAvgPrice,
  }) {
    // 1. RELEVANCE (0–25) — text matching against search query
    final relevance = _relevanceScore(product, searchQuery);

    // 2. SALES_SCORE (0–15) — best seller membership as proxy
    double salesScore = 0;
    if (bestSellerIds.contains(product.id)) {
      salesScore = 15;
    } else if (trendingIds.contains(product.id)) {
      salesScore = 10;
    }

    // 3. CTR_SCORE (0–10) — use backend recommendation matchScore as proxy
    double ctrScore = 5; // neutral default for cold start
    final recScore = recommendedScores[product.id];
    if (recScore != null && recScore > 0) {
      ctrScore = (recScore.clamp(0, 1) * 10);
    }

    // 4. CONVERSION (0–15) — best sellers + trending combined as proxy
    double conversionScore = 0;
    if (bestSellerIds.contains(product.id)) {
      conversionScore += 10;
    }
    if (trendingIds.contains(product.id)) {
      conversionScore += 5;
    }

    // 5. RATING (0–8) — Bayesian-inspired: use rating + top-rated membership
    double ratingScore = (product.rating.clamp(0, 5) / 5) * 5;
    if (topRatedIds.contains(product.id)) {
      ratingScore += 3; // boost for being in top-rated list
    }

    // 6. PRICE_SCORE (0–5) — competitiveness vs category average
    final catKey = product.categoryId.isNotEmpty
        ? product.categoryId
        : (product.categoryName ?? '_');
    final avgPrice = categoryAvgPrice[catKey];
    double priceScore = 2.5; // neutral
    if (avgPrice != null && avgPrice > 0) {
      final ratio = product.price / avgPrice;
      if (ratio <= 0.5) {
        // Suspiciously cheap — slight penalty
        priceScore = 1.5;
      } else if (ratio <= 0.9) {
        // Good deal
        priceScore = 5;
      } else if (ratio <= 1.1) {
        // Fair price
        priceScore = 4;
      } else if (ratio <= 1.5) {
        // Slightly expensive
        priceScore = 2;
      } else {
        // Expensive
        priceScore = 1;
      }
    }
    // Sale price bonus
    if (product.salePrice != null && product.price > 0) {
      final discountPct = (1 - (product.salePrice! / product.price)) * 100;
      priceScore += (discountPct.clamp(0, 30) / 30) * 1;
    }

    // 7. STOCK_SCORE (0–5) — use isActive as proxy
    double stockScore = 0;
    if (product.isActive) {
      stockScore = 5;
    }
    // Products with images are more "real"/stocked
    if (product.images.isEmpty) {
      stockScore -= 2;
    }

    // 8. SELLER_SCORE (0–7) — store rating + verified status
    double sellerScore = 3.5; // neutral default
    final store = sellerMap[product.sellerId];
    if (store != null) {
      sellerScore = (store.rating.clamp(0, 5) / 5) * 4;
      if (store.isVerified) sellerScore += 2;
      if (!store.isOpen) sellerScore -= 3; // closed store penalty
      // More products = more established seller
      if (store.totalProducts > 50) sellerScore += 1;
    }

    // 9. FRESHNESS (0–3) + COLD START BOOST
    double freshnessScore = 0;
    if (product.createdAt != null && product.createdAt!.isNotEmpty) {
      final created = DateTime.tryParse(product.createdAt!);
      if (created != null) {
        final ageDays = now.difference(created).inDays;
        if (ageDays <= 1) {
          // Cold start: first 24h → full boost
          freshnessScore = 3;
        } else if (ageDays <= 3) {
          freshnessScore = 2.5;
        } else if (ageDays <= 7) {
          freshnessScore = 2;
        } else if (ageDays <= 30) {
          freshnessScore = 1;
        } else if (ageDays <= 90) {
          freshnessScore = 0.5;
        }
      }
    }

    // 10. PERSONALIZATION (0–7) — category affinity + recently viewed similarity
    double personalizationScore = 0;
    if (product.categoryId.isNotEmpty &&
        affinityCategories.contains(product.categoryId)) {
      personalizationScore += 5;
    } else if (product.categoryName != null &&
        affinityCategories.contains(product.categoryName)) {
      personalizationScore += 5;
    }
    // Boost if user viewed this exact product before (re-engagement)
    if (affinityProductIds.contains(product.id)) {
      personalizationScore += 2;
    }

    // Diversity random (keeps feed fresh across loads)
    final diversity = _random.nextDouble() * 1.5;

    final totalScore = relevance * 0.25 +
        salesScore * 0.15 +
        ctrScore * 0.10 +
        conversionScore * 0.15 +
        ratingScore * 0.08 +
        priceScore * 0.05 +
        stockScore * 0.05 +
        sellerScore * 0.07 +
        freshnessScore * 0.03 +
        personalizationScore * 0.07 +
        diversity;

    return totalScore;
  }

  /// Text relevance scoring (0–25).
  /// Matches search query against product name, category, and description.
  double _relevanceScore(ProductModel product, String? searchQuery) {
    if (searchQuery == null || searchQuery.trim().isEmpty) {
      // No search → neutral score so other signals dominate
      return 12.5;
    }

    final query = searchQuery.toLowerCase().trim();
    final queryTerms = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (queryTerms.isEmpty) return 12.5;

    final name = product.name.toLowerCase();
    final category = (product.categoryName ?? '').toLowerCase();
    final description = (product.description ?? '').toLowerCase();

    double score = 0;

    for (final term in queryTerms) {
      // Exact name match → highest weight
      if (name == term) {
        score += 8;
      } else if (name.contains(term)) {
        // Term appears in name
        final position = name.indexOf(term);
        // Earlier position = more relevant
        score += 5 * (1 - (position / max(name.length, 1)));
      } else if (category.contains(term)) {
        score += 2;
      } else if (description.contains(term)) {
        score += 1;
      }
    }

    // Multi-term match bonus (all terms found somewhere)
    final allTermsInName = queryTerms.every((t) => name.contains(t));
    if (allTermsInName && queryTerms.length > 1) {
      score += 4;
    }

    // Exact phrase match in name
    if (name.contains(query)) {
      score += 3;
    }

    return score.clamp(0, 25);
  }

  /// Diversification: ensures max [maxPerSeller] products per seller
  /// in the top [topN] results. Excess products are moved after topN.
  List<ProductModel> _diversify(
    List<ProductModel> sorted,
    int maxPerSeller,
    int topN,
  ) {
    final top = <ProductModel>[];
    final rest = <ProductModel>[];
    final sellerCount = <String, int>{};

    for (final product in sorted) {
      final count = sellerCount[product.sellerId] ?? 0;
      if (top.length < topN && count < maxPerSeller) {
        top.add(product);
        sellerCount[product.sellerId] = count + 1;
      } else {
        rest.add(product);
      }
    }

    return [...top, ...rest];
  }

  /// Extracts category IDs from recently viewed products for affinity scoring.
  static Set<String> extractCategoryIds(List<ProductModel> recentlyViewed) {
    final ids = <String>{};
    for (final p in recentlyViewed) {
      if (p.categoryId.isNotEmpty) ids.add(p.categoryId);
      if (p.categoryName != null) ids.add(p.categoryName!);
    }
    return ids;
  }

  /// Extracts product IDs from a product list.
  static Set<String> extractProductIds(List<ProductModel> products) {
    return products.where((p) => p.id.isNotEmpty).map((p) => p.id).toSet();
  }

  /// Builds a map of productId → matchScore from backend recommended products.
  static Map<String, double> extractRecommendedScores(
    List<RecommendedProductModel> recommended,
  ) {
    final map = <String, double>{};
    for (final r in recommended) {
      if (r.product.id.isNotEmpty && r.matchScore > 0) {
        map[r.product.id] = r.matchScore;
      }
    }
    return map;
  }
}

class _ScoredProduct {
  final ProductModel product;
  final double score;

  _ScoredProduct(this.product, this.score);
}
