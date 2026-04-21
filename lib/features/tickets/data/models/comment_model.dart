import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String ticketId;
  final String userId;
  final String message;
  final DateTime createdAt;
  final String? userName;

  const Comment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    required this.createdAt,
    this.userName,
  });

  @override
  List<Object?> get props => [id, ticketId, userId, message, createdAt, userName];

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Supabase Join biasanya mengembalikan Map untuk profiles
    String? name;
    if (json['profiles'] != null) {
      final profiles = json['profiles'];
      if (profiles is Map) {
        name = profiles['full_name'];
      } else if (profiles is List && profiles.isNotEmpty) {
        name = profiles[0]['full_name'];
      }
    }

    return Comment(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      userName: name ?? 'User', // 'User' adalah fallback jika nama di DB tidak ada
    );
  }
}
