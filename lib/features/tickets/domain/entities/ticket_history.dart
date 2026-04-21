class TicketHistory {
  final String id;
  final String ticketId;
  final String? userId; // User atau Admin yang merubah
  final String? userName; // Alias Join Name jika ada dari auth.users
  final String? oldStatus;
  final String? newStatus;
  final DateTime changedAt;

  TicketHistory({
    required this.id,
    required this.ticketId,
    this.userId,
    this.userName,
    this.oldStatus,
    this.newStatus,
    required this.changedAt,
  });
}
