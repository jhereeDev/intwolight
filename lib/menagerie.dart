import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'forms.dart';
import 'geom.dart';
import 'level.dart';
import 'progress.dart';
import 'scene.dart';

const _amber = Color(0xFFE0A82E);
const _bg = Color(0xFF08080A);

/// The figures worth collecting: every level with a *name* rather than a
/// number.
///
/// Generated levels are called '1'…'36' and are abstract by construction —
/// there is nothing to recognise, so nothing to collect. The authored ones are
/// called Pear, Hare, Cat, Moth, and those are the only things in this game a
/// player can point at and name.
///
/// This is why star counts were never enough. A star total is a number about
/// you; a shelf of found figures is a set of *things*, and an empty slot on it
/// asks a question a number cannot.
final figures = <({int index, Level level})>[
  for (var i = 0; i < allLevels.length; i++)
    if (int.tryParse(allLevels[i].name) == null)
      (index: i, level: allLevels[i]),
];

final _outlines = <int, Path>{};

/// The figure as the wall sees it: wall B's shadow at the level's solution
/// pose, which is the silhouette the level was authored to produce.
Path outlineOf(int index) => _outlines.putIfAbsent(
      index,
      () => unionOutline2D(
        shadowMeshes(
            worldMeshes(allLevels[index], allLevels[index].solution), toWallB),
      ),
    );

class MenagerieScreen extends StatelessWidget {
  const MenagerieScreen({super.key, required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final found = figures.where((f) => progress.solved(f.index)).length;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 22, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.keyboard_arrow_left_rounded,
                        size: 20, color: Colors.white38),
                  ),
                  const Text('FOUND',
                      style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 5,
                          color: Colors.white54)),
                  const Spacer(),
                  Text('$found / ${figures.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: Colors.white38)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemCount: figures.length,
                itemBuilder: (_, i) {
                  final f = figures[i];
                  return _FigureTile(
                    index: f.index,
                    name: f.level.name,
                    found: progress.solved(f.index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FigureTile extends StatelessWidget {
  const _FigureTile(
      {required this.index, required this.name, required this.found});
  final int index;
  final String name;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: found ? _amber.withValues(alpha: 0.32) : Colors.white10),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        children: [
          Expanded(
            child: found
                ? CustomPaint(
                    painter: _OutlinePainter(outlineOf(index)),
                    size: Size.infinite,
                  )
                // Deliberately not a faded preview. Showing the shape of a
                // figure nobody has found yet spends the only surprise the
                // level has.
                : const Center(
                    child: Text('?',
                        style: TextStyle(
                            fontSize: 20, color: Colors.white12))),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              found ? name.toUpperCase() : '—',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 2,
                color: found ? Colors.white38 : Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinePainter extends CustomPainter {
  _OutlinePainter(this.path);
  final Path path;

  @override
  void paint(Canvas canvas, Size size) {
    final b = path.getBounds();
    if (b.isEmpty) return;
    // Wall coordinates are y-up; the canvas is y-down, so the vertical scale
    // is negated. Without it every figure hangs upside down — which for a Cat
    // still reads as a cat, so it would survive a careless glance.
    final s = math.min(size.width / b.width, size.height / b.height) * 0.7;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(s, -s)
      ..translate(-b.center.dx, -b.center.dy)
      ..drawPath(path, Paint()..color = _amber.withValues(alpha: 0.82))
      ..restore();
  }

  @override
  bool shouldRepaint(_OutlinePainter old) => old.path != path;
}
