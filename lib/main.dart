import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'geom.dart';
import 'level.dart';
import 'forms.dart';
import 'map_screen.dart';
import 'progress.dart';
import 'scene.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Declared in Info.plist and AndroidManifest too; this is the runtime half.
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final progress = await Progress.load();
  final store = Store();
  // Not awaited: a slow or unreachable store must never delay first paint.
  // Store reports unlocked until it knows otherwise, so the map is correct
  // either way and simply re-renders when the entitlement arrives.
  unawaited(store.init());

  runApp(InTwoLightsApp(progress: progress, store: store));
}

class InTwoLightsApp extends StatelessWidget {
  const InTwoLightsApp({super.key, required this.progress, required this.store});

  final Progress progress;
  final Store store;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'IN TWO LIGHTS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF08080A),
        ),
        home: Builder(
          builder: (context) => MapScreen(
            progress: progress,
            store: store,
            onPlay: (i) => Navigator.of(context).push<void>(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 420),
                reverseTransitionDuration: const Duration(milliseconds: 300),
                // Fade, not slide. The map and the room are the same space at
                // two scales, so sliding between them would read as a lie.
                pageBuilder: (_, a, _) => FadeTransition(
                  opacity: a,
                  child: PlayScreen(index: i, progress: progress),
                ),
              ),
            ),
          ),
        ),
      );
}

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.index, required this.progress});

  final int index;
  final Progress progress;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  late int _index = widget.index;
  Pose _pose = const Pose(0, 0, 0);
  late LevelRuntime _rt = LevelRuntime(allLevels[widget.index]);

  // Scored once per pose change, not once in _apply and again in build().
  late Score _score = _rt.score(_pose);

  // Target outlines are a boolean union of ~200 triangles. Built once per
  // level in wall-local space; the painter only applies an affine transform.
  late Path _targetA = unionOutline2D(_rt.targetShadowsA());
  late Path _targetB = unionOutline2D(_rt.targetShadowsB());

  /// Eases the whole scene between "cold" and "lit" so solving is a moment
  /// rather than a state flip.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..addListener(() => setState(() {}));

  bool _wasSolved = false;

  /// The wordless teach: a ghost hand that drifts until the player drags.
  bool _touched = false;

  /// The room's tone. Held for as long as this screen lives, its loudness
  /// tracking the weaker wall — the game's only warmer/colder channel.
  final GameAudio _audio = GameAudio();

  @override
  void initState() {
    super.initState();
    _audio.start();
    _audio.proximity(math.min(_score.a, _score.b), solved: _score.solved);
  }

  // Fixed so dust doesn't reshuffle every frame.
  late final List<Offset> _motes = [
    for (var i = 0; i < 26; i++)
      Offset(_rand(i * 2) * 0.9 + 0.05, _rand(i * 2 + 1) * 0.7 + 0.12),
  ];

  static double _rand(int i) {
    final x = math.sin(i * 12.9898 + 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void dispose() {
    // The disk write is debounced, so leaving quickly could otherwise drop
    // the last improvement.
    widget.progress.flush();
    _glow.dispose();
    _audio.dispose();
    super.dispose();
  }

  void _load(int i) {
    setState(() {
      _index = i.clamp(0, allLevels.length - 1);
      _rt = LevelRuntime(allLevels[_index]);
      _pose = const Pose(0, 0, 0);
      _score = _rt.score(_pose);
      _targetA = unionOutline2D(_rt.targetShadowsA());
      _targetB = unionOutline2D(_rt.targetShadowsB());
      _wasSolved = false;
      _glow.value = 0;
    });
    // Without this the drone would still be blooming from the level just
    // solved while the next one sits untouched.
    _audio.proximity(math.min(_score.a, _score.b), solved: _score.solved);
  }

  void _apply(Pose p) {
    final score = _rt.score(p);
    if (score.solved && !_wasSolved) {
      _wasSolved = true;
      HapticFeedback.mediumImpact();
      // Chord and glow are both 620ms, fired together so the arrival is one
      // event rather than a sound chasing a light.
      _audio.solved();
      _glow.forward();
    } else if (!score.solved && _wasSolved) {
      _wasSolved = false;
      _glow.reverse();
    }
    _audio.proximity(math.min(score.a, score.b), solved: score.solved);
    // Record continuously while solved, so easing further into the basin
    // earns the third star. Stars are precision, not speed — there is no
    // reason to punish someone for keeping at it.
    if (score.solved) {
      widget.progress.record(_index, math.min(score.a, score.b));
    }
    setState(() {
      _pose = p;
      _score = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lv = allLevels[_index];
    final world = worldMeshes(lv, _pose);
    final score = _score;
    final g = Curves.easeOutCubic.transform(_glow.value);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {
                  if (!_touched) setState(() => _touched = true);
                },
                onPanUpdate: (d) => _apply(Pose(
                  _pose.yaw + d.delta.dx * 0.012,
                  (_pose.pitch + d.delta.dy * 0.012).clamp(-1.4, 1.4),
                  _pose.hinge,
                )),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: CornerScenePainter(
                    world: world,
                    targetsA: _targetA,
                    targetsB: _targetB,
                    castA: shadowMeshes(world, toWallA),
                    castB: shadowMeshes(world, toWallB),
                    hitA: score.a >= kSolveThreshold,
                    hitB: score.b >= kSolveThreshold,
                    glow: g,
                    motes: _motes,
                  ),
                ),
              ),
            ),

            // Wordless teach — a drifting hand, gone the instant you drag.
            if (!_touched)
              const Positioned.fill(
                child: IgnorePointer(child: _DragHint()),
              ),

            _Hud(
              index: _index,
              total: allLevels.length,
              a: score.a,
              b: score.b,
              glow: g,
              hinge: lv.hasHinge ? _pose.hinge : null,
              onHinge: (v) => _apply(Pose(_pose.yaw, _pose.pitch, v)),
              stars: score.solved
                  ? starsForScore(math.min(score.a, score.b))
                  : 0,
              onBack: () => Navigator.of(context).pop(),
              onNext: _index < allLevels.length - 1
                  ? () => _load(_index + 1)
                  : null,
              onReset: () => _apply(const Pose(0, 0, 0)),
            ),

            // The panel waits for the glow to finish so the moment lands
            // before the UI asks for a decision.
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                ignoring: g < 0.95,
                child: AnimatedSlide(
                  offset: Offset(0, g > 0.95 ? 0 : 1),
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: g > 0.95 ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: _SolvePanel(
                      stars: starsForScore(math.min(score.a, score.b)),
                      precision: math.min(score.a, score.b),
                      best: widget.progress.bestOf(_index),
                      isLast: _index >= allLevels.length - 1,
                      onNext: _index < allLevels.length - 1
                          ? () => _load(_index + 1)
                          : null,
                      onMap: () => Navigator.of(context).pop(),
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

/// Two arcs and a dot, drifting left-right. Teaches "drag to rotate" without
/// a word, a modal, or a Skip button — the game is wordless, the tutorial is too.
class _DragHint extends StatefulWidget {
  const _DragHint();

  @override
  State<_DragHint> createState() => _DragHintState();
}

class _DragHintState extends State<_DragHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _DragHintPainter(_c.value),
        ),
      );
}

class _DragHintPainter extends CustomPainter {
  _DragHintPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // One sweep out and back, with a pause at each end.
    final phase = math.sin(t * 2 * math.pi);
    final fade = (math.sin(t * 2 * math.pi * 2).abs() * 0.35 + 0.45)
        .clamp(0.0, 1.0);

    final cx = size.width / 2 + phase * size.width * 0.16;
    final cy = size.height * 0.72;

    canvas.drawCircle(
      Offset(cx, cy),
      13,
      Paint()..color = Colors.white.withValues(alpha: 0.10 * fade),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.55 * fade),
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawLine(Offset(size.width * 0.34, cy),
        Offset(size.width * 0.66, cy), track);
  }

  @override
  bool shouldRepaint(_DragHintPainter old) => old.t != t;
}

