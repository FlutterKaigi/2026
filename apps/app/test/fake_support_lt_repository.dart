import 'dart:async';

import 'package:data/data.dart';

final class FakeSupportLtRepository implements SupportLtRepository {
  FakeSupportLtRepository({Map<String, SupportLtRegistration> registrations = const {}})
    : _registrations = Map.unmodifiable(registrations);

  final _controller = StreamController<void>.broadcast();
  Map<String, SupportLtRegistration> _registrations;
  List<String> submittedCodes = const [];
  List<String> watchedUids = const [];
  Completer<void>? pendingRegistration;
  Exception? nextRegisterError;
  Exception? watchError;

  /// Account that [register] registers.
  String registeringUid = 'uid-1';

  @override
  Stream<SupportLtRegistration?> watchRegistration(String uid) {
    watchedUids = [...watchedUids, uid];
    if (watchError case final error?) {
      return Stream.error(error);
    }
    return Stream.multi((listener) {
      final subscription = _controller.stream.listen(
        (_) => listener.add(_registrations[uid]),
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = subscription.cancel;
      listener.add(_registrations[uid]);
    });
  }

  void setRegistration(SupportLtRegistration registration) {
    _registrations = {..._registrations, registration.uid: registration};
    _controller.add(null);
  }

  /// Fails every active registration subscription.
  void emitWatchError(Object error) => _controller.addError(error);

  @override
  Future<void> register(String code) async {
    submittedCodes = [...submittedCodes, code];
    if (nextRegisterError case final error?) {
      nextRegisterError = null;
      throw error;
    }
    await pendingRegistration?.future;
    setRegistration(
      SupportLtRegistration(
        uid: registeringUid,
        displayName: 'Attendee',
        registeredAt: DateTime.utc(2026, 11, 13, 7),
      ),
    );
  }

  @override
  Stream<List<SupportLtRegistration>> watchRegistrations() => throw UnimplementedError();

  @override
  Stream<SupportLtCode?> watchCode() => throw UnimplementedError();

  @override
  Future<void> issueCode({bool rotate = false}) => throw UnimplementedError();

  void dispose() => unawaited(_controller.close());
}
