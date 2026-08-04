import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/forms.dart';
import 'package:in_two_lights/menagerie.dart';

void main() {
  test('only named figures are collectable, and every authored one is', () {
    // The rule is "has a name rather than a number". If a generated level ever
    // gets a name, or an authored one loses it, the cabinet silently changes
    // size and nobody notices until a slot is missing.
    expect(figures, isNotEmpty);
    for (final f in figures) {
      expect(int.tryParse(f.level.name), isNull,
          reason: '${f.level.name} is a generated level, not a figure');
    }
    final named =
        allLevels.where((l) => int.tryParse(l.name) == null).length;
    expect(figures.length, named);
    for (final want in ['Cat', 'Duck', 'Fish', 'Boat', 'Moth', 'Hare',
                        'Pear', 'Vessel']) {
      expect(figures.any((f) => f.level.name == want), isTrue,
          reason: '$want is missing from the cabinet');
    }
  });

  test('every figure has a drawable outline', () {
    // A figure whose wall-B shadow is empty would render as a blank tile that
    // still claims to be found — the exact failure a cosmetic feature hides.
    for (final f in figures) {
      final b = outlineOf(f.index).getBounds();
      expect(b.isEmpty, isFalse, reason: '${f.level.name} has no outline');
      expect(b.width, greaterThan(0.05));
      expect(b.height, greaterThan(0.05));
    }
  });

  test('indices point at the level they name', () {
    for (final f in figures) {
      expect(allLevels[f.index].name, f.level.name);
    }
  });
}
