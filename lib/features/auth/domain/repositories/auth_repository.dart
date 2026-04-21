import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> register({
    required String email,
    required String password,
    required String fullName,
  });

  Future<Either<Failure, void>> resetPassword(String email);

  Future<Either<Failure, void>> updatePassword(String newPassword);

  Future<Either<Failure, void>> updateProfile({required String fullName, String? avatarPath});

  Future<void> logout();
}
