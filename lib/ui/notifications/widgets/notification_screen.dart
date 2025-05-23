import 'package:app/ui/notifications/view_models/notification_viewmodel.dart';
import 'package:app/data/repositories/notification/notification_model.dart'
    as local;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, required this.viewModel});

  final NotificationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.0,
        title: Text(
          "Notifications",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: StreamBuilder<List<local.Notification>>(
        stream: viewModel.watchMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Oops! Something went wrong.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No notifications right now.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final _notifications = snapshot.data!;

          // TODO: display notifications
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: <Widget>[_notifications.map((notification) => Row()],
            ),
          );
        },
      ),
    );
  }
}
