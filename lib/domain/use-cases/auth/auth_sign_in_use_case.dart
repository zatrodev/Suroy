import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/utils/result.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthSignInUseCase {
  AuthSignInUseCase({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<Result<void>> signInWithEmailOrUsernameAndPassword({
    required String identifier,
    required String password,
  }) async {
    if (identifier.contains("@")) {
      try {
        return _authRepository.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        return Result.error(error);
      }
    } else {
      try {
        final result = await _userRepository.getEmailByUsername(identifier);

        switch (result) {
          case Ok<String?>():
            final email = result.value;
            if (email == null) {
              return Result.error(Exception("Username not found."));
            }

            return _authRepository.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          case Error<String?>():
            return Result.error(result.error);
        }
      } on Exception catch (error) {
        return Result.error(error);
      }
    }
  }
}
