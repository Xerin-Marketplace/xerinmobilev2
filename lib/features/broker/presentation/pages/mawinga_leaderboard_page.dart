import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/uicons.dart';
import '../../data/models/mawinga_models.dart';

class MawingaLeaderboardPage extends StatefulWidget {
  const MawingaLeaderboardPage({super.key});

  @override
  State<MawingaLeaderboardPage> createState() => _MawingaLeaderboardPageState();
}

class _MawingaLeaderboardPageState extends State<MawingaLeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Top Mawinga'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'This Month'),
          ],
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboard(cs, 'today'),
            _buildLeaderboard(cs, 'week'),
            _buildLeaderboard(cs, 'month'),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard(ColorScheme cs, String period) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Uicons.trophy, size: 36, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text('Leaderboard Coming Soon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'The Mawinga leaderboard will showcase top sellers by period. Compete for bonuses, smartphones, and recognition.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            _buildLevelsPreview(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelsPreview(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mawinga Levels',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 12),
          ...MawingaLevel.levels.map((level) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  level.name == 'Platinum' ? Uicons.star :
                  level.name == 'Gold' ? Uicons.crown :
                  level.name == 'Silver' ? Uicons.trophy :
                  level.name == 'Bronze' ? Uicons.medal :
                  Uicons.seedling,
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(level.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const Spacer(),
                Text(
                  level.minSales == 0 ? '0-${level.maxSales} sales' : '${level.minSales}+ sales',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
