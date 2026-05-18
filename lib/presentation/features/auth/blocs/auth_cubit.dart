import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/dev_constants.dart';
import '../../../../data/models/user_profile.dart';
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
      UserProfile? profile;
      for (int i = 0; i < AuthConstants.profileLoadRetries; i++) {
        profile = await _authRepository.getUserProfile(uid);
        if (profile != null) break;
        await Future.delayed(AuthConstants.profileLoadRetryDelay);
      }
      emit(profile != null
          ? AuthState.authenticated(profile)
          : const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());
    try {
      final didSignIn = await _authRepository.signInWithGoogle();
      if (!didSignIn) emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(_parseError(e.toString())));
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

  Future<void> updateProfile({
    String? name,
    String? avatarFilePath,
    String? avatarUrl,
    Map<String, String>? socialLinks,
    String? groupId,
    String? teacherId,
  }) async {
    final currentUser = state.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
    if (currentUser == null) throw Exception('User not found.');

    String? resolvedAvatarUrl = avatarUrl;
    if (avatarFilePath != null) {
      resolvedAvatarUrl =
          await _authRepository.uploadAvatar(currentUser.uid, avatarFilePath);
    }

    await _authRepository.updateUserProfile(
      currentUser.uid,
      name: name,
      avatarUrl: resolvedAvatarUrl,
      socialLinks: socialLinks,
      groupId: groupId,
      teacherId: teacherId,
    );

    final updated = await _authRepository.getUserProfile(currentUser.uid);
    if (updated != null) emit(AuthState.authenticated(updated));
  }

  Future<void> updateUserSelection({
    String? groupId,
    String? teacherId,
  }) =>
      updateProfile(groupId: groupId, teacherId: teacherId);

  String _parseError(String error) {
    if (error.contains('network')) return 'Network error. Check your connection.';
    if (error.contains('sign_in_failed')) return 'Google sign-in failed.';
    return error.replaceAll('Exception: ', '');
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
