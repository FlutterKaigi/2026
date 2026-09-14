import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts post links from different SNS hosts', () {
    for (final url in [
      'https://x.com/flutterkaigi/status/123',
      'https://www.instagram.com/p/ABC/?img_index=1',
      'https://bsky.app/profile/example.test/post/abc',
      'https://social.example.org/@attendee/123',
      'http://social.example.org/posts/123',
    ]) {
      expect(SnsPostRegistration.isValidUrl(url), isTrue, reason: url);
    }
  });

  test('rejects missing, unsafe, malformed, homepage and oversized URLs', () {
    for (final url in [
      '',
      'x.com/attendee/status/123',
      'javascript:alert(1)',
      'https://x.com',
      'https://x.com/',
      'https://x.com/?query=post',
      'https://x.com/a b',
      'https://user:password@x.com/post/123',
      'https://localhost/post/123',
      'https://x.com/${'a' * 2048}',
    ]) {
      expect(SnsPostRegistration.isValidUrl(url), isFalse, reason: url);
    }
  });

  test('persists one registration, restores it, and updates without duplicating', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreSnsPostRepository(firestore: firestore);
    expect(await repository.watch('attendee').first, isNull);
    await repository.save(uid: 'attendee', url: ' https://x.com/test/status/123 ', companion: SnsPostCompanion.staff);
    final restored = await FirestoreSnsPostRepository(firestore: firestore).watch('attendee').first;
    expect(restored?.url, 'https://x.com/test/status/123');
    expect(restored?.companion, SnsPostCompanion.staff);
    final first = await firestore.collection('snsPostRegistrations').doc('attendee').get();
    expect(first.data()?['updatedAt'], isA<Timestamp>());

    await repository.save(
      uid: 'attendee',
      url: 'https://bsky.app/profile/test/post/456',
      companion: SnsPostCompanion.speaker,
    );
    final updated = await repository.watch('attendee').first;
    expect(updated?.companion, SnsPostCompanion.speaker);
    expect(updated?.url, 'https://bsky.app/profile/test/post/456');
    expect((await firestore.collection('snsPostRegistrations').get()).size, 1);
    expect(await repository.watch('another-attendee').first, isNull);
  });

  test('invalid writes fail before reaching Firestore', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreSnsPostRepository(firestore: firestore);
    expect(
      () => repository.save(uid: 'attendee', url: 'javascript:alert(1)', companion: SnsPostCompanion.staff),
      throwsFormatException,
    );
    expect((await firestore.collection('snsPostRegistrations').get()).size, 0);
  });

  test('malformed saved data is an error, never a completed stamp', () async {
    final firestore = FakeFirebaseFirestore();
    final document = firestore.collection('snsPostRegistrations').doc('attendee');
    final valid = <String, dynamic>{
      'url': 'https://x.com/test/status/123',
      'companion': 'staff',
      'updatedAt': Timestamp.now(),
    };
    for (final invalid in [
      {...valid, 'companion': 'anything'},
      {...valid, 'companion': null},
      {...valid, 'url': 'javascript:alert(1)'},
      {...valid, 'updatedAt': null},
    ]) {
      await document.set(invalid);
      await expectLater(
        FirestoreSnsPostRepository(firestore: firestore).watch('attendee').first,
        throwsFormatException,
      );
    }
  });
}
