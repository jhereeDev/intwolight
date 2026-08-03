// ignore_for_file: avoid_print — CLI experiment, print is the output.
// Scratch experiment: does hill-climb findability separate the known-easy Tee
// from the known-good Hinge? Ground truth is Jhere's play session — the Tee
// solved itself in seconds, level 3 took real reasoning.
import 'dart:math' as math;

import 'package:two_suns/level.dart';

/// Climb from a random start toward whichever step most improves the weaker
/// wall. Roughly what a player does: push the shadow that is furthest off and
/// see what it costs the other one.
bool _climb(LevelRuntime rt, math.Random r, {int steps = 90}) {
  var p = Pose(
    (r.nextDouble() - 0.5) * 2 * math.pi,
    (r.nextDouble() - 0.5) * 2.4,
    rt.level.hasHinge ? (r.nextDouble() - 0.5) * 2.6 : 0,
  );
  var step = 0.30;

  for (var i = 0; i < steps; i++) {
    final here = rt.score(p);
    if (here.solved) return true;

    var best = math.min(here.a, here.b) + 0.001 * (here.a + here.b);
    Pose? bestPose;

    for (final d in [
      Pose(step, 0, 0), Pose(-step, 0, 0), //
      Pose(0, step, 0), Pose(0, -step, 0),
      if (rt.level.hasHinge) Pose(0, 0, step),
      if (rt.level.hasHinge) Pose(0, 0, -step),
    ]) {
      final q = Pose(p.yaw + d.yaw, p.pitch + d.pitch, p.hinge + d.hinge);
      final s = rt.score(q);
      final v = math.min(s.a, s.b) + 0.001 * (s.a + s.b);
      if (v > best) {
        best = v;
        bestPose = q;
      }
    }

    if (bestPose == null) {
      step *= 0.6; // stuck — refine
      if (step < 0.01) return false;
    } else {
      p = bestPose;
    }
  }
  return rt.score(p).solved;
}

void main() {
  for (final lv in levels) {
    final rt = LevelRuntime(lv, res: 32);
    final r = math.Random(11);
    var hits = 0;
    const tries = 60;
    for (var i = 0; i < tries; i++) {
      if (_climb(rt, r)) hits++;
    }
    print('${lv.name.padRight(10)} findability '
        '${(hits / tries * 100).toStringAsFixed(0)}%  ($hits/$tries climbs solved)');
  }
}
