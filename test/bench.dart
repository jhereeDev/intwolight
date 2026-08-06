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

  // The campaign went from 47 rooms to 247, and `extendedLevels` is a top-level
  // `final` — so the first thing that touches `allLevels` pays for building
  // every mixed-shape piece at once (lathes get revolved, prisms get ear
  // clipped). That cost lands on whoever opens the map first. If this ever
  // reaches a visible fraction of a second, the fix is a lazily-built mesh on
  // Box rather than trimming the level count.
  test('cold cost of building the campaign', () {
    final sw = Stopwatch()..start();
    final n = allLevels.length;
    final pieces = allLevels.fold(0, (a, lv) => a + lv.boxes.length);
    // Force every mesh, which is what the map does when it draws them.
    final tris = allLevels.fold(
        0, (a, lv) => a + lv.boxes.fold(0, (b, p) => b + p.mesh.triCount));
    sw.stop();
    print('campaign: $n levels, $pieces pieces, $tris tris '
        '— built in ${sw.elapsedMilliseconds}ms');
  });
}
