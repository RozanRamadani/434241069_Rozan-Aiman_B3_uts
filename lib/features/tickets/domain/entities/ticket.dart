import 'package:equatable/equatable.dart';

class Ticket extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final DateTime createdAt;
  final String? attachmentUrl;
  final String? assignedTo;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.attachmentUrl,
    this.assignedTo,
  });

  @override
  List<Object?> get props => [id, title, description, category, status, createdAt, attachmentUrl, assignedTo];
}
