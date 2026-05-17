import '../../data/models/user_profile.dart';

abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  Future<UserProfile?> getUserProfile(String uid);
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String name, String email, String password);
  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
}
