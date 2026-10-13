/// Remote Config parameter keys.
///
/// Every key listed here must also have an entry in [remoteConfigDefaults] so
/// that reads stay predictable before the first fetch, on the develop flavor
/// (which has no Remote Config backend) and whenever a fetch fails.
abstract final class RemoteConfigKeys {
  /// Whether the conference-day features are shown. Stored as a bool.
  static const eventFeaturesEnabled = 'event_features_enabled';

  /// HTTPS URL of the general survey. Empty means the survey is hidden.
  static const surveyUrl = 'survey_url';

  /// Forced-update policy encoded as a JSON object. Stored as a String.
  static const forceUpdate = 'force_update';
}

/// Policy served for [RemoteConfigKeys.forceUpdate] until a fetch succeeds.
///
/// `0.0.0` is below every shipped version, so the default never forces an
/// update. The App Store URL is only known after the first release, hence the
/// empty string on iOS.
const defaultForceUpdateJson =
    '{"minimum_version":{"ios":"0.0.0","android":"0.0.0"},'
    '"store_urls":{"ios":"",'
    '"android":"https://play.google.com/store/apps/details?id=jp.flutterkaigi.conf2026"},'
    '"message":{"ja":"","en":""}}';

/// Values applied with `setDefaults`, returned whenever a key has no fetched
/// value.
const remoteConfigDefaults = <String, Object>{
  RemoteConfigKeys.eventFeaturesEnabled: true,
  RemoteConfigKeys.surveyUrl: '',
  RemoteConfigKeys.forceUpdate: defaultForceUpdateJson,
};