/// Level number, the two wall readouts, and nav. Deliberately quiet — the
/// scene is the interface.
class _Hud extends StatelessWidget {
  const _Hud({
    required this.index,
    required this.total,
    required this.a,
    required this.b,
    required this.glow,
    required this.hinge,
    required this.onHinge,
    required this.stars,
    required this.onBack,
    required this.onNext,
    required this.onReset,
  });

  final int index, total;
  final double a, b, glow;
  final int stars;

  /// null when the level has no joint — the control simply isn't there.
  final double? hinge;
  final ValueChanged<double> onHinge;
  final VoidCallback? onBack, onNext, onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 8, 0),
          child: Row(
            children: [
              _GhostButton(
                  icon: Icons.keyboard_arrow_left_rounded, onTap: onBack),
              const SizedBox(width: 2),
              Text(
                '${index + 1}'.padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 4,
                  color: Color.lerp(
                      Colors.white38, const Color(0xFFE0A82E), glow),
                ),
              ),
              Text(
                ' / $total',
                style: const TextStyle(
                    fontSize: 13, letterSpacing: 2, color: Colors.white24),
              ),
              const Spacer(),
              // Stars appear only once earned — nothing to taunt you with
              // while you're still working.
              for (var s = 0; s < stars; s++)
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(Icons.star_rounded,
                      size: 13, color: Color(0xFFE0A82E)),
                ),
              const SizedBox(width: 8),
              _GhostButton(icon: Icons.refresh_rounded, onTap: onReset),
              _GhostButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: glow > 0.9 ? onNext : null),
            ],
          ),
        ),
        const Spacer(),
        // The solve panel takes the bottom of the screen when it slides in.
        // Lift the working controls clear of it rather than letting them
        // overlap: the dial used to sit ON TOP of the panel's NEXT button and
        // swallow its taps, and the panel's own text says "keep easing in for
        // another star" — which is a lie if the hinge is buried underneath.
        AnimatedPadding(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: glow > 0.95 ? kSolvePanelLift : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hinge != null)
                _HingeDial(value: hinge!, onChanged: onHinge),
              Padding(
                padding: const EdgeInsets.only(bottom: 22, top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Meter(value: a),
                    const SizedBox(width: 26),
                    _Meter(value: b),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A bar, not a number. The player needs "how close", not two decimal places.
class _Meter extends StatelessWidget {
  const _Meter({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final hit = value >= kSolveThreshold;
    // Rescale so the visible travel lives where the puzzle actually is.
    final t = ((value - 0.35) / (1 - 0.35)).clamp(0.0, 1.0);
    return SizedBox(
      width: 74,
      height: 3,
      child: Stack(
        children: [
          Container(color: Colors.white.withValues(alpha: 0.08)),
          FractionallySizedBox(
            widthFactor: t,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              color: hit
                  ? const Color(0xFFE0A82E)
                  : Colors.white.withValues(alpha: 0.32),
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        color: Colors.white38,
        disabledColor: Colors.white10,
        splashRadius: 20,
      );
}

/// The hinge, restyled off Material's default Slider.
class _HingeDial extends StatelessWidget {
  const _HingeDial({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 46),
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            activeTrackColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
            thumbColor: const Color(0xFFE0A82E),
            overlayColor: const Color(0x22E0A82E),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: -1.6,
            max: 1.6,
            onChanged: onChanged,
          ),
        ),
      );
}


/// How far the working controls lift to clear the solve panel.
///
/// ponytail: a measured constant, not a real measurement. It tracks
/// `_SolvePanel`'s content height (padding 48 + title + stars + match line +
/// the star hint + button row ≈ 232). If that panel grows, this has to grow
/// with it or the dial slides back under NEXT. The upgrade, if it ever drifts,
/// is to measure the panel with a GlobalKey and drive this from its real size.
const double kSolvePanelLift = 232;

/// Shown when both walls lock. Reports what was earned and offers the only two
/// moves worth offering — onward, or back to the map.
///
/// It deliberately does not block the scene: the pose is still live behind it,
/// so a player who wants a third star can keep easing into the basin and watch
/// the stars fill. Break the solve and the panel simply slides away.
class _SolvePanel extends StatelessWidget {
  const _SolvePanel({
    required this.stars,
    required this.precision,
    required this.best,
    required this.isLast,
    required this.onNext,
    required this.onMap,
  });

  final int stars;
  final double precision, best;
  final bool isLast;
  final VoidCallback? onNext, onMap;

  @override
  Widget build(BuildContext context) {
    final improved = precision >= best - 1e-9;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0008080A), Color(0xF008080A), Color(0xFF08080A)],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('SOLVED',
              style: TextStyle(
                  fontSize: 11, letterSpacing: 8, color: Color(0xFFE0A82E))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: AnimatedScale(
                    scale: i < stars ? 1 : 0.78,
                    duration: Duration(milliseconds: 260 + i * 110),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 34,
                      color: i < stars
                          ? const Color(0xFFE0A82E)
                          : Colors.white12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            // Precision, not a points total — the score IS how well it matched.
            '${(precision * 100).toStringAsFixed(1)}%  match'
            '${improved ? "" : "   ·   best ${(best * 100).toStringAsFixed(1)}%"}',
            style: const TextStyle(
                fontSize: 12, letterSpacing: 1.5, color: Colors.white38),
          ),
          if (stars < 3) ...[
            const SizedBox(height: 6),
            const Text('keep easing in for another star',
                style: TextStyle(
                    fontSize: 11, letterSpacing: 1, color: Colors.white24)),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onMap,
                  child: const Text('MAP',
                      style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 3,
                          color: Colors.white38)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE0A82E),
                      foregroundColor: const Color(0xFF16120A),
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: onNext,
                    child: Text(isLast ? 'THE END' : 'NEXT ROOM',
                        style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
