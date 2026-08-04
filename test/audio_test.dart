import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/audio.dart';
import 'package:in_two_lights/level.dart' show kSolveThreshold;

void main() {
  test('gain rises with the weaker wall and never leaves [0,1]', () {
    var prev = -1.0;
    for (var w = 0.0; w <= 1.0001; w += 0.01) {
      final g = droneGain(w);
      expect(g, inInclusiveRange(0.0, 1.0));
      expect(g, greaterThanOrEqualTo(prev),
          reason: 'gain must be monotonic — a dip would tell the player they '
              'got worse while getting closer');
      prev = g;
    }
  });

  test('audible floor below the proximity floor, full bloom at solve', () {
    expect(droneGain(0.0), closeTo(0.06, 1e-9));
    expect(droneGain(kProximityFloor), closeTo(0.06, 1e-9));
    expect(droneGain(kSolveThreshold), closeTo(1.0, 1e-9));
  });

  test('the last stretch carries most of the change', () {
    // Squared, not linear: the top half of the approach must be worth more
    // than the bottom half, or every pose sounds the same.
    final mid = (kProximityFloor + kSolveThreshold) / 2;
    final lower = droneGain(mid) - droneGain(kProximityFloor);
    final upper = droneGain(kSolveThreshold) - droneGain(mid);
    expect(upper, greaterThan(lower * 2));
  });

  test('solved ducks the drone so the chord has room', () {
    expect(droneGain(1.0, solved: true), lessThan(droneGain(kSolveThreshold)));
    expect(droneGain(0.99, solved: true), closeTo(0.25, 1e-9));
  });
}
