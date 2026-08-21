import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../config/constants/api_constants.dart';
import '../storage/token_storage.dart';

typedef SessionExpiredCallback = void Function();

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Logger _logger;
  bool _isRefreshing = false;
  SessionExpiredCallback? _onSessionExpired;

  ApiClient(this._dio, this._tokenStorage, this._logger) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenStorage.accessToken;
          if (token != null) {
            options.headers[ApiConstants.authorizationHeader] =
                '${ApiConstants.bearerPrefix} $token';
          }
          final isAuthCall = options.path.contains('/auth/');
          final sanitizedBody = isAuthCall ? '[REDACTED]' : options.data;
          final sanitizedHeaders = Map.of(options.headers);
          if (sanitizedHeaders.containsKey(ApiConstants.authorizationHeader)) {
            sanitizedHeaders[ApiConstants.authorizationHeader] = '[REDACTED]';
          }
          _logger.i(
            '➡️  REQUEST [${options.method}] ${options.uri}\n'
            'Headers: $sanitizedHeaders\n'
            'Body: $sanitizedBody',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
            '✅ RESPONSE [${response.statusCode}] ${response.requestOptions.uri}',
          );
          handler.next(response);
        },
        onError: (err, handler) async {
          _logger.e(
            '❌ ERROR [${err.response?.statusCode}] ${err.requestOptions.uri}',
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
              } else {
                _notifySessionExpired();
              }
            } catch (e) {
              _isRefreshing = false;
              _logger.e('❌ Token refresh failed: $e');
              _notifySessionExpired();
            }
          }
          handler.next(err);
        },
      ),
    );
  }

  void setSessionExpiredCallback(SessionExpiredCallback callback) {
    _onSessionExpired = callback;
  }

  void _notifySessionExpired() {
    _onSessionExpired?.call();
  }

  Future<bool> _refreshToken() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: '${ApiConstants.baseUrl}/api/v1',
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
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return _humanizeMessage(detail, statusCode);
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map) {
          final msg = first['msg']?.toString();
          if (msg != null) return _humanizeMessage(msg, statusCode);
        }
      }
      if (data['message'] is String) {
        return _humanizeMessage(data['message'] as String, statusCode);
      }
    }

    return _humanizeMessage(e.message ?? '', statusCode);
  }

  String _humanizeMessage(String raw, int? statusCode) {
    final msg = raw.trim();

    if (statusCode == 401) {
      if (msg.toLowerCase().contains('invalid email or password') ||
          msg.toLowerCase().contains('invalid credentials')) {
        return 'Invalid email or password. Please try again.';
      }
      if (msg.toLowerCase().contains('not verified') ||
          msg.toLowerCase().contains('account not verified')) {
        return 'Your account is not verified. Please verify your phone number.';
      }
      if (msg.toLowerCase().contains('token') ||
          msg.toLowerCase().contains('unauthorized')) {
        return 'Your session has expired. Please sign in again.';
      }
      return 'Authentication failed. Please sign in again.';
    }

    if (statusCode == 403) {
      if (msg.toLowerCase().contains('permission') ||
          msg.toLowerCase().contains('forbidden')) {
        return 'You do not have permission to perform this action.';
      }
      return 'Access denied. You do not have permission to do this.';
    }

    if (statusCode == 404) {
      return 'The requested resource was not found.';
    }

    if (statusCode == 409) {
      if (msg.toLowerCase().contains('already') ||
          msg.toLowerCase().contains('exists')) {
        return 'This item already exists.';
      }
      return 'A conflict occurred with the current state.';
    }

    if (statusCode == 422) {
      if (msg.toLowerCase().contains('validation')) {
        return 'Please check your input and try again.';
      }
      return msg.isEmpty ? 'Validation error. Please check your input.' : msg;
    }

    if (statusCode == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    if (msg.toLowerCase().contains('connection') ||
        msg.toLowerCase().contains('socket') ||
        msg.toLowerCase().contains('timeout')) {
      return 'Connection error. Please check your internet and try again.';
    }

    return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
  }

  String getErrorMessage(DioException e) => _extractErrorMessage(e);
}
