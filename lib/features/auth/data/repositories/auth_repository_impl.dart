import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final supabase.SupabaseClient supabaseClient;

  AuthRepositoryImpl({required this.supabaseClient});

  @override
  Future<Either<Failure, void>> login({
    required String email,
    required String password,
  }) async {
    try {
      await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {      
    try {
      await supabaseClient.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({required String fullName, String? avatarPath}) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? avatarUrl;

      if (avatarPath != null) {
        final File file = File(avatarPath);
        final fileExt = file.path.split('.').last;
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await supabaseClient.storage
            .from('avatars')
            .upload(fileName, file, fileOptions: const supabase.FileOptions(upsert: true));

        avatarUrl = supabaseClient.storage.from('avatars').getPublicUrl(fileName);
      }

      final Map<String, dynamic> data = {'full_name': fullName};
      if (avatarUrl != null) {
        data['avatar_url'] = avatarUrl;
      }

      await supabaseClient.auth.updateUser(
        supabase.UserAttributes(data: data),
      );

      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }
}

