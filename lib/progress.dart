import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'forms.dart';

/// Chapter boundaries, derived from how many joints the sculptures have.
/// Read off levels.g.dart rather than assumed: generated 1–12 have no hinge,
/// 13–27 have one, 28–36 mix one and two. Note that makes chapter 3 *mixed*,
/// not "two hinges" as the early notes claimed.
///
/// ⚠️ Every boundary past the first is shifted by one against those generated
/// numbers, because [catLevel] is spliced into CHAPTER I at index 3 (see
/// [allLevels]). CHAPTER I is therefore 13 levels, not 12, and stays the
/// no-joint chapter — the Cat is pure rotation, which is why it could go there
/// at all. FORMS is 3 (Pear, Hare, Vessel) and SILHOUETTES 4.
const chapterStarts = [0, 13, 28, 37, 40];

const chapterNames = ['ROTATION', 'THE JOINT', 'TWO JOINTS', 'FORMS', 'SILHOUETTES'];

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
  /// ⚠️ Bumped to v3 when the Cat replaced the Hare in CHAPTER I; v2 when the
  /// Hare first moved there. Stars are
  /// keyed by level index, so a reorder would silently reattribute every star
  /// after the insertion point to the wrong puzzle. Bumping drops old progress
  /// instead, which is the honest trade while the game is still pre-release.
  static const campaignKey = 'best_v3';

  /// Keyed by day number, not pool index — see `daily.dart`.
  static const dailyKey = 'daily_v1';

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

  /// Consecutive solved days ending at [today]. Only meaningful on the daily
  /// ledger, where the key IS the day number.
  ///
  /// If today is not solved yet the count runs from **yesterday**, so a player
  /// who has not played today still sees the chain they are protecting rather
  /// than a zero. Showing 0 until they play would make the streak feel already
  /// lost every morning, which is the opposite of what a streak is for.
  int streakEndingAt(int today) {
    var day = solved(today) ? today : today - 1;
    var n = 0;
    while (solved(day)) {
      n++;
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
