import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_staff.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';
import 'staff_section/staff_card.dart';

/// Home-page Staff section: a centered, wrapping grid of the members building
/// FlutterKaigi 2026, following the Figma layout (node 656:2774).
///
/// The data comes from `generated_staff.dart`, generated at build time from
/// the `staffMembers` Firestore collection by `tool/generate_staff.dart`.
class StaffSection extends StatelessComponent {
  const StaffSection({super.key});

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    // No staff yet (e.g. an empty collection): omit the section entirely
    // rather than rendering a heading over an empty grid.
    if (generatedStaff.isEmpty) return Component.fragment(const []);

    return section(id: 'staff', classes: 'staff-section', [
      div(classes: 'staff-section__inner', [
        div(classes: 'staff-section__header', [
          h2(classes: 'staff-section__title', [.text(strings.staffTitle)]),
          p(classes: 'staff-section__subtitle', [.text(strings.staffSubtitle)]),
        ]),
        div(classes: 'staff-section__grid', [
          for (final entry in generatedStaff) StaffCard(entry: entry),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.staff-section', [
      // White background so the section alternates with the tinted Sponsors
      // section right above it (per the Figma design).
      css('&').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 128.px),
        backgroundColor: onBrand,
      ),
      css('.staff-section__inner').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        width: 100.percent,
        gap: Gap.row(64.px),
        raw: const {'max-width': '1232px'},
      ),
      css('.staff-section__header', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          gap: Gap.row(16.px),
          textAlign: .center,
        ),
        css('.staff-section__title').styles(
          color: const Color('#1D1A25'),
          fontFamily: displayFontFamily,
          fontWeight: .w700,
          raw: const {
            'font-size': 'clamp(1.75rem, 4vw, 2.5rem)',
            'line-height': '1.2',
          },
        ),
        css('.staff-section__subtitle').styles(
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          fontWeight: .w400,
          raw: const {
            'font-size': 'clamp(0.95rem, 2vw, 1.125rem)',
            'line-height': '1.5',
          },
        ),
      ]),
      css('.staff-section__grid').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        raw: const {'flex-wrap': 'wrap', 'gap': '48px 32px'},
      ),
    ]),

    // Tighten vertical rhythm on smaller screens (matches SponsorsSection).
    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('.staff-section').styles(
        padding: .symmetric(horizontal: 24.px, vertical: 80.px),
      ),
      css('.staff-section__inner').styles(gap: Gap.row(48.px)),
    ]),
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.staff-section').styles(
        padding: .symmetric(horizontal: 16.px, vertical: 56.px),
      ),
      css('.staff-section__grid').styles(
        raw: const {'gap': '32px 16px'},
      ),
    ]),
  ];
}
