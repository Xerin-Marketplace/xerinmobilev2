import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/uicons.dart';

class SellerCancellationsPage extends StatelessWidget {
  const SellerCancellationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Cancellations'),
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
                  child: Icon(Uicons.circleXmark,
                      size: 36, color: cs.onSurface.withValues(alpha: 0.2)),
                ),
                const SizedBox(height: 20),
                Text('Cancellations',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const SizedBox(height: 8),
                Text(
                  'Review cancellation requests, approve seller-side cancellations and protect inventory.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cancellation management is not available yet. A seller cancellations API is required.',
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
