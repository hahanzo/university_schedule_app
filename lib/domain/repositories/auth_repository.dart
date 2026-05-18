import '../../data/models/user_profile.dart';

abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  Future<UserProfile?> getUserProfile(String uid);
  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Future<String> uploadAvatar(String uid, String filePath);
  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? avatarUrl,
    Map<String, String>? socialLinks,
    String? groupId,
    String? teacherId,
  });
}
