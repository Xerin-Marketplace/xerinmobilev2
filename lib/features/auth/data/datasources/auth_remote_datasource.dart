import 'package:dio/dio.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  const AuthRemoteDataSource(this._client);

  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.register,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'phone': ?phone,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<TokenModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      return TokenModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> logout({required String refreshToken}) async {
    try {
      await _client.post(
        ApiConstants.logout,
        data: {'refresh_token': refreshToken},
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<TokenModel> refreshToken({required String refreshToken}) async {
    try {
      final response = await _client.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      return TokenModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> sendOtp({required String phone}) async {
    try {
      await _client.post(
        ApiConstants.sendOtp,
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otpCode,
  }) async {
    try {
      await _client.post(
        ApiConstants.verifyOtp,
        data: {
          'phone': phone,
          'otp_code': otpCode,
        },
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _client.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      await _client.post(
        ApiConstants.resetPassword,
        data: {
          'email': email,
          'otp_code': otpCode,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<UserModel> getMyProfile() async {
    try {
      final response = await _client.get(ApiConstants.myProfile);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final response = await _client.patch(
        ApiConstants.myProfile,
        data: {
          'first_name': ?firstName,
          'last_name': ?lastName,
          'phone': ?phone,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
