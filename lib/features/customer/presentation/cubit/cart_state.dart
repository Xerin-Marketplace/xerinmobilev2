import 'package:equatable/equatable.dart';

import '../../data/models/cart_model.dart';

abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {
  const CartInitial();
}

class CartLoading extends CartState {
  const CartLoading();
}

class CartLoaded extends CartState {
  final CartModel cart;
  final bool isRefreshing;

  const CartLoaded({required this.cart, this.isRefreshing = false});

  int get itemCount => cart.itemCount;
  double get total => cart.total;
  String get formattedTotal => cart.formattedTotal;

  CartLoaded copyWith({CartModel? cart, bool? isRefreshing}) =>
      CartLoaded(
        cart: cart ?? this.cart,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );

  @override
  List<Object?> get props => [cart, isRefreshing];
}

class CartActionLoading extends CartState {
  final CartModel? lastCart;
  const CartActionLoading({this.lastCart});
  @override
  List<Object?> get props => [lastCart];
}

class CartError extends CartState {
  final String message;
  final CartModel? lastCart;
  const CartError({required this.message, this.lastCart});
  @override
  List<Object?> get props => [message, lastCart];
}

class CartEmpty extends CartState {
  const CartEmpty();
}
