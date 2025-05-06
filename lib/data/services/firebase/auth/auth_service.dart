import 'package:app/data/services/firebase/user/user_service.dart';
import 'package:app/utils/result.dart'; // Assuming your Result class is here
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService;

  AuthService({required UserService userService}) : _userService = userService;

  User? get currentUser => _firebaseAuth.currentUser;

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
    } on FirebaseAuthException catch (error) {
      print("Sign in error: ${error.code} - ${error.message}");
      return Result.error(error);
    } on Exception catch (error) {
      print("General sign in error: $error");
      return Result.error(error);
    }
  }

  Future<Result<UserCredential>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      print("User signed up: ${userCredential.user?.uid}");

      final user = userCredential.user;
      if (user != null) {
        await _userService.createUserProfile(
          userId: user.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
        );
        print("User profile created for: ${user.uid}");
        // If both steps are successful, return Ok result
        return Result.ok(userCredential);
      } else {
        // This case should technically not happen if createUser succeeds,
        // but handle defensively.
        print("Sign up error: User object was null after creation.");
        return Result.error(
          Exception("User object was null after successful creation"),
        );
      }
    } on FirebaseAuthException catch (error) {
      // Catch Firebase specific errors (e.g., email-already-in-use)
      print("Sign up FirebaseAuthException: ${error.code} - ${error.message}");
      return Result.error(error); // Return error result
    } on Exception catch (error) {
      // Catch other potential errors (e.g., during createUserProfile)
      print("General sign up error: $error");
      return Result.error(error); // Return error result
    }
  }

  // Refactored signOut
  Future<Result<void>> signOut() async {
    // Changed return type to Result<void>
    try {
      await _firebaseAuth.signOut();
      print("User signed out successfully");
      return Result.ok(()); // Use unit type `()` for void success
    } on FirebaseAuthException catch (error) {
      print(
        "Error signing out (FirebaseAuthException): ${error.code} - ${error.message}",
      );
      return Result.error(error); // Return error result
    } on Exception catch (error) {
      print("General error signing out: $error");
      return Result.error(error); // Return error result
    }
  }
}
