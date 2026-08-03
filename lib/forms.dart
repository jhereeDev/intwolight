import 'dart:math' as math;

import 'geom.dart';
import 'level.dart';
import 'levels.g.dart';
import 'mesh.dart';

/// CHAPTER IV — hand-authored organic sculptures.
///
/// ⚠️ **A lathe alone cannot be a puzzle**, and a small feature cannot rescue
/// it. A surface of revolution about Y has the same silhouette at every yaw,
/// so yaw carries no information and half the controls do nothing.
///
/// The first attempt here broke the symmetry with a stem, two ears and a
/// handle — and `tool/formcheck.dart` showed **all three levels still scoring
/// 0.94–1.00 at a half-turn of yaw**, i.e. solved. The reason is a scoring
/// property worth remembering: **IoU is an area ratio, so a body that dominates
/// the silhouette drowns out small features.** An ear worth 4% of the area can
/// only move the score by about 4%, which never crosses the 0.92 threshold.
///
/// The fix is to break the symmetry in the *body*, not with an appendage:
/// every revolved form is flattened along Z, so it is an ellipsoid rather than
/// a solid of revolution and every yaw reads differently. Appendages then add
/// character rather than carrying the puzzle.
Mesh _flatten(Mesh m, double sz) => m.map((v) => V3(v.x, v.y, v.z * sz));

/// Rotate and offset a 2D outline, so extruded parts can be angled.
List<V2> _place(List<V2> p, double a, double dx, double dy) {
  final c = math.cos(a), s = math.sin(a);
  return [
    for (final q in p) V2(q.x * c - q.y * s + dx, q.x * s + q.y * c + dy),
  ];
}

const _ear = [
  V2(-0.075, 0.0), V2(0.075, 0.0), V2(0.055, 0.34),
  V2(0.0, 0.46), V2(-0.055, 0.34),
];

const _stem = [
  V2(-0.05, 0.0), V2(0.05, 0.0), V2(0.05, 0.30), V2(-0.05, 0.30),
];

/// A pear: revolved body, stem tilted off-axis so yaw matters.
final _pear = Mesh.union([
  _flatten(Mesh.lathe(const [
    V2(0.02, -0.78), V2(0.34, -0.60), V2(0.46, -0.30),
    V2(0.40, 0.02), V2(0.26, 0.32), V2(0.13, 0.54), V2(0.03, 0.64),
  ], seg: 18), 0.42),
  Mesh.prism(_place(_stem, 0.42, 0.06, 0.58), 0.055),
]);

/// A hare: ovoid body, two ears at different angles. The ears are what the
/// shadow reads as, and they are also what makes the pose findable.
final _hare = Mesh.union([
  _flatten(Mesh.lathe(const [
    V2(0.02, -0.62), V2(0.28, -0.48), V2(0.42, -0.18),
    V2(0.40, 0.14), V2(0.26, 0.38), V2(0.05, 0.48),
  ], seg: 18), 0.38),
  Mesh.prism(_place(_ear, -0.30, -0.13, 0.40), 0.05),
  Mesh.prism(_place(_ear, 0.16, 0.10, 0.42), 0.05),
]);

/// A vessel with a handle. The handle is the hinged part — it swings, so the
/// same body reads as two different silhouettes.
final _vesselBody = _flatten(Mesh.lathe(const [
  V2(0.03, -0.70), V2(0.30, -0.62), V2(0.44, -0.34),
  V2(0.44, 0.10), V2(0.30, 0.40), V2(0.28, 0.58), V2(0.05, 0.62),
], seg: 18), 0.40);

final _handle = Mesh.prism(
  _place(const [
    V2(-0.05, 0.0), V2(0.05, 0.0), V2(0.30, 0.22),
    V2(0.30, 0.52), V2(0.20, 0.52), V2(0.20, 0.28), V2(-0.05, 0.10),
  ], 0.0, 0.34, -0.20),
  0.05,
);

final formLevels = <Level>[
  Level(
    name: 'Pear',
    hint: 'Not every shape is a box.',
    boxes: [Box.form(_pear)],
    solution: const Pose(0.74, 0.30, 0),
  ),
  Level(
    name: 'Hare',
    hint: 'Two ears, two shadows.',
    boxes: [Box.form(_hare)],
    solution: const Pose(-1.05, 0.24, 0),
  ),
  Level(
    name: 'Vessel',
    hint: 'The handle swings.',
    boxes: [
      Box.form(_vesselBody),
      Box.form(_handle, hinged: true),
    ],
    solution: const Pose(0.58, -0.22, 0.62),
  ),
];

/// Everything playable, in order. Generated levels first, then the authored
/// organic chapter.
final allLevels = <Level>[...generatedLevels, ...formLevels];
