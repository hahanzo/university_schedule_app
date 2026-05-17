import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail(String name, String email, String password) async {
    final lowerEmail = email.toLowerCase();
    if (!lowerEmail.endsWith('nltu.lviv.ua') && !lowerEmail.endsWith('nltu.edu.ua')) {
      throw Exception('Використовуйте пошту домену nltu.lviv.ua або nltu.edu.ua');
    }

    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    
    final uid = userCredential.user?.uid;
    if (uid != null) {
      final role = lowerEmail.endsWith('nltu.edu.ua') ? 'teacher' : 'student';
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  @override
  Future<void> resetPassword(String email) =>
      _firebaseAuth.sendPasswordResetEmail(email: email);
}
