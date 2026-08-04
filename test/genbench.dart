// flutter test test/genbench.dart
// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/generator.dart';

void main() {
  test('cost of generating one acceptable level', () {
    for (final hinges in [0, 1, 2]) {
      final sw = Stopwatch()..start();
      final kept = generateChapter(seed: 4242 + hinges, wanted: 8, hinges: hinges);
      sw.stop();
      final each = sw.elapsedMilliseconds / (kept.isEmpty ? 1 : kept.length);
      print('hinges=$hinges  kept=${kept.length}/8  '
          'total=${sw.elapsedMilliseconds}ms  per level=${each.toStringAsFixed(0)}ms');
    }
  });
}
