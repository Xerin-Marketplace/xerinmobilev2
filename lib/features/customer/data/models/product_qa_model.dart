class ProductQuestionModel {
  final String id;
  final String productId;
  final String customerId;
  final String question;
  final String status;
  final int answerCount;
  final int helpfulCount;
  final String? customerName;
  final String? createdAt;
  final List<ProductAnswerModel> answers;

  const ProductQuestionModel({
    required this.id,
    this.productId = '',
    this.customerId = '',
    required this.question,
    this.status = 'published',
    this.answerCount = 0,
    this.helpfulCount = 0,
    this.customerName,
    this.createdAt,
    this.answers = const [],
  });

  factory ProductQuestionModel.fromJson(Map<String, dynamic> json) {
    final answersList = json['answers'] as List<dynamic>? ?? [];
    return ProductQuestionModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      status: json['status'] as String? ?? 'published',
      answerCount: (json['answer_count'] as num?)?.toInt() ?? 0,
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
      customerName: json['customer_name'] as String?,
      createdAt: json['created_at'] as String?,
      answers: answersList.map((e) => ProductAnswerModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ProductAnswerModel {
  final String id;
  final String questionId;
  final String userId;
  final String answer;
  final bool isSellerAnswer;
  final bool isOfficial;
  final int helpfulCount;
  final String? userName;
  final String? createdAt;

  const ProductAnswerModel({
    required this.id,
    this.questionId = '',
    this.userId = '',
    required this.answer,
    this.isSellerAnswer = false,
    this.isOfficial = false,
    this.helpfulCount = 0,
    this.userName,
    this.createdAt,
  });

  factory ProductAnswerModel.fromJson(Map<String, dynamic> json) {
    return ProductAnswerModel(
      id: json['id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      answer: json['answer'] as String? ?? '',
      isSellerAnswer: json['is_seller_answer'] as bool? ?? false,
      isOfficial: json['is_official'] as bool? ?? false,
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
      userName: json['user_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class ProductQuestionListResponse {
  final int total;
  final int page;
  final int pageSize;
  final List<ProductQuestionModel> results;

  const ProductQuestionListResponse({
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.results = const [],
  });

  factory ProductQuestionListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return ProductQuestionListResponse(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      results: list.map((e) => ProductQuestionModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
