import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/logistics_models.dart';
import '../../presentation/cubit/logistics_cubit.dart';
import '../../presentation/cubit/logistics_state.dart';

class LogisticsOnboardingPage extends StatefulWidget {
  const LogisticsOnboardingPage({super.key});

  @override
  State<LogisticsOnboardingPage> createState() =>
      _LogisticsOnboardingPageState();
}

class _LogisticsOnboardingPageState extends State<LogisticsOnboardingPage> {
  @override
  void initState() {
    super.initState();
    context.read<LogisticsCubit>().loadOnboarding();
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
        title: const Text('Onboarding'),
      ),
      body: SafeArea(
        child: BlocConsumer<LogisticsCubit, LogisticsState>(
          listener: (context, state) {
            if (state is LogisticsError) {
              NotificationService().error(state.message);
            }
            if (state is LogisticsActionSuccess) {
              NotificationService().success(state.message);
            }
          },
          builder: (context, state) {
            if (state is LogisticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LogisticsOnboardingLoaded) {
              return _buildContent(state.onboarding, cs);
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

  Widget _buildContent(LogisticsOnboardingModel onboarding, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Onboarding Status',
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                Text(
                  onboarding.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Completed Steps',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          if (onboarding.completedSteps.isEmpty)
            Text('No steps completed yet',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))
          else
            ...onboarding.completedSteps.map((step) => _stepTile(
                cs, step, true)),
          const SizedBox(height: 24),
          Text('Pending Steps',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          if (onboarding.pendingSteps.isEmpty)
            Text('All steps completed!',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))
          else
            ...onboarding.pendingSteps.map((step) => _stepTile(
                cs, step, false)),
          const SizedBox(height: 32),
          if (onboarding.canSubmit)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () =>
                    context.read<LogisticsCubit>().submitOnboarding(),
                child: const Text('Submit for Review'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepTile(ColorScheme cs, String step, bool completed) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          completed ? Uicons.checkCircle : Uicons.circleQuestion,
          color: completed ? Colors.green : cs.onSurface.withValues(alpha: 0.3),
          size: 24,
        ),
        title: Text(step.replaceAll('_', ' '),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                decoration: completed ? TextDecoration.none : null)),
      ),
    );
  }
}
