import 'package:app/data/services/firebase/auth/auth_service.dart';
import 'package:app/utils/result.dart'; // Assuming your Result class is here
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class AuthRepository extends ChangeNotifier {
  final AuthService _authService;

  AuthRepository({required AuthService authService})
    : _authService = authService;

  // NOTE: maybe currentUser will not get automatically updated by Firebase so direct assignment is needed
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<Result<void>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final result = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    return switch (result) {
      Ok(value: final userCredential) => Result.ok(userCredential.user!),
      Error(error: final exception) => Result.error(exception),
    };
  }

  Future<Result<void>> signOut() async {
    final result = await _authService.signOut();

    final finalResult = switch (result) {
      Ok() => const Result.ok(()),
      Error(error: final exception) => Result.error(exception),
    };

    notifyListeners();

    return finalResult;
  }
}
