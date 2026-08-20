int _pi(dynamic v) { if (v == null) return 0; if (v is num) return v.toInt(); if (v is String) return int.tryParse(v) ?? 0; return 0; }

class StoreOpeningHourModel {
  final String id;
  final String storeId;
  final String dayOfWeek;
  final int dayPosition;
  final String? openingTime;
  final String? closingTime;
  final bool isClosed;
  final String? createdAt;
  final String? updatedAt;

  const StoreOpeningHourModel({
    required this.id,
    required this.storeId,
    required this.dayOfWeek,
    this.dayPosition = 0,
    this.openingTime,
    this.closingTime,
    this.isClosed = false,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreOpeningHourModel.fromJson(Map<String, dynamic> json) {
    return StoreOpeningHourModel(
      id: json['id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      dayOfWeek: json['day_of_week'] as String? ?? '',
      dayPosition: _pi(json['day_position']),
      openingTime: json['opening_time']?.toString(),
      closingTime: json['closing_time']?.toString(),
      isClosed: json['is_closed'] as bool? ?? false,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'is_closed': isClosed,
      };
}
