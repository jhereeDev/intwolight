import 'geom.dart';
import 'mesh.dart';

/// Solved when both walls reach this.
const double kSolveThreshold = 0.92;

/// One rigid part of a sculpture.
///
/// Still called Box because the 36 generated levels are boxes and
/// `levels.g.dart` constructs them by that name — but a piece is now any
/// mesh. Use [Box.form] for lathed and extruded shapes.
class Box {
  const Box({required this.center, required this.half, this.hinged = false})
      : shape = null;

  /// An arbitrary mesh piece. Pre-positioned in its own coordinates.
  const Box.form(Mesh this.shape, {this.hinged = false})
      : center = const V3(0, 0, 0),
        half = const V3(0, 0, 0);

  final V3 center, half;

  /// Hinged pieces swing about the world X axis through the origin.
  final bool hinged;

  final Mesh? shape;

  Mesh get mesh => shape ?? Mesh.box(center, half);
}

class Pose {
  const Pose(this.yaw, this.pitch, this.hinge);
  final double yaw, pitch, hinge;
}

class Level {
  const Level({
    required this.name,
    required this.hint,
    required this.boxes,
    required this.solution,
  });

  final String name;
  final String hint;
  final List<Box> boxes;

  /// The target silhouettes are the shadows cast at this pose, so every level
  /// is solvable by construction and needs no separately authored artwork.
  final Pose solution;

  bool get hasHinge => boxes.any((b) => b.hinged);
}

/// Each piece's mesh in world space at [p].
List<Mesh> worldMeshes(Level lv, Pose p) => [
      for (final b in lv.boxes)
        b.mesh.map((v) =>
            rotateYawPitch(b.hinged ? rotateX(v, p.hinge) : v, p.yaw, p.pitch)),
    ];

/// Project every piece onto a wall. Overlaps resolve in the raster union, so
/// pieces stay independent.
List<Mesh2> shadowMeshes(List<Mesh> world, V2 Function(V3) project) =>
    [for (final m in world) Mesh2([for (final v in m.verts) project(v)], m.tris)];

Mask maskOfShadows(List<Mesh2> shadows, int n, {Mask? into}) {
  final g = into ?? Mask(n);
  if (into != null) into.bits.fillRange(0, into.bits.length, 0);
  for (final s in shadows) {
    fillTriangles(g, s.v, s.t);
  }
  return g;
}

class Score {
  const Score(this.a, this.b);
  final double a, b;
  bool get solved => a >= kSolveThreshold && b >= kSolveThreshold;
}

class LevelRuntime {
  /// [res] is the scoring grid. 64 for play; the generator drops to 32, where
  /// it is 4x cheaper and still far finer than the accept/reject thresholds.
  LevelRuntime(this.level, {this.res = 64})
      : _targetA = maskOfShadows(
            shadowMeshes(worldMeshes(level, level.solution), toWallA), res),
        _targetB = maskOfShadows(
            shadowMeshes(worldMeshes(level, level.solution), toWallB), res);

  final Level level;
  final int res;
  final Mask _targetA, _targetB;

  // Scratch buffers. score() runs on every drag frame; allocating two 4KB
  // grids per call just to throw them away is pure GC churn.
  late final Mask _scratchA = Mask(res);
  late final Mask _scratchB = Mask(res);

  List<Mesh2> targetShadowsA() =>
      shadowMeshes(worldMeshes(level, level.solution), toWallA);
  List<Mesh2> targetShadowsB() =>
      shadowMeshes(worldMeshes(level, level.solution), toWallB);

  Score score(Pose p) {
    final w = worldMeshes(level, p);
    return Score(
      iou(maskOfShadows(shadowMeshes(w, toWallA), res, into: _scratchA),
          _targetA),
      iou(maskOfShadows(shadowMeshes(w, toWallB), res, into: _scratchB),
          _targetB),
    );
  }
}

/// The three M0 gate puzzles, one new idea each: rotation, harder rotation,
/// then the hinge. Kept because the test suite and `tool/probe.dart` measure
/// against them — the Hinge is the only level known to be good.
const levels = <Level>[
  Level(
    name: '1 · Tee',
    hint: 'Drag to rotate.',
    boxes: [
      Box(center: V3(0, 0, 0), half: V3(0.95, 0.24, 0.24)),
      Box(center: V3(0, 0.58, 0), half: V3(0.24, 0.34, 0.24)),
    ],
    solution: Pose(0.62, 0.34, 0),
  ),
  Level(
    name: '2 · Step',
    hint: 'Both shadows, at once.',
    boxes: [
      Box(center: V3(-0.52, -0.52, 0.1), half: V3(0.3, 0.3, 0.3)),
      Box(center: V3(0, 0, 0), half: V3(0.3, 0.3, 0.3)),
      Box(center: V3(0.52, 0.52, -0.1), half: V3(0.3, 0.3, 0.3)),
    ],
    solution: Pose(-0.88, 0.42, 0),
  ),
  Level(
    name: '3 · Hinge',
    hint: 'The upper arm folds.',
    boxes: [
      Box(center: V3(0, -0.42, 0), half: V3(0.72, 0.2, 0.2)),
      Box(center: V3(0, 0.42, 0), half: V3(0.72, 0.2, 0.2), hinged: true),
    ],
    solution: Pose(0.52, -0.36, 0.85),
  ),
];
