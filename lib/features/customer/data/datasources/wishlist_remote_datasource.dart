import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/wishlist_item_model.dart';

class WishlistRemoteDataSource {
  final ApiClient _client;

  const WishlistRemoteDataSource(this._client);

  Future<List<WishlistItemModel>> getWishlist() async {
    try {
      final response = await _client.get(ApiConstants.wishlistProducts);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        if (data['results'] != null) {
          list = data['results'] as List;
        } else if (data['items'] != null) {
          list = data['items'] as List;
        } else if (data['data'] != null) {
          list = data['data'] as List;
        } else {
          list = [];
        }
      } else {
        list = [];
      }
      return list
          .map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    } catch (e) {
      throw ServerException('Failed to parse wishlist: $e');
    }
  }

  Future<WishlistItemModel> addToWishlist({required String productId}) async {
    try {
      final response = await _client.post(
        ApiConstants.wishlistAddProduct(productId),
      );
      return WishlistItemModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> removeFromWishlist({required String productId}) async {
    try {
      await _client.delete(ApiConstants.wishlistRemoveProduct(productId));
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> clearWishlist() async {
    try {
      await _client.delete(ApiConstants.wishlistClear);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, int>> getWishlistSummary() async {
    try {
      final response = await _client.get(ApiConstants.wishlistSummary);
      final data = response.data as Map<String, dynamic>;
      return {
        'product_count': (data['product_count'] as num?)?.toInt() ?? 0,
        'store_count': (data['store_count'] as num?)?.toInt() ?? 0,
      };
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<bool> toggleWishlistItem({required String productId}) async {
    try {
      await _client.post(ApiConstants.wishlistAddProduct(productId));
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        await removeFromWishlist(productId: productId);
        return false;
      }
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
