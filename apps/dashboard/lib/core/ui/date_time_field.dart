import 'package:dashboard/core/extension/date_time_extension.dart';
import 'package:flutter/material.dart';

class DateTimeField extends StatelessWidget {
  const DateTimeField({super.key, required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), tooltip: '日時を選択', onPressed: onTap),
        ),
        child: Text(value.formatDateTime()),
      ),
    );
  }
}
