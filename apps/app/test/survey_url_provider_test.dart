import 'package:app/core/remote_config/remote_config_keys.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/remote_config/survey_url_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_remote_config_repository.dart';

void main() {
  ProviderContainer createContainer(FakeRemoteConfigRepository repository) {
    final container = ProviderContainer(
      overrides: [
        remoteConfigRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);
    container.listen(surveyUrlProvider, (_, _) {});
    return container;
  }

  test('ships an empty survey URL and hides the survey by default', () {
    final container = createContainer(FakeRemoteConfigRepository());

    expect(RemoteConfigKeys.surveyUrl, 'survey_url');
    expect(remoteConfigDefaults[RemoteConfigKeys.surveyUrl], '');
    expect(container.read(surveyUrlProvider), isNull);
  });

  for (final (label, value) in [
    ('empty', ''),
    ('whitespace only', ' \t\n '),
    ('plain text', 'not a URL'),
    ('relative path', '/survey'),
    ('protocol relative URL', '//forms.example.com/survey'),
    ('malformed host', 'https://[invalid'),
    ('spaces in the host', 'https://not a host/survey'),
    ('encoded spaces in the host', 'https://%20/survey'),
    ('control characters in the host', 'https://forms.example.com\n.evil/survey'),
    ('invalid port', 'https://forms.example.com:invalid/survey'),
    ('out-of-range port', 'https://forms.example.com:99999/survey'),
    ('zero port', 'https://forms.example.com:0/survey'),
    ('without a host', 'https:///survey'),
    ('without an authority', 'https:survey'),
    ('HTTP', 'http://forms.example.com/survey'),
    ('JavaScript', 'javascript:alert(1)'),
    ('with credentials', 'https://user:password@forms.example.com/survey'),
  ]) {
    test('returns null for a survey URL that is $label', () {
      final container = createContainer(
        FakeRemoteConfigRepository(
          initialValues: {RemoteConfigKeys.surveyUrl: value},
        ),
      );

      expect(container.read(surveyUrlProvider), isNull);
    });
  }

  for (final (value, expected) in [
    (
      'https://forms.example.com/survey',
      'https://forms.example.com/survey',
    ),
    (
      ' \nhttps://forms.example.com/survey?source=app#answer\t ',
      'https://forms.example.com/survey?source=app#answer',
    ),
    (
      'https://forms.example.com:8443/survey',
      'https://forms.example.com:8443/survey',
    ),
  ]) {
    test('returns the configured HTTPS survey URL $value', () {
      final container = createContainer(
        FakeRemoteConfigRepository(
          initialValues: {RemoteConfigKeys.surveyUrl: value},
        ),
      );

      expect(container.read(surveyUrlProvider), Uri.parse(expected));
    });
  }

  test('reacts to consecutive Remote Config activations', () async {
    final repository = FakeRemoteConfigRepository();
    final container = createContainer(repository);
    expect(container.read(surveyUrlProvider), isNull);

    const firstUrl = 'https://forms.example.com/first';
    repository.setValue(RemoteConfigKeys.surveyUrl, firstUrl);
    await pumpEventQueue();
    expect(container.read(surveyUrlProvider), Uri.parse(firstUrl));

    const secondUrl = 'https://forms.example.com/second';
    repository.setValue(RemoteConfigKeys.surveyUrl, secondUrl);
    await pumpEventQueue();
    expect(container.read(surveyUrlProvider), Uri.parse(secondUrl));

    repository.setValue(RemoteConfigKeys.surveyUrl, '');
    await pumpEventQueue();
    expect(container.read(surveyUrlProvider), isNull);
  });
}
