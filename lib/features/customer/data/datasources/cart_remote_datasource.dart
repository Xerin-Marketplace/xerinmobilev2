import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/cart_model.dart';

class CartRemoteDataSource {
  final ApiClient _client;

  const CartRemoteDataSource(this._client);

  Future<CartModel> getCart() async {
    try {
      final response = await _client.get(ApiConstants.cart);
      return CartModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<CartModel> addCartItem({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.cartItems,
        data: {
          'product_id': productId,
          if (variantId != null) 'variant_id': variantId,
          'quantity': quantity,
        },
      );
      return CartModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<CartModel> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    try {
      final response = await _client.put(
        ApiConstants.cartItemById(itemId),
        data: {'quantity': quantity},
      );
      return CartModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<CartModel> removeCartItem(String itemId) async {
    try {
      final response = await _client.delete(ApiConstants.cartItemById(itemId));
      return CartModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<CartModel> clearCart() async {
    try {
      final response = await _client.delete(ApiConstants.cart);
      return CartModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<CartModel> applyCoupon(String code) async {
    try {
      final response = await _client.post(
        ApiConstants.cartApplyCoupon,
        data: {'code': code},
      );
      return CartModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<CartModel> removeCoupon() async {
    try {
      final response = await _client.delete(ApiConstants.cartRemoveCoupon);
      return CartModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
