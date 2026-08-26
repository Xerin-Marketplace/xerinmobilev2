import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/uicons.dart';

class CustomerReviewsPage extends StatelessWidget {
  const CustomerReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Reviews'),
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
                  child: Icon(Uicons.star,
                      size: 36, color: cs.onSurface.withValues(alpha: 0.2)),
                ),
                const SizedBox(height: 20),
                Text('Reviews unavailable',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const SizedBox(height: 8),
                Text(
                  'The backend does not currently expose buyer review history or review mutations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
