import 'package:equatable/equatable.dart';

import '../../data/models/support_model.dart';

abstract class SupportState extends Equatable {
  const SupportState();

  @override
  List<Object?> get props => [];
}

class SupportInitial extends SupportState {}

class SupportLoading extends SupportState {}

class SupportTicketsLoaded extends SupportState {
  final List<SupportTicketModel> tickets;

  const SupportTicketsLoaded(this.tickets);

  @override
  List<Object?> get props => [tickets];
}

class SupportTicketDetailLoaded extends SupportState {
  final SupportTicketModel ticket;

  const SupportTicketDetailLoaded(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class SupportTicketCreated extends SupportState {
  final SupportTicketModel ticket;

  const SupportTicketCreated(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class SupportMessageSent extends SupportState {
  final SupportTicketModel ticket;

  const SupportMessageSent(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class SupportError extends SupportState {
  final String message;

  const SupportError(this.message);

  @override
  List<Object?> get props => [message];
}
