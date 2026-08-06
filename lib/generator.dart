import 'dart:math' as math;

import 'geom.dart';
import 'level.dart';
import 'mesh.dart';

/// The vocabulary a generated piece can be cut from.
///
/// M0 shipped boxes only, and a box's shadow is its convex hull — which is why
/// hulls were enough then. These are not all convex: [Shape.ell], [Shape.tee]
/// and [Shape.chevron] have real concavities, so their shadows cannot be
/// recovered from a hull and the union of projected triangles is doing work.
/// That is the point of mixing them in — a notch in a silhouette is a
/// constraint a rectangle cannot express.
enum Shape {
  /// The M0 primitive.
  box,

  /// Constant-radius lathe. Reads as a limb rather than a plank.
  rod,

  /// Swelling lathe — the pear/vase family. Its outline has no straight edge,
  /// so it cannot be mistaken for a box seen at an angle.
  bulb,

  /// Triangular prism. The one shape whose two walls disagree most sharply:
  /// a wedge reads as a triangle from one side and a rectangle from the other.
  wedge,

  /// L, concave.
  ell,

  /// T, concave on both shoulders.
  tee,

  /// A chevron — concave, and strongly directional.
  chevron,

  /// Hexagonal prism. Convex, but rounder than a box without a lathe's cost.
  hex,
}

/// Rotate a piece built around its natural axis onto [axis].
///
/// Lathes run along Y and prisms extrude along Z, so without this every rod in
/// the game would be vertical and every wedge would face the same way — the
/// generated levels would share a family resemblance no amount of resizing
/// hides. Applied at the piece's own origin, before it is moved into place.
V3 _onAxis(V3 v, int axis) => switch (axis) {
      0 => V3(v.y, v.x, v.z),
      2 => V3(v.x, v.z, v.y),
      _ => v,
    };

/// Build one piece from its recipe.
///
/// `levels_ext.g.dart` calls this directly rather than carrying baked vertices:
/// a single lathe is ~90 vertices, and 200 levels of vertex dumps would be a
/// megabyte of source no one can read or diff. The recipe is the level.
///
/// [size] is half-extents for [Shape.box]; for everything else x is the radius
/// or half-width, y the half-length along the piece's own axis, z the
/// half-depth.
Box piece(Shape shape, V3 at, V3 size, {int axis = 1, bool hinged = false}) {
  if (shape == Shape.box) {
    // Kept as a real box: it is the cheap path, it needs no mesh built at all
    // (`Box.mesh` lathes one on demand), and it keeps the emitted source for
    // the original chapters byte-identical.
    final h = _onAxis(size, axis);
    return Box(center: at, half: V3(h.x.abs(), h.y.abs(), h.z.abs()), hinged: hinged);
  }

  final r = size.x, len = size.y, d = size.z;
  final Mesh base = switch (shape) {
    Shape.rod => Mesh.lathe([V2(r, -len), V2(r, len)], seg: 8),
    Shape.bulb => Mesh.lathe([
        V2(r * 0.22, -len),
        V2(r, -len * 0.25),
        V2(r * 0.78, len * 0.45),
        V2(r * 0.18, len),
      ], seg: 8),
    Shape.wedge =>
      Mesh.prism([V2(-r, -len), V2(r, -len), V2(0, len)], d),
    Shape.ell => Mesh.prism([
        V2(-r, -len), V2(r, -len), V2(r, -len + r * 0.7),
        V2(-r + r * 0.7, -len + r * 0.7), V2(-r + r * 0.7, len), V2(-r, len),
      ], d),
    Shape.tee => Mesh.prism([
        V2(-r, len), V2(-r, len - r * 0.6), V2(-r * 0.3, len - r * 0.6),
        V2(-r * 0.3, -len), V2(r * 0.3, -len), V2(r * 0.3, len - r * 0.6),
        V2(r, len - r * 0.6), V2(r, len),
      ], d),
    Shape.chevron => Mesh.prism([
        V2(0, -len), V2(r, len), V2(r * 0.45, len),
        V2(0, -len + r * 0.9), V2(-r * 0.45, len), V2(-r, len),
      ], d),
    Shape.hex => Mesh.prism([
        V2(-r * 0.5, -len), V2(r * 0.5, -len), V2(r, 0),
        V2(r * 0.5, len), V2(-r * 0.5, len), V2(-r, 0),
      ], d),
    Shape.box => throw StateError('handled above'),
  };

  return Box.form(
    base.map((v) {
      final p = _onAxis(v, axis);
      return V3(at.x + p.x, at.y + p.y, at.z + p.z);
    }),
    hinged: hinged,
  );
}

