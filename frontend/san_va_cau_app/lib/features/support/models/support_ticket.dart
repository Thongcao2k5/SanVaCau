class SupportTicketMessage {
  const SupportTicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.isStaff,
    required this.createdAt,
    this.senderName,
    this.senderRole,
  });

  final String id;
  final String ticketId;
  final String senderId;
  final String? senderName;
  final String? senderRole;
  final String message;
  final bool isStaff;
  final DateTime createdAt;

  factory SupportTicketMessage.fromJson(Map<String, dynamic> json) {
    return SupportTicketMessage(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString(),
      senderRole: json['senderRole']?.toString(),
      message: json['message']?.toString() ?? '',
      isStaff: json['isStaff'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.targetType,
    this.targetId,
    this.messages = const [],
  });

  final String id;
  final String subject;
  final String message;
  final String category;
  final String status;
  final String priority;
  final String? targetType;
  final String? targetId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SupportTicketMessage> messages;

  bool get canReply => status != 'CLOSED';

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final messageJson = json['messages'] as List<dynamic>? ?? const [];
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      category: json['category']?.toString() ?? 'OTHER',
      status: json['status']?.toString() ?? 'OPEN',
      priority: json['priority']?.toString() ?? 'NORMAL',
      targetType: json['targetType']?.toString(),
      targetId: json['targetId']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      messages: messageJson
          .whereType<Map<String, dynamic>>()
          .map(SupportTicketMessage.fromJson)
          .toList(),
    );
  }
}
