import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'geom.dart';
import 'level.dart';

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

/// Wall-local hull -> world point, per wall.
V3 onWallA(V2 h) => V3(-kWall, h.y, h.x);
V3 onWallB(V2 h) => V3(h.x, h.y, -kWall);

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

  final List<List<V3>> world;
  final List<List<V2>> targetsA, targetsB, castA, castB;
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
    _drawHulls(canvas, size, k, o, targetsA, onWallA,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = (hitA ? _amber : Colors.white).withValues(alpha: 0.30));
    _drawHulls(canvas, size, k, o, targetsB, onWallB,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = (hitB ? _amber : Colors.white).withValues(alpha: 0.30));

    // A shadow is dark on a lit wall — not a bright shape on a dark one.
    // It warms toward amber only as the pair locks.
    for (final (hulls, map, hit) in [
      (castA, onWallA, hitA),
      (castB, onWallB, hitB),
    ]) {
      _drawHulls(
        canvas,
        size,
        k,
        o,
        hulls,
        map,
        Paint()
          ..color = hit
              ? _amber.withValues(alpha: 0.42)
              : const Color(0xFF05050A).withValues(alpha: 0.78)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
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

  void _drawHulls(Canvas c, Size s, double k, Offset o, List<List<V2>> hulls,
      V3 Function(V2) map, Paint paint) {
    for (final h in hulls) {
      if (h.length < 3) continue;
      final p = Path();
      for (var i = 0; i < h.length; i++) {
        final q = project(map(h[i]), s, k, o);
        i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
      }
      c.drawPath(p..close(), paint);
    }
  }

  static const _view = V3(0.577, 0.577, 0.577);

  void _drawSolid(Canvas canvas, Size size, double k, Offset o) {
    final faces = <({double depth, Path path, double shade})>[];
    for (final corners in world) {
      for (final fc in Box.faces) {
        final a = corners[fc[0]], b = corners[fc[1]], c = corners[fc[2]];
        final n = (b - a).cross(c - a);
        final lit = n.dot(_view);
        if (lit <= 0) continue;
        final len = math.sqrt(n.dot(n));
        final shade = len == 0 ? 0.0 : (lit / len).clamp(0.0, 1.0);

        final path = Path();
        for (var i = 0; i < fc.length; i++) {
          final p = project(corners[fc[i]], size, k, o);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();

        var d = 0.0;
        for (final i in fc) {
          d += corners[i].dot(_view);
        }
        faces.add((depth: d / fc.length, path: path, shade: shade));
      }
    }
    faces.sort((x, y) => x.depth.compareTo(y.depth));

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF07070B);
    for (final fc in faces) {
      canvas.drawPath(
        fc.path,
        Paint()
          ..color = Color.lerp(
              _solidDark, Color.lerp(_solidLit, _warm, glow * 0.35)!, fc.shade)!,
      );
      canvas.drawPath(fc.path, edge);
    }
  }

  @override
  bool shouldRepaint(CornerScenePainter old) => true;
}
