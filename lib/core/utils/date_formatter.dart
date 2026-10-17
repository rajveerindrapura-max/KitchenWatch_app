import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return 'in ${difference.inDays.abs()}d';
    }

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('d MMM').format(dateTime);
    }
  }

  static String shortDate(DateTime dateTime) {
    return DateFormat('d MMM, yyyy').format(dateTime);
  }

  static String shortDateTime(DateTime dateTime) {
    return DateFormat('d MMM, h:mm a').format(dateTime);
  }

  static String daysLeft(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    final days = difference.inDays;

    if (days < 0) {
      return 'Expired';
    } else if (days == 0) {
      return 'Expires today';
    } else if (days == 1) {
      return '1 day left';
    } else {
      return '$days days left';
    }
  }
}
