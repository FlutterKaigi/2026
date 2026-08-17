import 'package:app/core/ui/widget/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppNetworkImage prefers HTML image elements on web by default', () {
    const image = AppNetworkImage(imageUrl: 'https://example.com/image.png');

    expect(image.webHtmlElementStrategy, WebHtmlElementStrategy.prefer);
  });

  testWidgets('AppNetworkAvatar renders its fallback without an image URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppNetworkAvatar(
          imageUrl: null,
          fallback: Icon(Icons.person_outline),
        ),
      ),
    );

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byType(AppNetworkImage), findsNothing);
  });

  testWidgets('AppNetworkAvatar routes image URLs through AppNetworkImage', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppNetworkAvatar(
          imageUrl: ' https://example.com/avatar.png ',
          fallback: Icon(Icons.person_outline),
        ),
      ),
    );

    final image = tester.widget<AppNetworkImage>(
      find.byType(AppNetworkImage),
    );
    expect(image.imageUrl, 'https://example.com/avatar.png');
    expect(image.webHtmlElementStrategy, WebHtmlElementStrategy.prefer);
  });

  testWidgets('AppNetworkAvatar keeps its visible image square under a shorter height constraint', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 56,
            height: 48,
            child: AppNetworkAvatar(
              radius: 28,
              imageUrl: null,
              fallback: Icon(Icons.person_outline),
            ),
          ),
        ),
      ),
    );

    final visibleAvatarSize = tester.getSize(find.byType(ClipOval));
    expect(visibleAvatarSize.width, visibleAvatarSize.height);
    expect(visibleAvatarSize, const Size.square(48));
  });
}
