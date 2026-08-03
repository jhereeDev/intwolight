import 'dart:math' as math;

import 'geom.dart';

/// A mesh already projected onto a wall.
class Mesh2 {
  const Mesh2(this.v, this.t);
  final List<V2> v;
  final List<int> t;
}

/// An arbitrary triangle mesh.
///
/// This replaces the box-only model. The silhouette of a box is its convex
/// hull, which is why hulls were enough at M0 — but a rabbit's shadow is not
/// its convex hull, so shapes with concavities need the real projected
/// triangles unioned instead.
class Mesh {
  const Mesh(this.verts, this.tris);

  final List<V3> verts;

  /// Flat triple list: tris[i], tris[i+1], tris[i+2] index into [verts].
  final List<int> tris;

  int get triCount => tris.length ~/ 3;

  Mesh map(V3 Function(V3) f) => Mesh([for (final v in verts) f(v)], tris);

  /// Axis-aligned box — the M0 primitive, now just one mesh among several.
  factory Mesh.box(V3 c, V3 h) {
    final v = <V3>[
      for (final s in const [
        [-1, -1, -1], [-1, -1, 1], [-1, 1, -1], [-1, 1, 1], //
        [1, -1, -1], [1, -1, 1], [1, 1, -1], [1, 1, 1],
      ])
        V3(c.x + s[0] * h.x, c.y + s[1] * h.y, c.z + s[2] * h.z),
    ];
    const quads = [
      [0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], //
      [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3],
    ];
    final t = <int>[];
    for (final q in quads) {
      t.addAll([q[0], q[1], q[2], q[0], q[2], q[3]]);
    }
    return Mesh(v, t);
  }

  /// Revolve a profile around the Y axis. [profile] is (radius, y) pairs,
  /// bottom to top. This is where the organic shapes come from — pears,
  /// vases, bulbs, the body of an animal.
  factory Mesh.lathe(List<V2> profile, {int seg = 16, V3 at = const V3(0, 0, 0)}) {
    final v = <V3>[];
    final t = <int>[];
    for (var i = 0; i < profile.length; i++) {
      for (var s = 0; s < seg; s++) {
        final a = s * 2 * math.pi / seg;
        v.add(V3(
          at.x + profile[i].x * math.cos(a),
          at.y + profile[i].y,
          at.z + profile[i].x * math.sin(a),
        ));
      }
    }
    for (var i = 0; i < profile.length - 1; i++) {
      for (var s = 0; s < seg; s++) {
        final n = (s + 1) % seg;
        final a = i * seg + s, b = i * seg + n;
        final c = (i + 1) * seg + s, d = (i + 1) * seg + n;
        t.addAll([a, b, d, a, d, c]);
      }
    }
    // Caps, so the silhouette is solid rather than a shell seen end-on.
    v.add(V3(at.x, at.y + profile.first.y, at.z));
    final bot = v.length - 1;
    v.add(V3(at.x, at.y + profile.last.y, at.z));
    final top = v.length - 1;
    for (var s = 0; s < seg; s++) {
      final n = (s + 1) % seg;
      t.addAll([bot, n, s]);
      t.addAll([top, (profile.length - 1) * seg + s, (profile.length - 1) * seg + n]);
    }
    return Mesh(v, t);
  }

  /// Extrude a simple polygon along Z. Letters, claws, flat silhouettes —
  /// anything whose character lives in its outline.
  factory Mesh.prism(List<V2> poly, double depth, {V3 at = const V3(0, 0, 0)}) {
    final n = poly.length;
    final v = <V3>[
      for (final p in poly) V3(at.x + p.x, at.y + p.y, at.z - depth),
      for (final p in poly) V3(at.x + p.x, at.y + p.y, at.z + depth),
    ];
    final t = <int>[];
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      t.addAll([i, j, n + j, i, n + j, n + i]); // side wall
    }
    for (final tri in _earClip(poly)) {
      t.addAll([tri[0], tri[2], tri[1]]); // back cap
      t.addAll([n + tri[0], n + tri[1], n + tri[2]]); // front cap
    }
    return Mesh(v, t);
  }

  /// Glue several meshes into one piece.
  factory Mesh.union(List<Mesh> parts) {
    final v = <V3>[];
    final t = <int>[];
    for (final m in parts) {
      final off = v.length;
      v.addAll(m.verts);
      for (final i in m.tris) {
        t.add(i + off);
      }
    }
    return Mesh(v, t);
  }
}

/// Ear clipping for a simple (non-self-intersecting) polygon. Handles the
/// concave outlines that make a letter a letter — a fan triangulation would
/// spill outside them.
List<List<int>> _earClip(List<V2> poly) {
  final n = poly.length;
  if (n < 3) return const [];
  final idx = List<int>.generate(n, (i) => i);
  if (_area(poly) < 0) {
    final r = idx.reversed.toList();
    idx
      ..clear()
      ..addAll(r);
  }

  final out = <List<int>>[];
  var guard = 0;
  while (idx.length > 3 && guard++ < n * n) {
    var clipped = false;
    for (var i = 0; i < idx.length; i++) {
      final a = idx[(i - 1 + idx.length) % idx.length];
      final b = idx[i];
      final c = idx[(i + 1) % idx.length];
      if (_cross(poly[a], poly[b], poly[c]) <= 0) continue; // reflex
      var contains = false;
      for (final p in idx) {
        if (p == a || p == b || p == c) continue;
        if (_inTri(poly[p], poly[a], poly[b], poly[c])) {
          contains = true;
          break;
        }
      }
      if (contains) continue;
      out.add([a, b, c]);
      idx.removeAt(i);
      clipped = true;
      break;
    }
    if (!clipped) break; // degenerate input; keep what we have
  }
  if (idx.length == 3) out.add([idx[0], idx[1], idx[2]]);
  return out;
}

double _area(List<V2> p) {
  var a = 0.0;
  for (var i = 0; i < p.length; i++) {
    final j = (i + 1) % p.length;
    a += p[i].x * p[j].y - p[j].x * p[i].y;
  }
  return a / 2;
}

double _cross(V2 a, V2 b, V2 c) =>
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);

bool _inTri(V2 p, V2 a, V2 b, V2 c) {
  final d1 = _cross(a, b, p), d2 = _cross(b, c, p), d3 = _cross(c, a, p);
  final neg = d1 < 0 || d2 < 0 || d3 < 0;
  final pos = d1 > 0 || d2 > 0 || d3 > 0;
  return !(neg && pos);
}
