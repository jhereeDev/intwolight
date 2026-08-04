import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/daily.dart';
import 'package:in_two_lights/dailies.g.dart';

void main() {
  test('the same date is always the same room', () {
    // The entire social premise. If this ever varies, "everyone got the duck
    // today" stops being true and nobody finds out until it matters.
    for (final d in [
      DateTime(2026, 8, 4),
      DateTime(2027, 1, 1),
      DateTime(2026, 12, 25, 23, 59, 59),
    ]) {
      expect(dailyIndexFor(d), dailyIndexFor(DateTime(d.year, d.month, d.day)));
    }
  });

  test('time of day never changes the room', () {
    for (var h = 0; h < 24; h++) {
      expect(dailyIndexFor(DateTime(2026, 9, 15, h, 30)),
          dailyIndexFor(DateTime(2026, 9, 15)));
    }
  });

  test('every day advances by exactly one, including across DST', () {
    // The bug this exists for: DateTime.difference on LOCAL dates spanning a
    // daylight-saving boundary returns 23 or 25 hours, and .inDays truncates,
    // so a naive implementation repeats or skips a day twice a year. Walking
    // two full years catches it wherever the local zone puts its boundaries.
    var day = DateTime(2026, 8, 4);
    for (var i = 0; i < 730; i++) {
      final next = DateTime(day.year, day.month, day.day + 1);
      final step = (dailyIndexFor(next) - dailyIndexFor(day)) %
          dailyLevels.length;
      expect(step, 1, reason: 'from $day to $next was not one day');
      day = next;
    }
  });

  test('always a valid index, even before day zero', () {
    for (final d in [
      DateTime(2020, 1, 1),
      DateTime(2026, 8, 3),
      DateTime(2099, 6, 30),
    ]) {
      final i = dailyIndexFor(d);
      expect(i, inInclusiveRange(0, dailyLevels.length - 1));
      expect(() => dailyLevelFor(d), returnsNormally);
    }
  });

  test('the pool wraps rather than running out', () {
    final start = DateTime(2026, 8, 4);
    final wrapped =
        DateTime(start.year, start.month, start.day + dailyLevels.length);
    expect(dailyIndexFor(wrapped), dailyIndexFor(start));
  });

  test('a wrap reuses the room but never the record', () {
    // The pool wraps, so day 4 and day 184 are the same puzzle. They are not
    // the same day, and storing by pool index would silently overwrite the
    // earlier result -- so progress is keyed by day number, which never wraps.
    final start = DateTime(2026, 8, 4);
    final wrapped =
        DateTime(start.year, start.month, start.day + dailyLevels.length);
    expect(dailyIndexFor(wrapped), dailyIndexFor(start));
    expect(dailyDayNumber(wrapped), isNot(dailyDayNumber(start)));
    expect(dailyDayNumber(start), 0);
  });

  test('the pool is real content, not a stub', () {
    expect(dailyLevels.length, greaterThanOrEqualTo(90),
        reason: 'a daily that wraps inside a season is not a daily');
    for (final l in dailyLevels) {
      expect(l.hint.trim(), isNotEmpty);
      expect(l.boxes, isNotEmpty);
    }
  });
}
