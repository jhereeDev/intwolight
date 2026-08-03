import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/forms.dart';
import 'package:in_two_lights/level.dart';

void main() {
  test('every authored form solves at its pose and not at the opening one', () {
    for (final lv in formLevels) {
      final rt = LevelRuntime(lv);
      final at = rt.score(lv.solution);
      expect(at.a, greaterThan(0.99), reason: '${lv.name} wall A');
      expect(at.b, greaterThan(0.99), reason: '${lv.name} wall B');
      expect(rt.score(const Pose(0, 0, 0)).solved, isFalse,
          reason: '${lv.name} opens already solved');
    }
  });

  test('no form is a bare surface of revolution', () {
    // A lathe about Y has the same silhouette at every yaw, so yaw would carry
    // no information and half the controls would do nothing. Every form must
    // break that symmetry — this is the test that catches a level which
    // secretly solves itself.
    for (final lv in formLevels) {
      final rt = LevelRuntime(lv);
      final s = lv.solution;
      // A half-turn is deliberately NOT tested: the bodies are flattened
      // along Z, so yaw + pi maps the shape onto itself and those levels
      // legitimately have two solutions.
      var moved = false;
      for (final d in [0.7, 1.4, 2.2]) {
        final off = rt.score(Pose(s.yaw + d, s.pitch, s.hinge));
        if (!off.solved) moved = true;
      }
      expect(moved, isTrue,
          reason: '${lv.name} still solves after a large yaw change — it is '
              'rotationally symmetric and cannot be a puzzle');
    }
  });
}
