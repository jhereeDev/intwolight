import 'package:flutter_test/flutter_test.dart';
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
    expect(covered, generatedLevels.length);
  });

  test('chapter boundaries actually track hinge count', () {
    // Chapter 1 is the no-joint chapter. If the generator ever emits a hinged
    // sculpture there, the chapter names become a lie.
    for (var i = chapterStarts[0]; i < chapterEnd(0); i++) {
      expect(generatedLevels[i].hasHinge, isFalse,
          reason: 'level ${i + 1} is in CHAPTER I but has a joint');
    }
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

  test('best-of semantics: a sloppier replay cannot cost a star', () {
    final p = Progress({0: 0.99});
    expect(p.starsOf(0), 3);
    // record() short-circuits on a worse score before touching storage.
    expect(p.bestOf(0), 0.99);
    expect(p.solved(1), isFalse);
    expect(p.starsOf(1), 0);
  });
}
