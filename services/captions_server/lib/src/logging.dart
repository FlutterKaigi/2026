import 'dart:convert';
import 'dart:io';

/// Emits a single-line JSON log record to stdout (Cloud Run friendly).
///
/// Example: `{"ts":"2026-06-11T...","level":"info","event":"ingest_ready",...}`
void logEvent(String event, [Map<String, Object?> fields = const {}, String level = 'info']) {
  stdout.writeln(jsonEncode(<String, Object?>{
    'ts': DateTime.now().toUtc().toIso8601String(),
    'level': level,
    'event': event,
    ...fields,
  }));
}
