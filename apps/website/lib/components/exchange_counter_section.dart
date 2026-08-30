import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/firestore.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

/// Live count of `counters/profileExchanges`, fetched client-side from the
/// Firestore REST API (see the inline script below) rather than baked in at
/// build time — the design doc calls out that a build-time value would go
/// stale the moment the conference starts producing exchanges. Stays
/// hidden (`display: none`, flipped by the script on success) until the
/// fetch actually succeeds, and stays hidden forever if it fails, so a
/// blocked or errored request never leaves a broken or stuck-at-zero
/// section on the page.
class ExchangeCounterSection extends StatelessComponent {
  const ExchangeCounterSection({super.key});

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);

    return section(
      id: 'exchange-counter',
      classes: 'exchange-counter',
      [
        div(classes: 'exchange-counter__card', [
          p(classes: 'exchange-counter__title', [.text(strings.exchangeCounterTitle)]),
          p(classes: 'exchange-counter__value', [
            span(id: 'exchange-counter-value', []),
            .text(' '),
            span(classes: 'exchange-counter__unit', [.text(strings.exchangeCounterUnit)]),
          ]),
          p(classes: 'exchange-counter__caption', [.text(strings.exchangeCounterCaption)]),
        ]),
        script(content: _script),
      ],
    );
  }

  /// Fetches `counters/profileExchanges` from the public Firestore REST API
  /// (unauthenticated — `firestore.rules` allows `read` on `counters/*` for
  /// exactly this) and reveals `#exchange-counter` with the count filled in
  /// on success. Any failure (network error, non-200, App Check enforcement
  /// blocking the request, an unexpected response shape) is swallowed and
  /// simply leaves the section hidden — see the class doc comment.
  static String get _script =>
      '''
(function () {
  var url = "https://firestore.googleapis.com/v1/projects/$firestoreProjectId/databases/(default)/documents/counters/profileExchanges";
  fetch(url, { headers: { Accept: "application/json" } })
    .then(function (res) {
      if (!res.ok) throw new Error("status " + res.status);
      return res.json();
    })
    .then(function (doc) {
      var count = doc && doc.fields && doc.fields.count;
      var value = count && (count.integerValue !== undefined ? count.integerValue : count.doubleValue);
      if (value === undefined || value === null) throw new Error("missing count");
      var section = document.getElementById("exchange-counter");
      var valueEl = document.getElementById("exchange-counter-value");
      if (!section || !valueEl) return;
      valueEl.textContent = Number(value).toLocaleString();
      section.classList.add("exchange-counter--visible");
    })
    .catch(function () {
      // Left hidden — see ExchangeCounterSection's doc comment.
    });
})();
''';

  @css
  static List<StyleRule> get styles => [
    css('.exchange-counter', [
      css('&').styles(
        display: .none,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 48.px),
        backgroundColor: onBrand,
      ),
      css('&.exchange-counter--visible').styles(display: .flex),
      css('.exchange-counter__card').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        gap: Gap.row(4.px),
        textAlign: .center,
      ),
      css('.exchange-counter__title').styles(
        color: onSurfaceVariant,
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {'font-size': '0.875rem', 'margin': '0', 'letter-spacing': '0.02em'},
      ),
      css('.exchange-counter__value').styles(
        display: .flex,
        alignItems: .baseline,
        gap: Gap.column(6.px),
        color: deepPurple,
        fontFamily: displayFontFamily,
        fontWeight: .w700,
        raw: const {'font-size': 'clamp(2rem, 6vw, 3rem)', 'margin': '0'},
      ),
      css('.exchange-counter__unit').styles(
        color: onSurfaceVariant,
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {'font-size': '1rem'},
      ),
      css('.exchange-counter__caption').styles(
        color: onSurfaceVariant,
        fontFamily: uiFontFamily,
        raw: const {'font-size': '0.8125rem', 'margin': '0'},
      ),
    ]),
  ];
}
