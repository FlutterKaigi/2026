import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_support_lt_repository.dart';

void main() {
  test('isolates live registration streams by account uid', () async {
    final registration = SupportLtRegistration(
      uid: 'first',
      displayName: 'First attendee',
      registeredAt: DateTime.utc(2026, 11, 13),
    );
    final repository = FakeSupportLtRepository(registrations: {'first': registration});
    final container = ProviderContainer(
      overrides: [supportLtRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);
    container.listen(supportLtRegistrationProvider('first'), (_, _) {});
    container.listen(supportLtRegistrationProvider('second'), (_, _) {});

    expect(await container.read(supportLtRegistrationProvider('first').future), registration);
    expect(await container.read(supportLtRegistrationProvider('second').future), isNull);
    final second = SupportLtRegistration(
      uid: 'second',
      displayName: 'Second attendee',
      registeredAt: DateTime.utc(2026, 11, 13, 1),
    );
    repository.setRegistration(second);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(supportLtRegistrationProvider('first')).value, registration);
    expect(container.read(supportLtRegistrationProvider('second')).value, second);
  });
}
