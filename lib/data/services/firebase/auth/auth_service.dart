import 'package:app/data/services/firebase/user/user_model.dart';
import 'package:app/data/services/firebase/user/user_service.dart';
import 'package:app/utils/result.dart'; // Assuming your Result class is here
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService;

  AuthService({required UserService userService}) : _userService = userService;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<Result<UserCredential>> signInWithEmailOrUsernameAndPassword({
    required String identifier, // This can be email or username
    required String password,
  }) async {
    String? emailToUse;

    bool isEmail = identifier.contains('@') && identifier.contains('.');

    if (isEmail) {
      emailToUse = identifier;
      print("Attempting sign-in with provided email: $emailToUse");
    } else {
      print("Identifier '$identifier' treated as username. Fetching email...");
      try {
        emailToUse = await _userService.getEmailByUsername(identifier);
        if (emailToUse == null) {
          print("Username '$identifier' not found or no email associated.");
          // Return a specific error. Firebase's "user-not-found" is often
          // generic, so a custom error here can be more informative.
          return Result.error(
            FirebaseAuthException(
              code:
                  'user-not-found', // Or a custom code like 'username-not-found'
              message: 'No user found for the provided username.',
            ),
          );
        }
        print(
          "Email '$emailToUse' found for username '$identifier'. Proceeding with sign-in.",
        );
      } catch (e) {
        print("Error fetching email for username '$identifier': $e");
        return Result.error(
          Exception(
            "An error occurred while looking up your username. Please try again.",
          ),
        );
      }
    }

    // 2. Proceed with Firebase Auth sign-in using the determined email
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: emailToUse, password: password);

      print("User signed in successfully: ${userCredential.user?.uid}");
      return Result.ok(userCredential);
    } on FirebaseAuthException catch (error) {
      print("Sign in error: ${error.code} - ${error.message}");
      // You might want to map generic Firebase errors to be more user-friendly
      // e.g., 'user-not-found' could mean the email (derived or direct) doesn't exist
      // 'wrong-password' is clear.
      return Result.error(error);
    } on Exception catch (error) {
      // Catch other unexpected errors
      print("General sign in error: $error");
      return Result.error(error);
    }
  }

  Future<Result<UserCredential>> signUpWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    List<Interest> interests = const [],
    List<TravelStyle> travelStyles = const [],
  }) async {
    try {
      if (!await _userService.isUsernameUnique(username)) {
        throw Exception('Username "$username" is already taken.');
      }

      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      print("User signed up: ${userCredential.user?.uid}");

      final user = userCredential.user;
      if (user != null) {
        final newUser = UserModel(
          id: user.uid,
          firstName: firstName,
          lastName: lastName,
          username: username,
          phoneNumber: userCredential.user?.phoneNumber,
          email: email,
          interests: interests,
          travelStyles: travelStyles,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _userService.createUser(newUser);
        print("User profile created for: ${user.uid}");
        return Result.ok(userCredential);
      } else {
        print("Sign up error: User object was null after creation.");
        return Result.error(
          Exception("User object was null after successful creation"),
        );
      }
    } on FirebaseAuthException catch (error) {
      print("Sign up FirebaseAuthException: ${error.code} - ${error.message}");
      return Result.error(error);
    } on Exception catch (error) {
      print("General sign up error: $error");
      return Result.error(error);
    }
  }

  // Refactored signOut
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

  Future<bool> isUsernameUnique(String username) {
    return _userService.isUsernameUnique(username);
  }
}
