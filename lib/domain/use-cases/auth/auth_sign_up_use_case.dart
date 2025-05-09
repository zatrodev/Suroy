import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/utils/result.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthSignUpUseCase {
  AuthSignUpUseCase({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<Result<void>> signUp({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    List<Interest> interests = const [],
    List<TravelStyle> travelStyles = const [],
  }) async {
    try {
      final signUpResult = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      switch (signUpResult) {
        case Ok<UserCredential>():
          final user = signUpResult.value.user;
          if (user != null) {
            final newUser = UserModel(
              id: user.uid,
              firstName: firstName,
              lastName: lastName,
              username: username,
              phoneNumber: user.phoneNumber,
              email: email,
              interests: interests,
              travelStyles: travelStyles,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            return Result.ok(await _userRepository.createUser(newUser));
          } else {
            print("Sign up error: User object was null after creation.");
            return Result.error(
              Exception("User object was null after successful creation"),
            );
          }
        case Error<UserCredential>():
          return Result.error(Exception("Sign up error."));
      }
    } on Exception catch (error) {
      print("General sign up error: $error");
      return Result.error(error);
    }
  }
}
