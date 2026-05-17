import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/utils/auth_validators.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl(this._firebaseAuth, this._firestore);

  @override
  Stream<String?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid);

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return UserProfile(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
    );
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final lowerEmail = email.toLowerCase();
    if (!AuthValidators.isAllowedDomain(lowerEmail)) {
      throw Exception(
        'Використовуйте пошту домену nltu.lviv.ua або nltu.edu.ua',
      );
    }

    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user?.uid;
    if (uid != null) {
      final role = lowerEmail.endsWith(AuthValidators.teacherDomain)
          ? 'teacher'
          : 'student';
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final account = await googleSignIn.signIn();
    if (account == null) {
      return false;
    }

    final email = account.email;
    if (!AuthValidators.isAllowedDomain(email)) {
      await googleSignIn.signOut();
      throw Exception(
        'Використовуйте пошту домену nltu.lviv.ua або nltu.edu.ua',
      );
    }

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw Exception('Не вдалося увійти через Google');
    }

    final role = email.toLowerCase().endsWith(AuthValidators.teacherDomain)
        ? 'teacher'
        : 'student';

    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    final data = <String, dynamic>{
      'name': account.displayName ?? '',
      'email': email,
      'role': role,
    };

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await userDoc.set(data, SetOptions(merge: true));
    return true;
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  @override
  Future<void> resetPassword(String email) =>
      _firebaseAuth.sendPasswordResetEmail(email: email);
}
