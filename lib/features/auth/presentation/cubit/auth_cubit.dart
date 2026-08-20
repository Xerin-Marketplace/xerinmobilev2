import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../seller/data/datasources/seller_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRemoteDataSource _dataSource;
  final TokenStorage _tokenStorage;
  final Logger _logger;
  final SellerRemoteDataSource? _sellerDataSource;

  String? _pendingPhone;
  String? _pendingFirstName;
  String? _pendingLastName;
  String? _pendingEmail;
  String? _pendingPassword;

  AuthCubit({
    required AuthRemoteDataSource dataSource,
    required TokenStorage tokenStorage,
    required Logger logger,
    SellerRemoteDataSource? sellerDataSource,
  })  : _dataSource = dataSource,
        _tokenStorage = tokenStorage,
        _logger = logger,
        _sellerDataSource = sellerDataSource,
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

  Future<void> registerSeller({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String businessName,
    required List<String> businessCategoryIds,
    String? contactEmail,
    String? contactPhone,
  }) async {
    emit(const AuthLoading());
    try {
      final seller = await _dataSource.registerSeller(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        businessName: businessName,
        businessCategoryIds: businessCategoryIds,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
      );
      _logger.i(
          '✅ Seller register success: ${seller.businessName} (id: ${seller.id})');
      emit(AuthSellerRegisterSuccess(seller: seller));
    } on ServerException catch (e) {
      _logger.e('❌ Seller register error: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      _logger.e('❌ Seller register unexpected error: $e');
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

      final isSeller = user?.isSeller ?? false;
      final isAdmin = user?.isAdmin ?? false;

      await _tokenStorage.saveUserRole(
        accountType: user?.accountType ?? 'customer',
        isSeller: isSeller,
      );

      emit(AuthLoginSuccess(
        token: token,
        isSeller: isSeller,
        isAdmin: isAdmin,
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

  Future<void> continueAsGuest() async {
    await _tokenStorage.setGuestMode(true);
    _logger.i('✅ Continued as guest');
    emit(const AuthGuest());
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

  void clearError() {
    if (state is AuthError) emit(const AuthInitial());
  }
}
