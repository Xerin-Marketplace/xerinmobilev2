part of 'currency_cubit.dart';

class DisplayCurrencyModel {
  final String id;
  final String code;
  final String name;
  final String symbol;
  final int decimalPlaces;
  final bool isBase;
  final double rateToTzs;

  const DisplayCurrencyModel({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    required this.decimalPlaces,
    required this.isBase,
    required this.rateToTzs,
  });

  static const fallback = DisplayCurrencyModel(
    id: 'tzs',
    code: 'TZS',
    name: 'Tanzanian Shilling',
    symbol: 'TSh',
    decimalPlaces: 0,
    isBase: true,
    rateToTzs: 1.0,
  );

  factory DisplayCurrencyModel.fromJson(Map<String, dynamic> json) {
    return DisplayCurrencyModel(
      id: json['id']?.toString() ?? '',
      code: (json['code'] as String? ?? 'TZS').toUpperCase(),
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? 'TSh',
      decimalPlaces: (json['decimal_places'] as num?)?.toInt() ?? 0,
      isBase: json['is_base'] as bool? ?? false,
      rateToTzs: double.tryParse(json['rate_to_tzs']?.toString() ?? '1') ?? 1.0,
    );
  }
}

abstract class CurrencyState extends Equatable {
  const CurrencyState();
}

class CurrencyInitial extends CurrencyState {
  const CurrencyInitial();
  @override
  List<Object?> get props => [];
}

class CurrencyLoading extends CurrencyState {
  const CurrencyLoading();
  @override
  List<Object?> get props => [];
}

class CurrencyLoaded extends CurrencyState {
  final List<DisplayCurrencyModel> currencies;
  final String selectedCurrency;

  const CurrencyLoaded({
    required this.currencies,
    required this.selectedCurrency,
  });

  Map<String, double> get rateMap {
    final map = <String, double>{};
    for (final c in currencies) {
      if (c.rateToTzs > 0) map[c.code] = c.rateToTzs;
    }
    map['TZS'] = 1.0;
    return map;
  }

  DisplayCurrencyModel? currenciesWhereCode(String code) {
    final match = currencies.where((c) => c.code == code.toUpperCase());
    return match.isNotEmpty ? match.first : null;
  }

  @override
  List<Object?> get props => [currencies, selectedCurrency];
}
