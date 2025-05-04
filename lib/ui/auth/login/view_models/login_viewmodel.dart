// Copyright 2024 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../../../data/repositories/auth/auth_repository.dart';

class LoginViewModel {
  LoginViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  Future<void> login((String, String) credentials) async {
    final (email, password) = credentials;
    try {
      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // TODO
    }
  }
}
