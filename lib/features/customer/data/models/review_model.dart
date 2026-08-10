class ReviewModel {
  final String id;
  final String productId;
  final String? storeId;
  final String customerId;
  final String? sellerId;
  final int rating;
  final String? title;
  final String? comment;
  final bool verifiedPurchase;
  final String status;
  final String? sellerReply;
  final String? sellerRepliedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? customerName;

  const ReviewModel({
    required this.id,
    this.productId = '',
    this.storeId,
    required this.customerId,
    this.sellerId,
    required this.rating,
    this.title,
    this.comment,
    this.verifiedPurchase = false,
    this.status = 'pending',
    this.sellerReply,
    this.sellerRepliedAt,
    this.createdAt,
    this.updatedAt,
    this.customerName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      storeId: json['store_id']?.toString(),
      customerId: json['customer_id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      verifiedPurchase: json['verified_purchase'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
      sellerReply: json['seller_reply'] as String?,
      sellerRepliedAt: json['seller_replied_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      customerName: json['customer_name'] as String?,
    );
  }
}

class ReviewListResponse {
  final int total;
  final int page;
  final int pageSize;
  final double averageRating;
  final List<ReviewModel> results;

  const ReviewListResponse({
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.averageRating = 0.0,
    this.results = const [],
  });

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return ReviewListResponse(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      results: list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