/// One piece's recipe, kept alongside the built [Level] so the offline tool can
/// print it. A built [Mesh] cannot be printed back into readable source.
class PieceSpec {
  const PieceSpec(this.shape, this.at, this.size,
      {this.axis = 1, this.hinged = false});
  final Shape shape;
  final V3 at, size;
  final int axis;
  final bool hinged;

  Box build() => piece(shape, at, size, axis: axis, hinged: hinged);
}

/// Quality metrics for a candidate level, measured by sampling poses rather
/// than reasoned about. This is what replaces hand-authoring: a level is kept
/// or thrown away on numbers, not on taste.
class Metrics {
  const Metrics({
    required this.basin,
    required this.approach,
    required this.correlation,
  });

  /// Fraction of sampled poses that solve BOTH walls. Used to accept or reject,
  /// not to rank: at a few hundred samples it quantises hard — most keepable
  /// levels land on one or two solving poses and tie with each other.
  final double basin;

  /// Fraction of sampled poses that get BOTH walls close without necessarily
  /// solving. Same idea as [basin] but with hundreds of hits instead of one, so
  /// it actually varies — this is what orders the difficulty curve.
  final double approach;

  /// Of the poses that get one wall close, how often is the other wall close
  /// too. Reported for study, **not used to accept or reject** — see the note
  /// on [kMaxCorrelation].
  final double correlation;
}

/// A pose is "close" on a wall at this score — deliberately looser than
/// [kSolveThreshold], so correlation is measured over the approach, not just
/// the bullseye.
const double _near = 0.75;

/// ⚠️ NOT USED AS A FILTER, on purpose.
///
/// It was meant to reject levels where the second sun is redundant. Measured
/// against the only ground truth available — Jhere's play session — it ranks
/// backwards: the Tee he blew through scores 0.40 and the Hinge he had to
/// reason about scores 0.67. Gating on it would throw away the good level.
///
/// A hill-climb findability metric was tried as a replacement and separated
/// them no better (40% / 37% / 35% across the three). See `tool/probe.dart`.
///
/// So: no validated difficulty filter exists yet. The honest next step is
/// human — play generated 1, 6 and 12 and say whether difficulty rises.
/// Until then this number is recorded in `levels.g.dart` for study only.
const double kMaxCorrelation = 0.55;

/// Above this the level is too easy: too many poses simply solve it.
const double kMaxBasin = 0.015;

/// Below this it is a needle in a haystack and reads as unfair.
const double kMinBasin = 0.0004;

Metrics measure(Level lv, math.Random r, {int samples = 250, int res = 24}) {
  final rt = LevelRuntime(lv, res: res);
  var both = 0, nearA = 0, nearB = 0, nearBoth = 0;

  for (var i = 0; i < samples; i++) {
    final s = rt.score(Pose(
      (r.nextDouble() - 0.5) * 2 * math.pi,
      (r.nextDouble() - 0.5) * 2.8,
      lv.hasHinge ? (r.nextDouble() - 0.5) * 3.2 : 0,
    ));
    if (s.a >= kSolveThreshold && s.b >= kSolveThreshold) both++;
    final a = s.a >= _near, b = s.b >= _near;
    if (a) nearA++;
    if (b) nearB++;
    if (a && b) nearBoth++;
  }

  final floor = math.min(nearA, nearB);
  return Metrics(
    basin: both / samples,
    approach: nearBoth / samples,
    correlation: floor == 0 ? 0 : nearBoth / floor,
  );
}

