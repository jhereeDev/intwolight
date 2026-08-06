import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'forms.dart';

/// Chapter boundaries, derived from how many joints the sculptures have.
/// Read off levels.g.dart rather than assumed: generated 1–12 have no hinge,
/// 13–27 have one, 28–36 mix one and two. Note that makes chapter 3 *mixed*,
/// not "two hinges" as the early notes claimed.
///
/// ⚠️ These no longer index `generatedLevels` — [allLevels] opens with three
/// AUTHORED rooms (Tee, Step, Cat) and CHAPTER II opens with a fourth (Hinge),
/// so every boundary is shifted. See the note on [allLevels].
///   I   ROTATION    15 = Tee, Step, Cat + 12 no-joint generated
///   II  THE JOINT   16 = Hinge + 15 one-joint generated
///   III TWO JOINTS   9 = the remaining generated, one and two joints mixed
///   IV  FORMS        3   V SILHOUETTES 4     → 47 rooms
///
/// CHAPTERS VI–XIII are `levels_ext.g.dart` — 8 × 25 mixed-shape rooms cut
/// from rods, wedges, bulbs, hexes and the three concave shapes. **Each is
/// named for the pool it is actually generated from** (see
/// `tool/gen_levels_ext.dart`), and joint count runs 0 → 1 → 2 across the
/// eight, replaying I–III's progression over a vocabulary that is new. → 247.
///
/// ⚠️ These are APPENDED. Every index at or below 46 is unchanged, which is
/// why `campaignKey` stays at `best_v4` and nobody loses a star. Inserting a
/// chapter anywhere but the end would move every star after the splice onto a
/// different puzzle — bump the key if that ever happens.
const chapterStarts = [
  0, 15, 31, 40, 43, //
  47, 72, 97, 122, 147, 172, 197, 222,
];

const chapterNames = [
  'ROTATION', 'THE JOINT', 'TWO JOINTS', 'FORMS', 'SILHOUETTES', //
  'THE ROD', 'THE WEDGE', 'THE BULB', 'THE ANGLE', 'THE ARROW', //
  'ASSEMBLY', 'TANGLE', 'THE WORKS',
];

int chapterOf(int levelIndex) {
  for (var c = chapterStarts.length - 1; c >= 0; c--) {
    if (levelIndex >= chapterStarts[c]) return c;
  }
  return 0;
}

int chapterEnd(int c) => c + 1 < chapterStarts.length
    ? chapterStarts[c + 1]
    : allLevels.length;

/// Stars are earned on **precision, not speed** — how tightly both shadows
/// matched, scored on the weaker of the two walls. A timer would turn a
/// contemplative puzzle into a twitch one.
const starCuts = [0.92, 0.955, 0.985];

int starsForScore(double weakest) {
  var s = 0;
  for (final c in starCuts) {
    if (weakest >= c) s++;
  }
  return s;
}

/// Best result per level. Absent means never solved.
class Progress {
  Progress(this._best, {this.storeKey = campaignKey});

  /// Which namespace this instance reads and writes. The campaign and the
  /// daily room keep separate ledgers — they index different things, and a
  /// shared key would have day 7 overwrite level 7.
  final String storeKey;

  final Map<int, double> _best;
  /// ⚠️ v4: the authored opening arc (Tee, Step, Cat) replaced the first three
  /// generated rooms and the Hinge was planted at the head of CHAPTER II.
  /// v3 when the Cat replaced the Hare in CHAPTER I; v2 when the
  /// Hare first moved there. Stars are
  /// keyed by level index, so a reorder would silently reattribute every star
  /// after the insertion point to the wrong puzzle. Bumping drops old progress
  /// instead, which is the honest trade while the game is still pre-release.
  static const campaignKey = 'best_v4';

  /// Keyed by day number, not pool index — see `daily.dart`.
  static const dailyKey = 'daily_v1';

  /// Keyed by ROOM NUMBER — see `endless.dart`. Never version-bumped on a
  /// campaign reorder: endless rooms are derived from their number, so room
  /// 340 is the same puzzle forever and its stars stay valid.
  static const endlessKey = 'endless_v1';

  /// Furthest room solved, or 0. Endless resumes at the room after this.
  int get deepestRoom =>
      _best.keys.isEmpty ? 0 : _best.keys.reduce((a, b) => a > b ? a : b);

