import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/generator.dart';
import 'package:in_two_lights/geom.dart';
import 'package:in_two_lights/level.dart';
import 'package:in_two_lights/levels_ext.g.dart';

/// The shape vocabulary the mixed chapters are cut from.
///
/// A degenerate piece does not crash — it casts an empty or a wrong shadow,
/// the level still passes rejection sampling on its *other* pieces, and it
/// ships as a room with an invisible arm. So each shape is checked for the
/// things a bad mesh actually gets wrong: no triangles, zero area, or a size
/// wildly different from the one asked for.
void main() {
  const at = V3(0.3, -0.2, 0.15);
  const size = V3(0.2, 0.6, 0.18);

  group('every shape builds a usable piece', () {
    for (final shape in Shape.values) {
      test('$shape', () {
        final b = piece(shape, at, size);
        final m = b.mesh;

        expect(m.triCount, greaterThan(0), reason: 'no triangles');
        expect(m.verts, isNotEmpty);
        for (final v in m.verts) {
          expect(v.x.isFinite && v.y.isFinite && v.z.isFinite, isTrue,
              reason: 'non-finite vertex in $shape');
        }

        // Extent along the piece's own length. Every shape reads size.y that
        // way, boxes included — see the comment in _mixedCandidate.
        final ys = m.verts.map((v) => v.y);
        final span = ys.reduce((a, b) => a > b ? a : b) -
            ys.reduce((a, b) => a < b ? a : b);
        expect(span, closeTo(size.y * 2, size.y),
            reason: '$shape is not roughly the length it was asked for');

        // Centred on `at`, not left at the origin — a piece built in its own
        // coordinates and never moved would stack every arm on top of the
        // first and the chain would collapse into one blob.
        final cy = (ys.reduce((a, b) => a > b ? a : b) +
                ys.reduce((a, b) => a < b ? a : b)) /
            2;
        expect(cy, closeTo(at.y, size.y * 0.6), reason: '$shape is not at `at`');
      });
    }
  });

  test('axis actually reorients the piece', () {
    // A rod is built along Y. On axis 0 it must become long in X instead —
    // without this the whole vocabulary would point the same way and the
    // generated rooms would share a family resemblance.
    double span(Box b, double Function(V3) f) {
      final xs = b.mesh.verts.map(f);
      return xs.reduce((a, c) => a > c ? a : c) -
          xs.reduce((a, c) => a < c ? a : c);
    }

    final alongY = piece(Shape.rod, const V3(0, 0, 0), size, axis: 1);
    final alongX = piece(Shape.rod, const V3(0, 0, 0), size, axis: 0);

    expect(span(alongY, (v) => v.y), greaterThan(span(alongY, (v) => v.x)));
    expect(span(alongX, (v) => v.x), greaterThan(span(alongX, (v) => v.y)));
  });

  test('the concave shapes really do bite a notch out of their hull', () {
    // ell, tee and chevron exist to put a concavity in a silhouette. A box's
    // shadow IS its convex hull, which is why hulls were enough at M0; if
    // these filled their hulls too they would be doing nothing a box cannot,
    // and the union-of-triangles machinery would be dead weight.
    //
    // Measured by rasterising the real projected shadow against the hull of
    // the same points, using the same masks the scorer uses.
    for (final shape in Shape.values) {
      final m = piece(shape, const V3(0, 0, 0), size).mesh;
      final flat = [for (final v in m.verts) toWallB(v)];

      final shadow = Mask(64);
      fillTriangles(shadow, flat, m.tris);

      final hull = rasterize([convexHull(flat)], n: 64);
      final fill = _count(shadow) / _count(hull);

      expect(_count(shadow), greaterThan(0), reason: '$shape casts no shadow');
      if (shape == Shape.ell || shape == Shape.tee || shape == Shape.chevron) {
        expect(fill, lessThan(0.92),
            reason: '$shape fills ${(fill * 100).round()}% of its hull — '
                'it is not concave, so it adds nothing a box could not');
      } else {
        expect(fill, greaterThan(0.88),
            reason: '$shape should be convex but fills only '
                '${(fill * 100).round()}% of its hull');
      }
    }
  });

  // The same two guarantees geom_test makes for levels.g.dart, for the 200
  // rooms in levels_ext.g.dart. The generator enforces both while sampling —
  // but the emitted file is a recipe that `piece()` rebuilds, so a change to a
  // shape's geometry could quietly make a shipped room unsolvable long after
  // it was generated. This is the check that would catch that.
  test('all ${extendedLevels.length} mixed-shape levels are sane', () {
    expect(extendedLevels, hasLength(200));
    for (final lv in extendedLevels) {
      final rt = LevelRuntime(lv);
      expect(rt.score(lv.solution).solved, isTrue,
          reason: 'level ${lv.name} is unsolvable at its own solution');
      expect(rt.score(const Pose(0, 0, 0)).solved, isFalse,
          reason: 'level ${lv.name} opens already solved');
    }
  });

  test('the mixed chapters really are cut from more than boxes', () {
    // The whole point of the exercise. If `piece()` ever fell back to boxes,
    // every level above would still be solvable and every other test would
    // still pass — the game would just quietly lose its new vocabulary.
    final shaped = extendedLevels
        .expand((lv) => lv.boxes)
        .where((b) => b.shape != null)
        .length;
    final total = extendedLevels.expand((lv) => lv.boxes).length;
    expect(shaped / total, greaterThan(0.4),
        reason: 'only $shaped of $total pieces are non-box meshes');
  });

  test('mixed generation is opt-in, so endless is untouched', () {
    // Endless generates on the device from generateChapter and keys its stars
    // by depth. The default must stay box-only or room 340 stops being room
    // 340 — this asserts the default, not the mixed path.
    final boxes = generateChapter(seed: 1101, wanted: 3, hinges: 0);
    expect(boxes, isNotEmpty);
    for (final g in boxes) {
      expect(g.specs, isNull, reason: 'default path must not be mixed');
      for (final b in g.level.boxes) {
        expect(b.shape, isNull, reason: 'default path must emit plain boxes');
      }
    }
  });
}

int _count(Mask m) {
  var n = 0;
  for (final b in m.bits) {
    if (b != 0) n++;
  }
  return n;
}
