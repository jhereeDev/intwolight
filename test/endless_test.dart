import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/endless.dart';
import 'package:in_two_lights/level.dart';
import 'package:in_two_lights/rng.dart';

/// Endless rooms are generated on the device and shared by number, so the two
/// properties that matter are that a room is the SAME everywhere and that it is
/// actually playable. Both are pinned here rather than assumed.
void main() {
  test('the RNG sequence is fixed forever', () {
    // If this test ever fails, every player's room N has silently changed and
    // every shared room number now points somewhere else. Do not "update the
    // expected values" — work out why the sequence moved.
    //
    // These are measured from the implementation, not chosen. They assume
    // 64-bit integer wraparound, which holds on the Dart VM (iOS/Android) and
    // does NOT on dart2js — endless would need a different generator on web.
    final r = StableRandom(12345);
    final got = [for (var i = 0; i < 4; i++) r.nextDouble().toStringAsFixed(12)];
    expect(got, [
      '0.332795217252',
      '0.006751867246',
      '0.902467040629',
      '0.272684357116',
    ]);
  });

  test('the same seed replays exactly', () {
    final a = StableRandom(99), b = StableRandom(99);
    for (var i = 0; i < 50; i++) {
      expect(a.nextDouble(), b.nextDouble());
      expect(a.nextInt(7), b.nextInt(7));
      expect(a.nextBool(), b.nextBool());
    }
  });

  test('nextInt stays in range and uses the whole range', () {
    final r = StableRandom(5);
    final seen = <int>{};
    for (var i = 0; i < 400; i++) {
      final v = r.nextInt(3);
      expect(v, inInclusiveRange(0, 2));
      seen.add(v);
    }
    expect(seen, {0, 1, 2}, reason: 'a value never drawn means a biased range');
  });

  test('room N is identical every time it is asked for', () {
    for (final n in [1, 9, 30]) {
      final a = endlessLevelFor(n);
      final b = endlessLevelFor(n);
      expect(a.boxes.length, b.boxes.length);
      expect(a.solution.yaw, b.solution.yaw);
      expect(a.solution.pitch, b.solution.pitch);
      expect(a.solution.hinge, b.solution.hinge);
      expect(a.hasHinge, b.hasHinge);
    }
  });

  test('neighbouring rooms are different rooms', () {
    final a = endlessLevelFor(10), b = endlessLevelFor(11);
    expect(a.solution.yaw, isNot(b.solution.yaw));
  });

  test('the joint count ramps and then holds', () {
    expect(bandFor(1), 0);
    expect(bandFor(8), 0);
    expect(bandFor(9), 1);
    expect(bandFor(24), 1);
    expect(bandFor(25), 2);
    expect(bandFor(9999), 2);
  });

  test('every sampled room is solvable and does not open solved', () {
    // One per band. Generation is ~1s for a hinged room, so this samples
    // rather than sweeps.
    for (final n in [1, 5, 12, 30]) {
      final lv = endlessLevelFor(n);
      final rt = LevelRuntime(lv);
      final at = rt.score(lv.solution);
      expect(at.a, greaterThan(0.99), reason: 'room $n wall A');
      expect(at.b, greaterThan(0.99), reason: 'room $n wall B');
      expect(rt.score(const Pose(0, 0, 0)).solved, isFalse,
          reason: 'room $n opens already solved');
      expect(lv.hasHinge, bandFor(n) > 0, reason: 'room $n joint count');
    }
  });
}
