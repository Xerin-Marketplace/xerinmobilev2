import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/xerin_express_option_model.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';

class XerinExpressOptionsWidget extends StatefulWidget {
  final String addressId;
  final XerinExpressOption? selectedOption;
  final ValueChanged<XerinExpressOption?>? onOptionSelected;

  const XerinExpressOptionsWidget({
    super.key,
    required this.addressId,
    this.selectedOption,
    this.onOptionSelected,
  });

  @override
  State<XerinExpressOptionsWidget> createState() =>
      _XerinExpressOptionsWidgetState();
}

class _XerinExpressOptionsWidgetState extends State<XerinExpressOptionsWidget> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerCubit>().loadXerinExpressOptions(widget.addressId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      buildWhen: (prev, curr) =>
          curr is XerinExpressOptionsLoaded ||
          curr is CustomerActionInProgress ||
          curr is CustomerActionError,
      builder: (context, state) {
        if (state is CustomerActionInProgress) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is CustomerActionError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              state.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (state is XerinExpressOptionsLoaded) {
          if (state.options.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.bolt,
                        color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Xerin Express Delivery',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
              ...state.options.map((option) => _ExpressOptionTile(
                    option: option,
                    isSelected:
                        widget.selectedOption?.rateId == option.rateId,
                    onTap: () => widget.onOptionSelected?.(option),
                  )),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ExpressOptionTile extends StatelessWidget {
  final XerinExpressOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExpressOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: option.rateId,
      groupValue: isSelected ? option.rateId : null,
      onChanged: (_) => onTap(),
      title: Row(
        children: [
          if (option.isExpress)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'EXPRESS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'STANDARD',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.access_time,
                size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              _formatMinutes(option.promisedDeliveryMinutes),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.local_shipping_outlined,
                size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                option.logisticsCompanyName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${option.deliveryAmount} ${option.currency}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
