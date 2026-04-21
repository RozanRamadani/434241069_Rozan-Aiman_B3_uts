import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/comment_model.dart';
import '../entities/ticket.dart';
import '../entities/ticket_history.dart';

abstract class TicketRepository {
  Future<Either<Failure, List<Ticket>>> getTickets({String? statusFilter});
  Future<Either<Failure, Ticket>> createTicket(Ticket ticket, {File? imageFile, dynamic imageBytes, String? imageExt});
  Future<Either<Failure, void>> updateStatus(String ticketId, String status);
  Future<Either<Failure, List<Comment>>> getComments(String ticketId);
  Future<Either<Failure, void>> sendComment(String ticketId, String message);
  Future<Either<Failure, void>> assignTicket(String ticketId, String helpdeskId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getHelpdesks();
  Future<Either<Failure, List<TicketHistory>>> getTicketHistory(String ticketId);
}


