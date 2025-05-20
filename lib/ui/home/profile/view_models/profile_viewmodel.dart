import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/use-cases/user/update_avatar_use_case.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

class ProfileViewModel {
  ProfileViewModel({
    required UpdateAvatarUseCase updateAvatarUseCase,
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _updateAvatarUseCase = updateAvatarUseCase {
    changeAvatar = Command1<String, ImageSource>(_changeAvatar);
    signOut = Command0<void>(_signOut);

    _user = userRepository.user;
  }

  final AuthRepository _authRepository;
  final UpdateAvatarUseCase _updateAvatarUseCase;
  final _log = Logger('ProfileViewModel');

  late Command1<String, ImageSource> changeAvatar;
  late Command0<void> signOut;

  late User? _user;
  User? get user => _user;

  Future<Result<String>> _changeAvatar(ImageSource imageSource) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      _log.warning("User not logged in, cannot fetch profile.");
      return Result.error(Exception("User not authenticated."));
    }

    final userId = currentUser.uid;

    _log.info("Attempting to change profile picture for user ID: $userId");
    final result = await _updateAvatarUseCase.execute(userId, imageSource);

    if (result is Ok<String>) {
      final newImageUrl = result.value;
      _user = _user!.copyWith(avatar: newImageUrl);
      _log.info("Profile picture updated successfully.");
    } else if (result is Error<String>) {
      _log.severe("Failed to update profile picture: ${result.error}");
    }

    return result;
  }

  Future<Result<void>> _signOut() {
    return _authRepository.signOut();
  }

  void clearError() {
    changeAvatar.clearResult();
  }
}
