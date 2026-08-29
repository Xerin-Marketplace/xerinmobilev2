import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/currency/currency_cubit.dart';

class PriceFormatter {
  static const double _usdToTzs = 2500;

  static String fromUsd(String usdPrice) {
    final value = double.tryParse(
          usdPrice.replaceAll('\$', '').replaceAll(',', '').trim(),
        ) ??
        0;
    final tzs = (value * _usdToTzs).round();
    return 'TSh ${_formatNumber(tzs)}';
  }

  static double toTzsNumber(String usdPrice) {
    final value = double.tryParse(
          usdPrice.replaceAll('\$', '').replaceAll(',', '').trim(),
        ) ??
        0;
    return value * _usdToTzs;
  }

  /// Format using the globally-provided [CurrencyCubit], respecting the
  /// user's selected display currency and conversion rates.
  static String format(
    BuildContext context,
    double amount, {
    String sourceCurrency = 'TZS',
    bool approximate = false,
  }) {
    final cubit = context.read<CurrencyCubit>();
    return cubit.format(
      amount,
      sourceCurrency: sourceCurrency,
      approximate: approximate,
    );
  }

  /// Format in TZS regardless of the selected display currency.
  static String formatTzs(BuildContext context, double amount) {
    final cubit = context.read<CurrencyCubit>();
    return cubit.formatTzs(amount);
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }
}
