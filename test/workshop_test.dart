import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/geom.dart';
import 'package:in_two_lights/workshop.dart';

void main() {
  for (final p in workshopPuzzles) {
    group(p.name, () {
      final rt = WorkshopRuntime(p);

      test('is solvable by construction', () {
        // The target IS the pieces at home, so this is a tautology only if the
        // plumbing is right. It catches a piece whose polygon and home
        // disagree, or a scoring path that reads the wrong mask.
        final s = rt.score(p.solution);
        expect(s.a, closeTo(1.0, 1e-9));
        expect(s.b, closeTo(1.0, 1e-9));
        expect(s.solved, isTrue);
      });

      test('does not open solved', () {
        expect(rt.score(p.start).solved, isFalse);
      });

      test('start and pieces line up', () {
        expect(p.start.length, p.pieces.length);
        expect(p.pieces.length, greaterThanOrEqualTo(3));
      });

      test('depth moves wall A and leaves wall B alone', () {
        // The whole mechanic. If this ever fails the two walls have stopped
        // being independent editors and the Workshop has no puzzle in it.
        final moved = [...p.solution];
        moved[0] = V3(moved[0].x, moved[0].y, moved[0].z + 0.55);
        final s = rt.score(moved);
        expect(s.b, closeTo(1.0, 1e-9),
            reason: 'wall B must not see depth');
        expect(s.a, lessThan(0.999), reason: 'wall A must see depth');
      });

      test('left-right moves wall B and leaves wall A alone', () {
        final moved = [...p.solution];
        moved[0] = V3(moved[0].x + 0.55, moved[0].y, moved[0].z);
        final s = rt.score(moved);
        expect(s.a, closeTo(1.0, 1e-9),
            reason: 'wall A must not see left-right');
        expect(s.b, lessThan(0.999), reason: 'wall B must see left-right');
      });
    });
  }
}
