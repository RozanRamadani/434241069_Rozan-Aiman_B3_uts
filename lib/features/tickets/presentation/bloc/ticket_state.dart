import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket.dart';

abstract class TicketState extends Equatable {
  const TicketState();
  
  @override
  List<Object?> get props => [];
}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketsLoaded extends TicketState {
  final List<Ticket> tickets;
  final bool hasMore;
  const TicketsLoaded(this.tickets, {this.hasMore = true});

  @override
  List<Object?> get props => [tickets, hasMore];
}

class TicketError extends TicketState {
  final String message;
  const TicketError(this.message);

  @override
  List<Object?> get props => [message];
}

class TicketCreated extends TicketState {
  final Ticket ticket;
  const TicketCreated(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class StatusUpdated extends TicketState {} 

class TicketAssigned extends TicketState {}

class TicketAccepted extends TicketState {}

class TicketResolved extends TicketState {}

class TicketCancelled extends TicketState {}

class TicketDeleted extends TicketState {}

class HelpdesksLoaded extends TicketState {
  final List<Map<String, dynamic>> helpdesks;
  const HelpdesksLoaded(this.helpdesks);

  @override
  List<Object?> get props => [helpdesks];
}

