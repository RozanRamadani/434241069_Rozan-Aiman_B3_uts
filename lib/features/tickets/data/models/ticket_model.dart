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
    };
  }
}
