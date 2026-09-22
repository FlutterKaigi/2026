import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:data/data.dart';

List<T> _list<T>(Map<String, dynamic> data, String key, T Function(Map<String, dynamic>) parse) =>
    (data[key] as List<dynamic>? ?? []).map((value) => parse(Map<String, dynamic>.from(value as Map))).toList();
T? _document<T>(Map<String, dynamic> data, String key, T Function(Map<String, dynamic>) parse) =>
    data[key] == null ? null : parse(Map<String, dynamic>.from(data[key] as Map));

Never _attendeeOnly() => throw UnsupportedError('参加者アプリから操作してください。');

class AdminSupportLtRepository implements SupportLtRepository {
  AdminSupportLtRepository(this.client);
  final EventAdminClient client;

  @override
  Stream<SupportLtCode?> watchCode() => client.watch().map(
    (data) => _document(
      data,
      'code',
      (value) => SupportLtCode(
        code: value['code'] as String,
        issuedAt: DateTime.parse(value['issuedAt'] as String),
      ),
    ),
  );

  @override
  Stream<List<SupportLtRegistration>> watchRegistrations() => client.watch().map(
    (data) => _list(
      data,
      'registrations',
      (value) => SupportLtRegistration(
        uid: value['id'] as String,
        displayName: value['displayName'] as String,
        registeredAt: DateTime.parse(value['registeredAt'] as String),
      ),
    ),
  );

  @override
  Future<void> issueCode({bool rotate = false}) async => client.mutate('issueSupportLtCode', {'rotate': rotate});

  @override
  Stream<SupportLtRegistration?> watchRegistration(String uid) =>
      watchRegistrations().map((items) => items.where((item) => item.uid == uid).firstOrNull);

  @override
  Future<void> register(String code) async => _attendeeOnly();
}

class AdminQuizEventRepository implements QuizEventRepository {
  AdminQuizEventRepository(this.client);
  final EventAdminClient client;
  String? _newId;

  @override
  Stream<List<QuizEvent>> watchAll() => client.watch().map((data) => _list(data, 'events', QuizEvent.fromJson));
  @override
  Stream<List<QuizEvent>> watchPublished() =>
      watchAll().map((events) => events.where((event) => event.isPublic).toList());
  @override
  Stream<QuizEvent?> watchById(String eventId) =>
      client.watch().map((data) => _document(data, 'event', QuizEvent.fromJson));

  @override
  Future<String> save(QuizEvent event) async {
    final eventId = event.isNew ? (_newId ??= newEventOperationId()) : event.id;
    await client.mutate('saveEvent', {
      'eventId': eventId,
      'title': event.title.toJson(),
      'capacity': event.capacity,
      'sponsorIds': event.sponsorIds,
      'teamNamePool': event.teamNamePool,
    });
    _newId = null;
    return eventId;
  }

  @override
  Future<void> updateTeamNamePool(String eventId, List<String> names) async =>
      client.mutate('updateTeamNamePool', {'eventId': eventId, 'names': names});
}

class AdminQuizQuestionRepository implements QuizQuestionRepository {
  AdminQuizQuestionRepository(this.client);
  final EventAdminClient client;
  String? _newId;

  @override
  Stream<List<QuizQuestion>> watchAll(String eventId) =>
      client.watch().map((data) => _list(data, 'questions', QuizQuestion.fromJson));
  @override
  Stream<QuizQuestion?> watchById(String eventId, String questionId) =>
      client.watch().map((data) => _document(data, 'question', QuizQuestion.fromJson));
  @override
  Stream<QuizQuestionSecret?> watchSecret(String eventId, String questionId) =>
      client.watch().map((data) => _document(data, 'secret', QuizQuestionSecret.fromJson));

  @override
  Future<void> save(String eventId, QuizQuestion question, QuizQuestionSecret secret) async {
    final questionId = question.isNew ? (_newId ??= newEventOperationId()) : question.id;
    await client.mutate('saveQuestion', {
      'eventId': eventId,
      'questionId': questionId,
      'question': {
        'sponsorId': question.sponsorId,
        'order': question.order,
        'title': question.title.toJson(),
        'options': question.options.map((option) => option.toJson()).toList(),
        'durationSeconds': question.durationSeconds,
      },
      'secret': secret.toJson(),
    });
    _newId = null;
  }

  @override
  Future<void> delete(String eventId, String questionId) async =>
      client.mutate('deleteQuestion', {'eventId': eventId, 'questionId': questionId});
}

class AdminQuizTeamRepository implements QuizTeamRepository {
  AdminQuizTeamRepository(this.client);
  final EventAdminClient client;
  @override
  Stream<List<QuizTeam>> watchAll(String eventId) =>
      client.watch().map((data) => _list(data, 'teams', QuizTeam.fromJson));
  @override
  Stream<QuizTeam?> watchById(String eventId, String teamId) =>
      watchAll(eventId).map((teams) => teams.where((team) => team.id == teamId).firstOrNull);
  @override
  Future<void> updateName(String eventId, String teamId, String name) async =>
      client.mutate('renameTeam', {'eventId': eventId, 'teamId': teamId, 'name': name});
}

