import 'package:app/ui/core/ui/listenable_button.dart';
import 'package:app/ui/notifications/view_models/notification_viewmodel.dart';
import 'package:app/utils/timeago.dart';
import 'package:flutter/material.dart';
import 'package:app/data/repositories/notification/notification_model.dart'
    as local;

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.viewModel,
  });

  final local.Notification notification;
  final NotificationViewModel? viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          notification.type == "friend"
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
      children: [
        notification.senderAvatarBytes != null
            ? CircleAvatar(
              backgroundImage: MemoryImage(notification.senderAvatarBytes!),
            )
            : Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceBright,
              ),
              child: Center(
                child: Text(
                  notification.senderInitials,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            spacing: 4.0,
            children: [
              Text(
                notification.title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              notification.type == "friend"
                  ? Row(
                    spacing: 8.0,
                    children: [
                      ListenableButton(
                        icon: null,
                        command: viewModel!.removeFriendRequest,
                        onPressed: () {
                          viewModel!.removeFriendRequest.execute((
                            notification.senderId,
                            notification.id,
                          ));
                        },
                        buttonStyle: ButtonStyle(
                          textStyle: WidgetStatePropertyAll(
                            Theme.of(context).textTheme.labelMedium,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.tertiary,
                          ),
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          side: WidgetStatePropertyAll(
                            BorderSide(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        label: "Remove",
                        loadingIconColor:
                            Theme.of(context).colorScheme.onTertiary,
                      ),
                      ListenableButton(
                        icon: null,
                        buttonStyle: ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.onTertiary,
                          ),
                          backgroundColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.tertiary,
                          ),
                          textStyle: WidgetStatePropertyAll(
                            Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        label: "Accept",
                        loadingIconColor:
                            Theme.of(context).colorScheme.onTertiary,
                        command: viewModel!.acceptFriendRequest,
                        onPressed: () {
                          viewModel!.acceptFriendRequest.execute((
                            notification.senderId,
                            notification.id,
                          ));
                        },
                      ),
                    ],
                  )
                  : SizedBox.shrink(),
            ],
          ),
        ),
        SizedBox(width: 8),
        Text(
          formatTimeAgo(notification.body),

          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
