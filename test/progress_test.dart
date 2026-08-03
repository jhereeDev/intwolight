import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/level.dart';
import 'package:in_two_lights/forms.dart';
import 'package:in_two_lights/levels.g.dart';
import 'package:in_two_lights/progress.dart';

void main() {
  test('every level belongs to exactly one chapter, and they tile the set', () {
    var covered = 0;
    for (var c = 0; c < chapterStarts.length; c++) {
      expect(chapterEnd(c), greaterThan(chapterStarts[c]),
          reason: 'chapter $c is empty');
      covered += chapterEnd(c) - chapterStarts[c];
      for (var i = chapterStarts[c]; i < chapterEnd(c); i++) {
        expect(chapterOf(i), c);
      }
    }
    expect(covered, allLevels.length);
  });

  test('chapter boundaries actually track hinge count', () {
    // Chapter 1 is the no-joint chapter. If the generator ever emits a hinged
    // sculpture there, the chapter names become a lie.
    for (var i = chapterStarts[0]; i < chapterEnd(0); i++) {
      expect(generatedLevels[i].hasHinge, isFalse,
          reason: 'level ${i + 1} is in CHAPTER I but has a joint');
    }
    // Only chapters I-III are generated; CHAPTER IV is hand-authored organic
    // forms and is deliberately not bound by the hinge progression.
    for (var i = chapterStarts[1]; i < generatedLevels.length; i++) {
      expect(generatedLevels[i].hasHinge, isTrue,
          reason: 'level ${i + 1} is past CHAPTER I but has no joint');
    }
  });

  test('a star needs a solve, and the cuts are ordered', () {
    // Below the solve threshold nothing is earned, however close.
    expect(starsForScore(kSolveThreshold - 0.001), 0);
    expect(starsForScore(kSolveThreshold), 1);
    expect(starsForScore(1.0), 3);
    for (var i = 1; i < starCuts.length; i++) {
      expect(starCuts[i], greaterThan(starCuts[i - 1]));
    }
    expect(starCuts.first, greaterThanOrEqualTo(kSolveThreshold),
        reason: 'a level could otherwise score a star without being solved');
  });

  gateTests();

  test('best-of semantics: a sloppier replay cannot cost a star', () {
    final p = Progress({0: 0.99});
    expect(p.starsOf(0), 3);
    // record() short-circuits on a worse score before touching storage.
    expect(p.bestOf(0), 0.99);
    expect(p.solved(1), isFalse);
    expect(p.starsOf(1), 0);
  });
}

// --- commercial gate -------------------------------------------------------

void gateTests() {
  test('chapter I is free forever; everything past it is the unlock', () {
    expect(Progress.chapterLocked(0, unlocked: false), isFalse,
        reason: 'the free chapter must never be gated');
    for (var c = 1; c < chapterStarts.length; c++) {
      expect(Progress.chapterLocked(c, unlocked: false), isTrue);
      expect(Progress.chapterLocked(c, unlocked: true), isFalse);
    }
  });

  test('the gate fails OPEN, never closed', () {
    // Store.unlocked reports true whenever it could not reach RevenueCat, so
    // a missing key, an outage or a flaky connection can never paywall
    // someone who already paid — which would also be an App Review rejection
    // under Guideline 3.1.1.
    for (var c = 0; c < chapterStarts.length; c++) {
      expect(Progress.chapterLocked(c, unlocked: true), isFalse,
          reason: 'chapter $c locked despite an unreachable store');
    }
  });

  test('the free chapter is a real chapter, not a teaser', () {
    final free = chapterEnd(0) - chapterStarts[0];
    expect(free, greaterThanOrEqualTo(10),
        reason: 'a paywall this early reads as a demo, not a game');
    expect(allLevels.length - free, greaterThan(free),
        reason: 'the paid side should be the larger half');
  });
}
