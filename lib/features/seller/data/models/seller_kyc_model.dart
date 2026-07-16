class SellerKycDocumentModel {
  final String id;
  final String sellerId;
  final String documentType;
  final String documentUrl;
  final String status;
  final String? rejectionReason;
  final String? uploadedAt;

  const SellerKycDocumentModel({
    required this.id,
    required this.sellerId,
    required this.documentType,
    required this.documentUrl,
    this.status = 'pending',
    this.rejectionReason,
    this.uploadedAt,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  factory SellerKycDocumentModel.fromJson(Map<String, dynamic> json) {
    return SellerKycDocumentModel(
      id: json['id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      documentType: json['document_type'] as String? ?? '',
      documentUrl: json['document_url'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      uploadedAt: json['uploaded_at'] as String?,
    );
  }
}

class SellerKycStatusModel {
  final String sellerStatus;
  final List<String> requiredDocuments;
  final List<String> uploadedDocuments;
  final List<String> missingDocuments;
  final bool canSubmitForReview;

  const SellerKycStatusModel({
    required this.sellerStatus,
    required this.requiredDocuments,
    required this.uploadedDocuments,
    required this.missingDocuments,
    required this.canSubmitForReview,
  });

  factory SellerKycStatusModel.fromJson(Map<String, dynamic> json) {
    return SellerKycStatusModel(
      sellerStatus: json['seller_status'] as String? ?? 'pending',
      requiredDocuments:
          (json['required_documents'] as List<dynamic>?)?.cast<String>() ?? [],
      uploadedDocuments:
          (json['uploaded_documents'] as List<dynamic>?)?.cast<String>() ?? [],
      missingDocuments:
          (json['missing_documents'] as List<dynamic>?)?.cast<String>() ?? [],
      canSubmitForReview: json['can_submit_for_review'] as bool? ?? false,
    );
  }
}
