import 'package:app/core/designsystem/theme/app_gradients.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// Inner padding of [BrandHeaderCard] below the brand band.
const brandHeaderCardPadding = 24.0;

/// Height of the brand gradient band, matching the event overview card on the
/// event tab.
const _brandBandHeight = 152.0;

/// Outlined card topped by the brand gradient band and the FlutterKaigi logo.
///
/// Shared by the sign-in card and the Support LT registration states so these
/// entry flows read as the same branded surface.
class BrandHeaderCard extends StatelessWidget {
  const BrandHeaderCard({required this.child, super.key});

  /// Content laid out below the band with [brandHeaderCardPadding].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      // カード内の操作をそれぞれ個別のセマンティクスノードとして残す。
      semanticContainer: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _brandBandHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: AppGradients.brand),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'res/assets/shuriken-logo.png',
                  fit: BoxFit.contain,
                  semanticLabel: t.eventInfo.logoSemanticLabel,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(brandHeaderCardPadding),
            child: child,
          ),
        ],
      ),
    );
  }
}
