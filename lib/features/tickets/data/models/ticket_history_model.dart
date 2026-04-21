import '../../domain/entities/ticket_history.dart';

class TicketHistoryModel extends TicketHistory {
  TicketHistoryModel({
    required super.id,
    required super.ticketId,
    super.userId,
    super.userName,
    super.oldStatus,
    super.newStatus,
    required super.changedAt,
  });

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) {
    return TicketHistoryModel(
      id: json['id'],
      ticketId: json['ticket_id'],
      userId: json['user_id'],
      userName: json['full_name'] ?? json['user_name'],
      oldStatus: json['old_status'],
      newStatus: json['new_status'],
      changedAt: DateTime.parse(json['changed_at']).toLocal(),
    );
  }
}
