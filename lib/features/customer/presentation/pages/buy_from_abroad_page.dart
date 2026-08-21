import 'package:flutter/material.dart';

import '../widgets/coming_soon_page.dart';
import '../../../../core/theme/uicons.dart';

class BuyFromAbroadPage extends StatelessWidget {
  const BuyFromAbroadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: 'Buy from Abroad',
      subtitle: 'Verified international suppliers',
      icon: Uicons.globe,
      gradientColors: [Color(0xFF00A651), Color(0xFF00732F)],
      feature1: 'Verified suppliers from Dubai, China, Turkey & more',
      feature2: 'Total landed cost calculator — no hidden charges',
      feature3: 'Xerin handles cargo, customs & delivery',
      feature4: 'Track your international shipment step by step',
    );
  }
}
