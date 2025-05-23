import 'dart:async';

import 'package:app/data/repositories/notification/notification_model.dart';
import 'package:app/data/repositories/notification/notification_repostiory.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class NotificationViewModel {
  NotificationViewModel({
    required UserRepository userRepository,
    required NotificationRepository notificationRepository,
  }) : _userRepository = userRepository,
       _notificationRepository = notificationRepository;

  final UserRepository _userRepository;
  final NotificationRepository _notificationRepository;
  final _log = Logger('NotificationViewModel');

  Stream<List<Notification>>? _myNotificationStreamCache;

  void _avatarTransform(
    List<Notification> incomingNotifications,
    EventSink<List<Notification>> sink,
  ) async {
    final List<Future<Notification>> processedNotifFutures = [];

    for (final notification in incomingNotifications) {
      if (notification.senderId.isEmpty) {
        processedNotifFutures.add(Future.value(notification));
        continue;
      }

      final futureNotification = Future(() async {
        try {
          final result = await _userRepository.getAvatarBytesOfUser(
            notification.senderId,
          );

          switch (result) {
            case Ok<Uint8List?>():
              notification.senderAvatarBytes = result.value;
              return notification;
            case Error<Uint8List?>():
              return notification;
          }
        } catch (e) {
          return notification;
        }
      });
      processedNotifFutures.add(futureNotification);
    }

    try {
      final List<Notification> processedNotifications = await Future.wait(
        processedNotifFutures,
      );
      sink.add(processedNotifications);
    } catch (e) {
      sink.add(incomingNotifications);
    }
  }

  Stream<List<Notification>> watchMyNotifications() {
    _myNotificationStreamCache ??= _notificationRepository
        .getMyNotificationsStream(_userRepository.userFirebase!.id)
        .transform(StreamTransformer.fromHandlers(handleData: _avatarTransform))
        .handleError((error, stackTrace) {
          _log.severe(
            "Failed to listen to notification stream (or error in transform). Error: $error",
            error,
            stackTrace,
          );
          return <Notification>[];
        });

    return _myNotificationStreamCache!;
  }
}
