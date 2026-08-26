import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/mawinga_models.dart';

class MawingaAcademyPage extends StatefulWidget {
  const MawingaAcademyPage({super.key});

  @override
  State<MawingaAcademyPage> createState() => _MawingaAcademyPageState();
}

class _MawingaAcademyPageState extends State<MawingaAcademyPage> {
  final Set<String> _completedModules = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completedCount = _completedModules.length;
    final totalModules = MawingaTrainingModule.modules.length;
    final progress = completedCount / totalModules;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Xerin Academy'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'XERIN ACADEMY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn to sell. Grow your income.',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedCount/$totalModules modules completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Learning Modules',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 12),
            ...MawingaTrainingModule.modules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              final isCompleted = _completedModules.contains(module.id);
              final isLocked = index > 0 && !_completedModules.contains(MawingaTrainingModule.modules[index - 1].id);

              return _buildModuleCard(module, isCompleted, isLocked, cs);
            }),
            if (completedCount == totalModules) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Uicons.checkCircle, size: 28, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Xerin Certified Mawinga!',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cs.onSurface)),
                          const SizedBox(height: 2),
                          Text('You have completed all training modules.',
                              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(MawingaTrainingModule module, bool isCompleted, bool isLocked, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.2)
              : cs.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.1)
                : isLocked
                    ? cs.onSurface.withValues(alpha: 0.03)
                    : cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? Uicons.checkCircle : isLocked ? Uicons.lock : Uicons.book,
            size: 20,
            color: isCompleted
                ? Colors.green
                : isLocked
                    ? cs.onSurface.withValues(alpha: 0.2)
                    : cs.primary,
          ),
        ),
        title: Text(
          module.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isLocked ? cs.onSurface.withValues(alpha: 0.4) : cs.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            module.description,
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              module.duration,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            if (!isLocked && !isCompleted)
              TextButton(
                onPressed: () => _markCompleted(module.id),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 24),
                ),
                child: const Text('Start', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        onTap: isLocked
            ? null
            : () {
                if (!isCompleted) {
                  _markCompleted(module.id);
                }
              },
      ),
    );
  }

  void _markCompleted(String moduleId) {
    setState(() => _completedModules.add(moduleId));
    NotificationService().success('Module completed!');
  }
}
