import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

part 'currency_state.dart';

class CurrencyCubit extends Cubit<CurrencyState> {
  final ApiClient _client;
  static const _storageKey = 'xerin_display_currency';

  CurrencyCubit({required ApiClient client})
      : _client = client,
        super(const CurrencyInitial());

  Future<void> loadCurrencies() async {
    emit(const CurrencyLoading());
    try {
      final response = await _client.get(ApiConstants.displayCurrencies);
      final List data = response.data is List
          ? response.data
          : (response.data is Map
              ? (response.data['results'] as List? ?? [])
              : []);

      final currencies = data
          .map((e) => DisplayCurrencyModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (currencies.isEmpty) {
        currencies.add(DisplayCurrencyModel.fallback);
      }

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      String selected = 'TZS';

      if (stored != null) {
        final match = currencies.where((c) => c.code == stored.toUpperCase());
        if (match.isNotEmpty) {
          selected = stored.toUpperCase();
        }
      }

      emit(CurrencyLoaded(
        currencies: currencies,
        selectedCurrency: selected,
      ));
    } catch (e) {
      emit(CurrencyLoaded(
        currencies: [DisplayCurrencyModel.fallback],
        selectedCurrency: 'TZS',
      ));
    }
  }

  Future<void> selectCurrency(String code) async {
    final current = state;
    if (current is CurrencyLoaded) {
      final normalized = code.toUpperCase();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, normalized);
      emit(CurrencyLoaded(
        currencies: current.currencies,
        selectedCurrency: normalized,
      ));
    }
  }

  double convert(double amount, String fromCurrency, String toCurrency) {
    final current = state;
    if (current is! CurrencyLoaded) return amount;

    final source = fromCurrency.toUpperCase();
    final target = toCurrency.toUpperCase();
    if (source == target) return amount;

    final sourceRate = current.rateMap[source];
    final targetRate = current.rateMap[target];
    if (sourceRate == null || targetRate == null) return amount;

    return (amount * sourceRate) / targetRate;
  }

  double toTzs(double amount, String fromCurrency) {
    final current = state;
    if (current is! CurrencyLoaded) return amount;

    final source = fromCurrency.toUpperCase();
    final rate = current.rateMap[source];
    if (rate == null) return amount;

    return amount * rate;
  }

  String format(
    double amount, {
    String? sourceCurrency,
    String? targetCurrency,
    bool approximate = false,
  }) {
    final current = state;
    if (current is! CurrencyLoaded) {
      return _formatTzs(amount);
    }

    final source = (sourceCurrency ?? 'TZS').toUpperCase();
    final target = (targetCurrency ?? current.selectedCurrency).toUpperCase();
    final converted = convert(amount, source, target);
    final currency = current.currenciesWhereCode(target);
    final symbol = currency?.symbol ?? target;
    final decimals = currency?.decimalPlaces ?? 0;

    final prefix = approximate && source != target ? '≈ ' : '';
    return '$prefix$symbol ${_formatNumber(converted, decimals)}';
  }

  String formatTzs(double amount) {
    return _formatTzs(amount);
  }

  String _formatTzs(double amount) {
    return 'TSh ${_formatNumber(amount, 0)}';
  }

  String _formatNumber(double value, int decimals) {
    if (decimals > 0) {
      return value.toStringAsFixed(decimals).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(\.\d+)?$)'),
            (m) => '${m[1]},',
          );
    }
    return value.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
