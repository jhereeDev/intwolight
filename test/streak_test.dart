import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/progress.dart';

/// A streak is the whole reason a daily is a daily, so the counting rules get
/// pinned rather than eyeballed.
void main() {
  Progress daily(List<int> solvedDays) =>
      Progress({for (final d in solvedDays) d: 0.95},
          storeKey: Progress.dailyKey);

  test('an unbroken run counts', () {
    expect(daily([8, 9, 10]).streakEndingAt(10), 3);
  });

  test('today unplayed still shows the chain being protected', () {
    // Counting from today would read 0 every morning until the player opened
    // the app — a streak that looks already lost is worse than none.
    expect(daily([8, 9, 10]).streakEndingAt(11), 3);
  });

  test('a missed day ends it', () {
    // 8, 9 solved, 10 missed, 11 solved: the run is just today.
    expect(daily([8, 9, 11]).streakEndingAt(11), 1);
    // And with today unplayed and yesterday missed, it is gone.
    expect(daily([8, 9]).streakEndingAt(11), 0);
  });

  test('no days played is zero, not a crash', () {
    expect(daily([]).streakEndingAt(0), 0);
    expect(daily([]).streakEndingAt(500), 0);
  });

  test('solving today extends rather than restarts', () {
    final p = daily([8, 9, 10]);
    expect(p.streakEndingAt(11), 3);
    p.record(11, 0.99);
    expect(p.streakEndingAt(11), 4);
  });

  test('day zero and negative days terminate', () {
    // The daily epoch is day 0 and dates before it are negative, so the walk
    // backwards must not assume it will meet a floor.
    expect(daily([-2, -1, 0]).streakEndingAt(0), 3);
  });
}
