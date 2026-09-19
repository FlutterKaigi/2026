import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('splitIntoTeamSizes', () {
    test('0 人は空リストを返す', () {
      expect(splitIntoTeamSizes(0), isEmpty);
      expect(splitIntoTeamSizes(-3), isEmpty);
    });

    test('n <= 5 は 1 チームにまとめる', () {
      expect(splitIntoTeamSizes(1), [1]);
      expect(splitIntoTeamSizes(2), [2]);
      expect(splitIntoTeamSizes(3), [3]);
      expect(splitIntoTeamSizes(4), [4]);
      expect(splitIntoTeamSizes(5), [5]);
    });

    test('n % 4 == 0 はすべて 4 人チーム', () {
      expect(splitIntoTeamSizes(8), [4, 4]);
      expect(splitIntoTeamSizes(12), [4, 4, 4]);
      expect(splitIntoTeamSizes(80), List<int>.filled(20, 4));
    });

    test('n % 4 == 1 (n >= 6) は 4 人チームを 1 つ減らして 5 人チーム 1 つ', () {
      expect(splitIntoTeamSizes(9), [4, 5]);
      expect(splitIntoTeamSizes(13), [4, 4, 5]);
      expect(splitIntoTeamSizes(17), [4, 4, 4, 5]);
    });

    test('n % 4 == 2 (n >= 6) は 4 人チームを 1 つ減らして 3 人 + 3 人', () {
      expect(splitIntoTeamSizes(6), [3, 3]);
      expect(splitIntoTeamSizes(10), [4, 3, 3]);
      expect(splitIntoTeamSizes(14), [4, 4, 3, 3]);
    });

    test('n % 4 == 3 は 3 人チームを 1 つ追加', () {
      expect(splitIntoTeamSizes(7), [4, 3]);
      expect(splitIntoTeamSizes(11), [4, 4, 3]);
      expect(splitIntoTeamSizes(15), [4, 4, 4, 3]);
    });

    test('各チームは常に 3〜5 人（n >= 6 のとき）', () {
      for (var n = 6; n <= 100; n++) {
        final sizes = splitIntoTeamSizes(n);
        for (final size in sizes) {
          expect(size, inInclusiveRange(3, 5), reason: 'n=$n で $size 人チームが発生した');
        }
      }
    });

    test('分割後の合計は常に n に一致する', () {
      for (var n = 0; n <= 100; n++) {
        final sizes = splitIntoTeamSizes(n);
        final total = sizes.fold<int>(0, (sum, size) => sum + size);
        expect(total, n, reason: 'n=$n の合計が一致しない');
      }
    });
  });
}
