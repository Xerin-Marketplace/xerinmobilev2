class SellerProfileModel {
  final String id;
  final String userId;
  final String businessName;
  final String? businessDescription;
  final String? businessLocation;
  final String? businessCountry;
  final String? businessRegion;
  final String? businessCity;
  final String? businessAddress;
  final String? productDescription;
  final String? yearsInBusiness;
  final String? websiteUrl;
  final String? contactEmail;
  final String? contactPhone;
  final String status;
  final bool agreementAccepted;
  final String? createdAt;

  const SellerProfileModel({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessDescription,
    this.businessLocation,
    this.businessCountry,
    this.businessRegion,
    this.businessCity,
    this.businessAddress,
    this.productDescription,
    this.yearsInBusiness,
    this.websiteUrl,
    this.contactEmail,
    this.contactPhone,
    this.status = 'pending',
    this.agreementAccepted = false,
    this.createdAt,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending' || status == 'under_review';
  bool get isRejected => status == 'rejected';

  factory SellerProfileModel.fromJson(Map<String, dynamic> json) {
    return SellerProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      businessName: json['business_name'] as String? ?? '',
      businessDescription: json['business_description'] as String?,
      businessLocation: json['business_location'] as String?,
      businessCountry: json['business_country'] as String?,
      businessRegion: json['business_region'] as String?,
      businessCity: json['business_city'] as String?,
      businessAddress: json['business_address'] as String?,
      productDescription: json['product_description'] as String?,
      yearsInBusiness: json['years_in_business'] as String?,
      websiteUrl: json['website_url'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      status: json['status'] as String? ?? 'pending',
      agreementAccepted: json['agreement_accepted'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'business_name': businessName,
        'business_description': businessDescription,
        'business_location': businessLocation,
        'business_country': businessCountry,
        'business_region': businessRegion,
        'business_city': businessCity,
        'business_address': businessAddress,
        'product_description': productDescription,
        'years_in_business': yearsInBusiness,
        'website_url': websiteUrl,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
      };
}