  static Future<Progress> load({String storeKey = campaignKey}) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(storeKey) ?? const [];
    final map = <int, double>{};
    for (final e in raw) {
      final bits = e.split(':');
      if (bits.length != 2) continue;
      final i = int.tryParse(bits[0]);
      final v = double.tryParse(bits[1]);
      if (i != null && v != null) map[i] = v;
    }
    return Progress(map, storeKey: storeKey);
  }

  double bestOf(int i) => _best[i] ?? 0;
  int starsOf(int i) => _best.containsKey(i) ? starsForScore(_best[i]!) : 0;
  bool solved(int i) => _best.containsKey(i);

  /// How many missed days a streak survives. One, and only once per streak.
  ///
  /// Forgiving *every* single-day gap would make alternate-day play an
  /// unbroken streak forever, which is not a streak. Forgiving none punishes
  /// one bad evening by deleting a month — and this is a contemplative game,
  /// not a habit tracker with a guilt mechanic.
  static const streakGrace = 1;

  /// Consecutive solved days ending at [today]. Only meaningful on the daily
  /// ledger, where the key IS the day number.
  ///
  /// If today is not solved yet the count runs from **yesterday**, so a player
  /// who has not played today still sees the chain they are protecting rather
  /// than a zero. Showing 0 until they play would make the streak feel already
  /// lost every morning, which is the opposite of what a streak is for.
  ///
  /// Missed days are skipped rather than counted: the number is how many days
  /// were *played*, so it can never overstate the work done.
  int streakEndingAt(int today, {int grace = streakGrace}) {
    var day = solved(today) ? today : today - 1;
    var n = 0;
    var left = grace;
    while (true) {
      if (solved(day)) {
        n++;
      } else if (left > 0) {
        left--; // spend the grace, keep walking
      } else {
        break;
      }
      day--;
    }
    return n;
  }

  int get solvedCount => _best.length;

  int get totalStars {
    var n = 0;
    for (final i in _best.keys) {
      n += starsOf(i);
    }
    return n;
  }

  int solvedInChapter(int c) {
    var n = 0;
    for (var i = chapterStarts[c]; i < chapterEnd(c); i++) {
      if (solved(i)) n++;
    }
    return n;
  }

  /// Chapters are **not** skill-gated — the gate is commercial. Chapter I is
  /// free forever; everything past it is the one-time unlock.
  ///
  /// [unlocked] comes from Store, which reports true whenever the store could
  /// not be reached, so a bad key or an outage can never paywall someone who
  /// already paid.
  static bool chapterLocked(int c, {required bool unlocked}) =>
      c > 0 && !unlocked;

  /// Whether level [i] can be opened.
  ///
  /// Two independent gates, and they answer different questions:
  ///   * **commercial** — is this chapter bought? ([chapterLocked])
  ///   * **progression** — has the room before it been solved?
  ///
  /// Progression runs *within* a chapter, not across the whole game: the first
  /// room of every chapter you own is always open. A player who paid should be
  /// able to look at what they bought, and a chapter that cannot be entered
  /// until the previous one is 100% cleared turns an optional room into a wall.
  ///
  /// Solved means solved — one star, not three. Gating on precision would make
  /// the curve about patience instead of insight.
  ///
  /// The daily and endless ledgers never come through here. The daily is keyed
  /// by date and has no "previous level", and endless is inherently sequential.
  bool levelLocked(int i, {required bool unlocked}) {
    if (chapterLocked(chapterOf(i), unlocked: unlocked)) return true;
    if (i == chapterStarts[chapterOf(i)]) return false; // chapter opener
    return !solved(i - 1);
  }

  /// The level the player should be pointed at: the first unsolved room they
  /// are allowed to open, or the last one if they have finished everything.
  /// Falls back to the last **playable** room, not the last room. A player who
  /// has finished the free chapter and bought nothing would otherwise be
  /// pointed at level 44, which they cannot open — the map would scroll to a
  /// locked room and look broken.
  int currentLevel({required bool unlocked}) {
    var lastPlayable = 0;
    for (var i = 0; i < allLevels.length; i++) {
      if (levelLocked(i, unlocked: unlocked)) continue;
      if (!solved(i)) return i;
      lastPlayable = i;
    }
    return lastPlayable;
  }

  Timer? _flushTimer;

  /// Keeps the better of the two, so a sloppier replay can't cost you a star.
  ///
  /// Memory updates immediately; the disk write is debounced. This is called
  /// on **every drag frame** while the pose sits in the solved basin, and
  /// writing to SharedPreferences at 60Hz stutters the whole game.
  void record(int i, double weakest) {
    if (weakest <= bestOf(i)) return;
    _best[i] = weakest;
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 600), flush);
  }

  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      storeKey,
      [for (final e in _best.entries) '${e.key}:${e.value.toStringAsFixed(4)}'],
    );
  }
}
