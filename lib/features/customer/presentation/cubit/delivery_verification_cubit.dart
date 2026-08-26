import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/delivery_verification_remote_datasource.dart';
import 'delivery_verification_state.dart';

class DeliveryVerificationCubit
    extends Cubit<DeliveryVerificationState> {
  final DeliveryVerificationRemoteDataSource _dataSource;
  final Logger _logger;

  DeliveryVerificationCubit({
    required DeliveryVerificationRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const DeliveryVerificationInitial());

  Future<void> loadProofs() async {
    emit(const DeliveryVerificationLoading());
    try {
      final proofs = await _dataSource.getMyDeliveryProofs();
      emit(DeliveryVerificationLoaded(proofs));
    } catch (e) {
      _logger.e('DeliveryVerificationCubit.loadProofs error: $e');
      emit(DeliveryVerificationError(e.toString()));
    }
  }

  Future<void> disputeProof(String proofId, String reason,
      {String? notes}) async {
    try {
      await _dataSource.disputeDeliveryProof(proofId, reason, notes: notes);
      emit(const DeliveryVerificationActionSuccess(
          'Delivery disputed successfully'));
      await loadProofs();
    } catch (e) {
      _logger.e('DeliveryVerificationCubit.disputeProof error: $e');
      emit(DeliveryVerificationError(e.toString()));
    }
  }
}
