import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the scrollbar at the viewport edge for constrained content', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AppScrollbar(
          child: Center(
            child: ConstrainedBox(
              key: const ValueKey('scrollbar-content'),
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                children: const [
                  SizedBox(height: 1600),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final scrollbarRect = tester.getRect(find.byType(Scrollbar));
    final contentRect = tester.getRect(find.byKey(const ValueKey('scrollbar-content')));
    expect(scrollbarRect.width, 1200);
    expect(scrollbarRect.right, 1200);
    expect(contentRect.width, 760);
  });
}
