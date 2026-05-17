import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<String?>? _authSubscription;

  AuthCubit(this._authRepository) : super(const AuthState.initial()) {
    _authSubscription = _authRepository.authStateChanges.listen((uid) {
      if (uid == null) {
        emit(const AuthState.unauthenticated());
      } else {
        _loadUserProfile(uid);
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    emit(const AuthState.loading());
    try {
      final profile = await _authRepository.getUserProfile(uid);
      if (profile != null) {
        emit(AuthState.authenticated(profile));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signInWithEmail(email, password);
    } catch (e) {
      emit(AuthState.error(_parseErrorMessage(e.toString())));
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signUpWithEmail(name, email, password);
    } catch (e) {
      emit(AuthState.error(_parseErrorMessage(e.toString())));
    }
  }

  Future<void> signOut() async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signOut();
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.resetPassword(email);
      emit(const AuthState.unauthenticated()); // Or a specific reset state
    } catch (e) {
      emit(AuthState.error(_parseErrorMessage(e.toString())));
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('user-not-found')) return 'Користувача не знайдено.';
    if (error.contains('wrong-password')) return 'Неправильний пароль.';
    if (error.contains('email-already-in-use')) return 'Ця пошта вже зареєстрована.';
    if (error.contains('weak-password')) return 'Пароль надто слабкий.';
    if (error.contains('invalid-email')) return 'Неправильний формат пошти.';
    return error.replaceAll('Exception: ', '');
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
