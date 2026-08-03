import 'dart:math' as math;
import 'dart:typed_data';

class V3 {
  const V3(this.x, this.y, this.z);
  final double x, y, z;

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  double dot(V3 o) => x * o.x + y * o.y + z * o.z;
  V3 cross(V3 o) =>
      V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
}

class V2 {
  const V2(this.x, this.y);
  final double x, y;

  @override
  String toString() => '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

/// Yaw about Y, then pitch about X.
///
/// ponytail: two euler angles, not a quaternion arcball. Gimbal lock needs
/// pitch = ±90°, which the UI clamps away from. Upgrade to quaternions only
/// if the clamp starts to feel like a wall.
V3 rotateYawPitch(V3 v, double yaw, double pitch) {
  final cy = math.cos(yaw), sy = math.sin(yaw);
  final x1 = v.x * cy + v.z * sy;
  final z1 = -v.x * sy + v.z * cy;
  final cp = math.cos(pitch), sp = math.sin(pitch);
  return V3(x1, v.y * cp - z1 * sp, v.y * sp + z1 * cp);
}

/// Rotation about the world X axis through the origin — the hinge.
V3 rotateX(V3 v, double a) {
  final c = math.cos(a), s = math.sin(a);
  return V3(v.x, v.y * c - v.z * s, v.y * s + v.z * c);
}

// Both lights travel along a world axis (-X for the left wall, -Z for the
// back wall), so projection onto each wall is a coordinate drop. Exact, and
// free. Angled lights would need the full ray-plane solve; they don't earn it.
V2 toWallA(V3 v) => V2(v.z, v.y); // left wall, lit along -X
V2 toWallB(V3 v) => V2(v.x, v.y); // back wall, lit along -Z

/// Andrew monotone chain. Returns the hull counter-clockwise.
List<V2> convexHull(List<V2> pts) {
  if (pts.length < 3) return List.of(pts);
  final p = List.of(pts)
    ..sort((a, b) => a.x == b.x ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

  double cross(V2 o, V2 a, V2 b) =>
      (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);

  List<V2> half(Iterable<V2> src) {
    final out = <V2>[];
    for (final q in src) {
      while (out.length >= 2 &&
          cross(out[out.length - 2], out.last, q) <= 0) {
        out.removeLast();
      }
      out.add(q);
    }
    out.removeLast();
    return out;
  }

  return [...half(p), ...half(p.reversed)];
}

/// Point-in-hull for a counter-clockwise hull: inside means left of every edge.
bool insideHull(List<V2> h, double x, double y) {
  for (var i = 0; i < h.length; i++) {
    final a = h[i], b = h[(i + 1) % h.length];
    if ((b.x - a.x) * (y - a.y) - (b.y - a.y) * (x - a.x) < 0) return false;
  }
  return true;
}

/// Occupancy grid over [-half, half]².
///
/// ponytail: raster IoU instead of polygon booleans. Unions come free — every
/// hull draws into one grid — and it drops the clipper2 dependency along with
/// its unverified API. Ceiling: cells are ~1/64 of the window, so scores are
/// quantised at roughly ±0.01. That is far inside the 0.92 solve threshold.
/// Raise [n] or move to real polygon booleans only if scoring needs to be
/// finer than the eye can see.
class Mask {
  Mask(this.n) : bits = Uint8List(n * n);
  final int n;
  final Uint8List bits;
}

Mask rasterize(List<List<V2>> hulls, {double half = 2.0, int n = 64}) {
  final m = Mask(n);
  final step = 2 * half / n;
  for (var j = 0; j < n; j++) {
    final y = -half + (j + 0.5) * step;
    for (var i = 0; i < n; i++) {
      final x = -half + (i + 0.5) * step;
      for (final h in hulls) {
        if (h.length >= 3 && insideHull(h, x, y)) {
          m.bits[j * n + i] = 1;
          break;
        }
      }
    }
  }
  return m;
}

/// Union of projected triangles into an occupancy grid.
///
/// Replaces hull rasterisation for real meshes: the silhouette of a concave
/// shape is the union of its projected faces, which a convex hull would
/// over-cover — a rabbit's hull is a blob. Fills per triangle over its own
/// bounding box only, so cost tracks covered area rather than triangle count.
void fillTriangles(Mask m, List<V2> v, List<int> tris, {double half = 2.0}) {
  final n = m.n;
  final step = 2 * half / n;

  for (var t = 0; t + 2 < tris.length; t += 3) {
    final a = v[tris[t]], b = v[tris[t + 1]], c = v[tris[t + 2]];

    final minX = math.min(a.x, math.min(b.x, c.x));
    final maxX = math.max(a.x, math.max(b.x, c.x));
    final minY = math.min(a.y, math.min(b.y, c.y));
    final maxY = math.max(a.y, math.max(b.y, c.y));

    var i0 = ((minX + half) / step).floor();
    var i1 = ((maxX + half) / step).ceil();
    var j0 = ((minY + half) / step).floor();
    var j1 = ((maxY + half) / step).ceil();
    if (i1 < 0 || j1 < 0 || i0 >= n || j0 >= n) continue;
    i0 = i0.clamp(0, n - 1);
    i1 = i1.clamp(0, n - 1);
    j0 = j0.clamp(0, n - 1);
    j1 = j1.clamp(0, n - 1);

    // Signed area; sign tells us the winding so either order fills.
    final area = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    if (area == 0) continue;
    final s = area > 0 ? 1.0 : -1.0;

    for (var j = j0; j <= j1; j++) {
      final y = -half + (j + 0.5) * step;
      final row = j * n;
      for (var i = i0; i <= i1; i++) {
        if (m.bits[row + i] != 0) continue;
        final x = -half + (i + 0.5) * step;
        final w0 = ((b.x - a.x) * (y - a.y) - (b.y - a.y) * (x - a.x)) * s;
        if (w0 < 0) continue;
        final w1 = ((c.x - b.x) * (y - b.y) - (c.y - b.y) * (x - b.x)) * s;
        if (w1 < 0) continue;
        final w2 = ((a.x - c.x) * (y - c.y) - (a.y - c.y) * (x - c.x)) * s;
        if (w2 < 0) continue;
        m.bits[row + i] = 1;
      }
    }
  }
}

double iou(Mask a, Mask b) {
  var inter = 0, union = 0;
  for (var i = 0; i < a.bits.length; i++) {
    final p = a.bits[i] != 0, q = b.bits[i] != 0;
    if (p && q) inter++;
    if (p || q) union++;
  }
  return union == 0 ? 0 : inter / union;
}
