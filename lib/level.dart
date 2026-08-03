import 'geom.dart';

/// Solved when both walls reach this. Tune against real play in M0 — too tight
/// is frustrating, too loose is trivial.
const double kSolveThreshold = 0.92;

class Box {
  const Box({required this.center, required this.half, this.hinged = false});
  final V3 center;
  final V3 half;

  /// Hinged boxes swing about the world X axis through the origin.
  final bool hinged;

  static const _signs = [
    [-1, -1, -1], [-1, -1, 1], [-1, 1, -1], [-1, 1, 1], //
    [1, -1, -1], [1, -1, 1], [1, 1, -1], [1, 1, 1],
  ];

  /// Faces as corner indices, wound counter-clockwise seen from outside.
  static const faces = [
    [0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], //
    [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3],
  ];

  List<V3> corners() => [
        for (final s in _signs)
          V3(center.x + s[0] * half.x, center.y + s[1] * half.y,
              center.z + s[2] * half.z),
      ];
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

/// One box's corners in world space at [p].
List<List<V3>> worldCorners(Level lv, Pose p) => [
      for (final b in lv.boxes)
        [
          for (final c in b.corners())
            rotateYawPitch(b.hinged ? rotateX(c, p.hinge) : c, p.yaw, p.pitch),
        ],
    ];

/// Per-box shadow hulls on each wall. Overlaps are resolved by the raster
/// union in [rasterize], so these stay independent.
List<List<V2>> shadows(List<List<V3>> world, V2 Function(V3) project) =>
    [for (final cs in world) convexHull([for (final c in cs) project(c)])];

class Score {
  const Score(this.a, this.b);
  final double a, b;
  bool get solved => a >= kSolveThreshold && b >= kSolveThreshold;
}

class LevelRuntime {
  LevelRuntime(this.level)
      : _targetA = rasterize(
            shadows(worldCorners(level, level.solution), toWallA)),
        _targetB = rasterize(
            shadows(worldCorners(level, level.solution), toWallB));

  final Level level;
  final Mask _targetA, _targetB;

  List<List<V2>> targetHullsA() =>
      shadows(worldCorners(level, level.solution), toWallA);
  List<List<V2>> targetHullsB() =>
      shadows(worldCorners(level, level.solution), toWallB);

  Score score(Pose p) {
    final w = worldCorners(level, p);
    return Score(
      iou(rasterize(shadows(w, toWallA)), _targetA),
      iou(rasterize(shadows(w, toWallB)), _targetB),
    );
  }
}

/// Three puzzles, one new idea each: rotation, harder rotation, then the hinge.
/// That third one is the gate — if it isn't more *interesting* than the first,
/// and not merely fiddlier, the project stops. See status.md.
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
