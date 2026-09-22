import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:dashboard/core/event_environment/event_admin_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('subscribers share one read, receive updates and stop polling after disposal', () async {
    var reads = 0;
    final client = EventAdminClient(
      environment: Flavor.prod,
      view: {'view': 'quizConsole', 'eventId': 'same-id'},
      pollInterval: const Duration(days: 1),
      request: (request) async {
        expect(request['environment'], 'prod');
        reads++;
        return {'entryCode': '$reads'};
      },
    );
    final first = <Map<String, dynamic>>[];
    final second = <Map<String, dynamic>>[];
    final a = client.watch().listen(first.add);
    final b = client.watch().listen(second.add);
    await Future<void>.delayed(Duration.zero);
    expect(reads, 1);
    expect(first.single, second.single);
    await client.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(first.last['entryCode'], '2');
    await a.cancel();
    await b.cancel();
    client.dispose();
    await client.refresh();
    expect(reads, 2);
  });

  test('an old read cannot overwrite data after a mutation', () async {
    final pending = Completer<Map<String, dynamic>>();
    var reads = 0;
    final client = EventAdminClient(
      environment: Flavor.stg,
      view: {'view': 'supportLt'},
      pollInterval: const Duration(days: 1),
      request: (request) async {
        if (request['action'] != 'read') return {};
        return ++reads == 1 ? pending.future : {'code': 'new'};
      },
    );
    final received = <Map<String, dynamic>>[];
    final subscription = client.watch().listen(received.add);
    await Future<void>.delayed(Duration.zero);
    await client.mutate('issueSupportLtCode', {'rotate': true});
    pending.complete({'code': 'old'});
    await Future<void>.delayed(Duration.zero);
    expect(received, [
      {'code': 'new'},
    ]);
    await subscription.cancel();
    client.dispose();
  });

  test('operation retry retains its ID and environment after a network failure', () async {
    final requests = <Map<String, dynamic>>[];
    final client = EventAdminClient(
      environment: Flavor.prod,
      view: {'view': 'quizConsole', 'eventId': 'quiz'},
      request: (request) async {
        requests.add(request);
        if (requests.length == 1) throw FirebaseFunctionsException(code: 'deadline-exceeded', message: 'Timed out');
        return {};
      },
    );
    final repository = AdminQuizOperationsRepository(client);
    await expectLater(repository.extendQuestion('quiz', 'q1', seconds: 30), throwsA(isA<FirebaseFunctionsException>()));
    await repository.extendQuestion('quiz', 'q1', seconds: 30);
    expect(requests[0], requests[1]);
    expect(requests[1]['environment'], 'prod');
    client.dispose();
  });
}
