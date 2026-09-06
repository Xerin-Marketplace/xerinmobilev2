import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    {'name': 'Kanga & Vitenge', 'icon': Icons.checkroom_outlined, 'color': Color(0xFFE91E63)},
    {'name': 'Coffee & Tea', 'icon': Icons.coffee_outlined, 'color': Color(0xFF795548)},
    {'name': 'Spices', 'icon': Icons.restaurant_outlined, 'color': Color(0xFFFF5722)},
    {'name': 'Handicrafts', 'icon': Icons.brush_outlined, 'color': Color(0xFF9C27B0)},
    {'name': 'Art & Culture', 'icon': Icons.palette_outlined, 'color': Color(0xFF673AB7)},
    {'name': 'Natural Cosmetics', 'icon': Icons.eco_outlined, 'color': Color(0xFF4CAF50)},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
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
                      const Icon(Icons.local_shipping, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text('Tanzanian Heritage',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Authentic Tanzanian products delivered to\ndiaspora & buyers worldwide.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white,
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
    return Text(label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildInfoBanner(ColorScheme cs) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF1EB53A), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export Ready',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1EB53A),
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
    );
  }

  Widget _buildCategoryGrid(ColorScheme cs) {
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(cat['icon'] as IconData, color: color, size: 20),
            const Spacer(),
            Text(cat['name'] as String,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text('Export quality',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDestinationSelector(ColorScheme cs) {
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
          );
        },
      ),
    );
  }

  Widget _buildExportInfo(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFF1EB53A)),
            const SizedBox(width: 8),
            Text('Export Fulfilment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
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
              const Icon(Icons.check, size: 14, color: Color(0xFF1EB53A)),
              const SizedBox(width: 8),
              Text(item, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildHowItWorks(ColorScheme cs) {
    final steps = [
      {'icon': Icons.store_outlined, 'title': 'Browse Products', 'desc': 'Explore authentic Tanzanian goods'},
      {'icon': Icons.public, 'title': 'Select Destination', 'desc': 'Choose where to ship worldwide'},
      {'icon': Icons.local_shipping_outlined, 'title': 'We Handle Export', 'desc': 'Documentation, customs & shipping'},
      {'icon': Icons.inventory_2_outlined, 'title': 'Doorstep Delivery', 'desc': 'Tracking from Tanzania to you'},
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
                Icon(step['icon'] as IconData, color: const Color(0xFF1EB53A), size: 20),
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
