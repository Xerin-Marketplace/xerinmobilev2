import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/logistics_models.dart';
import '../../presentation/cubit/logistics_cubit.dart';
import '../../presentation/cubit/logistics_state.dart';

class LogisticsPricingPage extends StatefulWidget {
  const LogisticsPricingPage({super.key});

  @override
  State<LogisticsPricingPage> createState() => _LogisticsPricingPageState();
}

class _LogisticsPricingPageState extends State<LogisticsPricingPage> {
  @override
  void initState() {
    super.initState();
    context.read<LogisticsCubit>().loadPricing();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pricing & Rates'),
      ),
      body: SafeArea(
        child: BlocConsumer<LogisticsCubit, LogisticsState>(
          listener: (context, state) {
            if (state is LogisticsError) {
              NotificationService().error(state.message);
            }
          },
          builder: (context, state) {
            if (state is LogisticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LogisticsPricingLoaded) {
              return _buildContent(state.rates, state.services, cs);
            }
            return Center(
              child: Text('Loading...',
                  style:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
      List<LogisticsRateModel> rates, List<LogisticsServiceModel> services, ColorScheme cs) {
    return RefreshIndicator(
      onRefresh: () => context.read<LogisticsCubit>().loadPricing(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Services',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            if (services.isEmpty)
              Text('No services configured',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.4)))
            else
              ...services.map((s) => _ServiceCard(s, cs)),
            const SizedBox(height: 24),
            Text('Rates',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            if (rates.isEmpty)
              Text('No rates configured',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.4)))
            else
              ...rates.map((r) => _RateCard(r, cs)),
          ],
        ),
      ),
    );
  }

  Widget _ServiceCard(LogisticsServiceModel service, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(service.name,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
        subtitle: service.description != null
            ? Text(service.description!,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)))
            : null,
        trailing: Switch(
          value: service.isActive,
          onChanged: (val) => context
              .read<LogisticsCubit>()
              .updateService(service.id, {'is_active': val}),
        ),
      ),
    );
  }

  Widget _RateCard(LogisticsRateModel rate, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rate.serviceName ?? 'Unknown Service',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface),
                  ),
                ),
                Switch(
                  value: rate.isActive,
                  onChanged: (val) => context
                      .read<LogisticsCubit>()
                      .updateRate(rate.id, {'is_active': val}),
                ),
              ],
            ),
            if (rate.zoneName != null) ...[
              const SizedBox(height: 4),
              Text('Zone: ${rate.zoneName}',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _rateTag(cs, 'Base', '${rate.baseRate} ${rate.currency}'),
                if (rate.perKmRate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _rateTag(
                        cs, 'Per km', '${rate.perKmRate} ${rate.currency}'),
                  ),
                if (rate.perKgRate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _rateTag(
                        cs, 'Per kg', '${rate.perKgRate} ${rate.currency}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateTag(ColorScheme cs, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: $value',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
    );
  }
}
