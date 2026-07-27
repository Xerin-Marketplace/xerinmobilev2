import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../data/datasources/cart_remote_datasource.dart';
import '../../data/models/cart_model.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartRemoteDataSource _dataSource;
  final Logger _logger;

  CartCubit({
    required CartRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const CartInitial());

  CartModel? _lastCart;

  Future<void> loadCart() async {
    emit(const CartLoading());
    try {
      final cart = await _dataSource.getCart();
      _lastCart = cart;
      if (cart.items.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(cart: cart));
      }
    } on ServerException catch (e) {
      _logger.e('❌ Cart load error: ${e.message}');
      emit(CartError(message: e.message, lastCart: _lastCart));
    } catch (e) {
      _logger.e('❌ Cart load unexpected error: $e');
      emit(CartError(message: 'Failed to load cart', lastCart: _lastCart));
    }
  }

  Future<void> addToCart({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    try {
      final cart = await _dataSource.addCartItem(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      _lastCart = cart;
      if (cart.items.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(cart: cart));
      }
      _logger.i('✅ Added to cart: product=$productId, qty=$quantity');
    } on ServerException catch (e) {
      _logger.e('❌ Add to cart error: ${e.message}');
      emit(CartError(message: e.message, lastCart: _lastCart));
    } catch (e) {
      _logger.e('❌ Add to cart unexpected error: $e');
      emit(CartError(message: 'Failed to add item', lastCart: _lastCart));
    }
  }

  Future<void> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final current = state;
    if (current is CartLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    try {
      final cart = await _dataSource.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );
      _lastCart = cart;
      if (cart.items.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(cart: cart));
      }
    } on ServerException catch (e) {
      _logger.e('❌ Update cart error: ${e.message}');
      emit(CartError(message: e.message, lastCart: _lastCart));
    } catch (e) {
      _logger.e('❌ Update cart unexpected error: $e');
      emit(CartError(message: 'Failed to update quantity', lastCart: _lastCart));
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      final cart = await _dataSource.removeCartItem(itemId);
      _lastCart = cart;
      if (cart.items.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(cart: cart));
      }
      _logger.i('✅ Removed cart item: $itemId');
    } on ServerException catch (e) {
      _logger.e('❌ Remove cart item error: ${e.message}');
      emit(CartError(message: e.message, lastCart: _lastCart));
    } catch (e) {
      _logger.e('❌ Remove cart item unexpected error: $e');
      emit(CartError(message: 'Failed to remove item', lastCart: _lastCart));
    }
  }

  Future<void> clearCart() async {
    try {
      final cart = await _dataSource.clearCart();
      _lastCart = cart;
      emit(const CartEmpty());
      _logger.i('✅ Cart cleared');
    } on ServerException catch (e) {
      _logger.e('❌ Clear cart error: ${e.message}');
      emit(CartError(message: e.message, lastCart: _lastCart));
    } catch (e) {
      _logger.e('❌ Clear cart unexpected error: $e');
      emit(CartError(message: 'Failed to clear cart', lastCart: _lastCart));
    }
  }

  Future<void> applyCoupon(String code) async {
    final current = state;
    if (current is CartLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    try {
      final cart = await _dataSource.applyCoupon(code);
      _lastCart = cart;
      emit(CartLoaded(cart: cart));
      _logger.i('✅ Coupon applied: $code');
    } on ServerException catch (e) {
      _logger.e('❌ Apply coupon error: ${e.message}');
      emit(CartError(message: e.message, lastCart: _lastCart));
    } catch (e) {
      _logger.e('❌ Apply coupon unexpected error: $e');
      emit(CartError(message: 'Failed to apply coupon', lastCart: _lastCart));
    }
  }

  Future<void> removeCoupon() async {
    final current = state;
    if (current is CartLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    try {
      final cart = await _dataSource.removeCoupon();
      _lastCart = cart;
      emit(CartLoaded(cart: cart));
      _logger.i('✅ Coupon removed');
    } on ServerException catch (e) {
      _logger.e('❌ Remove coupon error: ${e.message}');
      emit(CartError(message: e.message, lastCart: _lastCart));
    } catch (e) {
      _logger.e('❌ Remove coupon unexpected error: $e');
      emit(CartError(message: 'Failed to remove coupon', lastCart: _lastCart));
    }
  }

  int get itemCount {
    if (_lastCart != null) return _lastCart!.itemCount;
    final current = state;
    if (current is CartLoaded) return current.itemCount;
    return 0;
  }
}
