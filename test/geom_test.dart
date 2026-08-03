import 'package:flutter_test/flutter_test.dart';
import 'package:two_suns/geom.dart';
import 'package:two_suns/level.dart';

void main() {
  test('hull drops interior points and keeps the corners', () {
    final h = convexHull(const [
      V2(0, 0), V2(1, 0), V2(1, 1), V2(0, 1), V2(0.5, 0.5), //
    ]);
    expect(h.length, 4);
  });

  test('iou is 1 for identical shapes and 0 for disjoint ones', () {
    List<List<V2>> square(double cx) => [
          convexHull([
            V2(cx - 0.5, -0.5), V2(cx + 0.5, -0.5), //
            V2(cx + 0.5, 0.5), V2(cx - 0.5, 0.5),
          ])
        ];

    expect(iou(rasterize(square(0)), rasterize(square(0))), closeTo(1.0, 1e-9));
    expect(iou(rasterize(square(-1.2)), rasterize(square(1.2))), 0);
  });

  test('overlapping hulls union rather than double-count', () {
    // Two unit squares overlapping by half. Union area is 1.5, not 2.0.
    // Scored against the first square alone: the intersection is that whole
    // square (1.0), so IoU is 1.0/1.5. Double-counting would push it lower.
    final pair = [
      convexHull(
          const [V2(-0.5, -0.5), V2(0.5, -0.5), V2(0.5, 0.5), V2(-0.5, 0.5)]),
      convexHull(const [V2(0, -0.5), V2(1, -0.5), V2(1, 0.5), V2(0, 0.5)]),
    ];
    expect(iou(rasterize(pair), rasterize([pair.first])),
        closeTo(1.0 / 1.5, 0.02));
  });

  // The one that protects the design: every level must be solvable at its own
  // stated solution, and must not already be solved when you open it.
  group('levels', () {
    for (final lv in levels) {
      test('${lv.name} scores 1.0 at its solution pose', () {
        final s = LevelRuntime(lv).score(lv.solution);
        expect(s.a, closeTo(1.0, 1e-9));
        expect(s.b, closeTo(1.0, 1e-9));
        expect(s.solved, isTrue);
      });

      test('${lv.name} is not already solved at the starting pose', () {
        expect(LevelRuntime(lv).score(const Pose(0, 0, 0)).solved, isFalse);
      });
    }
  });
}
