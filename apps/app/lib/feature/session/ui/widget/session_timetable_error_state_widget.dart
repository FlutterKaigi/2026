import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:flutter/material.dart';

class SessionTimetableErrorStateWidget extends StatelessWidget {
  const SessionTimetableErrorStateWidget({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppErrorView(
    error: error,
    onRetry: onRetry,
  );
}
