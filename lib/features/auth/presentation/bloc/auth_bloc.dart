import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.login(
        email: event.email,
        password: event.password,
      );
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(AuthSuccess()),
      );
    });

    on<RegisterSubmitted>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.register(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(AuthSuccess()),
      );
    });

    on<LogoutRequested>((event, emit) async {
      await authRepository.logout();
      emit(AuthInitial());
    });

    on<UpdateProfileRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.updateProfile(
        fullName: event.fullName,
        avatarPath: event.avatarPath,
      );
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(AuthSuccess()),
      );
    });
  }
}
