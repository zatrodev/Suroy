import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'dart:async';

import 'package:logging/logging.dart';

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel({
    required UserRepository userRepository,
    required User userToEdit,
  }) : _userRepository = userRepository,
       _initialUser = userToEdit {
    _editableUser = userToEdit.copyWith();
    saveChanges = Command0(_saveChanges);
    isUsernameUnique = Command1<bool, String>(_checkUsernameUniqueness);
  }

  final User _initialUser;
  late User _editableUser;
  final UserRepository _userRepository;
  final _log = Logger('EditProfileViewModel');

  late Command0 saveChanges;
  late Command1 isUsernameUnique;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User get editableUser => _editableUser;

  void updateUsername(String username) {
    _editableUser = _editableUser.copyWith(username: username);
    notifyListeners();
  }

  void updateFirstName(String firstName) {
    _editableUser = _editableUser.copyWith(firstName: firstName);
    notifyListeners();
  }

  void updateLastName(String lastName) {
    _editableUser = _editableUser.copyWith(lastName: lastName);
    notifyListeners();
  }

  void updatePhoneNumber(String phoneNumber) {
    _editableUser = _editableUser.copyWith(phoneNumber: phoneNumber);
    notifyListeners();
  }

  void updateInterests(List<Interest> interests) {
    _editableUser = _editableUser.copyWith(interests: interests);
    notifyListeners();
  }

  void updateTravelStyles(List<TravelStyle> travelStyles) {
    _editableUser = _editableUser.copyWith(travelStyles: travelStyles);
    notifyListeners();
  }

  Future<Result<void>> _saveChanges() async {
    _errorMessage = null;
    notifyListeners();

    final result = await _userRepository.updateUserProfile(_editableUser);
    switch (result) {
      case Ok<void>():
        return Result.ok({});
      case Error<void>():
        return Result.error(
          Exception("Failed to save changes: ${result.error}"),
        );
    }
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

  bool get hasUnsavedChanges {
    return _editableUser != _initialUser;
  }

  void discardChanges() {
    _editableUser = _initialUser.copyWith();
    notifyListeners();
  }
}
