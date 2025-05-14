import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/use-cases/auth/auth_sign_in_use_case.dart';
import 'package:app/domain/use-cases/auth/auth_sign_up_use_case.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:logging/logging.dart';

class SignInViewModel {
  SignInViewModel({
    required UserRepository userRepository,
    required AuthSignInUseCase signInUseCase,
    required AuthSignUpUseCase signUpUseCase,
  }) : _userRepository = userRepository,
       _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase {
    signIn = Command1<void, (String identifier, String password)>(_signIn);
    signUp = Command1<void, User>(_signUp);
    isUsernameUnique = Command1<bool, String>(_checkUsernameUniqueness);
  }

  final UserRepository _userRepository;
  final AuthSignInUseCase _signInUseCase;
  final AuthSignUpUseCase _signUpUseCase;
  final _log = Logger('SignInViewModel');

  late Command1<void, (String identifier, String password)> signIn;
  late Command1<void, User> signUp;
  late Command1<bool, String> isUsernameUnique;

  Future<Result<void>> _signIn((String, String) credentials) async {
    final (identifier, password) = credentials;
    final result = await _signInUseCase.signInWithEmailOrUsernameAndPassword(
      identifier: identifier,
      password: password,
    );

    if (result is Error<void>) {
      _log.warning('Login failed! ${result.error}');
      return Result.error(result.error);
    }

    return result;
  }

  Future<Result<void>> _signUp(User user) async {
    final result = await _signUpUseCase.signUp(user);

    if (result is Error<void>) {
      _log.warning('Sign up failed! ${result.error}');
      return Result.error(result.error);
    }

    return result;
  }

  Future<Result<bool>> _checkUsernameUniqueness(String username) async {
    final result = await _userRepository.isUsernameUnique(username);

    switch (result) {
      case Ok<bool>():
        if (result.value) {
          _log.info('Username "$username" is unique.');
        } else {
          _log.info('Username "$username" is taken.');
        }
      case Error<bool>():
        _log.warning(
          'Username uniqueness check failed from repository: ${result.error}',
        );
        break;
    }

    return result;
  }
}
