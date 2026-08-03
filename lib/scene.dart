import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'geom.dart';
import 'level.dart';
import 'mesh.dart';

/// The corner. One coherent room instead of three disconnected panels.
///
/// Wall A is the plane x = -kWall, lit along -X, and its 2D coords are (z, y).
/// Wall B is the plane z = -kWall, lit along -Z, with coords (x, y). They meet
/// at the vertical line x = z = -kWall, which the isometric projection puts
/// dead centre — so the seam reads as a real corner for free.
const double kWall = 2.0; // wall plane offset from origin
const double kExtent = 2.0; // how far each wall runs from the seam
const double kFloor = -2.0;

/// Walls run taller than the room is deep. A cube reads as a box; a tall
/// corner reads as a room, and it fills a phone's aspect instead of floating
/// in a sea of black.
const double kWallTop = 3.1;

// Palette. Warm light, cold shadow — the whole look lives in this contrast.
const _bg = Color(0xFF08080A);
const _wallLo = Color(0xFF14141A);
const _wallHi = Color(0xFF2A2620);
const _amber = Color(0xFFE0A82E);
const _warm = Color(0xFFFFD68C);
const _solidLit = Color(0xFFE8E4DA);
const _solidDark = Color(0xFF1D2230);

/// Isometric. Kept identical to the M0 projection so poses read the same.
Offset project(V3 v, Size s, double k, Offset origin) => Offset(
      origin.dx + (v.x - v.z) * 0.866 * k,
      origin.dy + (-v.y + (v.x + v.z) * 0.5) * k,
    );

/// Fits the room inside [size]. Width is the binding constraint on a phone,
/// so the floor's near corner is allowed to run off the bottom — cropping the
/// floor is free, cropping a wall is not.
({double k, Offset origin}) fitScene(Size size) {
  const halfW = 2 * kExtent * 0.866; // (x - z) half-span
  // Projected vertical span: top of the seam is -(kWallTop + kWall)·k above the
  // origin, the floor's near corner is +2·kExtent·k below it.
  const up = kWallTop + kWall;
  const down = 2 * kExtent;
  final byWidth = size.width / (halfW * 2 + 0.30);
  final byHeight = size.height / (up + down + 0.8);
  final k = math.min(byWidth, byHeight);

  // Centre the room in the space left over, then bias it up slightly so the
  // meters at the bottom have air and the eye lands on the sculpture.
  final slack = size.height - (up + down) * k;
  return (k: k, origin: Offset(size.width / 2, slack * 0.42 + up * k));
}

Path _quad(List<V3> pts, Size s, double k, Offset o) {
  final p = Path();
  for (var i = 0; i < pts.length; i++) {
    final q = project(pts[i], s, k, o);
    i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
  }
  return p..close();
}

/// Wall-local point -> world point, per wall.
V3 onWallA(V2 h) => V3(-kWall, h.y, h.x);
V3 onWallB(V2 h) => V3(h.x, h.y, -kWall);

/// Build one filled path from a projected mesh.
///
/// Every triangle is wound the same way before being added. A closed mesh
/// projects its front and back faces with opposite windings, and under
/// non-zero fill those cancel — the silhouette would come out with holes
/// exactly where the shape is thickest.
Path shadowPath(Mesh2 m, V3 Function(V2) toWorld, Size s, double k, Offset o) {
  final path = Path()..fillType = PathFillType.nonZero;
  for (var i = 0; i + 2 < m.t.length; i += 3) {
    var a = m.v[m.t[i]], b = m.v[m.t[i + 1]], c = m.v[m.t[i + 2]];
    final area = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    if (area == 0) continue;
    if (area < 0) {
      final tmp = b;
      b = c;
      c = tmp;
    }
    final pa = project(toWorld(a), s, k, o);
    final pb = project(toWorld(b), s, k, o);
    final pc = project(toWorld(c), s, k, o);
    path
      ..moveTo(pa.dx, pa.dy)
      ..lineTo(pb.dx, pb.dy)
      ..lineTo(pc.dx, pc.dy)
      ..close();
  }
  return path;
}

/// True outline of a silhouette, for the target ghost. Union is expensive, so
/// callers cache this per level rather than rebuilding it per frame.
Path unionOutline(List<Mesh2> ms, V3 Function(V2) toWorld, Size s, double k,
    Offset o) {
  var acc = Path();
  for (final m in ms) {
    acc = Path.combine(
        PathOperation.union, acc, shadowPath(m, toWorld, s, k, o));
  }
  return acc;
}

class CornerScenePainter extends CustomPainter {
  CornerScenePainter({
    required this.world,
    required this.targetsA,
    required this.targetsB,
    required this.castA,
    required this.castB,
    required this.hitA,
    required this.hitB,
    required this.glow,
    required this.motes,
  });

  final List<Mesh> world;
  final List<Mesh2> castA, castB;

  /// Pre-unioned outlines in *wall-local* space, rebuilt only when the level
  /// or the viewport changes.
  final List<Mesh2> targetsA, targetsB;
  final bool hitA, hitB;

  /// 0 -> unsolved, 1 -> fully solved. Drives the warm bloom.
  final double glow;
  final List<Offset> motes;

  @override
  void paint(Canvas canvas, Size size) {
    final f = fitScene(size);
    final k = f.k, o = f.origin;

    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);

    // ---- the room ---------------------------------------------------------
    final wallA = _quad(const [
      V3(-kWall, kWallTop, -kWall),
      V3(-kWall, kWallTop, kExtent),
      V3(-kWall, kFloor, kExtent),
      V3(-kWall, kFloor, -kWall),
    ], size, k, o);

