import 'package:app/data/services/firebase/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService;

  AuthService({required UserService userService}) : _userService = userService;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      print("User signed in: ${userCredential.user?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Sign in error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("General sign in error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      print("User signed up: ${userCredential.user?.uid}");

      if (userCredential.user != null) {
        await _userService.createUserProfile(
          userId: userCredential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Sign up error: ${e.code} - ${e.message}");

      rethrow;
    } catch (e) {
      print("General sign up error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print("User signed out");
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}
