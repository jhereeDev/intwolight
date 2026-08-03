// Not named *_test.dart, so `flutter test` skips it. Run explicitly:
//   flutter test test/bench.dart
// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/forms.dart';
import 'package:in_two_lights/geom.dart';
import 'package:in_two_lights/level.dart';
import 'package:in_two_lights/scene.dart';

double ms(void Function() f, int n) {
  f(); // warm
  final sw = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    f();
  }
  sw.stop();
  return sw.elapsedMicroseconds / n / 1000;
}

void main() {
  test('per-frame cost', () {
    for (final lv in [allLevels[0], ...formLevels]) {
      final rt = LevelRuntime(lv);
      final tris =
          worldMeshes(lv, lv.solution).fold(0, (a, m) => a + m.triCount);

      final union = ms(() {
        unionOutline2D(rt.targetShadowsA());
        unionOutline2D(rt.targetShadowsB());
      }, 20);

      final score = ms(() => rt.score(const Pose(0.3, 0.2, 0.1)), 60);

      final paths = ms(() {
        final w = worldMeshes(lv, const Pose(0.3, 0.2, 0.1));
        for (final m in shadowMeshes(w, toWallA)) {
          shadowPath2D(m);
        }
        for (final m in shadowMeshes(w, toWallB)) {
          shadowPath2D(m);
        }
      }, 60);

      print('${lv.name.padRight(8)} tris=${tris.toString().padLeft(4)}  '
          'union=${union.toStringAsFixed(2)}ms  '
          'score=${score.toStringAsFixed(2)}ms  '
          'paths=${paths.toStringAsFixed(2)}ms  '
          '=> was ${(union + score * 2 + paths).toStringAsFixed(1)}ms/frame, '
          'now ${(score + paths).toStringAsFixed(1)}ms/frame');
    }
  });
}
