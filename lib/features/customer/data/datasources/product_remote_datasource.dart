import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  final ApiClient _client;

  const ProductRemoteDataSource(this._client);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client.get(ApiConstants.productCategories);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else if (data is Map && data['data'] != null) {
        list = data['data'] as List;
      } else {
        list = [];
      }
      return list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<ProductModel>> getProducts({
    int skip = 0,
    int limit = 20,
    String? categoryId,
    String? search,
    String? sortBy,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        'category_id': ?categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        'sort_by': ?sortBy,
        'is_active': ?isActive,
      };
      final response = await _client.get(
        ApiConstants.products,
        queryParameters: queryParams,
      );
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else if (data is Map && data['data'] != null) {
        list = data['data'] as List;
      } else {
        list = [];
      }
      return list
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _client.get(ApiConstants.productById(id));
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<String>> getProductImages(String id) async {
    try {
      final response = await _client.get(ApiConstants.productImages(id));
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else if (data is Map && data['data'] != null) {
        list = data['data'] as List;
      } else {
        list = [];
      }
      return list.map((e) {
        if (e is String) return e;
        if (e is Map) return (e['image_url'] ?? e['url'] ?? '') as String;
        return '';
      }).where((url) => url.isNotEmpty).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, String>>> getCountryOptions() async {
    try {
      final response = await _client.get(ApiConstants.logisticsCountryOptions);
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] != null) {
        list = data['items'] as List;
      } else {
        list = [];
      }
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        return {
          'code': map['code']?.toString() ?? '',
          'name': map['name']?.toString() ?? '',
        };
      }).where((c) => c['name']!.isNotEmpty).toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
