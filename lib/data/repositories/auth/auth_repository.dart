import 'package:app/data/services/firebase/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class AuthRepository extends ChangeNotifier {
  final AuthService _authService; // Dependency on the AuthService

  AuthRepository({required AuthService authService})
    : _authService = authService;

  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential?.user;
    } catch (e) {
      // AuthService already prints and rethrows.
      // Repository layer could add more context if needed, but rethrowing is essential.
      print("AuthRepository: SignIn failed."); // Optional repo-level context
      rethrow; // Allow upper layers (Domain/UI) to handle the specific error
    }
  }

  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Delegate to the AuthService, which handles both auth and user profile creation
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      // Return the User object
      return userCredential?.user;
    } catch (e) {
      // AuthService already prints and rethrows.
      print("AuthRepository: SignUp failed."); // Optional repo-level context
      rethrow; // Allow upper layers (Domain/UI) to handle the specific error
    }
  }

  Future<void> signOut() async {
    try {
      // Delegate to the AuthService
      await _authService.signOut();
    } catch (e) {
      // AuthService prints the error.
      // Decide if the repository should rethrow or just absorb sign-out errors.
      // Often, sign-out errors aren't critical to propagate forcefully.
      print(
        "AuthRepository: SignOut encountered an error (logged by service).",
      );
      // rethrow; // Uncomment if the caller *must* know about sign-out failures
    } finally {
      notifyListeners();
    }
  }
}
