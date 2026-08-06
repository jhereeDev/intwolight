import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'geom.dart';
import 'mesh.dart';

/// The corner. One coherent room instead of three disconnected panels.
///
/// Wall A is the plane x = -kWall, lit along -X, and its 2D coords are (z, y).
/// Wall B is the plane z = -kWall, lit along -Z, with coords (x, y). They meet
/// at the vertical line x = z = -kWall, which the isometric projection puts
/// dead centre — so the seam reads as a real corner for free.
const double kWall = 2.35; // wall plane offset from origin
const double kExtent = 2.7; // how far each wall runs from the seam
const double kFloor = -2.2;

/// The solid is drawn smaller than its own shadow.
///
/// Physically right — the sculpture hangs nearer the lights than the walls, so
/// its shadows are magnified — and it fixes the real readability problem: at
/// 1:1 a chapter III sculpture sprawls across the corner and covers the very
/// shadows you are trying to read.
const double kSolidScale = 0.78;

/// Walls run taller than the room is deep. A cube reads as a box; a tall
/// corner reads as a room, and it fills a phone's aspect instead of floating
/// in a sea of black.
const double kWallTop = 3.6;

// Palette. Warm light, cold shadow — the whole look lives in this contrast.
const _bg = Color(0xFF08080A);
const _wallLo = Color(0xFF14141A);
const _wallHi = Color(0xFF2A2620);
const _amber = Color(0xFFE0A82E);

/// The two lights differ in **colour temperature**, not just position.
///
/// They were identical, which meant the only thing telling the walls apart was
/// their angle — and at a glance, mid-drag, that is not enough. Warm on the
/// left, cool on the right: the eye separates them instantly, so "which shadow
/// am I fixing" stops being a question. It also makes the room read as two
/// lamps rather than one ambient wash, which is the entire premise, and it is
/// the same split the app icon uses.
const _warm = Color(0xFFFFD68C);

/// The light a chapter is lit by.
///
/// Every room was the same corner in the same amber, which made a 47-room
/// campaign read as one long room. Chapters now change the *light* rather than
/// the geometry: same walls, same seam, different hour of the day. It costs
/// two colours per chapter and it is the first thing visible in a screenshot.
///
/// [wall] is the unlit wall; [lamp] is what the two lights throw onto it.
/// The two lamps are deliberately different colours — that contrast is how the
/// two walls stay legible as two separate constraints rather than one wash.
/// A chapter shifts both together; it must never collapse them to the same
/// colour, or the game loses the thing its name is about.
class Ambience {
  const Ambience(this.wall, this.lamp, this.lamp2);
  final Color wall;

  /// Wall A's light — the warm side.
  final Color lamp;

  /// Wall B's light — the cool side.
  final Color lamp2;

  /// Chapter I is deliberately the plainest: the tutorial should look like the
  /// game's default state, so later chapters read as a departure from it.
  static const byChapter = <Ambience>[
    // I ROTATION — the default. The tutorial should look like the game's
    // resting state so every later chapter reads as a departure from it.
    Ambience(Color(0xFF14141A), _warm, _cool),
    // II THE JOINT — dusk. Both lamps warm slightly, the gap stays.
    Ambience(Color(0xFF16131A), Color(0xFFFFC98F), Color(0xFF9FC8E8)),
    // III TWO JOINTS — the coldest room, for the hardest chapter.
    Ambience(Color(0xFF121620), Color(0xFFE8D2B4), Color(0xFF9DBEFF)),
    // IV FORMS — low sun on organic shapes.
    Ambience(Color(0xFF1A1512), Color(0xFFFFC178), Color(0xFF89B7C4)),
    // V SILHOUETTES — theatrical, nearly a stage.
    Ambience(Color(0xFF10141A), Color(0xFFF0E4FF), Color(0xFF8FD4FF)),

    // ── The mixed-shape chapters. ─────────────────────────────────────────
    // These run 0 → 1 → 2 joints again over a new vocabulary, so the palette
    // restarts warm and cools across the eight the way I–III do across three.
    // Every pair keeps the warm/cool split: the two walls are two constraints,
    // and collapsing the lamps to one colour would hide that.

    // VI THE ROD — brass. Round pieces catch a light that has some metal in it.
    Ambience(Color(0xFF171310), Color(0xFFFFCF8A), Color(0xFF93BEDC)),
    // VII THE WEDGE — hard light for hard edges, the highest contrast so far.
    Ambience(Color(0xFF0E1014), Color(0xFFFFE0B0), Color(0xFF7FB6F0)),
    // VIII THE BULB — the warmest room in the game. Lathed shapes have no edge
    // to read, so the light does the describing instead.
    Ambience(Color(0xFF1B1410), Color(0xFFFFB877), Color(0xFF8FC6C9)),
    // IX THE ANGLE — flat and even, so a notch is read by shape not by shading.
    Ambience(Color(0xFF141519), Color(0xFFEFD9B8), Color(0xFFA8C4E6)),
    // X THE ARROW — directional, a low raking light that agrees with the shape.
    Ambience(Color(0xFF15110F), Color(0xFFFFC58A), Color(0xFF86ADD8)),
    // XI ASSEMBLY — cooling off as the joints come back. Cf. III.
    Ambience(Color(0xFF10141C), Color(0xFFE3D0BA), Color(0xFF9FC0FF)),
    // XII TANGLE — colder still, and dimmer: the busiest silhouettes in the
    // game need the room to stop competing with them.
    Ambience(Color(0xFF0D1119), Color(0xFFD8C8B6), Color(0xFF97B8FA)),
    // XIII THE WORKS — the last room. Both lamps at full, the widest split in
    // the game, because everything the vocabulary knows shows up here at once.
    Ambience(Color(0xFF0F0F16), Color(0xFFFFE3B4), Color(0xFF8ECBFF)),
  ];

