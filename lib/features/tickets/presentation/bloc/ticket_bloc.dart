import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ticket_repository.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketRepository ticketRepository;

  TicketBloc({required this.ticketRepository}) : super(TicketInitial()) {
    on<FetchTickets>((event, emit) async {
      if (!event.isLoadMore) {
        emit(TicketLoading());
      }
      
      final result = await ticketRepository.getTickets(
        statusFilter: event.statusFilter, 
        helpdeskFilter: event.helpdeskFilter,
        cursor: event.cursor,
        limit: 20,
      );
      
      result.fold(
        (failure) {
          if (!event.isLoadMore) {
            emit(TicketError(failure.message));
          } else if (state is TicketsLoaded) {
            final currentState = state as TicketsLoaded;
            emit(TicketsLoaded(currentState.tickets, hasMore: currentState.hasMore));
          }
        },
        (newTickets) {
          if (event.isLoadMore && state is TicketsLoaded) {
            final currentTickets = (state as TicketsLoaded).tickets;
            emit(TicketsLoaded([...currentTickets, ...newTickets], hasMore: newTickets.length == 20));
          } else {
            emit(TicketsLoaded(newTickets, hasMore: newTickets.length == 20));
          }
        },
      );
    });

    on<CreateTicketEvent>((event, emit) async {
      emit(TicketLoading());
      final result = await ticketRepository.createTicket(
        event.ticket,
        imageFile: event.imageFile,
        imageBytes: event.imageBytes,
        imageExt: event.imageExt,
      );
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (ticket) => emit(TicketCreated(ticket)),
      );
    });

    on<UpdateStatusEvent>((event, emit) async {
      final result = await ticketRepository.updateStatus(event.ticketId, event.status);
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (_) => emit(StatusUpdated()),
      );
    });

    on<AssignTicketEvent>((event, emit) async {
      emit(TicketLoading());
      final result = await ticketRepository.assignTicket(event.ticketId, event.helpdeskId, event.helpdeskName);
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (_) => emit(TicketAssigned()),
      );
    });

    on<AcceptTicketEvent>((event, emit) async {
      emit(TicketLoading());
      final result = await ticketRepository.acceptTicket(event.ticketId);
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (_) => emit(TicketAccepted()),
      );
    });

    on<ResolveTicketEvent>((event, emit) async {
      emit(TicketLoading());
      final result = await ticketRepository.resolveTicket(event.ticketId);
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (_) => emit(TicketResolved()),
      );
    });

    on<CancelTicketEvent>((event, emit) async {
      emit(TicketLoading());
      final result = await ticketRepository.cancelTicket(event.ticketId);
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (_) => emit(TicketCancelled()),
      );
    });

    on<DeleteTicketEvent>((event, emit) async {
      emit(TicketLoading());
      final result = await ticketRepository.deleteTicket(event.ticketId);
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (_) => emit(TicketDeleted()),
      );
    });

    on<FetchHelpdesksEvent>((event, emit) async {
      emit(TicketLoading());
      final result = await ticketRepository.getHelpdesks();
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (helpdesks) => emit(HelpdesksLoaded(helpdesks)),
      );
    });
  }
}

