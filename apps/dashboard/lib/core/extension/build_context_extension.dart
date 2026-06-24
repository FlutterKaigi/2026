import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<DateTime?> pickDateTime({required DateTime initial}) async {
    final date = await showDatePicker(
      context: this,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null) return null;
    if (!mounted) return null;
    final time = await showTimePicker(
      context: this,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
