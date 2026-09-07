import 'package:app/core/ui/launch_external_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a message when the platform returns false', (tester) async {
    await _pumpLauncher(
      tester,
      launcher: (_) async => false,
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.text('Could not open link'), findsOneWidget);
  });

  testWidgets('shows a message when the platform throws', (tester) async {
    await _pumpLauncher(
      tester,
      launcher: (_) async => throw StateError('platform failure'),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.text('Could not open link'), findsOneWidget);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required ExternalUrlLauncher launcher,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => launchExternalUrl(
            context,
            uri: Uri.parse('https://example.com'),
            failureMessage: 'Could not open link',
            launcher: launcher,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);
