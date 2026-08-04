import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'geom.dart';
import 'level.dart';
import 'scene.dart';
import 'widgets.dart';
import 'workshop.dart';

const _amber = Color(0xFFE0A82E);

/// Build a sculpture that casts two given shadows.
///
/// The control scheme *is* the geometry lesson, so it is worth stating: drag
/// moves the selected piece left-right and up-down, and the dial moves it in
/// depth. Wall B cannot see depth and wall A cannot see left-right, so the
/// drag edits one wall and the dial edits the other. Height is the only axis
/// they share, and it is where the puzzle actually bites.
class WorkshopScreen extends StatefulWidget {
  const WorkshopScreen({super.key, required this.puzzle, this.suppressPanel = false});
  final WorkshopPuzzle puzzle;

  /// Press-kit capture only.
  final bool suppressPanel;

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen>
    with SingleTickerProviderStateMixin {
  late final WorkshopRuntime _rt = WorkshopRuntime(widget.puzzle);
  late List<V3> _at = [...widget.puzzle.start];
  late Score _score = _rt.score(_at);
  int _sel = 0;

  late final Path _targetA = unionOutline2D(_rt.targetShadowsA());
  late final Path _targetB = unionOutline2D(_rt.targetShadowsB());

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..addListener(() => setState(() {}));
  bool _wasSolved = false;

  final List<List<V3>> _undo = [];

  static final List<Offset> _motes = [
    for (var i = 0; i < 26; i++)
      Offset(_rand(i * 2) * 0.9 + 0.05, _rand(i * 2 + 1) * 0.7 + 0.12),
  ];
  static double _rand(int i) {
    final x = math.sin(i * 12.9898 + 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  void _mark() {
    _undo.add([..._at]);
    if (_undo.length > 24) _undo.removeAt(0);
  }

  void _place(V3 p) {
    // Kept inside the room. A piece dragged off into the dark is not a design
    // choice, it is a piece the player has to go looking for.
    final next = [..._at];
    next[_sel] = V3(
      p.x.clamp(-1.3, 1.3),
      p.y.clamp(-1.1, 1.1),
      p.z.clamp(-1.3, 1.3),
    );
    final s = _rt.score(next);
    if (s.solved && !_wasSolved) {
      _wasSolved = true;
      HapticFeedback.mediumImpact();
      _glow.forward();
    } else if (!s.solved && _wasSolved) {
      _wasSolved = false;
      _glow.reverse();
    }
    setState(() {
      _at = next;
      _score = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    final world = _rt.world(_at);
    final g = Curves.easeOutCubic.transform(_glow.value);
    final solved = _score.solved && !widget.suppressPanel;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => _mark(),
                onPanUpdate: (d) {
                  final c = _at[_sel];
                  _place(V3(c.x + d.delta.dx * 0.004,
                      c.y - d.delta.dy * 0.004, c.z));
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: CornerScenePainter(
                    world: world,
                    targetsA: _targetA,
                    targetsB: _targetB,
                    castA: shadowMeshes(world, toWallA),
                    castB: shadowMeshes(world, toWallB),
                    hitA: _score.a >= kSolveThreshold,
                    hitB: _score.b >= kSolveThreshold,
                    glow: g,
                    motes: _motes,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: Row(
                    children: [
                      GhostButton(
                        icon: Icons.keyboard_arrow_left_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        widget.puzzle.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 4,
                          color: Color.lerp(Colors.white38, _amber, g),
                        ),
                      ),
                      const Spacer(),
                      GhostButton(
                        icon: Icons.undo_rounded,
                        onTap: _undo.isEmpty
                            ? null
                            : () {
                                final p = _undo.removeLast();
                                setState(() {
                                  _at = p;
                                  _score = _rt.score(p);
                                });
                              },
                      ),
                      GhostButton(
                        icon: Icons.refresh_rounded,
                        onTap: () {
                          _undo.clear();
                          setState(() {
                            _at = [...widget.puzzle.start];
                            _score = _rt.score(_at);
                            _wasSolved = false;
                            _glow.value = 0;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _PieceBar(
                  count: widget.puzzle.pieces.length,
                  selected: _sel,
                  onSelect: (i) => setState(() => _sel = i),
                ),
                // Depth. The dial edits wall A and nothing else, which is the
                // whole reason this screen has a dial at all.
                AxisDial(
                  value: _at[_sel].z,
                  min: -1.3,
                  max: 1.3,
                  onStart: _mark,
                  onChanged: (v) =>
                      _place(V3(_at[_sel].x, _at[_sel].y, v)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 22, top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Meter(value: _score.a),
                      const SizedBox(width: 26),
                      Meter(value: _score.b),
                    ],
                  ),
                ),
              ],
            ),
            if (solved)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: g < 0.95,
                  child: AnimatedOpacity(
                    opacity: g > 0.95 ? 1 : 0,
                    duration: const Duration(milliseconds: 260),
                    child: ColoredBox(
                      color: const Color(0xF008080A),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('BUILT',
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 8,
                                    color: _amber)),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: 220,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _amber,
                                  foregroundColor: const Color(0xFF16120A),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('DONE',
                                    style: TextStyle(
                                        fontSize: 12,
                                        letterSpacing: 3,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Which piece the drag and the dial are aimed at.
///
/// Numbered rather than shaped: a thumbnail of a slab is a grey blob at this
/// size, and the pieces are told apart by watching the room, not the chip.
class _PieceBar extends StatelessWidget {
  const _PieceBar(
      {required this.count, required this.selected, required this.onSelect});
  final int count;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 30,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: i == selected ? _amber : Colors.white12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: i == selected ? _amber : Colors.white30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
