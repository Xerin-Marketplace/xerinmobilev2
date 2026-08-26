import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/broker_remote_datasource.dart';
import '../../data/models/broker_models.dart';

// ─── States ───
abstract class BrokerState {
  const BrokerState();
}

class BrokerInitial extends BrokerState {
  const BrokerInitial();
}

class BrokerLoading extends BrokerState {
  const BrokerLoading();
}

class BrokerDashboardLoaded extends BrokerState {
  final BrokerModel broker;
  final BrokerAnalyticsOverviewModel? analytics;
  final BrokerCommissionSummaryModel? commissionSummary;
  final BrokerWalletModel? wallet;
  final bool refreshing;

  const BrokerDashboardLoaded({
    required this.broker,
    this.analytics,
    this.commissionSummary,
    this.wallet,
    this.refreshing = false,
  });

  BrokerDashboardLoaded copyWith({
    BrokerModel? broker,
    BrokerAnalyticsOverviewModel? analytics,
    BrokerCommissionSummaryModel? commissionSummary,
    BrokerWalletModel? wallet,
    bool? refreshing,
  }) {
    return BrokerDashboardLoaded(
      broker: broker ?? this.broker,
      analytics: analytics ?? this.analytics,
      commissionSummary: commissionSummary ?? this.commissionSummary,
      wallet: wallet ?? this.wallet,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

class BrokerKycLoaded extends BrokerState {
  final BrokerModel broker;
  final BrokerKycStatusModel kycStatus;
  final List<BrokerKycDocumentModel> documents;

  const BrokerKycLoaded({
    required this.broker,
    required this.kycStatus,
    required this.documents,
  });
}

class BrokerOpportunitiesLoaded extends BrokerState {
  final List<BrokerOpportunityModel> opportunities;
  final List<BrokerOpportunityModel> accepted;

  const BrokerOpportunitiesLoaded({
    required this.opportunities,
    required this.accepted,
  });
}

class BrokerWalletLoaded extends BrokerState {
  final BrokerWalletModel wallet;
  final BrokerCommissionSummaryModel? commissionSummary;
  final List<BrokerPayoutAccountModel> payoutAccounts;

  const BrokerWalletLoaded({
    required this.wallet,
    this.commissionSummary,
    required this.payoutAccounts,
  });
}

class BrokerProductsLoaded extends BrokerState {
  final List<BrokerProductModel> products;

  const BrokerProductsLoaded({required this.products});
}

class BrokerAnalyticsLoaded extends BrokerState {
  final BrokerAnalyticsOverviewModel overview;

  const BrokerAnalyticsLoaded({required this.overview});
}

class BrokerActionSuccess extends BrokerState {
  final String message;

  const BrokerActionSuccess({required this.message});
}

class BrokerError extends BrokerState {
  final String message;

  const BrokerError({required this.message});
}

// ─── Cubit ───
class BrokerCubit extends Cubit<BrokerState> {
  final BrokerRemoteDataSource _dataSource;
  final Logger _logger;

  BrokerCubit({
    required BrokerRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const BrokerInitial());

  Future<void> loadDashboard({bool refresh = false}) async {
    if (!refresh) emit(const BrokerLoading());
    try {
      final broker = await _dataSource.getBrokerMe();
      BrokerAnalyticsOverviewModel? analytics;
      BrokerCommissionSummaryModel? commissionSummary;
      BrokerWalletModel? wallet;

      if (broker.isApproved) {
        try {
          analytics = await _dataSource.getAnalyticsOverview();
        } catch (_) {}
        try {
          commissionSummary = await _dataSource.getCommissionSummary();
        } catch (_) {}
        try {
          wallet = await _dataSource.getWallet();
        } catch (_) {}
      }

      emit(BrokerDashboardLoaded(
        broker: broker,
        analytics: analytics,
        commissionSummary: commissionSummary,
        wallet: wallet,
        refreshing: refresh,
      ));
    } on ServerException catch (e) {
      _logger.e('Broker dashboard error: ${e.message}');
      emit(BrokerError(message: e.message));
    } catch (e) {
      _logger.e('Broker dashboard unexpected error: $e');
      emit(const BrokerError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> loadKyc() async {
    emit(const BrokerLoading());
    try {
      final results = await Future.wait([
        _dataSource.getBrokerMe(),
        _dataSource.getKycStatus(),
        _dataSource.getKycDocuments(),
      ]);
      emit(BrokerKycLoaded(
        broker: results[0] as BrokerModel,
        kycStatus: results[1] as BrokerKycStatusModel,
        documents: results[2] as List<BrokerKycDocumentModel>,
      ));
    } on ServerException catch (e) {
      _logger.e('Broker KYC error: ${e.message}');
      emit(BrokerError(message: e.message));
    } catch (e) {
      _logger.e('Broker KYC unexpected error: $e');
      emit(const BrokerError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> updateNidaNumber(String nidaNumber) async {
    emit(const BrokerLoading());
    try {
      await _dataSource.updateBrokerMe({'nida_number': nidaNumber});
      _logger.i('NIDA number updated');
      await loadKyc();
    } on ServerException catch (e) {
      _logger.e('Update NIDA error: ${e.message}');
      emit(BrokerError(message: e.message));
    }
  }

  Future<void> submitKyc() async {
    emit(const BrokerLoading());
    try {
      await _dataSource.submitKyc();
      _logger.i('KYC submitted for review');
      await loadKyc();
      emit(const BrokerActionSuccess(
          message: 'KYC submitted for admin review'));
    } on ServerException catch (e) {
      _logger.e('Submit KYC error: ${e.message}');
      emit(BrokerError(message: e.message));
    }
  }

  Future<void> loadOpportunities() async {
    emit(const BrokerLoading());
    try {
      final results = await Future.wait([
        _dataSource.getOpportunities(),
        _dataSource.getAcceptedOpportunities(),
      ]);
      emit(BrokerOpportunitiesLoaded(
        opportunities: results[0] as List<BrokerOpportunityModel>,
        accepted: results[1] as List<BrokerOpportunityModel>,
      ));
    } on ServerException catch (e) {
      _logger.e('Broker opportunities error: ${e.message}');
      emit(BrokerError(message: e.message));
    } catch (e) {
      _logger.e('Broker opportunities unexpected error: $e');
      emit(const BrokerError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> acceptOpportunity(String offerId) async {
    try {
      await _dataSource.acceptOpportunity(offerId);
      _logger.i('Opportunity accepted: $offerId');
      emit(const BrokerActionSuccess(message: 'Opportunity accepted'));
      await loadOpportunities();
    } on ServerException catch (e) {
      _logger.e('Accept opportunity error: ${e.message}');
      emit(BrokerError(message: e.message));
    }
  }

  Future<void> stopOpportunity(String offerId) async {
    try {
      await _dataSource.stopOpportunity(offerId);
      _logger.i('Opportunity stopped: $offerId');
      emit(const BrokerActionSuccess(message: 'Opportunity stopped'));
      await loadOpportunities();
    } on ServerException catch (e) {
      _logger.e('Stop opportunity error: ${e.message}');
      emit(BrokerError(message: e.message));
    }
  }

  Future<void> loadWallet() async {
    emit(const BrokerLoading());
    try {
      final results = await Future.wait([
        _dataSource.getWallet(),
        _dataSource.getPayoutAccounts(),
      ]);
      BrokerCommissionSummaryModel? commissionSummary;
      try {
        commissionSummary = await _dataSource.getCommissionSummary();
      } catch (_) {}

      emit(BrokerWalletLoaded(
        wallet: results[0] as BrokerWalletModel,
        commissionSummary: commissionSummary,
        payoutAccounts: results[1] as List<BrokerPayoutAccountModel>,
      ));
    } on ServerException catch (e) {
      _logger.e('Broker wallet error: ${e.message}');
      emit(BrokerError(message: e.message));
    }
  }

  Future<void> createPayoutAccount({
    required String accountType,
    required String provider,
    required String accountName,
    required String accountNumber,
    String currency = 'TZS',
  }) async {
    try {
      await _dataSource.createPayoutAccount({
        'account_type': accountType,
        'provider': provider,
        'account_name': accountName,
        'account_number': accountNumber,
        'currency': currency,
      });
      _logger.i('Payout account created');
      emit(const BrokerActionSuccess(message: 'Payout account created'));
      await loadWallet();
    } on ServerException catch (e) {
      _logger.e('Create payout account error: ${e.message}');
      emit(BrokerError(message: e.message));
    }
  }

  Future<void> requestPayout({
    required String payoutAccountId,
    required String amount,
    String? note,
  }) async {
    try {
      await _dataSource.requestPayout({
        'payout_account_id': payoutAccountId,
        'amount': amount,
        if (note != null) 'note': note,
      });
      _logger.i('Payout requested');
      emit(const BrokerActionSuccess(message: 'Payout requested successfully'));
      await loadWallet();
    } on ServerException catch (e) {
      _logger.e('Request payout error: ${e.message}');
      emit(BrokerError(message: e.message));
    }
  }

  Future<void> loadProducts() async {
    emit(const BrokerLoading());
    try {
      final products = await _dataSource.getProducts();
      emit(BrokerProductsLoaded(products: products));
    } on ServerException catch (e) {
      _logger.e('Broker products error: ${e.message}');
      emit(BrokerError(message: e.message));
    }
  }

  Future<void> loadAnalytics({int days = 30}) async {
    emit(const BrokerLoading());
    try {
      final overview = await _dataSource.getAnalyticsOverview(days: days);
      emit(BrokerAnalyticsLoaded(overview: overview));
    } on ServerException catch (e) {
      _logger.e('Broker analytics error: ${e.message}');
      emit(BrokerError(message: e.message));
    }
  }
}
