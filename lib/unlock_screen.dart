import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'forms.dart';
import 'progress.dart';
import 'store.dart';

const _bg = Color(0xFF08080A);
const _amber = Color(0xFFE0A82E);
const _warm = Color(0xFFFFD68C);

/// The unlock, staged as a corridor of dark rooms with one light on.
///
/// The plan called for an in-world transition rather than a modal, and the map
/// already reads as a chain of lit corners — so the paywall is the same idea
/// with the lights off. Nothing here is a dialog box.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key, required this.store});

  final Store store;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lights = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _busy = false;

  int get _lockedLevels => allLevels.length - chapterEnd(0);

  @override
  void dispose() {
    _lights.dispose();
    super.dispose();
  }

  Future<void> _run(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      // The rooms light up before the screen leaves — the purchase resolves
      // in the world, not in a receipt.
      await _lights.forward();
      if (mounted) Navigator.of(context).pop(true);
    } else if (widget.store.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A1A1F),
          content: Text(widget.store.lastError!,
              style: const TextStyle(color: Colors.white70)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _lights,
                builder: (_, _) => CustomPaint(
                  painter: _CorridorPainter(
                      Curves.easeOutCubic.transform(_lights.value)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded, size: 22),
                color: Colors.white38,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'THE LIGHTS GO ON',
                      style: TextStyle(
                          fontSize: 11, letterSpacing: 6, color: _amber),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$_lockedLevels more rooms',
                      style: const TextStyle(
                          fontSize: 27,
                          letterSpacing: 2,
                          color: Color(0xFFEEEEF0)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Every chapter, once. No subscription,\n'
                      'no timers, no hints to buy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, height: 1.5, color: Colors.white38),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _amber,
                          foregroundColor: const Color(0xFF16120A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed:
                            (!s.canBuy || _busy) ? null : () => _run(s.buy),
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF16120A)),
                              )
                            : Text(
                                s.canBuy
                                    ? 'UNLOCK  ·  ${s.price}'
                                    : 'STORE UNAVAILABLE',
                                style: const TextStyle(
                                    fontSize: 13,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    // Apple requires this for any non-consumable purchase
                    // (Guideline 3.1.1). Its absence is a rejection.
                    TextButton(
                      onPressed: _busy ? null : () => _run(s.restore),
                      child: const Text(
                        'Restore purchase',
                        style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            color: Colors.white38),
                      ),
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

class _CorridorPainter extends CustomPainter {
  _CorridorPainter(this.lit);

  /// 0 -> all dark but the first, 1 -> every room lit.
  final double lit;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);

    const rooms = 5;
    final cx = size.width / 2;
    final top = size.height * 0.17;
    final gap = size.height * 0.085;

    for (var i = 0; i < rooms; i++) {
      // Rooms recede: smaller and dimmer with depth.
      final t = i / (rooms - 1);
      final r = size.width * (0.17 - 0.085 * t);
      final o = Offset(cx, top + i * gap + t * gap * 0.4);

      // The first room is chapter I and is always yours.
      final on = i == 0 ? 1.0 : (lit * rooms - i).clamp(0.0, 1.0);

      if (on > 0) {
        canvas.drawCircle(
          o,
          r * 2.2,
          Paint()
            ..shader = ui.Gradient.radial(o, r * 2.2, [
              _warm.withValues(alpha: 0.14 * on * (1 - t * 0.5)),
              const Color(0x0008080A),
            ], [
              0.0,
              1.0
            ]),
        );
      }

      final hex = Path();
      for (var v = 0; v < 6; v++) {
        final a = math.pi / 2 + v * math.pi / 3;
        final p = Offset(o.dx + math.cos(a) * r, o.dy - math.sin(a) * r);
        v == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
      }
      hex.close();

      canvas.drawPath(
        hex,
        Paint()
          ..color = Color.lerp(Colors.white.withValues(alpha: 0.02),
              _amber.withValues(alpha: 0.16), on)!,
      );
      canvas.drawPath(
        hex,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Color.lerp(Colors.white.withValues(alpha: 0.10),
              _amber.withValues(alpha: 0.85), on)!,
      );
      canvas.drawLine(
        Offset(o.dx, o.dy - r * 0.86),
        Offset(o.dx, o.dy + r * 0.12),
        Paint()
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.05 + 0.17 * on),
      );
    }
  }

  @override
  bool shouldRepaint(_CorridorPainter old) => old.lit != lit;
}
