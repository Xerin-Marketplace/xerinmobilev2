import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/uicons.dart';

class ShopTanzaniaPage extends StatefulWidget {
  const ShopTanzaniaPage({super.key});

  @override
  State<ShopTanzaniaPage> createState() => _ShopTanzaniaPageState();
}

class _ShopTanzaniaPageState extends State<ShopTanzaniaPage> {
  String? _selectedDestination;

  static const _destinations = [
    {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': 'AE', 'name': 'Dubai', 'flag': '🇦🇪'},
    {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
  ];

  static const _categories = [
    {'name': 'Kanga & Vitenge', 'icon': Uicons.shirt, 'color': Color(0xFFE91E63)},
    {'name': 'Coffee & Tea', 'icon': Uicons.coffee, 'color': Color(0xFF795548)},
    {'name': 'Spices', 'icon': Uicons.utensils, 'color': Color(0xFFFF5722)},
    {'name': 'Handicrafts', 'icon': Uicons.brush, 'color': Color(0xFF9C27B0)},
    {'name': 'Art & Culture', 'icon': Uicons.palette, 'color': Color(0xFF673AB7)},
    {'name': 'Natural Cosmetics', 'icon': Uicons.leaf, 'color': Color(0xFF4CAF50)},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(cs),
                    const SizedBox(height: 24),
                    _buildInfoBanner(cs),
                    const SizedBox(height: 24),
                    Text('Product Categories',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text('Authentic Tanzanian goods for export',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryGrid(cs),
                    const SizedBox(height: 24),
                    Text('Ship To',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text('Select your destination country',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                    const SizedBox(height: 16),
                    _buildDestinationSelector(cs),
                    const SizedBox(height: 24),
                    _buildExportInfo(cs),
                    const SizedBox(height: 24),
                    _buildHowItWorks(cs),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Uicons.arrowBack, color: cs.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shop Tanzania',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              Text('Tanzanian heritage to the world',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(ColorScheme cs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1EB53A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/retro-style-organic-turing-lines-pattern-background-design.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1EB53A).withValues(alpha: 0.88),
                    const Color(0xFF15803D).withValues(alpha: 0.55),
                    const Color(0xFF15803D).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Uicons.shippingFast, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text('Tanzanian Heritage',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Authentic Tanzanian products delivered to\ndiaspora & buyers worldwide.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.95),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildHeroTag('Export Ready'),
                      const SizedBox(width: 8),
                      _buildHeroTag('Worldwide Shipping'),
                      const SizedBox(width: 8),
                      _buildHeroTag('Authentic Goods'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.95)),
      ),
    );
  }

  Widget _buildInfoBanner(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1EB53A).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1EB53A).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1EB53A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Uicons.checkCircle, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export Ready',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1EB53A),
                  ),
                ),
                const SizedBox(height: 2),
                Text('Authentic Tanzanian products available for worldwide shipping!',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final color = cat['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat['icon'] as IconData, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(cat['name'] as String,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text('Export quality',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDestinationSelector(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _destinations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final dest = _destinations[index];
          final isSelected = _selectedDestination == dest['code'];

          return GestureDetector(
            onTap: () => setState(() => _selectedDestination = dest['code'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.08)
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.08),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(dest['flag'] as String, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(dest['name'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportInfo(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1EB53A).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1EB53A).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Uicons.shippingFast, size: 20, color: Color(0xFF1EB53A)),
              const SizedBox(width: 8),
              Text('Export Fulfilment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Xerin handles the entire export process for you:',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          ...['Quality inspection before export', 'Export documentation & permits', 'International shipping (air/sea freight)', 'Customs clearance at destination', 'Doorstep delivery to buyer'].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Uicons.check, size: 14, color: Color(0xFF1EB53A)),
                const SizedBox(width: 8),
                Text(item, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(ColorScheme cs) {
    final steps = [
      {'icon': Uicons.storeAlt, 'title': 'Browse Products', 'desc': 'Explore authentic Tanzanian goods'},
      {'icon': Uicons.globe, 'title': 'Select Destination', 'desc': 'Choose where to ship worldwide'},
      {'icon': Uicons.shippingFast, 'title': 'We Handle Export', 'desc': 'Documentation, customs & shipping'},
      {'icon': Uicons.box, 'title': 'Doorstep Delivery', 'desc': 'Tracking from Tanzania to you'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How It Works',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1EB53A), Color(0xFF15803D)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(step['icon'] as IconData, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step ${i + 1}: ${step['title']}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(step['desc'] as String,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
