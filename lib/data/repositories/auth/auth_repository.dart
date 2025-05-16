import 'package:app/utils/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class AuthRepository extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<Result<UserCredential>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      print("User signed in: ${userCredential.user?.uid}");
      return Result.ok(userCredential);
    } on FirebaseAuthException catch (error) {
      return Result.error(Exception(error.message));
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
    } on FirebaseAuthException catch (error) {
      if (error.code == "email-already-in-use") {
        return Result.error(
          FirebaseAuthException(
            code: error.code,
            message: "Email already in use.",
          ),
        );
      }

      return Result.error(error);
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
}
