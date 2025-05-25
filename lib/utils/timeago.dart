import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

String formatTimeAgo(String dateString) {
  try {
    final DateFormat inputFormat = DateFormat('MMM dd, yyyy | HH:mm', 'en_US');

    final DateTime notificationDateTime = inputFormat.parse(dateString);

    return timeago.format(notificationDateTime, allowFromNow: true);
  } catch (e) {
    return dateString;
  }
}