class AdminQuizParticipantRepository implements QuizParticipantRepository {
  AdminQuizParticipantRepository(this.client);
  final EventAdminClient client;
  @override
  Stream<List<QuizParticipant>> watchAll(String eventId) =>
      client.watch().map((data) => _list(data, 'participants', QuizParticipant.fromJson));
  @override
  Stream<QuizParticipant?> watchByUid(String eventId, String uid) =>
      watchAll(eventId).map((people) => people.where((person) => person.id == uid).firstOrNull);
  @override
  Future<QuizParticipantAccount?> findAccount(String eventId, String uid) async => _attendeeOnly();
  @override
  Future<void> register(
    String eventId, {
    String? uid,
    required String displayName,
    required String entryCode,
    String? signInProvider,
    String? email,
    String? accountName,
    String? photoUrl,
  }) async => _attendeeOnly();
}

class AdminQuizAnswerRepository implements QuizAnswerRepository {
  AdminQuizAnswerRepository(this.client);
  final EventAdminClient client;
  @override
  Stream<List<QuizAnswer>> watchByQuestion(String eventId, String questionId) => client.watch().map(
    (data) => _list(data, 'answers', QuizAnswer.fromJson).where((answer) => answer.questionId == questionId).toList(),
  );
  @override
  Stream<QuizAnswer?> watchByQuestionAndTeam(String eventId, String questionId, String teamId) => watchByQuestion(
    eventId,
    questionId,
  ).map((answers) => answers.where((answer) => answer.teamId == teamId).firstOrNull);
  @override
  Future<void> submit(
    String eventId,
    String questionId,
    String teamId, {
    required int selectedOptionIndex,
    String? uid,
  }) async => _attendeeOnly();
}

class AdminQuizOperationsRepository implements QuizOperationsRepository {
  AdminQuizOperationsRepository(this.client);
  final EventAdminClient client;
  final _pendingIds = <String, String>{};

  Future<Map<String, dynamic>> _operate(
    String eventId,
    String operation, [
    Map<String, dynamic> args = const {},
  ]) async {
    final payload = {'eventId': eventId, 'operation': operation, ...args};
    final key = jsonEncode(payload);
    payload['operationId'] = _pendingIds.putIfAbsent(key, newEventOperationId);
    try {
      final result = await client.mutate('quizOperation', payload);
      _pendingIds.remove(key);
      return result;
    } on FirebaseFunctionsException catch (error) {
      if (const [
        'invalid-argument',
        'failed-precondition',
        'permission-denied',
        'unauthenticated',
        'not-found',
        'resource-exhausted',
      ].contains(error.code)) {
        _pendingIds.remove(key);
      }
      rethrow;
    }
  }

  @override
  Future<void> publishEvent(String eventId) async => _operate(eventId, 'publish');
  @override
  Future<void> unpublishEvent(String eventId) async => _operate(eventId, 'unpublish');
  @override
  Future<void> openRegistration(String eventId) async => _operate(eventId, 'openRegistration');
  @override
  Future<void> closeRegistration(String eventId) async => _operate(eventId, 'closeRegistration');
  @override
  Future<void> reopenRegistration(String eventId) async => _operate(eventId, 'reopenRegistration');
  @override
  Future<void> buildTeams(String eventId) async => _operate(eventId, 'buildTeams');
  @override
  Future<void> rebuildTeams(String eventId) async => _operate(eventId, 'rebuildTeams');
  @override
  Future<void> removeParticipant(String eventId, String uid) async =>
      _operate(eventId, 'removeParticipant', {'uid': uid});
  @override
  Stream<String?> watchEntryCode(String eventId) => client.watch().map((data) => data['entryCode'] as String?);
  @override
  Future<String> regenerateEntryCode(String eventId) async =>
      (await _operate(eventId, 'regenerateEntryCode'))['code'] as String;
  @override
  Future<void> presentQuestion(String eventId, String questionId) async =>
      _operate(eventId, 'presentQuestion', {'questionId': questionId});
  @override
  Future<void> openQuestion(String eventId, String questionId) async =>
      _operate(eventId, 'openQuestion', {'questionId': questionId});
  @override
  Future<void> closeQuestion(String eventId, String questionId) async =>
      _operate(eventId, 'closeQuestion', {'questionId': questionId});
  @override
  Future<void> extendQuestion(String eventId, String questionId, {required int seconds}) async =>
      _operate(eventId, 'extendQuestion', {'questionId': questionId, 'seconds': seconds});
  @override
  Future<void> revealQuestion(String eventId, String questionId) async =>
      _operate(eventId, 'revealQuestion', {'questionId': questionId});
  @override
  Future<void> finalizeEvent(String eventId) async => _operate(eventId, 'finalizeEvent');
}

class AdminQuizClockRepository implements QuizClockRepository {
  AdminQuizClockRepository(this.client);
  final EventAdminClient client;
  @override
  Future<QuizClock> synchronize() async {
    final roundTrip = Stopwatch()..start();
    final result = await client.call('clock');
    final halfRoundTrip = Duration(microseconds: roundTrip.elapsedMicroseconds ~/ 2);
    return QuizClock(
      serverNow: DateTime.fromMillisecondsSinceEpoch(
        (result['serverNowMs'] as num).toInt(),
        isUtc: true,
      ).add(halfRoundTrip),
      uncertainty: halfRoundTrip,
    );
  }
}

class AdminQuizSponsorRepository implements SponsorRepository {
  AdminQuizSponsorRepository(this.client);
  final EventAdminClient client;
  @override
  Stream<List<Sponsor>> watchAll({bool excludeUnsupportedTiers = false}) =>
      client.watch().map((data) => _list(data, 'sponsors', Sponsor.fromJson));
  @override
  Future<void> save(Sponsor sponsor) async => throw UnsupportedError('スポンサー画面から編集してください。');
  @override
  Future<void> delete(String id) async => throw UnsupportedError('スポンサー画面から編集してください。');
}
