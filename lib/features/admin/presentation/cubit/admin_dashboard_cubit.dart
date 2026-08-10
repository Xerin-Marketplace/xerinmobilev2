import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/admin_dashboard_datasource.dart';
import '../../data/models/admin_dashboard_model.dart';

abstract class AdminDashboardState {
  const AdminDashboardState();
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardSummaryLoaded extends AdminDashboardState {
  final AdminDashboardSummary summary;
  final AdminDashboardSales sales;
  final AdminDashboardSellers sellers;
  final AdminDashboardProducts products;
  final AdminDashboardCustomers customers;
  final AdminDashboardPayments payments;
  final AdminDashboardRefunds refunds;
  final AdminDashboardDelivery delivery;
  final AdminDashboardNotifications notifications;

  const AdminDashboardSummaryLoaded({
    required this.summary,
    required this.sales,
    required this.sellers,
    required this.products,
    required this.customers,
    required this.payments,
    required this.refunds,
    required this.delivery,
    required this.notifications,
  });
}

class AdminAlertsLoaded extends AdminDashboardState {
  final List<AdminSystemAlert> alerts;
  const AdminAlertsLoaded(this.alerts);
}

class AdminActivityLogsLoaded extends AdminDashboardState {
  final List<AdminActivityLog> logs;
  const AdminActivityLogsLoaded(this.logs);
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminDashboardDataSource _dataSource;
  final Logger _logger;

  AdminDashboardCubit({
    required AdminDashboardDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const AdminDashboardInitial());

  Future<void> loadDashboard({String period = '30d'}) async {
    emit(const AdminDashboardLoading());
    try {
      final summary = await _dataSource.getSummary(period: period);
      final sales = await _dataSource.getSales(period: period);
      final sellers = await _dataSource.getSellers();
      final products = await _dataSource.getProducts();
      final customers = await _dataSource.getCustomers();
      final payments = await _dataSource.getPayments();
      final refunds = await _dataSource.getRefunds();
      final delivery = await _dataSource.getDelivery();
      final notifications = await _dataSource.getNotifications();

      emit(AdminDashboardSummaryLoaded(
        summary: summary,
        sales: sales,
        sellers: sellers,
        products: products,
        customers: customers,
        payments: payments,
        refunds: refunds,
        delivery: delivery,
        notifications: notifications,
      ));
    } catch (e) {
      _logger.e('❌ Failed to load admin dashboard: $e');
      emit(AdminDashboardError(e.toString()));
    }
  }

  Future<void> loadAlerts({bool? resolved}) async {
    try {
      final alerts = await _dataSource.getAlerts(resolved: resolved);
      emit(AdminAlertsLoaded(alerts));
    } catch (e) {
      _logger.e('❌ Failed to load alerts: $e');
      emit(AdminDashboardError(e.toString()));
    }
  }

  Future<void> resolveAlert(String alertId) async {
    try {
      await _dataSource.resolveAlert(alertId);
      _logger.i('✅ Alert resolved');
      await loadAlerts();
    } catch (e) {
      _logger.e('❌ Failed to resolve alert: $e');
    }
  }

  Future<void> loadActivityLogs({int limit = 100}) async {
    try {
      final logs = await _dataSource.getActivityLogs(limit: limit);
      emit(AdminActivityLogsLoaded(logs));
    } catch (e) {
      _logger.e('❌ Failed to load activity logs: $e');
      emit(AdminDashboardError(e.toString()));
    }
  }
}
