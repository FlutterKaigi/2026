import 'dart:async';
import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:dashboard/core/event_environment/event_admin_repositories.dart';
import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:dashboard/feature/support_lt/data/provider/support_lt_state.dart';
import 'package:dashboard/feature/support_lt/ui/page/support_lt_page.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Admin extends Fake implements User {
  @override
  String get uid => 'admin';
}

Map<String, dynamic> snapshot(String code) => {
  'code': {'code': code, 'issuedAt': '2026-10-20T10:00:00Z'},
  'registrations': <Map<String, dynamic>>[],
};

void main() {
  testWidgets('rotation hides the old code until the refreshed code arrives', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final delayedRead = Completer<Map<String, dynamic>>();
    var serverCode = '123456';
    var reads = 0;
    final client = EventAdminClient(
      environment: Flavor.dev,
      view: {'view': 'supportLt'},
      pollInterval: const Duration(days: 1),
      request: (request) async {
        if (request['action'] == 'issueSupportLtCode') {
          serverCode = '654321';
          return {'code': serverCode, 'issuedAt': 0};
        }
        reads++;
        return reads == 1 ? snapshot(serverCode) : delayedRead.future;
      },
    );
    addTearDown(client.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventAdminClientProvider.overrideWithValue(client),
          supportLtRepositoryProvider.overrideWithValue(AdminSupportLtRepository(client)),
          authStateProvider.overrideWith((_) => Stream.value(Admin())),
        ],
        child: const MaterialApp(home: Scaffold(body: SupportLtPage())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('123456'), findsOneWidget);
    await tester.tap(find.text('コードを再発行'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再発行する'));
    await tester.pump();
    await tester.pump();
    expect(serverCode, '654321');
    expect(find.text('登録コードを再発行しました'), findsNothing);
    expect(find.text('123456'), findsNothing);
    expect(find.text('654321'), findsNothing);
    expect(find.byWidgetPredicate((widget) => widget is IconButton && widget.tooltip == 'コードをコピー'), findsNothing);
    expect(find.text('発行中…'), findsOneWidget);
    delayedRead.complete(snapshot(serverCode));
    await tester.pumpAndSettle();
    expect(find.text('654321'), findsOneWidget);
    expect(find.text('登録コードを再発行しました'), findsOneWidget);
    expect(find.text('123456'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
