import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:logging/logging.dart';

class SocialViewModel {
  SocialViewModel({required UserRepository userRepository})
    : _userRepository = userRepository {
    addFriend = Command1<void, Friend>(_addFriend);
  }

  final UserRepository _userRepository;
  final _log = Logger('SocialViewModel');

  late Command1 addFriend;

  Stream<List<User>>? _similarPeopleStreamCache;

  void _handleUserTransform(
    List<User> incomingUsers,
    EventSink<List<User>> sink,
  ) async {
    final List<Future<User>> processedUserFutures = [];

    for (final user in incomingUsers) {
      if (user.avatarBytes != null) {
        final futureUser = Future(() async {
          try {
            final colorScheme = await ColorScheme.fromImageProvider(
              provider: MemoryImage(user.avatarBytes!),
            );
            return user.copyWith(colorScheme: colorScheme);
          } catch (e) {
            return user;
          }
        });
        processedUserFutures.add(futureUser);
      } else {
        processedUserFutures.add(Future.value(user));
      }
    }

    try {
      final List<User> processedUsers = await Future.wait(processedUserFutures);
      sink.add(processedUsers);
    } catch (e) {
      sink.add(incomingUsers);
    }
  }

  Stream<List<User>> watchSimilarPeople() {
    _similarPeopleStreamCache = _userRepository
        .getSimilarPeopleStream()
        .transform(
          StreamTransformer.fromHandlers(handleData: _handleUserTransform),
        )
        .handleError((error, stackTrace) {
          _log.severe(
            "Failed to listen to similar people stream (or error in transform). Error: $error",
            error,
            stackTrace,
          );
          return <User>[];
        });

    return _similarPeopleStreamCache!;
  }

  Future<Result<void>> _addFriend(Friend userToBefriend) async {
    final result = await _userRepository.addFriend(userToBefriend);

    if (result is Error<void>) {
      _log.warning('Friend request failed! ${result.error}');
      return Result.error(result.error);
    }

    _similarPeopleStreamCache = null;
    return result;
  }
}
