import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/promotion_remote_datasource.dart';
import '../../data/models/promotion_model.dart';

abstract class PromotionState {
  const PromotionState();
}

class PromotionInitial extends PromotionState {
  const PromotionInitial();
}

class PromotionLoading extends PromotionState {
  const PromotionLoading();
}

class PromotionsLoaded extends PromotionState {
  final List<PromotionModel> promotions;
  final List<CampaignModel> campaigns;

  const PromotionsLoaded({required this.promotions, this.campaigns = const []});
}

class PromotionApplied extends PromotionState {
  final PromotionApplyResult result;
  const PromotionApplied(this.result);
}

class PromotionError extends PromotionState {
  final String message;
  const PromotionError(this.message);
}

class PromotionCubit extends Cubit<PromotionState> {
  final PromotionRemoteDataSource _dataSource;
  final Logger _logger;

  PromotionCubit({
    required PromotionRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const PromotionInitial());

  Future<void> loadAvailablePromotions() async {
    emit(const PromotionLoading());
    try {
      final promotions = await _dataSource.getAvailablePromotions();
      emit(PromotionsLoaded(promotions: promotions));
    } catch (e) {
      _logger.e('❌ Failed to load promotions: $e');
      emit(PromotionError(e.toString()));
    }
  }

  Future<void> loadCampaigns() async {
    try {
      final campaigns = await _dataSource.getCampaigns();
      final current = state;
      if (current is PromotionsLoaded) {
        emit(PromotionsLoaded(promotions: current.promotions, campaigns: campaigns));
      } else {
        emit(PromotionsLoaded(promotions: const [], campaigns: campaigns));
      }
    } catch (e) {
      _logger.e('❌ Failed to load campaigns: $e');
    }
  }

  Future<void> applyPromotion({required String code, required double subtotal}) async {
    emit(const PromotionLoading());
    try {
      final result = await _dataSource.applyPromotion(code: code, subtotal: subtotal);
      _logger.i('✅ Promotion applied: ${result.code}');
      emit(PromotionApplied(result));
    } catch (e) {
      _logger.e('❌ Failed to apply promotion: $e');
      emit(PromotionError(e.toString()));
    }
  }
}
