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
