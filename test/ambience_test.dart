import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/progress.dart';
import 'package:in_two_lights/scene.dart';

/// The two lights are what the game is named after. A chapter may re-colour
/// them; it may not merge them.
void main() {
  test('every chapter has a light', () {
    expect(Ambience.byChapter.length, chapterStarts.length,
        reason: 'a chapter without an entry silently falls back to the last');
  });

  test('the two lamps stay distinguishable in every chapter', () {
    // Not a style preference: if both walls are lit identically, the player
    // loses the cue telling them which constraint they are looking at.
    for (var c = 0; c < Ambience.byChapter.length; c++) {
      final a = Ambience.byChapter[c];
      final warmth = (a.lamp.r - a.lamp.b) - (a.lamp2.r - a.lamp2.b);
      expect(warmth, greaterThan(0.08),
          reason: 'chapter $c: lamps too close to tell apart');
    }
  });

  test('walls stay dark enough for a shadow to read against', () {
    // Shadows are drawn dark ON a lit wall. If a chapter brightens the unlit
    // wall too far, the contrast that carries the whole mechanic collapses.
    for (var c = 0; c < Ambience.byChapter.length; c++) {
      final w = Ambience.byChapter[c].wall;
      final luma = 0.2126 * w.r + 0.7152 * w.g + 0.0722 * w.b;
      expect(luma, lessThan(0.14), reason: 'chapter $c wall too bright');
    }
  });

  test('out-of-range and null chapters resolve rather than crash', () {
    expect(Ambience.of(null), Ambience.neutral);
    expect(Ambience.of(99), Ambience.byChapter.last);
    expect(Ambience.of(-1), Ambience.byChapter.first);
  });
}