  /// Rooms with no chapter — the daily, endless, the Workshop — use the
  /// default rather than borrowing a chapter's identity.
  static const neutral = Ambience(_wallLo, _warm, _cool);

  static Ambience of(int? chapter) => chapter == null
      ? neutral
      : byChapter[chapter.clamp(0, byChapter.length - 1)];
}
const _cool = Color(0xFFBFD2F2);
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

/// Build one filled path from a projected mesh, in **wall-local** coords.
///
/// Every triangle is wound the same way before being added. A closed mesh
/// projects its front and back faces with opposite windings, and under
/// non-zero fill those cancel — the silhouette would come out with holes
/// exactly where the shape is thickest.
Path shadowPath2D(Mesh2 m) {
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
    path
      ..moveTo(a.x, a.y)
      ..lineTo(b.x, b.y)
      ..lineTo(c.x, c.y)
      ..close();
  }
  return path;
}

/// True outline of a silhouette, for the target ghost.
///
/// `Path.combine` is a boolean op and is far too slow to run per frame — this
/// was the whole cause of the stutter once meshes arrived, because a lathe has
/// ~200 triangles and this ran twice a frame. It is built once per level in
/// wall-local space and mapped to the screen with [wallMatrix].
Path unionOutline2D(List<Mesh2> ms) {
  // One path per *triangle*, then a balanced pairwise union.
  //
  // Two things matter here. Accumulating `acc = acc ∪ next` is O(n²) — every
  // combine re-walks the whole accumulated outline, which is what made a
  // 264-triangle lathe take 523ms. And the union must be per triangle, not per
  // piece: a piece drawn as one non-zero path *fills* correctly but still
  // contains every internal edge, so stroking it draws a wireframe instead of
  // an outline.
  var level = <Path>[];
  for (final m in ms) {
    for (var i = 0; i + 2 < m.t.length; i += 3) {
      var a = m.v[m.t[i]], b = m.v[m.t[i + 1]], c = m.v[m.t[i + 2]];
      final area = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
      if (area == 0) continue;
      if (area < 0) {
        final tmp = b;
        b = c;
        c = tmp;
      }
      level.add(Path()
        ..moveTo(a.x, a.y)
        ..lineTo(b.x, b.y)
        ..lineTo(c.x, c.y)
        ..close());
    }
  }
  if (level.isEmpty) return Path();
  while (level.length > 1) {
    final next = <Path>[];
    for (var i = 0; i < level.length; i += 2) {
      next.add(i + 1 < level.length
          ? Path.combine(PathOperation.union, level[i], level[i + 1])
          : level[i]);
    }
    level = next;
  }
  return level.first;
}

