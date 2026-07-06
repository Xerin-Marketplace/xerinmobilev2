import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  final List<Map<String, dynamic>> _reports = const [
    {'month': 'June 2026', 'sales': 'TSh 12.4M', 'orders': 342, 'growth': '+12.5%'},
    {'month': 'May 2026', 'sales': 'TSh 10.8M', 'orders': 298, 'growth': '+8.2%'},
    {'month': 'April 2026', 'sales': 'TSh 9.1M', 'orders': 245, 'growth': '+5.7%'},
    {'month': 'March 2026', 'sales': 'TSh 8.5M', 'orders': 210, 'growth': '+3.1%'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BackIconButton(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppConstants.sellerDashboardRoute);
                            }
                          },
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Reports',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Sales',
                            'TSh 40.8M',
                            Icons.show_chart_rounded,
                            colorScheme,
                            const Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Orders',
                            '1,095',
                            Icons.shopping_cart_checkout_rounded,
                            colorScheme,
                            const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.onSurface.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales Overview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBar(0.45, colorScheme),
                                const SizedBox(width: 12),
                                _buildBar(0.62, colorScheme),
                                const SizedBox(width: 12),
                                _buildBar(0.78, colorScheme),
                                const SizedBox(width: 12),
                                _buildBar(0.92, colorScheme),
                                const SizedBox(width: 12),
                                _buildBar(0.55, colorScheme),
                                const SizedBox(width: 12),
                                _buildBar(0.70, colorScheme),
                                const SizedBox(width: 12),
                                _buildBar(0.85, colorScheme),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Jan',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.4))),
                              Text('Feb',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.4))),
                              Text('Mar',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.4))),
                              Text('Apr',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.4))),
                              Text('May',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.4))),
                              Text('Jun',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.4))),
                              Text('Jul',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.4))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Monthly Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._reports.asMap().entries.map((entry) {
                      final index = entry.key;
                      final report = entry.value;

                      return AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final delay = index * 0.1;
                          final value = Curves.easeOutCubic.transform(
                            (_animController.value - delay).clamp(0.0, 1.0),
                          );
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    report['month'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      report['growth'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF22C55E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sales',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          report['sales'] as String,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Orders',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${report['orders']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, ColorScheme colorScheme, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, ColorScheme colorScheme) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        height: 100 * height,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
