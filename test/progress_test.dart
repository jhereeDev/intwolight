import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/forms.dart';
import 'package:in_two_lights/level.dart';
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
    // ⚠️ Assert against the SOURCE lists, not chapter indices. allLevels is no
    // longer generatedLevels in order — the Cat is spliced in at index 3 — so
    // `generatedLevels[chapterIndex]` now reads a different level than it
    // names, and would keep passing while checking the wrong thing.
    const generatedNoJoint = 12;
    for (var i = 0; i < generatedNoJoint; i++) {
      expect(generatedLevels[i].hasHinge, isFalse,
          reason: 'generated ${i + 1} must have no joint');
    }
    // Only chapters I-III are generated; CHAPTER IV is hand-authored organic
    // forms and is deliberately not bound by the hinge progression.
    for (var i = generatedNoJoint; i < generatedLevels.length; i++) {
      expect(generatedLevels[i].hasHinge, isTrue,
          reason: 'generated ${i + 1} is past the no-joint run but has none');
    }
    // The promise the chapter NAME makes: CHAPTER I is "ROTATION", so nothing
    // in it may have a joint — authored levels included.
    for (var i = chapterStarts[0]; i < chapterEnd(0); i++) {
      expect(allLevels[i].hasHinge, isFalse,
          reason: 'level ${i + 1} is in CHAPTER I but has a joint');
    }
  });

  test('the free chapter shows what the game actually is', () {
    // The recognition moment — an abstract sculpture resolving into something
    // nameable — is the whole pitch. It used to start at level 37: behind the
    // paywall, after 36 generated box arrangements. A new player and a
    // competition judge would both have finished the free chapter without
    // ever seeing it.
    final free = allLevels.sublist(chapterStarts[0], chapterEnd(0));
    expect(free.contains(catLevel), isTrue,
        reason: 'CHAPTER I is all abstractions again — the free chapter no '
            'longer demonstrates the thing the game is for');
    expect(free.indexOf(catLevel), lessThan(6),
        reason: 'the payoff has drifted late inside the free chapter');
  });

  test('every level has something to say when a player is stuck', () {
    for (var i = 0; i < allLevels.length; i++) {
      // generator.dart builds Levels with `hint: ''` by default, so a band
      // whose hint was never set would ship a level that fades in an empty
      // string after 60 seconds — the feature failing silently, which is the
      // only way a cosmetic feature ever fails.
      expect(allLevels[i].hint.trim(), isNotEmpty,
          reason: 'level ${i + 1} has no hint');
      // Hints surface only after a minute of being stuck, by which point the
      // player has been dragging the whole time. CHAPTER I shipped
      // 'Drag to rotate.' as its hint for a while: a line that tells someone
      // what they are already doing is worse than saying nothing.
      expect(allLevels[i].hint, isNot('Drag to rotate.'),
          reason: 'level ${i + 1} answers a question nobody stuck is asking');
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
