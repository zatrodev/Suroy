// Copyright 2024 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/auth/auth_repository.dart';

class SignInViewModel {
  SignInViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository {
    signIn = Command1<void, (String identifier, String password)>(_signIn);
    signUp = Command1<
      void,
      (
        String firstName,
        String lastName,
        String username,
        String email,
        String password,
      )
    >(_signUp);
    isUsernameUniqueCommand = Command1<bool, String>(_checkUsernameUniqueness);
  }

  final AuthRepository _authRepository;
  final _log = Logger('SignInViewModel');

  late Command1 signIn;
  late Command1 signUp;
  late Command1 isUsernameUniqueCommand;

  Future<Result<void>> _signIn((String, String) credentials) async {
    final (identifier, password) = credentials;
    final result = await _authRepository.signInWithEmailOrUsernameAndPassword(
      identifier: identifier,
      password: password,
    );

    if (result is Error<void>) {
      _log.warning('Login failed! ${result.error}');
    }
    return result;
  }

  Future<Result<void>> _signUp(
    (String, String, String, String, String) credentials,
  ) async {
    final (firstName, lastName, username, email, password) = credentials;
    final result = await _authRepository.signUpWithEmailAndPassword(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
    );

    if (result is Error<void>) {
      _log.warning('Login failed! ${result.error}');
    }

    return result;
  }

  Future<Result<bool>> _checkUsernameUniqueness(String username) async {
    final result = await _authRepository.isUsernameUnique(username);

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
