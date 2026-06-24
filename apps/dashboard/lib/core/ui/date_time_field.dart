import 'package:dashboard/core/extension/date_time_extension.dart';
import 'package:flutter/material.dart';

class DateTimeField extends StatelessWidget {
  const DateTimeField({super.key, required this.label, required this.value, required this.onTap, this.onClear});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: (onClear != null && value != null)
              ? IconButton(icon: const Icon(Icons.clear), tooltip: 'クリア', onPressed: onClear)
              : IconButton(icon: const Icon(Icons.calendar_today), tooltip: '日時を選択', onPressed: onTap),
        ),
        child: Text(
          value?.formatDateTime() ?? '未設定',
          style: value == null ? const TextStyle(color: Colors.grey) : null,
        ),
      ),
    );
  }
}
