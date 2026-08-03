import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/geom.dart';
import 'package:in_two_lights/mesh.dart';

Mask maskOf(Mesh m, V2 Function(V3) wall, {int n = 128}) {
  final grid = Mask(n);
  fillTriangles(grid, [for (final v in m.verts) wall(v)], m.tris);
  return grid;
}

double coverage(Mask m) {
  var c = 0;
  for (final b in m.bits) {
    if (b != 0) c++;
  }
  return c / m.bits.length;
}

void main() {
  test('a box mesh silhouettes exactly like the old convex hull', () {
    // The regression guard for the whole migration: all 36 generated levels
    // are boxes, and their scores must not move when the pipeline switches
    // from hulls to triangles.
    final box = Mesh.box(const V3(0.1, -0.2, 0.05), const V3(0.6, 0.3, 0.45));
    for (final wall in [toWallA, toWallB]) {
      final tri = maskOf(box, wall);
      final hull = rasterize([
        convexHull([for (final v in box.verts) wall(v)])
      ], n: 128);
      expect(iou(tri, hull), greaterThan(0.999),
          reason: 'box silhouette changed when moving to triangles');
    }
  });

  test('a concave outline is NOT its convex hull', () {
    // An L. The notch must stay empty — this is the whole reason meshes
    // replace hulls, and it is what makes a rabbit possible.
    const poly = [
      V2(-0.8, -0.8), V2(0.8, -0.8), V2(0.8, -0.3),
      V2(-0.3, -0.3), V2(-0.3, 0.8), V2(-0.8, 0.8),
    ];
    final ell = Mesh.prism(poly, 0.2);
    final tri = maskOf(ell, toWallB);
    final hull = rasterize([
      convexHull([for (final v in ell.verts) toWallB(v)])
    ], n: 128);

    expect(coverage(tri), greaterThan(0.02), reason: 'nothing was filled');
    expect(coverage(tri), lessThan(coverage(hull) * 0.85),
        reason: 'triangles covered as much as the hull — the notch got filled');
    expect(iou(tri, hull), lessThan(0.9),
        reason: 'a concave shape should differ from its hull');
  });

  test('ear clipping keeps fill inside the outline', () {
    // The notch of the L, in wall coords. Inside the hull, outside the shape.
    const poly = [
      V2(-0.8, -0.8), V2(0.8, -0.8), V2(0.8, -0.3),
      V2(-0.3, -0.3), V2(-0.3, 0.8), V2(-0.8, 0.8),
    ];
    final ell = Mesh.prism(poly, 0.2);
    final m = Mask(128);
    fillTriangles(m, [for (final v in ell.verts) toWallB(v)], ell.tris);

    bool filledAt(double x, double y) {
      const half = 2.0;
      final i = ((x + half) / (2 * half / 128)).floor();
      final j = ((y + half) / (2 * half / 128)).floor();
      return m.bits[j * 128 + i] != 0;
    }

    expect(filledAt(0.4, -0.6), isTrue, reason: 'the foot should be solid');
    expect(filledAt(-0.6, 0.4), isTrue, reason: 'the upright should be solid');
    expect(filledAt(0.4, 0.4), isFalse, reason: 'the notch must stay empty');
  });

  test('a lathe closes: a cylinder fills its own rectangle', () {
    final cyl = Mesh.lathe(const [V2(0.5, -0.6), V2(0.5, 0.6)], seg: 24);
    final m = maskOf(cyl, toWallB);
    // Silhouette should be ~1.0 x 1.2 of a 4x4 window.
    expect(coverage(m), closeTo((1.0 * 1.2) / 16, 0.01));
  });

  test('meshes union without double counting', () {
    final a = Mesh.box(const V3(0, 0, 0), const V3(0.4, 0.4, 0.4));
    final b = Mesh.box(const V3(0.2, 0, 0), const V3(0.4, 0.4, 0.4));
    final both = maskOf(Mesh.union([a, b]), toWallB);
    final justA = maskOf(a, toWallB);
    expect(coverage(both), greaterThan(coverage(justA)));
    expect(coverage(both), lessThan(coverage(justA) * 2));
  });
}
