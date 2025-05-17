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

  Future<Result<String>> signInWithEmailOrUsernameAndPassword({
    required String identifier,
    required String password,
  }) async {
    if (identifier.contains("@")) {
      try {
        final result = await _authRepository.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );

        switch (result) {
          case Ok<UserCredential>():
            return Result.ok(result.value.user!.uid);
          case Error<UserCredential>():
            return Result.error(result.error);
        }
      } on FirebaseAuthException catch (error) {
        return Result.error(error);
      }
    } else {
      try {
        final getEmailResult = await _userRepository.getEmailByUsername(
          identifier,
        );

        switch (getEmailResult) {
          case Ok<String?>():
            final email = getEmailResult.value;
            if (email == null) {
              return Result.error(Exception("Username not found."));
            }

            final signInResult = await _authRepository
                .signInWithEmailAndPassword(email: email, password: password);

            switch (signInResult) {
              case Ok<UserCredential>():
                return Result.ok(signInResult.value.user!.uid);
              case Error<UserCredential>():
                return Result.error(
                  Exception("Failed loading user: ${signInResult.error}"),
                );
            }
          case Error<String?>():
            return Result.error(getEmailResult.error);
        }
      } on Exception catch (error) {
        return Result.error(error);
      }
    }
  }
}
