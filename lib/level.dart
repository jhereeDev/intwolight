import 'geom.dart';
import 'mesh.dart';

/// Solved when both walls reach this.
const double kSolveThreshold = 0.92;

/// A solve is only given up below **this**, not below [kSolveThreshold].
///
/// Without the gap, success flickers. Drag is 0.012 rad per logical pixel and a
/// diagonal moves both axes, so a finger resting on the glass wanders across
/// 0.92 repeatedly: the chord re-fires, the glow reverses, the finish panel's
/// timer restarts. The player stops trusting the silhouette they just reasoned
/// out and starts stabilising a number.
///
/// Entering at 0.92 and releasing at 0.89 makes the solve latch. It is
/// deliberately not a full lock — back the sculpture properly out of the pose
/// and you do lose it, because a solve you cannot lose is not a puzzle.
const double kReleaseThreshold = 0.89;

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

  /// Crossing into a solve.
  bool get solved => a >= kSolveThreshold && b >= kSolveThreshold;

  /// Still solved, for a pose that already was. See [kReleaseThreshold].
  bool get holds => a >= kReleaseThreshold && b >= kReleaseThreshold;

  /// Whether a solve survives, given whether one was already in hand. This is
  /// the only place the two thresholds should be compared — doing it inline
  /// is how one of them gets forgotten.
  bool latched({required bool wasSolved}) => wasSolved ? holds : solved;
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
    // Not "drag to rotate": hints only appear after a minute of being stuck,
    // and by then the player has been dragging the whole time. What they are
    // missing on the first room is that ONE turn drives BOTH shadows.
    hint: 'One shape. Two shadows. Both must fit.',
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
