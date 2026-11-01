import 'dart:convert';
import 'dart:io';

import 'package:data/session_model.dart';
import 'package:test/test.dart';

void main() {
  test('generated timetable carries safe archive URLs for sessions and both event layouts', () async {
    final repository = Directory.current.absolute;
    final temporary = await Directory.systemTemp.createTemp('generate-session-archives-');
    final output = File('${temporary.path}/apps/website/lib/constants/generated_sessions.dart');
    await output.parent.create(recursive: true);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final createdAt = DateTime.utc(2026, 10, 1);
    final base = <String, Object?>{
      'title': {'ja': 'テスト', 'en': 'Test'},
      'createdAt': createdAt,
      'updatedAt': createdAt,
    };
    Map<String, Object?> at(int hour) => {
      'startsAt': DateTime.utc(2026, 10, 29, hour),
      'endsAt': DateTime.utc(2026, 10, 29, hour + 1),
    };
    final collections = <String, List<Map<String, Object?>>>{
      'venues': [
        {
          ...base,
          'id': 'room',
          'name': {'ja': '会場', 'en': 'Room'},
          'order': 1,
        },
      ],
      'sessions': [
        for (final (hour, url) in <(int, String?)>[
          (1, ' https://www.youtube.com/watch?v=session123&t=30s '),
          (2, 'https://youtube.com.evil.example/watch?v=unsafe'),
          (3, null),
        ])
          {
            ...base,
            ...at(hour),
            'id': 'session-$hour',
            'description': {'ja': '説明', 'en': 'Description'},
            'primaryLocale': 'ja',
            'venueId': 'room',
            'archiveUrl': ?url,
          },
      ],
      'speakers': [],
      'timelineEvents': [
        {
          ...base,
          ...at(4),
          'id': 'venue-event',
          'venueId': 'room',
          'archiveUrl': 'https://youtu.be/venueEvent123',
        },
        {...base, ...at(5), 'id': 'full-width-event', 'archiveUrl': 'https://youtube.com/live/fullWidth123'},
        {...base, ...at(6), 'id': 'unsafe-event', 'archiveUrl': 'javascript:alert(1)'},
      ],
    };
    server.listen((request) async {
      final collection = request.uri.pathSegments.last;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'documents': [
            for (final document in collections[collection] ?? <Map<String, Object?>>[])
              {
                'name': 'projects/test/databases/(default)/documents/$collection/${document['id']}',
                'fields': encodeFirestoreFields({
                  for (final entry in document.entries)
                    if (entry.key != 'id') entry.key: entry.value,
                }),
              },
          ],
        }),
      );
      await request.response.close();
    });
    try {
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          '--packages=${repository.path}/.dart_tool/package_config.json',
          '${repository.path}/tool/generate_sessions.dart',
        ],
        workingDirectory: temporary.path,
        environment: {
          'FIRESTORE_EMULATOR_HOST': '127.0.0.1:${server.port}',
          'FIRESTORE_HOST': '127.0.0.1:${server.port}',
          'FIREBASE_PROJECT_ID': 'test',
          'PATH': '${File(Platform.resolvedExecutable).parent.path}:${Platform.environment['PATH'] ?? ''}',
        },
        includeParentEnvironment: false,
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final generated = await output.readAsString();
      expect(generated, contains("archiveUrl: 'https://www.youtube.com/watch?v=session123&t=30s'"));
      expect(generated, contains("eventArchiveUrl: 'https://youtu.be/venueEvent123'"));
      expect(generated, contains("eventArchiveUrl: 'https://youtube.com/live/fullWidth123'"));
      expect(RegExp(r'\barchiveUrl:').allMatches(generated), hasLength(1));
      expect(RegExp(r'\beventArchiveUrl:').allMatches(generated), hasLength(2));
      expect(generated, isNot(contains('evil.example')));
      expect(generated, isNot(contains('javascript:')));
    } finally {
      await server.close(force: true);
      await temporary.delete(recursive: true);
    }
  });
}
