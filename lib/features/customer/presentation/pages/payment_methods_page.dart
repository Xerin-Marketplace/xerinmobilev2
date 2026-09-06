import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/payment_method_model.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().refreshPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final methods = state is CustomerLoaded
              ? state.paymentMethods
              : <PaymentMethodModel>[];

          if (methods.isEmpty) {
            return Center(
              child: Text('No saved payment methods',
                  style: TextStyle(
                      fontSize: 15,
                      color: cs.onSurface.withValues(alpha: 0.5))),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final m = methods[index];
              return ListTile(
                leading: Icon(_typeIcon(m.type), color: _typeColor(m.type)),
                title: Text(m.typeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${m.provider}\n${m.maskedNumber}',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                isThreeLine: true,
                trailing: m.isDefault
                    ? Text('Default',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.primary))
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'mobile_money':
        return const Color(0xFF22C55E);
      case 'card':
        return const Color(0xFFF59E0B);
      case 'bank':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'mobile_money':
        return Icons.phone_android;
      case 'card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.credit_card;
    }
  }
}
