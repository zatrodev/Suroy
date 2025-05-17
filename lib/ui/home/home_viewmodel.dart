import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:logging/logging.dart';

class HomeViewModel {
  HomeViewModel({
    required UserRepository userRepository,
    required AuthRepository authRepository,
  }) : _userRepository = userRepository {
    loadUser = Command1<User, String>(_loadUser);

    final loggedInUserId = authRepository.currentUser?.uid;
    assert(loggedInUserId != null);
    loadUser.execute(loggedInUserId!);
  }

  final UserRepository _userRepository;
  final _log = Logger('HomeViewModel');

  late Command1 loadUser;

  Future<Result<User>> _loadUser(String userId) async {
    _log.info("Fetching profile for user ID: $userId");
    final result = await _userRepository.getUserById(userId);

    switch (result) {
      case Ok<User>():
        return Result.ok(result.value);
      case Error<User>():
        _log.severe("Failed to load profile: ${result.error}");
        break;
    }

    return result;
  }
}
