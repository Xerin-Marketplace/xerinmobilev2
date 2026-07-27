import 'package:equatable/equatable.dart';

import '../../data/models/product_model.dart';
import '../../data/models/recommendation_model.dart';

abstract class RecommendationState extends Equatable {
  const RecommendationState();
  @override
  List<Object?> get props => [];
}

class RecommendationInitial extends RecommendationState {
  const RecommendationInitial();
}

class RecommendationLoading extends RecommendationState {
  const RecommendationLoading();
}

class RecommendationLoaded extends RecommendationState {
  final List<RecommendedProductModel> recommended;
  final List<ProductModel> trending;
  final List<FlashDealModel> flashDeals;
  final List<ProductModel> recentlyViewed;
  final List<ProductModel> newArrivals;
  final List<ProductModel> topRated;
  final List<ProductModel> bestSellers;
  final List<StoreModel> stores;
  final List<CouponModel> coupons;
  final bool isRefreshing;

  const RecommendationLoaded({
    this.recommended = const [],
    this.trending = const [],
    this.flashDeals = const [],
    this.recentlyViewed = const [],
    this.newArrivals = const [],
    this.topRated = const [],
    this.bestSellers = const [],
    this.stores = const [],
    this.coupons = const [],
    this.isRefreshing = false,
  });

  RecommendationLoaded copyWith({
    List<RecommendedProductModel>? recommended,
    List<ProductModel>? trending,
    List<FlashDealModel>? flashDeals,
    List<ProductModel>? recentlyViewed,
    List<ProductModel>? newArrivals,
    List<ProductModel>? topRated,
    List<ProductModel>? bestSellers,
    List<StoreModel>? stores,
    List<CouponModel>? coupons,
    bool? isRefreshing,
  }) =>
      RecommendationLoaded(
        recommended: recommended ?? this.recommended,
        trending: trending ?? this.trending,
        flashDeals: flashDeals ?? this.flashDeals,
        recentlyViewed: recentlyViewed ?? this.recentlyViewed,
        newArrivals: newArrivals ?? this.newArrivals,
        topRated: topRated ?? this.topRated,
        bestSellers: bestSellers ?? this.bestSellers,
        stores: stores ?? this.stores,
        coupons: coupons ?? this.coupons,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );

  @override
  List<Object?> get props => [
        recommended, trending, flashDeals, recentlyViewed,
        newArrivals, topRated, bestSellers, stores, coupons, isRefreshing,
      ];
}

class RecommendationError extends RecommendationState {
  final String message;
  const RecommendationError({required this.message});
  @override
  List<Object?> get props => [message];
}

class RelatedProductsLoading extends RecommendationState {
  const RelatedProductsLoading();
}

class RelatedProductsLoaded extends RecommendationState {
  final List<ProductModel> products;
  const RelatedProductsLoaded({required this.products});
  @override
  List<Object?> get props => [products];
}

class StoreProductsLoading extends RecommendationState {
  const StoreProductsLoading();
}

class StoreProductsLoaded extends RecommendationState {
  final StoreModel store;
  final List<ProductModel> products;
  const StoreProductsLoaded({required this.store, required this.products});
  @override
  List<Object?> get props => [store, products];
}
