import 'generator.dart';
import 'level.dart';
import 'rng.dart';

/// ENDLESS — rooms that never run out.
///
/// The campaign is 41 authored-and-curated rooms and it ends. The daily is one
/// room a day from a pool of 180 that wraps. Endless is the same generator with
/// neither a curator nor a calendar: room 1, 2, 3 … for as long as anyone
/// wants to keep going.
///
/// **Room N is the same room for everyone.** The seed is derived from the room
/// number alone, so "I'm on room 340" means something, and a shared challenge
/// resolves to the same puzzle on the other person's device. That property is
/// the entire reason this uses [StableRandom] rather than `dart:math` — see
/// the warning there before changing anything in this file.
///
/// ⚠️ Generation is NOT free: measured on a desktop, a 0-hinge room costs
/// ~37ms and a hinged one ~1s, and a phone is several times slower. Call
/// [endlessLevelFor] off the UI isolate and prefetch the next room while the
/// current one is being played.

/// Rooms before the first joint appears.
///
/// Deliberately longer than the tutorial: a player arriving here has already
/// finished the campaign, but this is also the first thing a *new* buyer might
/// open, and starting them on two joints would be a wall rather than a door.
const int _plainRooms = 8;

/// Rooms before the second joint appears.
const int _oneJointRooms = 24;

/// How many joints room [n] has. Ramps, then holds at two — three-joint chains
/// were never validated and this is not the place to find out.
int bandFor(int n) {
  if (n <= _plainRooms) return 0;
  if (n <= _oneJointRooms) return 1;
  return 2;
}

/// The seed for room [n]. Mixed rather than used raw so neighbouring rooms do
/// not produce visibly similar sculptures.
int seedFor(int n) => 0x51ED2 ^ (n * 0x9E3779B1);

/// The room at depth [n], counting from 1.
///
/// Deterministic: same [n], same [Level], on every device and every SDK.
///
/// Falls back to a wider search rather than returning null. `generateChapter`
/// can exhaust `maxTries` without finding a keeper, and a player who taps NEXT
/// deserves a room rather than an error — so a stubborn seed gets retried with
/// a derived one before giving up.
Level endlessLevelFor(int n) {
  final hinges = bandFor(n);
  for (var attempt = 0; attempt < 4; attempt++) {
    final kept = generateChapter(
      seed: seedFor(n) ^ (attempt * 0x2545F491),
      wanted: 1,
      hinges: hinges,
      rng: StableRandom.new,
    );
    if (kept.isNotEmpty) {
      final lv = kept.first.level;
      return Level(
        name: '$n',
        hint: hinges == 0
            ? ''
            : hinges == 1
                ? 'One arm folds.'
                : 'Two arms fold.',
        boxes: lv.boxes,
        solution: lv.solution,
      );
    }
  }
  // Four independent seeds all failing means the accept band is misconfigured,
  // not that this room is unlucky. Surface it rather than shipping a silent
  // fallback that would quietly hand everyone the same room.
  throw StateError('endless: no acceptable room at depth $n');
}
