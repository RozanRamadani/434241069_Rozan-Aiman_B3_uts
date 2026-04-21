import 'dart:io';
import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/entities/ticket_history.dart';
import '../datasources/ticket_remote_data_source.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource dataSource;
  TicketRepositoryImpl(this.dataSource);

  final Duration _timeout = const Duration(seconds: 10);

  @override
  Future<Either<Failure, List<Ticket>>> getTickets({String? statusFilter}) async {
    try {
      final result = await dataSource.getTickets(statusFilter: statusFilter).timeout(_timeout);
      return Right(result);
    } on TimeoutException {
      return Left(ServerFailure('Waktu tunggu habis. Periksa koneksi Anda.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ticket>> createTicket(Ticket ticket, {File? imageFile, dynamic imageBytes, String? imageExt}) async {
    try {
      final model = TicketModel(
        id: ticket.id,
        title: ticket.title,
        description: ticket.description,
        category: ticket.category,
        status: ticket.status,
        createdAt: ticket.createdAt,
      );
      final result = await dataSource.createTicket(model, imageFile: imageFile, imageBytes: imageBytes, imageExt: imageExt).timeout(const Duration(seconds: 30));
      return Right(result);
    } on TimeoutException {
      return Left(ServerFailure('Gagal mengunggah tiket. Koneksi terputus.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatus(String ticketId, String status) async {
    try {
      await dataSource.updateStatus(ticketId, status).timeout(_timeout);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Comment>>> getComments(String ticketId) async {
    try {
      final result = await dataSource.getComments(ticketId).timeout(_timeout);
      return Right(result);
    } on TimeoutException {
      return Left(ServerFailure('Gagal memuat komentar. Periksa internet.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendComment(String ticketId, String message) async {
    try {
      await dataSource.sendComment(ticketId, message).timeout(_timeout);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignTicket(String ticketId, String helpdeskId) async {
    try {
      await dataSource.assignTicket(ticketId, helpdeskId).timeout(_timeout);
      return const Right(null);
    } on TimeoutException {
      return Left(ServerFailure('Waktu tunggu habis saat menugaskan tiket.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getHelpdesks() async {
    try {
      final result = await dataSource.getHelpdesks().timeout(_timeout);
      return Right(result);
    } on TimeoutException {
      return Left(ServerFailure('Waktu tunggu habis saat memuat daftar helpdesk.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, List<TicketHistory>>> getTicketHistory(String ticketId) async {
    try {
      final result = await dataSource.getTicketHistory(ticketId).timeout(_timeout);
      return Right(result);
    } on TimeoutException {
      return Left(ServerFailure('Gagal memuat timeline history. Waktu tunggu habis.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

