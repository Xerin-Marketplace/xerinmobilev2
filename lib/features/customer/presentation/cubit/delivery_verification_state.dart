import 'package:equatable/equatable.dart';
import '../../data/models/delivery_proof_model.dart';

abstract class DeliveryVerificationState extends Equatable {
  const DeliveryVerificationState();
  @override
  List<Object?> get props => [];
}

class DeliveryVerificationInitial extends DeliveryVerificationState {
  const DeliveryVerificationInitial();
}

class DeliveryVerificationLoading extends DeliveryVerificationState {
  const DeliveryVerificationLoading();
}

class DeliveryVerificationLoaded extends DeliveryVerificationState {
  final List<DeliveryProofModel> proofs;
  const DeliveryVerificationLoaded(this.proofs);
  @override
  List<Object?> get props => [proofs];
}

class DeliveryVerificationActionSuccess extends DeliveryVerificationState {
  final String message;
  const DeliveryVerificationActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class DeliveryVerificationError extends DeliveryVerificationState {
  final String message;
  const DeliveryVerificationError(this.message);
  @override
  List<Object?> get props => [message];
}
