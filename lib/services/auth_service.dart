import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iot_v3/constants/app_constants.dart';

class AuthFailure implements Exception {
  final String code;
  final String message;

  const AuthFailure({required this.code, required this.message});
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({required String email, required String password}) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(code: error.code, message: _mapAuthError(error));
    } catch (error) {
      throw AuthFailure(code: 'sign-in-failure', message: error.toString());
    }
  }

  Future<UserCredential> signUp({required String email, required String password}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null) {
        await _createUserProfile(user);
        await sendEmailVerification(user);
      }
      return credential;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(code: error.code, message: _mapAuthError(error));
    } catch (error) {
      throw AuthFailure(code: 'sign-up-failure', message: error.toString());
    }
  }

  Future<void> _createUserProfile(User user) async {
    final doc = _firestore.collection(AppConstants.usersCollection).doc(user.uid);
    await doc.set({
      'userUID': user.uid,
      'email': user.email,
      'devices': const [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(code: error.code, message: _mapAuthError(error));
    } catch (error) {
      throw AuthFailure(code: 'reset-password-failure', message: error.toString());
    }
  }

  Future<void> sendEmailVerification(User user) async {
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
    return _auth.currentUser;
  }

  Future<void> signOut() => _auth.signOut();

  String _mapAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'The email you entered is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support if this is unexpected.';
      case 'user-not-found':
        return 'No user found for that email address.';
      case 'wrong-password':
        return 'The password you entered is incorrect.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Please choose a stronger password (min 8 characters with numbers).';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled for this project.';
      default:
        return exception.message ?? 'Something went wrong. Please try again.';
    }
  }
}
