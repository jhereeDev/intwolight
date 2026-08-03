import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'geom.dart';
import 'level.dart';
import 'levels.g.dart';

// M0 — the kill gate. Deliberately ugly: three flat panels, a slider, and two
// numbers. The only question this build exists to answer is whether making one
// shadow right actually breaks the other. None of this is the real interface.

void main() => runApp(const TwoSunsApp());

class TwoSunsApp extends StatelessWidget {
  const TwoSunsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TWO SUNS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const GateScreen(),
      );
}

class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  int _index = 0;
  Pose _pose = const Pose(0, 0, 0);
  late LevelRuntime _rt = LevelRuntime(generatedLevels[0]);

  void _load(int i) => setState(() {
        _index = i.clamp(0, generatedLevels.length - 1);
        _rt = LevelRuntime(generatedLevels[_index]);
        _pose = const Pose(0, 0, 0);
      });

  @override
  Widget build(BuildContext context) {
    final lv = generatedLevels[_index];
    final world = worldCorners(lv, _pose);
    final score = _rt.score(_pose);

    return Scaffold(
      appBar: AppBar(
        title: Text('TWO SUNS · ${_index + 1}/${generatedLevels.length}'),
        actions: [
          IconButton(
            onPressed: _index > 0 ? () => _load(_index - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: _index < generatedLevels.length - 1
                ? () => _load(_index + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(lv.hint,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onPanUpdate: (d) => setState(() => _pose = Pose(
                    _pose.yaw + d.delta.dx * 0.012,
                    (_pose.pitch + d.delta.dy * 0.012).clamp(-1.4, 1.4),
                    _pose.hinge,
                  )),
              child: CustomPaint(
                size: Size.infinite,
                painter: SolidPainter(world),
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('drag to rotate',
                        style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: _WallPanel(
                    label: 'LEFT WALL',
                    value: score.a,
                    target: _rt.targetHullsA(),
                    current: shadows(world, toWallA),
                  ),
                ),
                Expanded(
                  child: _WallPanel(
                    label: 'BACK WALL',
                    value: score.b,
                    target: _rt.targetHullsB(),
                    current: shadows(world, toWallB),
                  ),
                ),
              ],
            ),
          ),
          if (lv.hasHinge)
            Slider(
              value: _pose.hinge,
              min: -1.6,
              max: 1.6,
              onChanged: (v) =>
                  setState(() => _pose = Pose(_pose.yaw, _pose.pitch, v)),
            ),
          Container(
            width: double.infinity,
            color: score.solved ? Colors.amber : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              score.solved ? 'SOLVED' : 'keep going',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: score.solved ? Colors.black : Colors.white24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WallPanel extends StatelessWidget {
  const _WallPanel({
    required this.label,
    required this.value,
    required this.target,
    required this.current,
  });

  final String label;
  final double value;
  final List<List<V2>> target, current;

  @override
  Widget build(BuildContext context) {
    final hit = value >= kSolveThreshold;
    return Column(
      children: [
        Text('$label  ${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 11,
                color: hit ? Colors.amber : Colors.white38,
                letterSpacing: 1)),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: ShadowPainter(target: target, current: current, hit: hit),
          ),
        ),
      ],
    );
  }
}

/// Isometric view of the solid: cull back faces, sort far-to-near, flat shade.
/// Correct at the 2–3 boxes these levels use; do not generalise it.
class SolidPainter extends CustomPainter {
  SolidPainter(this.world);
  final List<List<V3>> world;

  static const _view = V3(0.577, 0.577, 0.577);

  Offset _project(V3 v, Size s, double k) => Offset(
        s.width / 2 + (v.x - v.z) * 0.866 * k,
        s.height / 2 + (-v.y + (v.x + v.z) * 0.5) * k,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width, size.height) / 5.0;
    final faces = <({double depth, Path path, double shade})>[];

    for (final corners in world) {
      for (final f in Box.faces) {
        final a = corners[f[0]], b = corners[f[1]], c = corners[f[2]];
        final n = (b - a).cross(c - a);
        final lit = n.dot(_view);
        if (lit <= 0) continue; // back face

        final len = math.sqrt(n.dot(n));
        final shade = len == 0 ? 0.0 : (lit / len).clamp(0.0, 1.0);

        final path = Path();
        for (var i = 0; i < f.length; i++) {
          final p = _project(corners[f[i]], size, k);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();

        var d = 0.0;
        for (final i in f) {
          d += corners[i].dot(_view);
        }
        faces.add((depth: d / f.length, path: path, shade: shade));
      }
    }

    faces.sort((x, y) => x.depth.compareTo(y.depth)); // far first
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF0C0E14);
    for (final f in faces) {
      canvas.drawPath(
          f.path,
          Paint()
            ..color = Color.lerp(
                const Color(0xFF1D2230), const Color(0xFFE8E4DA), f.shade)!);
      canvas.drawPath(f.path, edge);
    }
  }

  @override
  bool shouldRepaint(SolidPainter old) => true;
}

class ShadowPainter extends CustomPainter {
  ShadowPainter(
      {required this.target, required this.current, required this.hit});
  final List<List<V2>> target, current;
  final bool hit;

  Path _path(List<V2> hull, Size s, double k) {
    final p = Path();
    for (var i = 0; i < hull.length; i++) {
      final x = s.width / 2 + hull[i].x * k;
      final y = s.height / 2 - hull[i].y * k;
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width, size.height) / 4.4;

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white24;
    for (final h in target) {
      if (h.length >= 3) canvas.drawPath(_path(h, size, k), outline);
    }

    final fill = Paint()
      ..color = hit
          ? Colors.amber.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.28);
    for (final h in current) {
      if (h.length >= 3) canvas.drawPath(_path(h, size, k), fill);
    }
  }

  @override
  bool shouldRepaint(ShadowPainter old) => true;
}
