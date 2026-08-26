class MawingaLevel {
  final String name;
  final int minSales;
  final int maxSales;
  final String color;
  final String icon;
  final List<String> perks;

  const MawingaLevel({
    required this.name,
    required this.minSales,
    required this.maxSales,
    required this.color,
    required this.icon,
    required this.perks,
  });

  static const List<MawingaLevel> levels = [
    MawingaLevel(
      name: 'Starter',
      minSales: 0,
      maxSales: 10,
      color: '#6B7280',
      icon: 'seedling',
      perks: ['Basic commission', 'Access to product catalog'],
    ),
    MawingaLevel(
      name: 'Bronze',
      minSales: 11,
      maxSales: 50,
      color: '#B45309',
      icon: 'medal',
      perks: ['Higher commission', 'Early access to products'],
    ),
    MawingaLevel(
      name: 'Silver',
      minSales: 51,
      maxSales: 200,
      color: '#64748B',
      icon: 'trophy',
      perks: ['Higher commission', 'Special campaigns', 'Priority support'],
    ),
    MawingaLevel(
      name: 'Gold',
      minSales: 201,
      maxSales: 500,
      color: '#D97706',
      icon: 'crown',
      perks: ['Premium commission', 'Bonuses', 'Training access', 'Recognition'],
    ),
    MawingaLevel(
      name: 'Platinum',
      minSales: 501,
      maxSales: 999999,
      color: '#7C3AED',
      icon: 'star',
      perks: ['Top commission', 'Business opportunities', 'Exclusive campaigns', 'VIP support'],
    ),
  ];

  static MawingaLevel getLevelForSales(int sales) {
    for (final level in levels) {
      if (sales >= level.minSales && sales <= level.maxSales) {
        return level;
      }
    }
    return levels.first;
  }

  static MawingaLevel getNextLevel(MawingaLevel current) {
    final idx = levels.indexOf(current);
    if (idx < levels.length - 1) return levels[idx + 1];
    return current;
  }
}

class MawingaTrainingModule {
  final String id;
  final String title;
  final String description;
  final String duration;
  final bool isCompleted;
  final bool isLocked;

  const MawingaTrainingModule({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    this.isCompleted = false,
    this.isLocked = false,
  });

  static const List<MawingaTrainingModule> modules = [
    MawingaTrainingModule(
      id: 'start-selling',
      title: 'How to Start Selling',
      description: 'Learn the basics of becoming a successful Mawinga.',
      duration: '10 min',
    ),
    MawingaTrainingModule(
      id: 'find-customers',
      title: 'How to Find Customers',
      description: 'Strategies for reaching buyers through social media.',
      duration: '15 min',
    ),
    MawingaTrainingModule(
      id: 'whatsapp-selling',
      title: 'Selling Through WhatsApp',
      description: 'Turn WhatsApp into your sales channel.',
      duration: '12 min',
    ),
    MawingaTrainingModule(
      id: 'product-content',
      title: 'Creating Good Product Content',
      description: 'Photos, descriptions and pricing that convert.',
      duration: '18 min',
    ),
    MawingaTrainingModule(
      id: 'customer-service',
      title: 'Customer Service Basics',
      description: 'Handle questions, complaints and build trust.',
      duration: '14 min',
    ),
    MawingaTrainingModule(
      id: 'digital-marketing',
      title: 'Digital Marketing Basics',
      description: 'Boost your reach with simple marketing tactics.',
      duration: '20 min',
    ),
  ];
}

class MawingaProductCategory {
  final String name;
  final String icon;
  final String color;

  const MawingaProductCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<MawingaProductCategory> categories = [
    MawingaProductCategory(name: 'Electronics', icon: 'mobile', color: '#3B82F6'),
    MawingaProductCategory(name: 'Fashion', icon: 'shirt', color: '#EC4899'),
    MawingaProductCategory(name: 'Beauty', icon: 'heart', color: '#F43F5E'),
    MawingaProductCategory(name: 'Home', icon: 'house', color: '#10B981'),
    MawingaProductCategory(name: 'Automotive', icon: 'car', color: '#6B7280'),
    MawingaProductCategory(name: 'Food', icon: 'utensils', color: '#F59E0B'),
    MawingaProductCategory(name: 'Tanzania Products', icon: 'flag', color: '#22C55E'),
    MawingaProductCategory(name: 'Dubai Products', icon: 'globe', color: '#8B5CF6'),
    MawingaProductCategory(name: 'China Products', icon: 'globe', color: '#EF4444'),
    MawingaProductCategory(name: 'Turkey Products', icon: 'globe', color: '#F97316'),
    MawingaProductCategory(name: 'Global Products', icon: 'globe', color: '#06B6D4'),
  ];
}
