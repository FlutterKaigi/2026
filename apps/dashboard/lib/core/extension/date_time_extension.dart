extension DateTimeExtension on DateTime {
  String formatDate() => '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';

  String formatDateTime() => '${formatDate()} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
