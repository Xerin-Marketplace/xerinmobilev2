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

  Future<Map<String, dynamic>> registerSeller({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String businessName,
    required List<String> businessCategoryIds,
    String? businessDescription,
    String? businessCountry,
    String? businessRegion,
    String? businessCity,
    String? businessAddress,
    String? productDescription,
    String? yearsInBusiness,
    String? websiteUrl,
    String? contactEmail,
    String? contactPhone,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.registerSeller,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          'business_name': businessName,
          'business_category_ids': businessCategoryIds,
          if (businessDescription != null) 'business_description': businessDescription,
          if (businessCountry != null) 'business_country': businessCountry,
          if (businessRegion != null) 'business_region': businessRegion,
          if (businessCity != null) 'business_city': businessCity,
          if (businessAddress != null) 'business_address': businessAddress,
          if (productDescription != null) 'product_description': productDescription,
          if (yearsInBusiness != null) 'years_in_business': yearsInBusiness,
          if (websiteUrl != null) 'website_url': websiteUrl,
          if (contactEmail != null) 'contact_email': contactEmail,
          if (contactPhone != null) 'contact_phone': contactPhone,
          'agreement_accepted': true,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> registerBroker({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String country,
    required String region,
    required String city,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.registerBroker,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          'country': country,
          'region': region,
          'city': city,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> getBusinessCategories() async {
    try {
      final response = await _client.get(ApiConstants.adminBusinessCategories);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => e as Map<String, dynamic>)
          .toList();
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

  // ─── Role Selection & Onboarding ───

  Future<Map<String, dynamic>> selectInitialRole({
    required String role,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.selectInitialRole,
        data: {'selected_role': role},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> onboardSeller({
    required String businessName,
    required List<String> businessCategoryIds,
    String? businessDescription,
    String? businessCountry,
    String? businessRegion,
    String? businessCity,
    String? businessDistrict,
    String? businessWard,
    String? businessAddress,
    String? productDescription,
    String? yearsInBusiness,
    String? websiteUrl,
    String? contactEmail,
    String? contactPhone,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.onboardSeller,
        data: {
          'business_name': businessName,
          'business_category_ids': businessCategoryIds,
          'agreement_accepted': true,
          if (businessDescription != null) 'business_description': businessDescription,
          if (businessCountry != null) 'business_country': businessCountry,
          if (businessRegion != null) 'business_region': businessRegion,
          if (businessCity != null) 'business_city': businessCity,
          if (businessDistrict != null) 'business_district': businessDistrict,
          if (businessWard != null) 'business_ward': businessWard,
          if (businessAddress != null) 'business_address': businessAddress,
          if (productDescription != null) 'product_description': productDescription,
          if (yearsInBusiness != null) 'years_in_business': yearsInBusiness,
          if (websiteUrl != null) 'website_url': websiteUrl,
          if (contactEmail != null) 'contact_email': contactEmail,
          if (contactPhone != null) 'contact_phone': contactPhone,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> onboardBroker({
    required String country,
    required String region,
    required String city,
    String? district,
    String? ward,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.onboardBroker,
        data: {
          'country': country,
          'region': region,
          'city': city,
          if (district != null) 'district': district,
          if (ward != null) 'ward': ward,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<void> resendVerification({required String identifier}) async {
    try {
      await _client.post(
        ApiConstants.resendVerification,
        data: {'identifier': identifier},
      );
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> verifyAccountOtp({
    required String identifier,
    required String otpCode,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.verifyAccountOtp,
        data: {
          'identifier': identifier,
          'otp_code': otpCode,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }
}
