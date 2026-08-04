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

  test('ONE missed day is forgiven', () {
    // 8, 9 solved, 10 missed, 11 solved. The gap costs the grace, not the run,
    // and the count is days *played* — 3, not 4 — so it never overstates.
    expect(daily([8, 9, 11]).streakEndingAt(11), 3);
    // Today unplayed and yesterday missed: still protecting 8 and 9, because
    // playing today would close the gap.
    expect(daily([8, 9]).streakEndingAt(11), 2);
  });

  test('two missed days end it', () {
    // 8, 9 solved, 10 AND 11 missed, 12 solved. Grace covers one gap only.
    expect(daily([8, 9, 12]).streakEndingAt(12), 1);
  });

  test('grace is spent once, not once per gap', () {
    // Alternate-day play must not be an unbroken streak forever.
    expect(daily([4, 6, 8, 10]).streakEndingAt(10), 2);
  });

  test('grace is configurable and zero restores the strict rule', () {
    expect(daily([8, 9, 11]).streakEndingAt(11, grace: 0), 1);
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
