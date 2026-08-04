import 'dart:math' as math;

import 'geom.dart';
import 'level.dart';
import 'mesh.dart';

/// THE WORKSHOP — the game read backwards.
///
/// The campaign is a *search*: here is a fixed sculpture, find the pose whose
/// two shadows match. The Workshop is *synthesis*: here are two shadows, build
/// something that casts them.
///
/// It works because of a property the silhouette chapter already leans on:
///
///   * wall B projects `(x, y)` — it **cannot see depth**
///   * wall A projects `(z, y)` — it **cannot see left-right**
///
/// So sliding a piece in X moves its shadow on B and leaves A untouched, and
/// sliding it in Z moves A and leaves B untouched. The two walls are two
/// independent editors of the same object, and Y is the one axis they share
/// and fight over. That is the puzzle, and it needs no new geometry — the
/// projections were always orthogonal, nobody had handed the player the axes.
///
/// Pieces are authored **centred on the origin**, with their home recorded
/// separately, so a placement is a translation and nothing else. The target is
/// the shadow cast by every piece sitting at home, which makes every puzzle
/// solvable by construction — the same guarantee the campaign levels get from
/// being authored as a solved pose.
class WorkshopPiece {
  const WorkshopPiece(this.poly, this.home, {this.thick = 0.16});

  /// Outline centred on (0,0).
  final List<V2> poly;

  /// Where it belongs.
  final V3 home;
  final double thick;

  Mesh at(V3 p) => Mesh.prism(poly, thick, at: p);
}

class WorkshopPuzzle {
  const WorkshopPuzzle(this.name, this.pieces, this.start);
  final String name;
  final List<WorkshopPiece> pieces;

  /// Where the pieces begin. Deliberately not "all at the origin": a heap at
  /// the centre casts one blob and reads as a bug rather than as a start.
  final List<V3> start;

  List<V3> get solution => [for (final p in pieces) p.home];
}

/// Scores an arbitrary arrangement against the puzzle's target shadows.
///
/// Separate from [LevelRuntime] because that one derives its targets from the
/// level's own geometry at a solved *pose* — here the geometry is what moves
/// and the pose never changes.
class WorkshopRuntime {
  WorkshopRuntime(this.puzzle, {this.res = 64})
      : _targetA = maskOfShadows(
            shadowMeshes(_world(puzzle, puzzle.solution), toWallA), res),
        _targetB = maskOfShadows(
            shadowMeshes(_world(puzzle, puzzle.solution), toWallB), res);

  final WorkshopPuzzle puzzle;
  final int res;
  final Mask _targetA, _targetB;
  late final Mask _scratchA = Mask(res);
  late final Mask _scratchB = Mask(res);

  static List<Mesh> _world(WorkshopPuzzle p, List<V3> at) =>
      [for (var i = 0; i < p.pieces.length; i++) p.pieces[i].at(at[i])];

  List<Mesh> world(List<V3> at) => _world(puzzle, at);

  List<Mesh2> targetShadowsA() =>
      shadowMeshes(_world(puzzle, puzzle.solution), toWallA);
  List<Mesh2> targetShadowsB() =>
      shadowMeshes(_world(puzzle, puzzle.solution), toWallB);

  Score score(List<V3> at) {
    final w = _world(puzzle, at);
    return Score(
      iou(maskOfShadows(shadowMeshes(w, toWallA), res, into: _scratchA),
          _targetA),
      iou(maskOfShadows(shadowMeshes(w, toWallB), res, into: _scratchB),
          _targetB),
    );
  }
}

// --- shape helpers ---------------------------------------------------------

List<V2> _ell(double rx, double ry, {int n = 14}) => [
      for (var i = 0; i < n; i++)
        V2(rx * math.cos(i * 2 * math.pi / n), ry * math.sin(i * 2 * math.pi / n)),
    ];

List<V2> _tri(double w, double h) =>
    [V2(0, h / 2), V2(w / 2, -h / 2), V2(-w / 2, -h / 2)];

List<V2> _quad(double w, double h) =>
    [V2(-w / 2, -h / 2), V2(w / 2, -h / 2), V2(w / 2, h / 2), V2(-w / 2, h / 2)];

/// Spread the pieces along X at mixed depths. Deterministic, so a puzzle opens
/// the same way for everyone, and far enough from home that nothing starts
/// solved.
List<V3> _scatter(int n) => [
      for (var i = 0; i < n; i++)
        V3(-0.78 + 1.56 * (i / math.max(1, n - 1)), -0.86,
            (i.isEven ? 0.55 : -0.55)),
    ];

final workshopPuzzles = <WorkshopPuzzle>[
  // Three pieces, one of them the whole point: the beak is small enough that
  // wall B barely notices it and wall A cannot see it at all until the depth
  // is right.
  WorkshopPuzzle(
    'Swan',
    [
      WorkshopPiece(_ell(0.52, 0.30), const V3(-0.10, -0.28, 0.00)), // body
      WorkshopPiece(_ell(0.13, 0.30), const V3(0.26, 0.16, -0.42)), // neck
      WorkshopPiece(_ell(0.17, 0.15), const V3(0.34, 0.46, 0.58)), // head
    ],
    _scatter(3),
  ),
  WorkshopPuzzle(
    'Cat',
    [
      WorkshopPiece(_ell(0.38, 0.40), const V3(0.00, -0.30, 0.00)), // body
      WorkshopPiece(_ell(0.27, 0.23), const V3(0.02, 0.30, -0.50)), // head
      WorkshopPiece(_tri(0.26, 0.34), const V3(-0.17, 0.58, 0.62)), // ear
      WorkshopPiece(_tri(0.26, 0.34), const V3(0.21, 0.58, -0.84)), // ear
      WorkshopPiece(_quad(0.16, 0.52), const V3(0.52, -0.34, 0.38)), // tail
    ],
    _scatter(5),
  ),
  WorkshopPuzzle(
    'Boat',
    [
      WorkshopPiece(_quad(1.26, 0.34), const V3(0.00, -0.58, 0.00)), // hull
      WorkshopPiece(_quad(0.09, 1.24), const V3(0.00, 0.20, -0.66)), // mast
      WorkshopPiece(_tri(0.62, 1.10), const V3(0.34, 0.16, 0.60)), // sail
    ],
    _scatter(3),
  ),
];
