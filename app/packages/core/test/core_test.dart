import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  group('expiryStatus', () {
    final today = DateTime(2026, 10, 15, 22, 30);
    ExpiryStatus at(int y, int m, int d) =>
        expiryStatus(today: today, expiresOn: DateTime(y, m, d));

    test('classifies by calendar day, ignoring time of day', () {
      expect(at(2026, 10, 13), const ExpiryStatus(ExpiryLevel.overdue, -2));
      expect(at(2026, 10, 15), const ExpiryStatus(ExpiryLevel.today, 0));
      expect(at(2026, 10, 16), const ExpiryStatus(ExpiryLevel.tomorrow, 1));
      expect(at(2026, 10, 18), const ExpiryStatus(ExpiryLevel.soon, 3));
      expect(at(2026, 10, 19), const ExpiryStatus(ExpiryLevel.later, 4));
    });

    test('crosses month and year ends', () {
      final s = expiryStatus(today: DateTime(2026, 12, 31), expiresOn: DateTime(2027, 1, 1));
      expect(s.level, ExpiryLevel.tomorrow);
    });

    test('urgent covers everything except later', () {
      expect(at(2026, 10, 18).isUrgent, isTrue);
      expect(at(2026, 10, 25).isUrgent, isFalse);
    });
  });

  group('reminderTimes', () {
    test('D-3, D-1 and the day at 9:00, skipping past ones', () {
      final times = reminderTimes(
        now: DateTime(2026, 10, 20, 10),
        expiresOn: DateTime(2026, 10, 22),
      );
      expect(times, [DateTime(2026, 10, 21, 9), DateTime(2026, 10, 22, 9)]);
    });
  });

  group('search', () {
    test('initialsOf keeps non-Hangul characters', () {
      expect(initialsOf('건전지 AA'), 'ㄱㅈㅈ AA');
    });

    test('initial-consonant query matches Korean names', () {
      expect(matchesQuery('가위', 'ㄱㅇ'), isTrue);
      expect(matchesQuery('건전지 AA', 'ㄱㅈ'), isTrue);
      expect(matchesQuery('가위', 'ㄴㅇ'), isFalse);
    });

    test('plain text is a case-insensitive substring match', () {
      expect(matchesQuery('AA Batteries', 'batt'), isTrue);
      expect(matchesQuery('여름 이불', '여름이불'), isTrue);
      expect(matchesQuery('Scissors', 'tape'), isFalse);
      expect(matchesQuery('anything', '  '), isTrue);
    });
  });

  group('location codes', () {
    test('space prefix from Latin letters, numbered when taken', () {
      expect(spacePrefix('Living room', {}), 'LIV');
      expect(spacePrefix('Living room', {'LIV'}), 'LI2');
      expect(spacePrefix('거실', {}), 'SP1');
      expect(spacePrefix('주방', {'SP1'}), 'SP2');
    });

    test('container and child codes', () {
      expect(containerCode('LIV', 0), 'LIV-A1');
      expect(containerCode('LIV', 8), 'LIV-A9');
      expect(containerCode('LIV', 9), 'LIV-B1');
      expect(childCode('LIV-A1', 1), 'LIV-A1-2');
    });
  });
}
