import 'dailies.g.dart';
import 'level.dart';

/// Day zero of the daily room. Fixed forever — moving it reshuffles which
/// puzzle every past date maps to, and invalidates every recorded daily.
final _epoch = DateTime.utc(2026, 8, 4);

/// How many days since [_epoch]. Unbounded and strictly increasing, so it is
/// also the **storage key**: day 4 and day 184 land on the same *room* once the
/// pool wraps, but they are different *days* and must record separately.
/// Negative before the epoch, which is fine for a map key.
///
/// **UTC, not local, for the arithmetic.** The date the player sees is their
/// local one, but the *subtraction* happens in UTC. `DateTime.difference` on
/// local dates crossing a daylight-saving boundary returns 23 or 25 hours, and
/// `.inDays` truncates — so twice a year a player's daily would either repeat
/// or skip a room. Normalising to UTC midnight removes the possibility.
int dailyDayNumber(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).difference(_epoch).inDays;

/// Which room, as an index into [dailyLevels].
///
/// Dart's `%` is non-negative for a positive divisor, so dates before the
/// epoch land in range rather than crashing on a negative index.
///
/// **The pool wraps.** After `dailyLevels.length` days it starts over — that is
/// deliberate and honest. Extend the bands in `tool/gen_dailies.dart` before it
/// comes around rather than pretending the pool is infinite.
int dailyIndexFor(DateTime day) =>
    dailyDayNumber(day) % dailyLevels.length;

Level dailyLevelFor(DateTime day) => dailyLevels[dailyIndexFor(day)];
