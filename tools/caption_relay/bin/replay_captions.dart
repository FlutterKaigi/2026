import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('base-url', defaultsTo: 'http://127.0.0.1:8088')
    ..addOption('file', mandatory: true, help: 'Anonymous JSON rehearsal fixture.')
    ..addOption('room', defaultsTo: 'main')
    ..addOption('session', defaultsTo: 'rehearsal')
    ..addFlag('help', abbr: 'h', negatable: false);
  final options = parser.parse(arguments);
  if (options.flag('help')) {
    stdout.writeln('Replay caption fixtures\n\n${parser.usage}');
    return;
  }

  final fixture = File(options.option('file')!);
  if (!fixture.existsSync()) {
    stderr.writeln('Fixture does not exist: ${fixture.path}');
    exitCode = 66;
    return;
  }
  final decoded = jsonDecode(await fixture.readAsString());
  if (decoded is! List<Object?>) {
    throw const FormatException('Fixture must contain a JSON array.');
  }

  final baseUrl = Uri.parse(options.option('base-url')!);
  final token = Platform.environment['VENUE_CAPTION_WRITE_TOKEN'];
  if (token == null || token.length < 32) {
    throw const FormatException('VENUE_CAPTION_WRITE_TOKEN must contain at least 32 characters.');
  }
  final headers = <String, String>{
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: 'Bearer $token',
  };

  for (final item in decoded) {
    if (item is! Map<String, Object?>) {
      throw const FormatException('Every fixture entry must be a JSON object.');
    }
    final delayMs = item['delayMs'];
    if (delayMs is! int || delayMs < 0) {
      throw const FormatException('delayMs must be a non-negative integer.');
    }
    final sourceAgeMs = item['sourceAgeMs'] ?? 0;
    if (sourceAgeMs is! int || sourceAgeMs < 0 || sourceAgeMs > 300000) {
      throw const FormatException('sourceAgeMs must be an integer between 0 and 300000.');
    }
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    final body = <String, Object?>{
      'roomId': options.option('room'),
      'sessionId': options.option('session'),
      'utteranceId': item['utteranceId'],
      'utteranceSequence': item['utteranceSequence'],
      'revision': item['revision'],
      'translatedText': item['translatedText'],
      if (item['sourceText'] != null) 'sourceText': item['sourceText'],
      'isFinal': item['isFinal'] ?? true,
      'sourceStartedAt': DateTime.now().toUtc().subtract(Duration(milliseconds: sourceAgeMs)).toIso8601String(),
      'clearAfterMs': item['clearAfterMs'] ?? 8000,
    };
    final response = await http.post(baseUrl.resolve('/api/v1/captions'), headers: headers, body: jsonEncode(body));
    if (response.statusCode != HttpStatus.accepted) {
      throw HttpException('Relay rejected a caption (${response.statusCode}): ${response.body}');
    }
    stdout.writeln('Sent utterance ${item['utteranceSequence']}');
  }

  final clearResponse = await http.post(
    baseUrl.resolve('/api/v1/clear'),
    headers: headers,
    body: jsonEncode({'roomId': options.option('room'), 'sessionId': options.option('session')}),
  );
  if (clearResponse.statusCode != HttpStatus.accepted) {
    throw HttpException('Relay rejected clear (${clearResponse.statusCode}): ${clearResponse.body}');
  }
}
