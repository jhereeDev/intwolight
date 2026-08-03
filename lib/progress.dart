import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'forms.dart';

/// Chapter boundaries, derived from how many joints the sculptures have.
/// Read off levels.g.dart rather than assumed: 1–12 have no hinge, 13–27 have
/// one, 28–36 mix one and two. Note that makes chapter 3 *mixed*, not "two
/// hinges" as the early notes claimed.
const chapterStarts = [0, 12, 27, 36, 39];

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
  Progress(this._best);

  final Map<int, double> _best;
  static const _key = 'best_v1';

  static Future<Progress> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? const [];
    final map = <int, double>{};
    for (final e in raw) {
      final bits = e.split(':');
      if (bits.length != 2) continue;
      final i = int.tryParse(bits[0]);
      final v = double.tryParse(bits[1]);
      if (i != null && v != null) map[i] = v;
    }
    return Progress(map);
  }

  double bestOf(int i) => _best[i] ?? 0;
  int starsOf(int i) => _best.containsKey(i) ? starsForScore(_best[i]!) : 0;
  bool solved(int i) => _best.containsKey(i);

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

  /// Chapters are **not** skill-gated. Gating here is commercial — chapters 2
  /// and 3 become the one-time RevenueCat unlock at M3 — so this stays false
  /// until that lands. The map already renders a locked state for it.
  bool chapterLocked(int c) => false;

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
      _key,
      [for (final e in _best.entries) '${e.key}:${e.value.toStringAsFixed(4)}'],
    );
  }
}
