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
  const FetchTickets({this.statusFilter});

  @override
  List<Object?> get props => [statusFilter];
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

  const AssignTicketEvent({required this.ticketId, required this.helpdeskId});

  @override
  List<Object?> get props => [ticketId, helpdeskId];
}

class FetchHelpdesksEvent extends TicketEvent {}
