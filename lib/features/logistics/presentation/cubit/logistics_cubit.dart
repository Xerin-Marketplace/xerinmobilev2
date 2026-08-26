import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/logistics_remote_datasource.dart';
import 'logistics_state.dart';

class LogisticsCubit extends Cubit<LogisticsState> {
  final LogisticsRemoteDataSource _dataSource;
  final Logger _logger;

  LogisticsCubit({
    required LogisticsRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const LogisticsInitial());

  Future<void> loadDashboard() async {
    emit(const LogisticsLoading());
    try {
      final dashboard = await _dataSource.getDashboard();
      final account = await _dataSource.getAccount();
      emit(LogisticsDashboardLoaded(dashboard, account));
    } catch (e) {
      _logger.e('LogisticsCubit.loadDashboard error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> loadShipments({String? status}) async {
    emit(const LogisticsLoading());
    try {
      final shipments = await _dataSource.getShipments(status: status);
      emit(LogisticsShipmentsLoaded(shipments, statusFilter: status));
    } catch (e) {
      _logger.e('LogisticsCubit.loadShipments error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> arrivedForPickup(String shipmentId) async {
    try {
      await _dataSource.arrivedForPickup(shipmentId);
      emit(const LogisticsActionSuccess('Arrived for pickup confirmed'));
    } catch (e) {
      _logger.e('LogisticsCubit.arrivedForPickup error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> loadWallet() async {
    emit(const LogisticsLoading());
    try {
      final wallet = await _dataSource.getWallet();
      final transactions = await _dataSource.getWalletTransactions();
      emit(LogisticsWalletLoaded(wallet, transactions));
    } catch (e) {
      _logger.e('LogisticsCubit.loadWallet error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> loadTeam() async {
    emit(const LogisticsLoading());
    try {
      final members = await _dataSource.getTeamMembers();
      emit(LogisticsTeamLoaded(members));
    } catch (e) {
      _logger.e('LogisticsCubit.loadTeam error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> updateTeamMember(
      String userId, Map<String, dynamic> data) async {
    try {
      await _dataSource.updateTeamMember(userId, data);
      emit(const LogisticsActionSuccess('Team member updated'));
      await loadTeam();
    } catch (e) {
      _logger.e('LogisticsCubit.updateTeamMember error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> loadPricing() async {
    emit(const LogisticsLoading());
    try {
      final rates = await _dataSource.getRates();
      final services = await _dataSource.getServices();
      emit(LogisticsPricingLoaded(rates, services));
    } catch (e) {
      _logger.e('LogisticsCubit.loadPricing error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> updateRate(String rateId, Map<String, dynamic> data) async {
    try {
      await _dataSource.updateRate(rateId, data);
      emit(const LogisticsActionSuccess('Rate updated'));
      await loadPricing();
    } catch (e) {
      _logger.e('LogisticsCubit.updateRate error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> updateService(
      String serviceId, Map<String, dynamic> data) async {
    try {
      await _dataSource.updateService(serviceId, data);
      emit(const LogisticsActionSuccess('Service updated'));
      await loadPricing();
    } catch (e) {
      _logger.e('LogisticsCubit.updateService error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> loadIntegration() async {
    emit(const LogisticsLoading());
    try {
      final integration = await _dataSource.getIntegration();
      final events = await _dataSource.getWebhookEvents();
      emit(LogisticsIntegrationLoaded(integration, events));
    } catch (e) {
      _logger.e('LogisticsCubit.loadIntegration error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> loadOnboarding() async {
    emit(const LogisticsLoading());
    try {
      final onboarding = await _dataSource.getOnboarding();
      emit(LogisticsOnboardingLoaded(onboarding));
    } catch (e) {
      _logger.e('LogisticsCubit.loadOnboarding error: $e');
      emit(LogisticsError(e.toString()));
    }
  }

  Future<void> submitOnboarding() async {
    try {
      await _dataSource.submitOnboarding();
      emit(const LogisticsActionSuccess('Onboarding submitted'));
      await loadOnboarding();
    } catch (e) {
      _logger.e('LogisticsCubit.submitOnboarding error: $e');
      emit(LogisticsError(e.toString()));
    }
  }
}