    final wallB = _quad(const [
      V3(-kWall, kWallTop, -kWall),
      V3(kExtent, kWallTop, -kWall),
      V3(kExtent, kFloor, -kWall),
      V3(-kWall, kFloor, -kWall),
    ], size, k, o);

    final floor = _quad(const [
      V3(-kWall, kFloor, -kWall),
      V3(kExtent, kFloor, -kWall),
      V3(kExtent, kFloor, kExtent),
      V3(-kWall, kFloor, kExtent),
    ], size, k, o);

    canvas.drawPath(floor, Paint()..color = const Color(0xFF0C0C10));
    canvas.drawPath(wallA, Paint()..color = _wallLo);
    canvas.drawPath(wallB, Paint()..color = _wallLo);

    // Two lights, pooling behind the sculpture. This is the whole mood, and
    // it is what gives the shadows a lit surface to be dark against.
    final centre = project(const V3(0, 0, 0), size, k, o);
    for (final spot in [
      (project(const V3(-kWall, 0.9, 0.1), size, k, o), wallA),
      (project(const V3(0.1, 0.9, -kWall), size, k, o), wallB),
    ]) {
      canvas.save();
      canvas.clipPath(spot.$2);
      final r = k * 2.9;
      canvas.drawCircle(
        spot.$1,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            spot.$1,
            r,
            [
              Color.lerp(_wallHi, _warm, 0.16 + glow * 0.30)!,
              Color.lerp(_wallHi, _wallLo, 0.7)!,
              _wallLo.withValues(alpha: 0.0),
            ],
            [0.0, 0.55, 1.0],
          ),
      );
      canvas.restore();
    }

    // The seam, and where each wall meets the floor. Cheap, sells the corner.
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawPath(wallA, seam);
    canvas.drawPath(wallB, seam);

    // ---- targets, then the shadows themselves -----------------------------
    for (final (ms, map, hit) in [
      (targetsA, onWallA, hitA),
      (targetsB, onWallB, hitB),
    ]) {
      final outline = unionOutline(ms, map, size, k, o);
      canvas.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = (hit ? _amber : Colors.white).withValues(alpha: 0.34),
      );
    }

    // A shadow is dark on a lit wall — not a bright shape on a dark one.
    // It warms toward amber only as the pair locks.
    for (final (ms, map, hit) in [
      (castA, onWallA, hitA),
      (castB, onWallB, hitB),
    ]) {
      final paint = Paint()
        ..color = hit
            ? _amber.withValues(alpha: 0.42)
            : const Color(0xFF05050A).withValues(alpha: 0.78)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
      for (final m in ms) {
        canvas.drawPath(shadowPath(m, map, size, k, o), paint);
      }
    }

    // ---- dust in the beam -------------------------------------------------
    final mote = Paint()..color = _warm.withValues(alpha: 0.05 + glow * 0.07);
    for (final m in motes) {
      canvas.drawCircle(
          Offset(m.dx * size.width, m.dy * size.height), 1.1, mote);
    }

    // ---- the sculpture ----------------------------------------------------
    _drawSolid(canvas, size, k, o);

    if (glow > 0) {
      canvas.drawCircle(
        centre,
        k * 2.2,
        Paint()
          ..shader = ui.Gradient.radial(centre, k * 2.2, [
            _warm.withValues(alpha: 0.10 * glow),
            _warm.withValues(alpha: 0.0),
          ], [
            0.0,
            1.0
          ]),
      );
    }
  }

  static const _view = V3(0.577, 0.577, 0.577);

  /// Painter's algorithm over triangles. Exact enough for the small,
  /// non-interpenetrating pieces these sculptures are built from; it would
  /// need a depth buffer for anything that self-intersects.
  void _drawSolid(Canvas canvas, Size size, double k, Offset o) {
    final faces = <({double depth, Path path, double shade})>[];
    for (final m in world) {
      for (var i = 0; i + 2 < m.tris.length; i += 3) {
        final a = m.verts[m.tris[i]];
        final b = m.verts[m.tris[i + 1]];
        final c = m.verts[m.tris[i + 2]];
        final n = (b - a).cross(c - a);
        final lit = n.dot(_view);
        if (lit <= 0) continue; // back face
        final len = math.sqrt(n.dot(n));
        final shade = len == 0 ? 0.0 : (lit / len).clamp(0.0, 1.0);

        final pa = project(a, size, k, o);
        final pb = project(b, size, k, o);
        final pc = project(c, size, k, o);
        final path = Path()
          ..moveTo(pa.dx, pa.dy)
          ..lineTo(pb.dx, pb.dy)
          ..lineTo(pc.dx, pc.dy)
          ..close();

        faces.add((
          depth: (a.dot(_view) + b.dot(_view) + c.dot(_view)) / 3,
          path: path,
          shade: shade,
        ));
      }
    }
    faces.sort((x, y) => x.depth.compareTo(y.depth)); // far first

    for (final fc in faces) {
      final fill = Color.lerp(
          _solidDark, Color.lerp(_solidLit, _warm, glow * 0.35)!, fc.shade)!;
      // Stroke each triangle in its own fill colour: it closes the hairline
      // seams antialiasing leaves between adjacent triangles, without drawing
      // a visible wireframe over a curved surface.
      canvas.drawPath(fc.path, Paint()..color = fill);
      canvas.drawPath(
        fc.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(CornerScenePainter old) => true;
}
