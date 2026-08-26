import 'package:equatable/equatable.dart';
import '../../data/models/logistics_models.dart';

abstract class LogisticsState extends Equatable {
  const LogisticsState();
  @override
  List<Object?> get props => [];
}

class LogisticsInitial extends LogisticsState {
  const LogisticsInitial();
}

class LogisticsLoading extends LogisticsState {
  const LogisticsLoading();
}

class LogisticsDashboardLoaded extends LogisticsState {
  final LogisticsDashboardModel dashboard;
  final LogisticsAccountModel account;
  const LogisticsDashboardLoaded(this.dashboard, this.account);
  @override
  List<Object?> get props => [dashboard, account];
}

class LogisticsShipmentsLoaded extends LogisticsState {
  final List<LogisticsShipmentModel> shipments;
  final String? statusFilter;
  const LogisticsShipmentsLoaded(this.shipments, {this.statusFilter});
  @override
  List<Object?> get props => [shipments, statusFilter];
}

class LogisticsWalletLoaded extends LogisticsState {
  final LogisticsWalletModel wallet;
  final List<Map<String, dynamic>> transactions;
  const LogisticsWalletLoaded(this.wallet, this.transactions);
  @override
  List<Object?> get props => [wallet, transactions];
}

class LogisticsTeamLoaded extends LogisticsState {
  final List<LogisticsTeamMemberModel> members;
  const LogisticsTeamLoaded(this.members);
  @override
  List<Object?> get props => [members];
}

class LogisticsPricingLoaded extends LogisticsState {
  final List<LogisticsRateModel> rates;
  final List<LogisticsServiceModel> services;
  const LogisticsPricingLoaded(this.rates, this.services);
  @override
  List<Object?> get props => [rates, services];
}

class LogisticsIntegrationLoaded extends LogisticsState {
  final LogisticsIntegrationModel integration;
  final List<Map<String, dynamic>> webhookEvents;
  const LogisticsIntegrationLoaded(this.integration, this.webhookEvents);
  @override
  List<Object?> get props => [integration, webhookEvents];
}

class LogisticsOnboardingLoaded extends LogisticsState {
  final LogisticsOnboardingModel onboarding;
  const LogisticsOnboardingLoaded(this.onboarding);
  @override
  List<Object?> get props => [onboarding];
}

class LogisticsActionSuccess extends LogisticsState {
  final String message;
  const LogisticsActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class LogisticsError extends LogisticsState {
  final String message;
  const LogisticsError(this.message);
  @override
  List<Object?> get props => [message];
}
