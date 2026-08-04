import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/challenge.dart';
import 'package:in_two_lights/daily.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a challenge card renders to a real PNG', () async {
    final bytes = await renderChallengeCard(dailyLevelFor(DateTime(2026, 8, 4)));
    expect(bytes, isNotNull);
    // PNG magic. A card that silently produced an empty or malformed buffer
    // would share as a broken attachment and look like the app is broken.
    expect(bytes!.sublist(0, 8),
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    expect(bytes.length, greaterThan(4000),
        reason: 'a card this small is an empty rectangle, not a room');
  });

  test('the same day always yields the same card', () async {
    // The whole premise of a challenge: the room your friend opens is the room
    // you were looking at.
    final a = await renderChallengeCard(dailyLevelFor(DateTime(2026, 9, 1)));
    final b = await renderChallengeCard(dailyLevelFor(DateTime(2026, 9, 1, 23)));
    expect(a, equals(b));
  });

  test('different days yield different cards', () async {
    final a = await renderChallengeCard(dailyLevelFor(DateTime(2026, 9, 1)));
    final b = await renderChallengeCard(dailyLevelFor(DateTime(2026, 9, 2)));
    expect(a, isNot(equals(b)));
  });
}
