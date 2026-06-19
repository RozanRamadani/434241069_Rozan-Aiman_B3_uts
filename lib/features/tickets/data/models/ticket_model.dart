import '../../domain/entities/ticket.dart';

class TicketModel extends Ticket {
  const TicketModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.status,
    required super.createdAt,
    super.attachmentUrl,
    super.assignedTo,
    super.assignedAt,
    super.processedAt,
    super.acceptedAt,
    super.resolvedAt,
    super.cancelledAt,
    super.assignedToName,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      attachmentUrl: json['attachment_url'],
      assignedTo: json['assigned_to'] as String?,
      assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at']).toLocal() : null,
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']).toLocal() : null,
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']).toLocal() : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']).toLocal() : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']).toLocal() : null,
      assignedToName: json['assigned_profile']?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'attachment_url': attachmentUrl,
      'assigned_to': assignedTo,
      'assigned_at': assignedAt?.toUtc().toIso8601String(),
      'processed_at': processedAt?.toUtc().toIso8601String(),
      'accepted_at': acceptedAt?.toUtc().toIso8601String(),
      'resolved_at': resolvedAt?.toUtc().toIso8601String(),
      'cancelled_at': cancelledAt?.toUtc().toIso8601String(),
    };
  }
}
