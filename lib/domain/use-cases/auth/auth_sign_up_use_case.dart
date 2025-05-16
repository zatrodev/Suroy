import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/utils/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/domain/models/user.dart' as local;

class AuthSignUpUseCase {
  AuthSignUpUseCase({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<Result<void>> signUp(local.User user) async {
    try {
      final signUpResult = await _authRepository.signUpWithEmailAndPassword(
        email: user.email,
        password: user.password!,
      );

      switch (signUpResult) {
        case Ok<UserCredential>():
          final userFromFirebase = signUpResult.value.user;
          if (userFromFirebase != null) {
            final newUser = UserFirebaseModel(
              id: userFromFirebase.uid,
              firstName: user.firstName,
              lastName: user.lastName,
              username: user.username,
              phoneNumber: user.phoneNumber,
              email: user.email,
              interests: user.interests,
              travelStyles: user.travelStyles,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            return Result.ok(await _userRepository.createUser(newUser));
          } else {
            return Result.error(
              Exception("User object was null after successful creation"),
            );
          }
        case Error<UserCredential>():
          return Result.error(signUpResult.error);
      }
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
