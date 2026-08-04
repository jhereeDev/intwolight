import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/forms.dart';
import 'package:in_two_lights/progress.dart';

/// Two gates that must not be confused: one asks whether the chapter was
/// bought, the other whether the previous room was solved.
void main() {
  Progress campaign(List<int> solvedLevels) =>
      Progress({for (final i in solvedLevels) i: 0.95});

  test('the very first room is always open', () {
    expect(campaign([]).levelLocked(0, unlocked: false), isFalse);
    expect(campaign([]).levelLocked(0, unlocked: true), isFalse);
  });

  test('the next room opens only once this one is solved', () {
    final p = campaign([]);
    expect(p.levelLocked(1, unlocked: true), isTrue);
    expect(campaign([0]).levelLocked(1, unlocked: true), isFalse);
    expect(campaign([0]).levelLocked(2, unlocked: true), isTrue);
  });

  test('one star is enough — precision does not gate progress', () {
    // Exactly at the solve threshold: one star, and it must open the next room.
    final barely = Progress({0: starCuts.first});
    expect(barely.starsOf(0), 1);
    expect(barely.levelLocked(1, unlocked: true), isFalse);
  });

  test('every chapter opener is reachable without clearing the last chapter',
      () {
    // A buyer should be able to see what they bought. Only the commercial gate
    // stands between them and the first room of each chapter.
    for (var c = 1; c < chapterStarts.length; c++) {
      final start = chapterStarts[c];
      expect(campaign([]).levelLocked(start, unlocked: true), isFalse,
          reason: 'chapter $c opener should be open to an owner');
      expect(campaign([]).levelLocked(start, unlocked: false), isTrue,
          reason: 'chapter $c opener should still be behind the paywall');
    }
  });

  test('the commercial gate outranks progression', () {
    // Solving the previous room must not open a chapter that was never bought.
    final justBefore = chapterStarts[1] - 1;
    final p = campaign([for (var i = 0; i <= justBefore; i++) i]);
    expect(p.levelLocked(chapterStarts[1], unlocked: false), isTrue);
    expect(p.levelLocked(chapterStarts[1], unlocked: true), isFalse);
  });

  test('progression never locks a player out of chapter I', () {
    // The free chapter must always be completable, whatever the store says.
    var p = campaign([]);
    for (var i = 0; i < chapterEnd(0); i++) {
      expect(p.levelLocked(i, unlocked: false), isFalse,
          reason: 'free chapter room $i unreachable');
      p = campaign([for (var j = 0; j <= i; j++) j]);
    }
  });

  test('currentLevel points at the first playable unsolved room', () {
    expect(campaign([]).currentLevel(unlocked: true), 0);
    expect(campaign([0, 1]).currentLevel(unlocked: true), 2);
    // Everything solved: stay on the last room rather than running off the end.
    final all = campaign([for (var i = 0; i < allLevels.length; i++) i]);
    expect(all.currentLevel(unlocked: true), allLevels.length - 1);
  });

  test('a locked-out player is pointed inside the free chapter', () {
    // With chapters II+ unbought, current must never point past chapter I.
    final done = campaign([for (var i = 0; i < chapterEnd(0); i++) i]);
    expect(done.currentLevel(unlocked: false), lessThan(chapterEnd(0)));
  });
}