/// Wall-local (u, v) -> screen is **affine**, so a cached path can simply be
/// transformed rather than rebuilt.
///
/// Wall A: (u,v) -> world(-kWall, v, u).  Wall B: (u,v) -> world(u, v, -kWall).
/// Both reduce to sx = a·u + c, sy = 0.5k·u - k·v + f.
Float64List wallMatrix({required bool isA, required double k, required Offset o}) {
  final sign = isA ? -1.0 : 1.0;
  final a = sign * 0.866 * k;
  final c = o.dx + sign * 0.866 * k * kWall;
  final f = o.dy - 0.5 * k * kWall;

  final m = Float64List(16);
  m[0] = a; // m00
  m[1] = 0.5 * k; // m10
  m[4] = 0; // m01
  m[5] = -k; // m11
  m[10] = 1;
  m[12] = c; // tx
  m[13] = f; // ty
  m[15] = 1;
  return m;
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
    this.ambience = Ambience.neutral,
  });

  final List<Mesh> world;
  final List<Mesh2> castA, castB;

  /// Pre-unioned outlines in *wall-local* space, built once per level.
  final Path targetsA, targetsB;
  final bool hitA, hitB;

  /// 0 -> unsolved, 1 -> fully solved. Drives the warm bloom.
  final double glow;

  /// Which light this room is lit by. See [Ambience].
  final Ambience ambience;
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
    canvas.drawPath(wallA, Paint()..color = ambience.wall);
    canvas.drawPath(wallB, Paint()..color = ambience.wall);

    // Two lights, pooling behind the sculpture. This is the whole mood, and
    // it is what gives the shadows a lit surface to be dark against.
    final centre = project(const V3(0, 0, 0), size, k, o);
    for (final spot in [
      (project(const V3(-kWall, 0.9, 0.1), size, k, o), wallA, ambience.lamp),
      (project(const V3(0.1, 0.9, -kWall), size, k, o), wallB, ambience.lamp2),
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
              Color.lerp(_wallHi, spot.$3, 0.20 + glow * 0.32)!,
              Color.lerp(_wallHi, spot.$3, 0.07 + glow * 0.10)!,
              Color.lerp(_wallHi, ambience.wall, 0.72)!,
              ambience.wall.withValues(alpha: 0.0),
            ],
            // A tighter core with a longer tail. The old two-stop ramp fell off
            // evenly and read as a flat disc; a lamp is bright in a small
            // middle and dim for a long way after.
            [0.0, 0.22, 0.62, 1.0],
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
    final mA = wallMatrix(isA: true, k: k, o: o);
    final mB = wallMatrix(isA: false, k: k, o: o);

    for (final (path, mat, hit) in [
      (targetsA, mA, hitA),
      (targetsB, mB, hitB),
    ]) {
      canvas.drawPath(
        path.transform(mat),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = (hit ? _amber : Colors.white).withValues(alpha: 0.34),
      );
    }

    // A shadow is dark on a lit wall — not a bright shape on a dark one.
    // It warms toward amber only as the pair locks.
    for (final (ms, mat, hit) in [
      (castA, mA, hitA),
      (castB, mB, hitB),
    ]) {
      final paint = Paint()
        ..color = hit
            ? _amber.withValues(alpha: 0.42)
            : const Color(0xFF05050A).withValues(alpha: 0.78)
        // Scaled to the room, not fixed in device pixels. At a constant 2.2 a
        // shadow was correctly soft on a small phone and razor-edged on a
        // tablet, because the room grew and the penumbra did not.
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.6, k * 0.022));
      for (final m in ms) {
        canvas.drawPath(shadowPath2D(m).transform(mat), paint);
      }
    }

    // ---- dust in the beam -------------------------------------------------
    final mote =
        Paint()..color = ambience.lamp.withValues(alpha: 0.05 + glow * 0.07);
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

  static V3 _shrink(V3 v) =>
      V3(v.x * kSolidScale, v.y * kSolidScale, v.z * kSolidScale);

  /// Painter's algorithm over triangles. Exact enough for the small,
  /// non-interpenetrating pieces these sculptures are built from; it would
  /// need a depth buffer for anything that self-intersects.
  void _drawSolid(Canvas canvas, Size size, double k, Offset o) {
    final faces = <({double depth, Path path, double shade})>[];
    for (final m in world) {
      for (var i = 0; i + 2 < m.tris.length; i += 3) {
        final a = _shrink(m.verts[m.tris[i]]);
        final b = _shrink(m.verts[m.tris[i + 1]]);
        final c = _shrink(m.verts[m.tris[i + 2]]);
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
