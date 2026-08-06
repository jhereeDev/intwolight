import 'package:flutter/material.dart';

import 'daily.dart';
import 'forms.dart';
import 'level.dart';
import 'main.dart';
import 'map_screen.dart';
import 'menagerie.dart';
import 'progress.dart';
import 'store.dart';
import 'unlock_screen.dart';
import 'workshop.dart';
import 'workshop_screen.dart';

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
  const Shot(this.label,
      {this.level,
      this.pose,
      this.map = false,
      this.menagerie = false,
      this.workshop = false,
      this.unlock = false});
  final String label;
  final int? level;

  /// null means "use the level's own solution", i.e. show it solved.
  final Pose? pose;
  final bool map;
  final bool menagerie;
  final bool workshop;
  final bool unlock;
}

/// The paywall, shown as a customer sees it.
///
/// A build with no RevenueCat keys has nothing to sell, so the real screen
/// renders its button as "STORE UNAVAILABLE" — which is exactly the wrong
/// picture for the App Store Connect **in-app purchase review screenshot**,
/// whose whole job is to show the purchase actually on offer.
///
/// This overrides only the two getters the screen reads. It grants nothing:
/// `Store.unlocked` is `entitled || !canBuy`, so forcing `canBuy` true makes
/// the app *more* locked, not less, and `computeUnlocked` is untouched. The
/// money path in `store.dart` is deliberately not modified for a screenshot.
///
///   flutter run --release --dart-define=SHOT=true --dart-define=SHOT_PRICE='$2.99'
class _ShotStore extends Store {
  @override
  bool get canBuy => true;

  @override
  String get price =>
      const String.fromEnvironment('SHOT_PRICE', defaultValue: '\$2.99');
}

const shots = <Shot>[
  // The differentiator first: scattered shards, a clean moth on the wall.
  Shot('01-silhouette', level: 43),
  // The recognition moment inside the FREE chapter.
  Shot('02-cat', level: 3),
  // Mid-puzzle and unsolved, so the mechanic is visible rather than the prize.
  Shot('03-working', level: 20, pose: Pose(0.9, -0.35, 0.4)),
  Shot('04-map', map: true),
  // The cabinet, partly filled — an empty one shows nothing and a full one
  // shows no reason to keep playing.
  Shot('05-found', menagerie: true),
  // The Workshop mid-build, so the piece bar and the depth dial are both
  // visible doing something.
  Shot('06-workshop', workshop: true),
  // Not part of the store listing set — this one exists for the App Store
  // Connect IAP review screenshot, which was previously taken by hand and had
  // gone two days stale by the time anyone looked at it.
  Shot('07-unlock', unlock: true),
];

/// Plausible progress, so the map reads as a game in play rather than an empty
/// grid. Real UI, sample data — the same thing a person would have after an
/// evening, which is what a store screenshot is supposed to depict.
Progress _sampleCampaign() => Progress({
      for (var i = 0; i < 16; i++) i: [0.99, 0.96, 0.93][i % 3],
      // A few figures found and most not: the cabinet only reads as a
      // collection when some slots are still open.
      40: 0.98, // Duck
      43: 0.97, // Moth
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
  late final Store _shotStore = _ShotStore();

  @override
  Widget build(BuildContext context) {
    final shot = shots[_i % shots.length];
    final Widget screen = shot.unlock
        ? UnlockScreen(store: _shotStore)
        : shot.workshop
        ? WorkshopScreen(
            puzzle: workshopPuzzles[1], suppressPanel: true)
        : shot.menagerie
        ? MenagerieScreen(progress: _campaign)
        : shot.map
        ? MapScreen(
            progress: _campaign,
            daily: _daily,
            // Press shots want a clean slate, not this device's real depth.
            endless: Progress(const {}, storeKey: Progress.endlessKey),
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
