import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();

  @override
  List<Object?> get props => [];
}

class FetchTickets extends TicketEvent {
  final String? statusFilter;
  final String? helpdeskFilter;
  final DateTime? cursor;
  final bool isLoadMore;
  
  const FetchTickets({this.statusFilter, this.helpdeskFilter, this.cursor, this.isLoadMore = false});

  @override
  List<Object?> get props => [statusFilter, helpdeskFilter, cursor, isLoadMore];
}

class CreateTicketEvent extends TicketEvent {
  final Ticket ticket;
  final File? imageFile;
  final dynamic imageBytes; // type: Uint8List?
  final String? imageExt;
  const CreateTicketEvent(this.ticket, {this.imageFile, this.imageBytes, this.imageExt});

  @override
  List<Object?> get props => [ticket, imageFile, imageBytes, imageExt];
}

class UpdateStatusEvent extends TicketEvent {
  final String ticketId;
  final String status;

  const UpdateStatusEvent({required this.ticketId, required this.status});

  @override
  List<Object?> get props => [ticketId, status];
}
class AssignTicketEvent extends TicketEvent {
  final String ticketId;
  final String helpdeskId;
  final String helpdeskName;

  const AssignTicketEvent({
    required this.ticketId, 
    required this.helpdeskId, 
    required this.helpdeskName,
  });

  @override
  List<Object?> get props => [ticketId, helpdeskId, helpdeskName];
}

class AcceptTicketEvent extends TicketEvent {
  final String ticketId;
  const AcceptTicketEvent(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class ResolveTicketEvent extends TicketEvent {
  final String ticketId;
  const ResolveTicketEvent(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class CancelTicketEvent extends TicketEvent {
  final String ticketId;
  const CancelTicketEvent(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class DeleteTicketEvent extends TicketEvent {
  final String ticketId;
  const DeleteTicketEvent(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class FetchHelpdesksEvent extends TicketEvent {}

