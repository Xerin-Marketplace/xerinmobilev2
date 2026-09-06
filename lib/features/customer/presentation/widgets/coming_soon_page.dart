import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String feature1;
  final String feature2;
  final String feature3;
  final String feature4;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.feature1,
    required this.feature2,
    required this.feature3,
    required this.feature4,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, cs),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHero(cs),
                    const SizedBox(height: 32),
                    _buildFeatures(cs),
                    const SizedBox(height: 32),
                    _buildNotifyButton(cs),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              Text(subtitle,
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/retro-style-organic-turing-lines-pattern-background-design.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 220,
            ),
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientColors[0].withValues(alpha: 0.9),
                    gradientColors[1].withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SizedBox(
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 32),
                  const SizedBox(height: 16),
                  Text(title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('AVAILABLE NOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures(ColorScheme cs) {
    final features = [feature1, feature2, feature3, feature4];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Feature Highlights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 16),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.check, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(f,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildNotifyButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.arrow_forward, size: 20),
        label: const Text('Explore Now',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
