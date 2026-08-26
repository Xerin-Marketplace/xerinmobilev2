import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/uicons.dart';

class SellerReturnsPage extends StatelessWidget {
  const SellerReturnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Returns'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Uicons.arrowLeft,
                      size: 36, color: cs.onSurface.withValues(alpha: 0.2)),
                ),
                const SizedBox(height: 20),
                Text('Returns',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const SizedBox(height: 8),
                Text(
                  'Review and process customer return requests, issue refunds and manage return logistics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Return management is not available yet. A seller returns workflow API is required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
