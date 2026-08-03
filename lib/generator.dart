import 'dart:math' as math;

import 'geom.dart';
import 'level.dart';

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

  for (var i = 0; i < count; i++) {
    // One axis stays long so silhouettes have direction instead of reading
    // as a cloud of cubes.
    final long = r.nextInt(3);
    double ext(int axis) =>
        axis == long ? 0.5 + r.nextDouble() * 0.45 : 0.16 + r.nextDouble() * 0.14;
    final half = V3(ext(0), ext(1), ext(2));

    boxes.add(Box(
      center: at,
      half: half,
      hinged: i > 0 && i <= hinges,
    ));

    // Hang the next box off the end of this one, with a little overlap so the
    // chain stays visually joined.
    final axis = r.nextInt(3);
    final dir = r.nextBool() ? 1.0 : -1.0;
    final step = 0.75;
    at = V3(
      at.x + (axis == 0 ? half.x * 2 * step * dir : 0),
      at.y + (axis == 1 ? half.y * 2 * step * dir : 0),
      at.z + (axis == 2 ? half.z * 2 * step * dir : 0),
    );
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

class Generated {
  const Generated(this.level, this.metrics);
  final Level level;
  final Metrics metrics;
}

/// Rejection-sample until [wanted] levels survive, then order them easiest
/// first. Deterministic in [seed], so level 14 is the same level for everyone.
List<Generated> generateChapter({
  required int seed,
  required int wanted,
  required int hinges,
  int maxTries = 4000,
}) {
  final r = math.Random(seed);
  final kept = <Generated>[];

  for (var t = 0; kept.length < wanted && t < maxTries; t++) {
    final lv = _candidate(r, hinges, kept.length + 1);

    // Never ship a level that opens already solved.
    if (LevelRuntime(lv, res: 32).score(const Pose(0, 0, 0)).solved) continue;

    final m = measure(lv, r);
    if (m.basin > kMaxBasin || m.basin < kMinBasin) continue;
    // No correlation gate — see kMaxCorrelation. An unvalidated filter that
    // rejects the one level known to be good is worse than no filter.

    kept.add(Generated(lv, m));
  }

  // Easiest first. Ordered on [approach] rather than [basin] because basin
  // quantises to one or two solving poses and ties almost everything.
  kept.sort((a, b) => b.metrics.approach.compareTo(a.metrics.approach));
  return kept;
}
