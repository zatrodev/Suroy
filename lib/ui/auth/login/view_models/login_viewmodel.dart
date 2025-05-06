// Copyright 2024 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/auth/auth_repository.dart';

class LoginViewModel {
  LoginViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository {
    signIn = Command1<void, (String email, String password)>(_signIn);
    signUp = Command1<
      void,
      (String firstName, String lastName, String email, String password)
    >(_signUp);
  }

  final AuthRepository _authRepository;
  final _log = Logger('LoginViewModel');

  late Command1 signIn;
  late Command1 signUp;

  Future<Result<void>> _signIn((String, String) credentials) async {
    final (email, password) = credentials;
    final result = await _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result is Error<void>) {
      _log.warning('Login failed! ${result.error}');
    }
    return result;
  }

  Future<Result<void>> _signUp(
    (String, String, String, String) credentials,
  ) async {
    final (firstName, lastName, email, password) = credentials;
    final result = await _authRepository.signUpWithEmailAndPassword(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );

    if (result is Error<void>) {
      _log.warning('Login failed! ${result.error}');
    }
    return result;
  }
}
