import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/currency/currency_cubit.dart';
import '../../../core/theme/uicons.dart';

class CurrencyPickerTile extends StatelessWidget {
  const CurrencyPickerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (context, state) {
        final currencies = state is CurrencyLoaded ? state.currencies : [];
        final selected =
            state is CurrencyLoaded ? state.selectedCurrency : 'TZS';
        final selectedCurrency = currencies.where((c) => c.code == selected).firstOrNull;

        return GestureDetector(
          onTap: currencies.isEmpty ? null : () => _showPicker(context, currencies, selected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Uicons.dollar, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Display Currency',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        selectedCurrency != null
                            ? '${selectedCurrency.symbol} ${selectedCurrency.name}'
                            : selected,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Uicons.angleRight, size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPicker(
    BuildContext context,
    List currencies,
    String selected,
  ) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...currencies.map((c) {
                final isSelected = c.code == selected;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary.withValues(alpha: 0.1)
                          : cs.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        c.symbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  title: Text(c.name),
                  subtitle: Text(c.code),
                  trailing: isSelected
                      ? Icon(Uicons.checkCircle, color: cs.primary, size: 22)
                      : null,
                  onTap: () {
                    context.read<CurrencyCubit>().selectCurrency(c.code);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
