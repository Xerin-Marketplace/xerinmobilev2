class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String userId;
  final String? customerName;
  final String? customerEmail;
  final String subject;
  final String? description;
  final String? category;
  final String? channel;
  final String priority;
  final String status;
  final String? assignedToName;
  final String? sellerName;
  final String? logisticsProvider;
  final List<SupportTicketMessageModel> messages;
  final String? resolutionNote;
  final String? firstResponseDueAt;
  final String? resolutionDueAt;
  final String? resolvedAt;
  final String? closedAt;
  final String createdAt;
  final String? updatedAt;

  const SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    this.customerName,
    this.customerEmail,
    required this.subject,
    this.description,
    this.category,
    this.channel,
    required this.priority,
    required this.status,
    this.assignedToName,
    this.sellerName,
    this.logisticsProvider,
    this.messages = const [],
    this.resolutionNote,
    this.firstResponseDueAt,
    this.resolutionDueAt,
    this.resolvedAt,
    this.closedAt,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOpen =>
      status != 'closed' && status != 'resolved' && status != 'cancelled';

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) =>
      SupportTicketModel(
        id: json['id']?.toString() ?? '',
        ticketNumber: json['ticket_number']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        customerName: json['customer_name']?.toString(),
        customerEmail: json['customer_email']?.toString(),
        subject: json['subject']?.toString() ?? '',
        description: json['description']?.toString(),
        category: json['category']?.toString(),
        channel: json['channel']?.toString(),
        priority: json['priority']?.toString() ?? 'medium',
        status: json['status']?.toString() ?? 'open',
        assignedToName: json['assigned_to_name']?.toString(),
        sellerName: json['seller_name']?.toString(),
        logisticsProvider: json['logistics_provider']?.toString(),
        messages: (json['messages'] as List<dynamic>?)
                ?.map((e) =>
                    SupportTicketMessageModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        resolutionNote: json['resolution_note']?.toString(),
        firstResponseDueAt: json['first_response_due_at']?.toString(),
        resolutionDueAt: json['resolution_due_at']?.toString(),
        resolvedAt: json['resolved_at']?.toString(),
        closedAt: json['closed_at']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_number': ticketNumber,
        'user_id': userId,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'subject': subject,
        'description': description,
        'category': category,
        'channel': channel,
        'priority': priority,
        'status': status,
        'assigned_to_name': assignedToName,
        'seller_name': sellerName,
        'logistics_provider': logisticsProvider,
        'messages': messages.map((e) => e.toJson()).toList(),
        'resolution_note': resolutionNote,
        'first_response_due_at': firstResponseDueAt,
        'resolution_due_at': resolutionDueAt,
        'resolved_at': resolvedAt,
        'closed_at': closedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class SupportTicketMessageModel {
  final String id;
  final String? senderId;
  final String? senderName;
  final String? senderRole;
  final String message;
  final String visibility;
  final String createdAt;

  const SupportTicketMessageModel({
    required this.id,
    this.senderId,
    this.senderName,
    this.senderRole,
    required this.message,
    required this.visibility,
    required this.createdAt,
  });

  bool get isStaff =>
      senderRole != null &&
      (senderRole!.contains('admin') || senderRole!.contains('staff'));

  factory SupportTicketMessageModel.fromJson(Map<String, dynamic> json) =>
      SupportTicketMessageModel(
        id: json['id']?.toString() ?? '',
        senderId: json['sender_id']?.toString(),
        senderName: json['sender_name']?.toString(),
        senderRole: json['sender_role']?.toString(),
        message: json['message']?.toString() ?? '',
        visibility: json['visibility']?.toString() ?? 'all',
        createdAt: json['created_at']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'message': message,
        'visibility': visibility,
        'created_at': createdAt,
      };
}
