import 'package:equatable/equatable.dart';

import '../../../../features/auth/data/models/user_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final UserModel? user;
  final List<CategoryModel> categories;
  final List<ProductModel> featuredProducts;
  final List<OrderModel> orders;
  final List<ProductModel> searchResults;
  final List<Map<String, String>> countries;
  final bool isSearching;

  const HomeLoaded({
    this.user,
    this.categories = const [],
    this.featuredProducts = const [],
    this.orders = const [],
    this.searchResults = const [],
    this.countries = const [],
    this.isSearching = false,
  });

  HomeLoaded copyWith({
    UserModel? user,
    List<CategoryModel>? categories,
    List<ProductModel>? featuredProducts,
    List<OrderModel>? orders,
    List<ProductModel>? searchResults,
    List<Map<String, String>>? countries,
    bool? isSearching,
  }) =>
      HomeLoaded(
        user: user ?? this.user,
        categories: categories ?? this.categories,
        featuredProducts: featuredProducts ?? this.featuredProducts,
        orders: orders ?? this.orders,
        searchResults: searchResults ?? this.searchResults,
        countries: countries ?? this.countries,
        isSearching: isSearching ?? this.isSearching,
      );

  @override
  List<Object?> get props =>
      [user, categories, featuredProducts, orders, searchResults, countries, isSearching];
}

class HomeError extends HomeState {
  final String message;
  const HomeError({required this.message});
  @override
  List<Object?> get props => [message];
}
