import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'forms.dart';
import 'daily.dart';
import 'progress.dart';
import 'store.dart';
import 'unlock_screen.dart';

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
      nodeAt(allLevels.length - 1).dy + _botPad;

  int? hit(Offset p) {
    for (var i = 0; i < allLevels.length; i++) {
      if ((nodeAt(i) - p).distance <= 38) return i;
    }
    return null;
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.progress,
    required this.daily,
    required this.store,
    required this.onPlay,
    required this.onDaily,
  });

  final Progress progress;

  /// The daily ledger, keyed by day number rather than level index.
  final Progress daily;
  final Store store;

  /// Returns the level index chosen; the caller pushes the play screen.
  final Future<void> Function(int index) onPlay;

  /// Today's room. Free, and outside the chapter gate on purpose — it is the
  /// reason to open the app on a day when the campaign is finished, so
  /// paywalling it would be charging for the retention loop.
  final Future<void> Function() onDaily;

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centreOnCurrent());
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  bool get _unlocked => widget.store.unlocked;

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _scroll.dispose();
    super.dispose();
  }

  int get _current {
    for (var i = 0; i < allLevels.length; i++) {
      if (!widget.progress.solved(i)) return i;
    }
    return allLevels.length - 1;
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
                  if (Progress.chapterLocked(chapterOf(i),
                      unlocked: _unlocked)) {
                    await Navigator.of(context).push<bool>(MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => UnlockScreen(store: widget.store),
                    ));
                    if (mounted) setState(() {});
                    return;
                  }
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
                      unlocked: _unlocked,
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
                    const SizedBox(width: 14),
                    _TodayChip(
                      done: widget.daily.solved(dailyDayNumber(DateTime.now())),
                      streak:
                          widget.daily.streakEndingAt(dailyDayNumber(DateTime.now())),
                      onTap: () async {
                        await widget.onDaily();
                        if (mounted) setState(() {});
                      },
                    ),
                    const Spacer(),
                    Icon(Icons.star_rounded,
                        size: 13, color: _amber.withValues(alpha: 0.8)),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.progress.totalStars}'
                      ' / ${allLevels.length * 3}',
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

/// The only always-visible entry point that is not a chapter. Deliberately
/// small: the campaign is still the game, and this is the thing that brings
/// someone back on day 42 when the campaign is done.
class _TodayChip extends StatelessWidget {
  const _TodayChip(
      {required this.done, required this.streak, required this.onTap});
  final bool done;

  /// Consecutive days. Shown from the first one, because a streak that only
  /// appears at 3 is invisible exactly when it would start mattering.
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
                color: done ? _amber.withValues(alpha: 0.5) : Colors.white24),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done) ...[
                Icon(Icons.check_rounded, size: 11, color: _amber),
                const SizedBox(width: 5),
              ],
              Text(
                'TODAY',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 3,
                  color: done ? _amber : Colors.white54,
                ),
              ),
              if (streak > 0) ...[
                const SizedBox(width: 7),
                Container(
                  width: 1,
                  height: 9,
                  color: Colors.white24,
                ),
                const SizedBox(width: 7),
                Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: done ? _amber : Colors.white38,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Repeating 'I' gave "CHAPTER IIII" the moment a fourth chapter existed.
String _roman(int n) {
  const pairs = [(10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I')];
  var out = '', left = n;
  for (final (value, sym) in pairs) {
    while (left >= value) {
      out += sym;
      left -= value;
    }
  }
  return out;
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.layout,
    required this.progress,
    required this.current,
    required this.unlocked,
  });

  final MapLayout layout;
  final Progress progress;
  final int current;
  final bool unlocked;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);

    // The thread between rooms.
    final thread = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.07);
    for (var i = 0; i < allLevels.length - 1; i++) {
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
    for (var i = 0; i < allLevels.length; i++) {
      _room(canvas, i);
    }
  }

  void _chapterHeader(Canvas canvas, Size size, int c) {
    final y = layout.headerY(c);
    final locked = Progress.chapterLocked(c, unlocked: unlocked);
    final done = progress.solvedInChapter(c);
    final total = chapterEnd(c) - chapterStarts[c];

    _text(
      canvas,
      'CHAPTER ${_roman(c + 1)}',
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
    final locked = Progress.chapterLocked(chapterOf(i), unlocked: unlocked);
    // Locked beats solved. Progress survives an expired or refunded unlock, so
    // without this a locked chapter renders in full amber as though it were
    // still yours to play.
    final solved = progress.solved(i) && !locked;
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