/// One candidate sculpture: a chain of boxes, each hung off the previous one
/// so the whole thing reads as a single object rather than scattered blocks.
Level _candidate(math.Random r, int hinges, int index) {
  final count = 2 + r.nextInt(3); // 2–4 boxes
  final boxes = <Box>[];
  var at = const V3(0, 0, 0);
  var prevLong = -1;

  for (var i = 0; i < count; i++) {
    // One axis stays long so silhouettes have direction instead of reading as
    // a cloud of cubes — and it must differ from the previous arm's, or the
    // chain extends in a straight line and the whole sculpture is a featureless
    // column. (Generated level 1 was exactly that before this rule.)
    var long = r.nextInt(3);
    if (long == prevLong) long = (long + 1 + r.nextInt(2)) % 3;

    double ext(int axis) => axis == long
        ? 0.5 + r.nextDouble() * 0.45
        : 0.16 + r.nextDouble() * 0.14;
    final half = V3(ext(0), ext(1), ext(2));

    boxes.add(Box(
      center: at,
      half: half,
      hinged: i > 0 && i <= hinges,
    ));

    // Hang the next arm off the end of this one along its long axis, with a
    // little overlap so the chain stays visually joined. Since the next arm
    // runs along a different axis, every joint is a bend.
    final dir = r.nextBool() ? 1.0 : -1.0;
    const step = 0.8;
    at = V3(
      at.x + (long == 0 ? half.x * 2 * step * dir : 0),
      at.y + (long == 1 ? half.y * 2 * step * dir : 0),
      at.z + (long == 2 ? half.z * 2 * step * dir : 0),
    );
    prevLong = long;
  }

  return Level(
    name: '$index',
    hint: '',
    boxes: boxes,
    solution: Pose(
      (r.nextDouble() - 0.5) * 2 * math.pi,
      (r.nextDouble() - 0.5) * 2.4,
      hinges > 0 ? (r.nextDouble() - 0.5) * 2.6 : 0,
    ),
  );
}

/// Every shape, weighted. Repeats are the weighting.
///
/// Boxes stay the most common piece on purpose. A room of nothing but lathes
/// and chevrons reads as decoration — the player needs at least one edge whose
/// orientation they can name in order to reason about the pose at all.
const kAllShapes = <Shape>[
  Shape.box, Shape.box, Shape.box,
  Shape.rod, Shape.rod,
  Shape.wedge, Shape.wedge,
  Shape.hex,
  Shape.bulb,
  Shape.ell,
  Shape.tee,
  Shape.chevron,
];

