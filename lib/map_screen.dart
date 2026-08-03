import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'levels.g.dart';
import 'progress.dart';

const _bg = Color(0xFF08080A);
const _amber = Color(0xFFE0A82E);
const _warm = Color(0xFFFFD68C);

const double _spacing = 104;
const double _headerH = 104;
const double _topPad = 96;
const double _botPad = 120;

/// Where every node sits. Shared by the painter and the hit test so they can
/// never disagree — the commonest way a hand-drawn map goes subtly wrong.
class MapLayout {
  MapLayout(this.width);
  final double width;

  double _headersBefore(int i) => (chapterOf(i) + 1) * _headerH;

  Offset nodeAt(int i) => Offset(
        width / 2 + math.sin(i * 0.85) * width * 0.19,
        _topPad + _headersBefore(i) + i * _spacing,
      );

  /// y of the chapter [c] title block.
  double headerY(int c) =>
      _topPad + c * _headerH + chapterStarts[c] * _spacing + _headerH * 0.35;

  double get contentHeight =>
      nodeAt(generatedLevels.length - 1).dy + _botPad;

  int? hit(Offset p) {
    for (var i = 0; i < generatedLevels.length; i++) {
      if ((nodeAt(i) - p).distance <= 38) return i;
    }
    return null;
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.progress, required this.onPlay});

  final Progress progress;

  /// Returns the level index chosen; the caller pushes the play screen.
  final Future<void> Function(int index) onPlay;

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centreOnCurrent());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int get _current {
    for (var i = 0; i < generatedLevels.length; i++) {
      if (!widget.progress.solved(i)) return i;
    }
    return generatedLevels.length - 1;
  }

  void _centreOnCurrent() {
    if (!_scroll.hasClients) return;
    final l = MapLayout(MediaQuery.sizeOf(context).width);
    final target = l.nodeAt(_current).dy - MediaQuery.sizeOf(context).height * 0.45;
    _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final layout = MapLayout(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scroll,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) async {
                  final i = layout.hit(d.localPosition);
                  if (i == null) return;
                  if (widget.progress.chapterLocked(chapterOf(i))) return;
                  await widget.onPlay(i);
                  if (mounted) setState(() {});
                },
                child: SizedBox(
                  width: layout.width,
                  height: layout.contentHeight,
                  child: CustomPaint(
                    painter: _MapPainter(
                      layout: layout,
                      progress: widget.progress,
                      current: _current,
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Container(
                height: 90,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_bg, Color(0x0008080A)],
                  ),
                ),
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Row(
                  children: [
                    const Text(
                      'IN TWO LIGHTS',
                      style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 5,
                          color: Colors.white54),
                    ),
                    const Spacer(),
                    Icon(Icons.star_rounded,
                        size: 13, color: _amber.withValues(alpha: 0.8)),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.progress.totalStars}'
                      ' / ${generatedLevels.length * 3}',
                      style: const TextStyle(
                          fontSize: 12, letterSpacing: 2, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.layout,
    required this.progress,
    required this.current,
  });

  final MapLayout layout;
  final Progress progress;
  final int current;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);

    // The thread between rooms.
    final thread = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.07);
    for (var i = 0; i < generatedLevels.length - 1; i++) {
      if (chapterOf(i) != chapterOf(i + 1)) continue;
      final a = layout.nodeAt(i), b = layout.nodeAt(i + 1);
      final path = Path()
        ..moveTo(a.dx, a.dy + 30)
        ..cubicTo(a.dx, a.dy + 68, b.dx, b.dy - 68, b.dx, b.dy - 30);
      canvas.drawPath(path, thread);
    }

    for (var c = 0; c < chapterStarts.length; c++) {
      _chapterHeader(canvas, size, c);
    }
    for (var i = 0; i < generatedLevels.length; i++) {
      _room(canvas, i);
    }
  }

  void _chapterHeader(Canvas canvas, Size size, int c) {
    final y = layout.headerY(c);
    final locked = progress.chapterLocked(c);
    final done = progress.solvedInChapter(c);
    final total = chapterEnd(c) - chapterStarts[c];

    _text(
      canvas,
      'CHAPTER ${'I' * (c + 1)}',
      Offset(size.width / 2, y - 16),
      TextStyle(
          fontSize: 10,
          letterSpacing: 5,
          color: _amber.withValues(alpha: locked ? 0.25 : 0.75)),
    );
    _text(
      canvas,
      chapterNames[c],
      Offset(size.width / 2, y + 8),
      TextStyle(
          fontSize: 19,
          letterSpacing: 3,
          color: Colors.white.withValues(alpha: locked ? 0.2 : 0.82)),
    );
    _text(
      canvas,
      locked ? 'LOCKED' : '$done / $total',
      Offset(size.width / 2, y + 34),
      const TextStyle(fontSize: 10, letterSpacing: 3, color: Colors.white24),
    );

    // Above the title, not below it — below puts the rule straight through the
    // chapter's first room.
    if (c > 0) {
      final rule = Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(size.width * 0.34, y - 46),
          Offset(size.width * 0.66, y - 46), rule);
    }
  }

  /// Each node is a miniature of the room the level is played in — the map is
  /// a chain of little corners rather than a row of numbered circles.
  void _room(Canvas canvas, int i) {
    final o = layout.nodeAt(i);
    final solved = progress.solved(i);
    final locked = progress.chapterLocked(chapterOf(i));
    final isCurrent = i == current && !solved && !locked;
    const r = 26.0;

    final hex = Path();
    for (var v = 0; v < 6; v++) {
      final a = math.pi / 2 + v * math.pi / 3;
      final p = Offset(o.dx + math.cos(a) * r, o.dy - math.sin(a) * r);
      v == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
    }
    hex.close();

    if (isCurrent || solved) {
      canvas.drawCircle(
        o,
        r * 2.1,
        Paint()
          ..shader = ui.Gradient.radial(o, r * 2.1, [
            (solved ? _amber : _warm).withValues(alpha: solved ? 0.13 : 0.09),
            const Color(0x0008080A),
          ], [
            0.0,
            1.0
          ]),
      );
    }

    canvas.drawPath(
      hex,
      Paint()
        ..color = solved
            ? _amber.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: locked ? 0.015 : 0.035),
    );
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 1.6 : 1.1
        ..color = solved
            ? _amber.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: locked ? 0.10 : (isCurrent ? 0.7 : 0.28)),
    );

    // The seam, so the glyph reads as a corner and not just a hexagon.
    canvas.drawLine(
      Offset(o.dx, o.dy - r * 0.86),
      Offset(o.dx, o.dy + r * 0.12),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white
            .withValues(alpha: locked ? 0.05 : (solved ? 0.22 : 0.13)),
    );

    if (locked) {
      _text(canvas, '·', o.translate(0, 1),
          const TextStyle(fontSize: 20, color: Colors.white24));
      return;
    }

    _text(
      canvas,
      '${i + 1}',
      o.translate(0, 1),
      TextStyle(
        fontSize: 13,
        letterSpacing: 1,
        color: solved
            ? _warm.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: isCurrent ? 0.85 : 0.4),
      ),
    );

    // Three marks below, filled by precision.
    final stars = progress.starsOf(i);
    for (var s = 0; s < 3; s++) {
      final p = Offset(o.dx + (s - 1) * 11, o.dy + r + 13);
      canvas.drawCircle(
        p,
        2.4,
        Paint()
          ..color = s < stars
              ? _amber
              : Colors.white.withValues(alpha: solved ? 0.14 : 0.07),
      );
    }
  }

  void _text(Canvas canvas, String s, Offset centre, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MapPainter old) => true;
}
