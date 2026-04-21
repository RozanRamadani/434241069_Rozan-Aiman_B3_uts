import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ticket_repository.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketRepository ticketRepository;

  TicketBloc({required this.ticketRepository}) : super(TicketInitial()) {
    on<FetchTickets>((event, emit) async {
      emit(TicketLoading());
      // ✅ Menggunakan statusFilter sebagai pengganti isActive (FR-011)
      final result = await ticketRepository.getTickets(statusFilter: event.statusFilter);
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (tickets) => emit(TicketsLoaded(tickets)),
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
      final result = await ticketRepository.assignTicket(event.ticketId, event.helpdeskId);
      result.fold(
        (failure) => emit(TicketError(failure.message)),
        (_) => emit(TicketAssigned()),
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
