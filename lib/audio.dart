import 'package:audioplayers/audioplayers.dart';

import 'level.dart' show kSolveThreshold;

/// Where the drone stops being flat and starts responding. Below this the pose
/// is not meaningfully "near" anything, and a rising tone would be a lie.
const double kProximityFloor = 0.35;

/// Gain for the room drone, given the **weaker** of the two wall scores.
///
/// The weaker wall is the honest one: this game is about a constraint that
/// binds on both walls at once, so rewarding the better wall would let the
/// player hear progress they have not made.
///
/// Squared rather than linear on purpose. Linear makes the whole search sound
/// the same; squared keeps the low range quiet and lets the tone bloom over the
/// last stretch, which is exactly where a player is deciding whether they are
/// onto something or fiddling.
///
/// Solved ducks the drone rather than peaking it — the solve chord needs room,
/// and a drone still climbing under it muddies the one consonance in the game.
double droneGain(double weakest, {bool solved = false}) {
  if (solved) return 0.25;
  final t =
      ((weakest - kProximityFloor) / (kSolveThreshold - kProximityFloor))
          .clamp(0.0, 1.0);
  return 0.06 + 0.94 * t * t;
}

/// The room's voice. One held tone whose loudness tracks how close the
/// sculpture is to satisfying both shadows, plus the chord that lands on solve.
///
/// This is the only "warmer / colder" channel in a game with no words, no
/// numbers on screen by default, and no fail state.
class GameAudio {
  final AudioPlayer _drone = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();
  double _lastGain = -1;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _drone.setReleaseMode(ReleaseMode.loop);
    await _drone.setVolume(0);
    await _drone.play(AssetSource('audio/drone.wav'));
  }

  /// ponytail: one platform-channel call per meaningful change, gated on a
  /// 0.02 delta so a 60fps drag does not become 60 channel hops a second.
  /// Ceiling: if this still stutters on a low-end Android, the upgrade is a
  /// native engine with a real gain node (flutter_soloud), not a smaller gate.
  void proximity(double weakest, {bool solved = false}) {
    final g = droneGain(weakest, solved: solved);
    if ((g - _lastGain).abs() < 0.02) return;
    _lastGain = g;
    _drone.setVolume(g);
  }

  void solved() => _sfx.play(AssetSource('audio/solve.wav'));

  void dispose() {
    _drone.dispose();
    _sfx.dispose();
  }
}
