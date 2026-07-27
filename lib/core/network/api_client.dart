import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../config/constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Logger _logger;
  bool _isRefreshing = false;

  ApiClient(this._dio, this._tokenStorage, this._logger) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenStorage.accessToken;
          if (token != null) {
            options.headers[ApiConstants.authorizationHeader] =
                '${ApiConstants.bearerPrefix} $token';
          }
          _logger.i(
            '➡️  REQUEST [${options.method}] ${options.uri}\n'
            'Headers: ${options.headers}\n'
            'Body: ${options.data}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
            '✅ RESPONSE [${response.statusCode}] ${response.requestOptions.uri}\n'
            'Data: ${response.data}',
          );
          handler.next(response);
        },
        onError: (err, handler) async {
          _logger.e(
            '❌ ERROR [${err.response?.statusCode}] ${err.requestOptions.uri}\n'
            'Message: ${err.message}\n'
            'Response: ${err.response?.data}',
          );

          final statusCode = err.response?.statusCode;
          final path = err.requestOptions.path;

          final isRefreshCall = path.contains(ApiConstants.refreshToken);
          final isAuthCall = path.contains('/auth/');

          if (statusCode == 401 && !isRefreshCall && !isAuthCall && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshed = await _refreshToken();
              _isRefreshing = false;
              if (refreshed) {
                final newToken = _tokenStorage.accessToken;
                err.requestOptions.headers[ApiConstants.authorizationHeader] =
                    '${ApiConstants.bearerPrefix} $newToken';
                final response = await _dio.fetch(err.requestOptions);
                handler.resolve(response);
                return;
              }
            } catch (e) {
              _isRefreshing = false;
              _logger.e('❌ Token refresh failed: $e');
            }
          }
          handler.next(err);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': ApiConstants.contentType},
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ).post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      _logger.i('✅ Token refreshed successfully');
      return true;
    } catch (e) {
      _logger.e('❌ Token refresh error: $e');
      await _tokenStorage.clearTokens();
      return false;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path,
          queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.put<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.delete<T>(path, data: data, options: options);

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map) return first['msg']?.toString() ?? 'Validation error';
      }
      return data['message']?.toString() ?? e.message ?? 'Unknown error';
    }
    return e.message ?? 'Unknown error';
  }

  String getErrorMessage(DioException e) => _extractErrorMessage(e);
}
