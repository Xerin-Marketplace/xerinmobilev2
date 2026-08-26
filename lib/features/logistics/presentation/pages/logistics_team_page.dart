import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/logistics_models.dart';
import '../../presentation/cubit/logistics_cubit.dart';
import '../../presentation/cubit/logistics_state.dart';

class LogisticsTeamPage extends StatefulWidget {
  const LogisticsTeamPage({super.key});

  @override
  State<LogisticsTeamPage> createState() => _LogisticsTeamPageState();
}

class _LogisticsTeamPageState extends State<LogisticsTeamPage> {
  @override
  void initState() {
    super.initState();
    context.read<LogisticsCubit>().loadTeam();
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
        title: const Text('Team Members'),
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
            if (state is LogisticsTeamLoaded) {
              if (state.members.isEmpty) {
                return _buildEmpty(cs);
              }
              return RefreshIndicator(
                onRefresh: () => context.read<LogisticsCubit>().loadTeam(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _MemberCard(member: state.members[index]),
                ),
              );
            }
            return _buildEmpty(cs);
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.users,
                size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No Team Members',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Team members will appear here once added.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final LogisticsTeamMemberModel member;

  const _MemberCard({required this.member});

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'manager':
        return Colors.blue;
      case 'driver':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              child: Text(
                member.name.isNotEmpty
                    ? member.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(member.email,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              _roleColor(member.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          member.role.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _roleColor(member.role)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!member.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('INACTIVE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (member.phone != null)
              IconButton(
                icon: const Icon(Uicons.phone, size: 18),
                onPressed: () {},
              ),
          ],
        ),
      ),
    );
  }
}
