import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRemoteDataSource _dataSource;
  final TokenStorage _tokenStorage;
  final Logger _logger;

  String? _pendingPhone;
  String? _pendingFirstName;
  String? _pendingLastName;
  String? _pendingEmail;
  String? _pendingPassword;

  AuthCubit({
    required AuthRemoteDataSource dataSource,
    required TokenStorage tokenStorage,
    required Logger logger,
  })  : _dataSource = dataSource,
        _tokenStorage = tokenStorage,
        _logger = logger,
        super(const AuthInitial());

  String? get pendingPhone => _pendingPhone;
  String? get pendingFirstName => _pendingFirstName;
  String? get pendingLastName => _pendingLastName;
  String? get pendingEmail => _pendingEmail;
  String? get pendingPassword => _pendingPassword;

  void storeRegistrationData({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) {
    _pendingFirstName = firstName;
    _pendingLastName = lastName;
    _pendingEmail = email;
    _pendingPassword = password;
    _pendingPhone = phone;
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    emit(const AuthLoading());
    try {
      storeRegistrationData(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone ?? '',
      );
      final user = await _dataSource.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
      _logger.i('✅ Register success: ${user.fullName} (${user.email})');
      emit(AuthRegisterSuccess(user: user, phone: phone ?? ''));
    } on ServerException catch (e) {
      _logger.e('❌ Register error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Register unexpected error: $e');
      emit(AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> loadBusinessCategories() async {
    try {
      final categories = await _dataSource.getBusinessCategories();
      emit(BusinessCategoriesLoaded(categories: categories));
    } on ServerException catch (e) {
      _logger.e('❌ Load business categories error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Load business categories unexpected error: $e');
      emit(AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> registerSeller({
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
    emit(const AuthLoading());
    try {
      final result = await _dataSource.registerSeller(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        businessName: businessName,
        businessCategoryIds: businessCategoryIds,
        businessDescription: businessDescription,
        businessCountry: businessCountry,
        businessRegion: businessRegion,
        businessCity: businessCity,
        businessAddress: businessAddress,
        productDescription: productDescription,
        yearsInBusiness: yearsInBusiness,
        websiteUrl: websiteUrl,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
      );
      final message = result['message']?.toString() ??
          'Seller registration successful. Please verify your phone.';
      _logger.i('✅ Seller register success: $email');
      emit(SellerRegisterSuccess(phone: phone, message: message));
    } on ServerException catch (e) {
      _logger.e('❌ Seller register error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Seller register unexpected error: $e');
      emit(AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> registerBroker({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String country,
    required String region,
    required String city,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _dataSource.registerBroker(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        country: country,
        region: region,
        city: city,
      );
      final message = result['message']?.toString() ??
          'Broker account created. Please verify your phone.';
      _logger.i('✅ Broker register success: $email');
      emit(BrokerRegisterSuccess(phone: phone, message: message));
    } on ServerException catch (e) {
      _logger.e('❌ Broker register error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Broker register unexpected error: $e');
      emit(AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final token = await _dataSource.login(email: email, password: password);
      await _tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
      _logger.i('✅ Login success — token_type: ${token.tokenType}');

      UserModel? user = token.user;

      if (user == null) {
        try {
          user = await _dataSource.getMyProfile();
          _logger.i('✅ User profile fetched separately: ${user.fullName}');
        } catch (e) {
          _logger.w('Could not fetch user profile: $e');
        }
      } else {
        _logger.i('✅ User from token: ${user.fullName}, account_type: ${user.accountType}');
      }

      if (user != null) {
        await _tokenStorage.saveUser(user);
      }

      emit(AuthLoginSuccess(
        token: token,
        user: user,
      ));
    } on ServerException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('not verified') || msg.contains('account not verified')) {
        emit(AuthNeedsVerification(email: email));
      } else {
        emit(AuthError(message: e.message));
      }
    } catch (e) {
      emit(const AuthError(message: 'An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> logout() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null) {
      await _tokenStorage.clearTokens();
      emit(const AuthLoggedOut());
      return;
    }
    try {
      await _dataSource.logout(refreshToken: refreshToken);
    } catch (_) {}
    await _tokenStorage.clearTokens();
    _logger.i('✅ Logged out');
    emit(const AuthLoggedOut());
  }

  Future<void> sendOtp({required String phone}) async {
    emit(const AuthLoading());
    try {
      _pendingPhone = phone;
      await _dataSource.sendOtp(phone: phone);
      _logger.i('✅ OTP sent to $phone');
      emit(AuthOtpSent(phone: phone));
    } on ServerException catch (e) {
      _logger.e('❌ Send OTP error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Send OTP unexpected error: $e');
      emit(AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otpCode,
  }) async {
    emit(const AuthLoading());
    try {
      await _dataSource.verifyOtp(phone: phone, otpCode: otpCode);
      _logger.i('✅ OTP verified for $phone');
      emit(const AuthOtpVerified());
    } on ServerException catch (e) {
      _logger.e('❌ Verify OTP error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Verify OTP unexpected error: $e');
      emit(AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> forgotPassword({required String email}) async {
    emit(const AuthLoading());
    try {
      await _dataSource.forgotPassword(email: email);
      _logger.i('✅ Forgot password email sent to $email');
      emit(AuthForgotPasswordSent(email: email));
    } on ServerException catch (e) {
      _logger.e('❌ Forgot password error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Forgot password unexpected error: $e');
      emit(AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    emit(const AuthLoading());
    try {
      await _dataSource.resetPassword(
        email: email,
        otpCode: otpCode,
        newPassword: newPassword,
      );
      _logger.i('✅ Password reset successful for $email');
      emit(const AuthResetPasswordSuccess());
    } on ServerException catch (e) {
      _logger.e('❌ Reset password error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Reset password unexpected error: $e');
      emit(AuthError(message: 'An unexpected error occurred'));
    }
  }

  void resetState() => emit(const AuthInitial());

  Future<bool> validateSession() async {
    if (!_tokenStorage.hasTokens) return false;
    try {
      final user = await _dataSource.getMyProfile();
      _logger.i('✅ Session valid — user: ${user.fullName}');
      return true;
    } catch (e) {
      _logger.w('❌ Session invalid: $e');
      await _tokenStorage.clearTokens();
      return false;
    }
  }

  void clearError() {
    if (state is AuthError) emit(const AuthInitial());
  }

  // ─── Role Selection & Onboarding ───

  Future<void> selectInitialRole({required String role}) async {
    emit(const AuthLoading());
    try {
      final result = await _dataSource.selectInitialRole(role: role);
      final selectedRole = result['selected_role']?.toString() ?? role;
      final completed = result['completed'] as bool? ?? false;
      final userJson = result['user'];
      UserModel? user;
      if (userJson is Map<String, dynamic>) {
        user = UserModel.fromJson(userJson);
        await _tokenStorage.saveUser(user);
      }
      _logger.i('✅ Role selected: $selectedRole (completed: $completed)');
      emit(RoleSelectionSuccess(
        selectedRole: selectedRole,
        completed: completed,
        user: user,
      ));
    } on ServerException catch (e) {
      _logger.e('❌ Role selection error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Role selection unexpected error: $e');
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> onboardSeller({
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
    emit(const AuthLoading());
    try {
      final result = await _dataSource.onboardSeller(
        businessName: businessName,
        businessCategoryIds: businessCategoryIds,
        businessDescription: businessDescription,
        businessCountry: businessCountry,
        businessRegion: businessRegion,
        businessCity: businessCity,
        businessDistrict: businessDistrict,
        businessWard: businessWard,
        businessAddress: businessAddress,
        productDescription: productDescription,
        yearsInBusiness: yearsInBusiness,
        websiteUrl: websiteUrl,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
      );
      final sellerId = result['seller_id']?.toString();
      final sellerStatus = result['seller_status']?.toString();
      final userJson = result['user'];
      UserModel? user;
      if (userJson is Map<String, dynamic>) {
        user = UserModel.fromJson(userJson);
        await _tokenStorage.saveUser(user);
      }
      _logger.i('✅ Seller onboarded: $sellerId (status: $sellerStatus)');
      emit(SellerOnboardingSuccess(
        sellerId: sellerId,
        sellerStatus: sellerStatus,
        user: user,
      ));
    } on ServerException catch (e) {
      _logger.e('❌ Seller onboarding error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Seller onboarding unexpected error: $e');
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> onboardBroker({
    required String country,
    required String region,
    required String city,
    String? district,
    String? ward,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _dataSource.onboardBroker(
        country: country,
        region: region,
        city: city,
        district: district,
        ward: ward,
      );
      final brokerId = result['broker_id']?.toString();
      final brokerCode = result['broker_code']?.toString();
      final brokerStatus = result['broker_status']?.toString();
      final userJson = result['user'];
      UserModel? user;
      if (userJson is Map<String, dynamic>) {
        user = UserModel.fromJson(userJson);
        await _tokenStorage.saveUser(user);
      }
      _logger.i('✅ Broker onboarded: $brokerId (code: $brokerCode)');
      emit(BrokerOnboardingSuccess(
        brokerId: brokerId,
        brokerCode: brokerCode,
        brokerStatus: brokerStatus,
        user: user,
      ));
    } on ServerException catch (e) {
      _logger.e('❌ Broker onboarding error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Broker onboarding unexpected error: $e');
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> resendVerification({required String identifier}) async {
    emit(const AuthLoading());
    try {
      await _dataSource.resendVerification(identifier: identifier);
      _logger.i('✅ Verification resent to $identifier');
      emit(AccountVerificationSent(identifier: identifier));
    } on ServerException catch (e) {
      _logger.e('❌ Resend verification error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Resend verification unexpected error: $e');
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> verifyAccountOtp({
    required String identifier,
    required String otpCode,
  }) async {
    emit(const AuthLoading());
    try {
      await _dataSource.verifyAccountOtp(
        identifier: identifier,
        otpCode: otpCode,
      );
      _logger.i('✅ Account verified for $identifier');
      emit(const AccountVerified());
    } on ServerException catch (e) {
      _logger.e('❌ Verify account OTP error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Verify account OTP unexpected error: $e');
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }
}
