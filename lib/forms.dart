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
final allLevels = <Level>[...generatedLevels, ...formLevels, ...silhouetteLevels];

// ---------------------------------------------------------------------------
// CHAPTER V — SILHOUETTES
//
// The Shadowmatic trick, and it costs almost nothing here because both lights
// are axis-aligned.
//
// Wall B's shadow is (x, y): it does not depend on z **at all**. So a piece can
// be slid to any depth without changing that shadow by one pixel. Author the
// object as flat outlines in the XY plane, extrude each into its own thin slab,
// and scatter the slabs through depth: the sculpture reads as unrelated
// fragments floating apart, while their combined shadow is a clean, recognisable
// figure. Wall A's shadow — (z, y) — becomes a row of abstract bars, which is
// the second constraint and the actual puzzle.
//
// Targets are derived from the solution pose, so a designed silhouette needs the
// mesh pre-rotated by the inverse of that pose: at the solution the rotation
// cancels and the intended outline appears.

Mesh _preRotated(Mesh m, Pose p) =>
    m.map((v) => unrotateYawPitch(v, p.yaw, p.pitch));

/// A flat outline pushed to depth [z] as a thin slab.
Mesh _slab(List<V2> poly, double z, {double thick = 0.17}) =>
    Mesh.prism(poly, thick, at: V3(0, 0, z));

List<V2> _ellipse(double cx, double cy, double rx, double ry, {int n = 14}) => [
      for (var i = 0; i < n; i++)
        V2(cx + rx * math.cos(i * 2 * math.pi / n),
            cy + ry * math.sin(i * 2 * math.pi / n)),
    ];

/// Assemble scattered slabs into one piece, pre-rotated for [solution].
Mesh _figure(List<(List<V2>, double)> parts, Pose solution) => _preRotated(
      Mesh.union([for (final (poly, z) in parts) _slab(poly, z)]),
      solution,
    );

const _duckPose = Pose(0.62, -0.26, 0);
const _fishPose = Pose(-0.78, 0.20, 0);

final _duck = _figure([
  (_ellipse(-0.10, -0.30, 0.62, 0.34), 0.00), // body
  ([                                          // neck
    const V2(0.10, -0.16), const V2(0.32, -0.10),
    const V2(0.44, 0.34), const V2(0.22, 0.36),
  ], -0.46),
  (_ellipse(0.40, 0.46, 0.21, 0.19), 0.62), // head
  ([                                        // beak
    const V2(0.57, 0.50), const V2(0.92, 0.42), const V2(0.57, 0.36),
  ], 0.95),
  ([                                        // tail
    const V2(-0.66, -0.20), const V2(-0.95, -0.02), const V2(-0.62, -0.44),
  ], -0.80),
], _duckPose);

final _fish = _figure([
  (_ellipse(0.00, 0.00, 0.52, 0.38), 0.00), // body
  ([                                        // tail fin
    const V2(-0.48, 0.02), const V2(-0.92, 0.34),
    const V2(-0.86, 0.00), const V2(-0.92, -0.34),
  ], 0.70),
  ([                                        // dorsal fin
    const V2(-0.16, 0.30), const V2(0.02, 0.78),
    const V2(0.26, 0.28),
  ], -0.62),
  ([                                        // belly fin
    const V2(-0.10, -0.30), const V2(0.04, -0.72), const V2(0.24, -0.28),
  ], 0.42),
], _fishPose);

final silhouetteLevels = <Level>[
  Level(
    name: 'Duck',
    hint: 'The pieces are not the picture.',
    boxes: [Box.form(_duck)],
    solution: _duckPose,
  ),
  Level(
    name: 'Fish',
    hint: 'Scattered, then whole.',
    boxes: [Box.form(_fish)],
    solution: _fishPose,
  ),
];
