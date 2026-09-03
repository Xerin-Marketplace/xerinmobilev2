import 'package:equatable/equatable.dart';

import '../../data/models/token_model.dart';
import '../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthRegisterSuccess extends AuthState {
  final UserModel user;
  final String phone;

  const AuthRegisterSuccess({required this.user, required this.phone});

  @override
  List<Object?> get props => [user, phone];
}

class SellerRegisterSuccess extends AuthState {
  final String phone;
  final String message;

  const SellerRegisterSuccess({required this.phone, required this.message});

  @override
  List<Object?> get props => [phone, message];
}

class BrokerRegisterSuccess extends AuthState {
  final String phone;
  final String message;

  const BrokerRegisterSuccess({required this.phone, required this.message});

  @override
  List<Object?> get props => [phone, message];
}

class BusinessCategoriesLoaded extends AuthState {
  final List<Map<String, dynamic>> categories;

  const BusinessCategoriesLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class AuthLoginSuccess extends AuthState {
  final TokenModel token;
  final UserModel? user;

  const AuthLoginSuccess({
    required this.token,
    this.user,
  });

  @override
  List<Object?> get props => [token, user];
}

class AuthOtpSent extends AuthState {
  final String phone;

  const AuthOtpSent({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class AuthOtpVerified extends AuthState {
  const AuthOtpVerified();
}

class AuthForgotPasswordSent extends AuthState {
  final String email;

  const AuthForgotPasswordSent({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthResetPasswordSuccess extends AuthState {
  const AuthResetPasswordSuccess();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthNeedsVerification extends AuthState {
  final String email;

  const AuthNeedsVerification({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class RoleSelectionSuccess extends AuthState {
  final String selectedRole;
  final bool completed;
  final UserModel? user;

  const RoleSelectionSuccess({
    required this.selectedRole,
    required this.completed,
    this.user,
  });

  @override
  List<Object?> get props => [selectedRole, completed, user];
}

class SellerOnboardingSuccess extends AuthState {
  final String? sellerId;
  final String? sellerStatus;
  final UserModel? user;

  const SellerOnboardingSuccess({
    this.sellerId,
    this.sellerStatus,
    this.user,
  });

  @override
  List<Object?> get props => [sellerId, sellerStatus, user];
}

class BrokerOnboardingSuccess extends AuthState {
  final String? brokerId;
  final String? brokerCode;
  final String? brokerStatus;
  final UserModel? user;

  const BrokerOnboardingSuccess({
    this.brokerId,
    this.brokerCode,
    this.brokerStatus,
    this.user,
  });

  @override
  List<Object?> get props => [brokerId, brokerCode, brokerStatus, user];
}

class AccountVerificationSent extends AuthState {
  final String identifier;

  const AccountVerificationSent({required this.identifier});

  @override
  List<Object?> get props => [identifier];
}

class AccountVerified extends AuthState {
  const AccountVerified();
}
