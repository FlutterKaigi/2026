import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/staff/data/provider/staff_member_repository.dart';
import 'package:app/feature/staff/ui/page/staff_member_list_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('builds the typed staff list route location', () {
    expect(const StaffMemberListRoute().location, '/info/staff');
  });

  testWidgets('renders staff profiles from the repository', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            staffMemberRepositoryProvider.overrideWithValue(
              _FakeStaffMemberRepository([
                _staffMember(
                  id: 'staff-001',
                  name: '運営 太郎',
                  greeting: 'よろしくお願いします！',
                ),
              ]),
            ),
          ],
          child: MaterialApp(
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const StaffMemberListPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('スタッフ'), findsOneWidget);
    expect(find.text('運営 太郎'), findsOneWidget);
    expect(find.text('よろしくお願いします！'), findsOneWidget);
  });

  testWidgets('renders the empty state when no staff profiles exist', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            staffMemberRepositoryProvider.overrideWithValue(
              const _FakeStaffMemberRepository([]),
            ),
          ],
          child: MaterialApp(
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const StaffMemberListPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('スタッフはまだ公開されていません'), findsOneWidget);
  });
}

final class _FakeStaffMemberRepository implements StaffMemberRepository {
  const _FakeStaffMemberRepository(this._staffMembers);

  final List<StaffMember> _staffMembers;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> save(StaffMember staffMember) async {}

  @override
  Stream<List<StaffMember>> watchAll() => Stream.value(_staffMembers);
}

StaffMember _staffMember({
  required String id,
  required String name,
  String? greeting,
}) {
  return StaffMember(
    id: id,
    name: name,
    iconUrl: 'https://example.com/$id.png',
    greeting: greeting,
    order: 1,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
