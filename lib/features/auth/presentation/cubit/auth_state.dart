import 'package:equatable/equatable.dart';

import '../../data/models/seller_model.dart';
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

class AuthSellerRegisterSuccess extends AuthState {
  final SellerModel seller;

  const AuthSellerRegisterSuccess({required this.seller});

  @override
  List<Object?> get props => [seller];
}

class AuthLoginSuccess extends AuthState {
  final TokenModel token;
  final bool isSeller;

  const AuthLoginSuccess({required this.token, this.isSeller = false});

  @override
  List<Object?> get props => [token, isSeller];
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

class AuthGuest extends AuthState {
  const AuthGuest();
}
