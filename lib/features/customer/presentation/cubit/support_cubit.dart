import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/support_remote_datasource.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final SupportRemoteDataSource _dataSource;
  final Logger _logger;

  SupportCubit({
    required SupportRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(SupportInitial());

  Future<void> loadMyTickets() async {
    emit(SupportLoading());
    try {
      final tickets = await _dataSource.getMyTickets();
      emit(SupportTicketsLoaded(tickets));
    } catch (e) {
      _logger.e('Failed to load support tickets: $e');
      emit(SupportError(e.toString()));
    }
  }

  Future<void> loadTicketDetail(String ticketId) async {
    emit(SupportLoading());
    try {
      final ticket = await _dataSource.getTicket(ticketId);
      emit(SupportTicketDetailLoaded(ticket));
    } catch (e) {
      _logger.e('Failed to load ticket detail: $e');
      emit(SupportError(e.toString()));
    }
  }

  Future<void> createTicket({
    required String subject,
    String? description,
    String? category,
    String priority = 'medium',
    String? orderId,
    String? sellerId,
    String? shipmentId,
  }) async {
    emit(SupportLoading());
    try {
      final ticket = await _dataSource.createTicket(
        subject: subject,
        description: description,
        category: category,
        priority: priority,
        orderId: orderId,
        sellerId: sellerId,
        shipmentId: shipmentId,
      );
      emit(SupportTicketCreated(ticket));
    } catch (e) {
      _logger.e('Failed to create ticket: $e');
      emit(SupportError(e.toString()));
    }
  }

  Future<void> replyTicket({
    required String ticketId,
    required String message,
  }) async {
    try {
      await _dataSource.replyTicket(
        ticketId: ticketId,
        message: message,
      );
      final ticket = await _dataSource.getTicket(ticketId);
      emit(SupportMessageSent(ticket));
    } catch (e) {
      _logger.e('Failed to reply to ticket: $e');
      emit(SupportError(e.toString()));
    }
  }

  // Admin methods
  Future<void> adminLoadTickets({
    String? search,
    String? status,
  }) async {
    emit(SupportLoading());
    try {
      final tickets = await _dataSource.adminGetAllTickets(
        search: search,
        status: status,
      );
      emit(SupportTicketsLoaded(tickets));
    } catch (e) {
      _logger.e('Failed to load admin tickets: $e');
      emit(SupportError(e.toString()));
    }
  }

  Future<void> adminUpdateTicket({
    required String ticketId,
    String? status,
    String? priority,
    String? resolutionNote,
  }) async {
    try {
      final ticket = await _dataSource.adminUpdateTicket(
        ticketId: ticketId,
        status: status,
        priority: priority,
        resolutionNote: resolutionNote,
      );
      emit(SupportTicketDetailLoaded(ticket));
    } catch (e) {
      _logger.e('Failed to update ticket: $e');
      emit(SupportError(e.toString()));
    }
  }

  Future<void> adminReplyTicket({
    required String ticketId,
    required String message,
  }) async {
    try {
      await _dataSource.adminReplyTicket(
        ticketId: ticketId,
        message: message,
      );
      final ticket = await _dataSource.adminGetTicket(ticketId);
      emit(SupportMessageSent(ticket));
    } catch (e) {
      _logger.e('Failed to reply as admin: $e');
      emit(SupportError(e.toString()));
    }
  }
}
