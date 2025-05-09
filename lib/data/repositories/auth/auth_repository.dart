import 'package:app/utils/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class AuthRepository extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // NOTE: maybe currentUser will not get automatically updated by Firebase so direct assignment is needed
  User? get currentUser => _firebaseAuth.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<Result<UserCredential>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      print("User signed in: ${userCredential.user?.uid}");
      return Result.ok(userCredential);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<UserCredential>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      print("User created: ${userCredential.user?.uid}");
      return Result.ok(userCredential);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<void>> signOut() async {
    try {
      return Result.ok(await _firebaseAuth.signOut());
    } on FirebaseAuthException catch (error) {
      print(
        "Error signing out (FirebaseAuthException): ${error.code} - ${error.message}",
      );
      return Result.error(error);
    } on Exception catch (error) {
      print("General error signing out: $error");
      return Result.error(error);
    }
  }

  //Future<Result<bool>> isUsernameUnique(String username) async {
  //  try {
  //    return Result.ok(await _authService.isUsernameUnique(username));
  //  } on Exception catch (error) {
  //    print('Error checking username uniqueness: $error');
  //    return Result.error(error);
  //  }
  //}
}
