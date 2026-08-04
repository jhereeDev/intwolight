import 'package:flutter/material.dart';

import 'daily.dart';
import 'forms.dart';
import 'level.dart';
import 'main.dart';
import 'map_screen.dart';
import 'progress.dart';
import 'store.dart';

/// Press-kit capture mode. Off unless built with `--dart-define=SHOT=true`,
/// so the whole file tree-shakes out of a normal release — the same pattern
/// `Store._forceLock` already uses.
///
///   flutter run --release --dart-define=SHOT=true
///
/// Tap anywhere to advance to the next shot. One build covers the whole set,
/// because `--dart-define` is compile-time and a shot-per-build would mean a
/// full rebuild for every picture.
///
/// Why this exists rather than capturing by hand: store screenshots have to be
/// redone every time the UI moves, and they had gone stale twice in a day —
/// showing a HUD button that no longer exists and a solve panel that had become
/// a modal. A ritual that has to be repeated by hand is a ritual that rots.
const bool shotMode = bool.fromEnvironment('SHOT');

/// Levels are authored *as* a solved pose, so a solved room needs no solver —
/// just the pose the level already stores.
class Shot {
  const Shot(this.label, {this.level, this.pose, this.map = false});
  final String label;
  final int? level;

  /// null means "use the level's own solution", i.e. show it solved.
  final Pose? pose;
  final bool map;
}

const shots = <Shot>[
  // The differentiator first: scattered shards, a clean moth on the wall.
  Shot('01-silhouette', level: 43),
  // The recognition moment inside the FREE chapter.
  Shot('02-cat', level: 3),
  // Mid-puzzle and unsolved, so the mechanic is visible rather than the prize.
  Shot('03-working', level: 20, pose: Pose(0.9, -0.35, 0.4)),
  Shot('04-map', map: true),
];

/// Plausible progress, so the map reads as a game in play rather than an empty
/// grid. Real UI, sample data — the same thing a person would have after an
/// evening, which is what a store screenshot is supposed to depict.
Progress _sampleCampaign() => Progress({
      for (var i = 0; i < 16; i++) i: [0.99, 0.96, 0.93][i % 3],
    });

Progress _sampleDaily() {
  final today = dailyDayNumber(DateTime.now());
  return Progress({for (var d = today - 3; d <= today; d++) d: 0.97},
      storeKey: Progress.dailyKey);
}

class ShotRunner extends StatefulWidget {
  const ShotRunner({super.key, required this.store});
  final Store store;

  @override
  State<ShotRunner> createState() => _ShotRunnerState();
}

class _ShotRunnerState extends State<ShotRunner> {
  int _i = 0;
  late final Progress _campaign = _sampleCampaign();
  late final Progress _daily = _sampleDaily();

  @override
  Widget build(BuildContext context) {
    final shot = shots[_i % shots.length];
    final Widget screen = shot.map
        ? MapScreen(
            progress: _campaign,
            daily: _daily,
            store: widget.store,
            onPlay: (_) async {},
            onDaily: () async {},
          )
        : PlayScreen(
            // Keyed so advancing rebuilds the screen from scratch rather than
            // reusing the previous level's state.
            key: ValueKey(_i),
            index: shot.level!,
            progress: _campaign,
            initialPose: shot.pose ?? allLevels[shot.level!].solution,
            suppressPanel: true,
          );

    return Stack(
      children: [
        screen,
        // Above everything, so a tap advances even over the HUD.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _i++),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
