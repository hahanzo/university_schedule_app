import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile.dart';

const _studentDomain = 'nltu.lviv.ua';
const _teacherDomain = 'nltu.edu.ua';

bool _isAllowedDomain(String email) =>
    email.endsWith(_studentDomain) || email.endsWith(_teacherDomain);

bool _isTeacherDomain(String email) => email.endsWith(_teacherDomain);

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthRepositoryImpl(this._firebaseAuth, this._firestore, this._storage);

  @override
  Stream<String?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid);

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;

    Map<String, String>? socialLinks;
    final rawSocial = data['socialLinks'];
    if (rawSocial is Map) {
      socialLinks = rawSocial.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return UserProfile(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      avatarUrl: data['avatarUrl'] as String?,
      socialLinks: socialLinks,
      groupId: data['groupId'] as String?,
      teacherId: data['teacherId'] as String?,
    );
  }

  @override
  Future<bool> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final account = await googleSignIn.signIn();
    if (account == null) return false;

    final lowerEmail = account.email.toLowerCase();

    if (!_isAllowedDomain(lowerEmail)) {
      await googleSignIn.signOut();
      throw Exception('Use @nltu.lviv.ua or @nltu.edu.ua email.');
    }

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('Google sign-in failed.');

    final isTeacher = _isTeacherDomain(lowerEmail);
    final role = isTeacher ? AppConstants.teacherRole : AppConstants.studentRole;

    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    String resolvedName;
    if (isTeacher) {
      resolvedName = account.displayName?.trim() ?? '';
    } else {
      final displayName = account.displayName?.trim() ?? '';
      resolvedName = displayName.isNotEmpty
          ? displayName
          : account.email.split('@').first;
    }

    if (!snapshot.exists && resolvedName.isNotEmpty) {
      await _ensureUniqueName(resolvedName);
    }

    final data = <String, dynamic>{
      'email': account.email,
      'role': role,
      if (isTeacher) 'teacherId': lowerEmail,
    };

    if (!snapshot.exists) {
      data['name'] = resolvedName;
      if (resolvedName.isNotEmpty) {
        data['nameLower'] = resolvedName.toLowerCase();
      }
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await userDoc.set(data, SetOptions(merge: true));
    return true;
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  @override
  Future<String> uploadAvatar(String uid, String filePath) async {
    final file = File(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('users/$uid/avatar_$timestamp.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  @override
  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? avatarUrl,
    Map<String, String>? socialLinks,
    String? groupId,
    String? teacherId,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) {
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        final snapshot = await _firestore.collection('users').doc(uid).get();
        final currentName = (snapshot.data()?['name'] ?? '').toString();
        if (trimmedName != currentName) {
          await _ensureUniqueName(trimmedName, currentUid: uid);
        }
        updates['name'] = trimmedName;
        updates['nameLower'] = trimmedName.toLowerCase();
      } else {
        updates['name'] = '';
        updates['nameLower'] = '';
      }
    }

    if (avatarUrl != null) {
      updates['avatarUrl'] = avatarUrl;
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        final currentAvatarUrl = doc.data()?['avatarUrl'] as String?;
        if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
          if (!currentAvatarUrl.contains('googleusercontent.com')) {
            final path = _extractStoragePath(currentAvatarUrl);
            if (path != null && path.isNotEmpty) {
              await _storage.ref(path).delete();
            }
          }
        }
      } catch (_) {}
    }
    if (socialLinks != null) updates['socialLinks'] = socialLinks;
    if (groupId != null) updates['groupId'] = groupId.trim();
    if (teacherId != null) updates['teacherId'] = teacherId.trim();

    if (updates.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .set(updates, SetOptions(merge: true));
  }

  Future<void> _ensureUniqueName(String name, {String? currentUid}) async {
    if (name.isEmpty) return;
    final normalizedName = name.toLowerCase();
    final existing = await _firestore
        .collection('users')
        .where('nameLower', isEqualTo: normalizedName)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final docId = existing.docs.first.id;
      if (currentUid == null || docId != currentUid) {
        throw Exception('A user with this name already exists.');
      }
    }
  }

  String? _extractStoragePath(String url) {
    try {
      if (url.startsWith('gs://')) {
        final uri = Uri.parse(url);
        String path = uri.path;
        if (path.startsWith('/')) {
          path = path.substring(1);
        }
        return path;
      } else if (url.contains('/o/')) {
        final oIndex = url.indexOf('/o/');
        String pathPart = url.substring(oIndex + 3);
        final qIndex = pathPart.indexOf('?');
        if (qIndex != -1) {
          pathPart = pathPart.substring(0, qIndex);
        }
        return Uri.decodeComponent(pathPart);
      }
    } catch (_) {}
    return null;
  }
}