/// A candidate cut from mixed shapes rather than boxes alone.
///
/// Deliberately a separate function from [_candidate] rather than a flag
/// inside it. The two draw different numbers of values from [r], and
/// [_candidate]'s exact draw order is load-bearing: endless mode generates on
/// the device from the same code, so a changed sequence would silently
/// renumber every endless room and invalidate stars that are keyed by depth.
(Level, List<PieceSpec>) _mixedCandidate(
    math.Random r, int hinges, int index, List<Shape> pool) {
  final count = 2 + r.nextInt(3); // 2–4 pieces
  final specs = <PieceSpec>[];
  var at = const V3(0, 0, 0);
  var prevAxis = -1;

  for (var i = 0; i < count; i++) {
    // Same rule as the box chain: the long axis must differ from the previous
    // arm's, or the sculpture grows into a featureless column.
    var axis = r.nextInt(3);
    if (axis == prevAxis) axis = (axis + 1 + r.nextInt(2)) % 3;

    final shape = pool[r.nextInt(pool.length)];
    final len = 0.5 + r.nextDouble() * 0.45;
    final girth = 0.16 + r.nextDouble() * 0.14;
    final depth = 0.15 + r.nextDouble() * 0.15;

    // Every shape reads the second component as "along my own length", boxes
    // included — `piece` runs the half-extents through the same _onAxis turn,
    // so one convention covers the whole vocabulary.
    specs.add(PieceSpec(shape, at, V3(girth, len, depth),
        axis: axis, hinged: i > 0 && i <= hinges));

    final dir = r.nextBool() ? 1.0 : -1.0;
    const step = 0.8;
    final reach = len * 2 * step * dir;
    at = V3(
      at.x + (axis == 0 ? reach : 0),
      at.y + (axis == 1 ? reach : 0),
      at.z + (axis == 2 ? reach : 0),
    );
    prevAxis = axis;
  }

  final lv = Level(
    name: '$index',
    hint: '',
    boxes: [for (final s in specs) s.build()],
    solution: Pose(
      (r.nextDouble() - 0.5) * 2 * math.pi,
      (r.nextDouble() - 0.5) * 2.4,
      hinges > 0 ? (r.nextDouble() - 0.5) * 2.6 : 0,
    ),
  );
  return (lv, specs);
}

class Generated {
  const Generated(this.level, this.metrics, {this.specs});
  final Level level;
  final Metrics metrics;

  /// Present only for mixed-shape rooms. The offline tool needs the recipe to
  /// emit source; the box chapters print their boxes directly.
  final List<PieceSpec>? specs;
}

/// Rejection-sample until [wanted] levels survive, then order them easiest
/// first. Deterministic in [seed], so level 14 is the same level for everyone.
List<Generated> generateChapter({
  required int seed,
  required int wanted,
  required int hinges,
  int maxTries = 4000,
  math.Random Function(int seed)? rng,
  /// Cut rooms from the full shape vocabulary instead of boxes alone.
  ///
  /// ⚠️ **Defaults false, and endless mode must never pass true.** Endless
  /// generates on the device and its ledger is keyed by depth on the promise
  /// that room 340 is the same puzzle forever; flipping this would rewrite
  /// every room and quietly move the stars onto different puzzles.
  bool mixed = false,

  /// Which shapes this chapter may be cut from. Restricting it is what lets a
  /// chapter be *named* after a shape without the name becoming a lie — the
  /// same reason `progress_test` asserts chapter boundaries track hinge count.
  /// Ignored unless [mixed].
  List<Shape> pool = kAllShapes,
}) {
  // Defaults to dart:math so the already-baked levels.g.dart and dailies.g.dart
  // stay byte-identical if they are ever regenerated. Endless passes
  // StableRandom, because it generates on the device and its sequence must
  // outlive SDK upgrades — see lib/rng.dart.
  final r = (rng ?? math.Random.new)(seed);
  final kept = <Generated>[];

  for (var t = 0; kept.length < wanted && t < maxTries; t++) {
    final Level lv;
    final List<PieceSpec>? specs;
    if (mixed) {
      (lv, specs) = _mixedCandidate(r, hinges, kept.length + 1, pool);
    } else {
      lv = _candidate(r, hinges, kept.length + 1);
      specs = null;
    }

    // Never ship a level that opens already solved.
    if (LevelRuntime(lv, res: 32).score(const Pose(0, 0, 0)).solved) continue;

    final m = measure(lv, r);
    if (m.basin > kMaxBasin || m.basin < kMinBasin) continue;
    // No correlation gate — see kMaxCorrelation. An unvalidated filter that
    // rejects the one level known to be good is worse than no filter.

    kept.add(Generated(lv, m, specs: specs));
  }

  // Easiest first. Ordered on [approach] rather than [basin] because basin
  // quantises to one or two solving poses and ties almost everything.
  kept.sort((a, b) => b.metrics.approach.compareTo(a.metrics.approach));
  return kept;
}
