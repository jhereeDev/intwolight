import 'package:flutter_test/flutter_test.dart';
import 'package:in_two_lights/store.dart';

/// The gate is the money path, so it gets the one test in this file that
/// matters: it must never lock content the player has no way to buy.
void main() {
  bool unlocked({bool entitled = false, bool canBuy = true, bool force = false}) =>
      Store.computeUnlocked(
          entitled: entitled, canBuy: canBuy, forceLock: force);

  test('nothing to sell means nothing is locked', () {
    // The real state of this app before the Paid Applications agreement goes
    // Active: keys valid, SDK configured, offering empty. The old rule only
    // failed open when the SDK was *unconfigured*, so this case locked 28 of
    // 41 levels behind a disabled "STORE UNAVAILABLE" button.
    expect(unlocked(entitled: false, canBuy: false), isTrue);
  });

  test('a paying customer stays unlocked even if the store goes away', () {
    expect(unlocked(entitled: true, canBuy: false), isTrue);
    expect(unlocked(entitled: true, canBuy: true), isTrue);
  });

  test('a real, sellable offering is the only thing that locks', () {
    expect(unlocked(entitled: false, canBuy: true), isFalse);
  });

  test('QA force-lock beats everything, so the paywall can be inspected', () {
    expect(unlocked(entitled: true, canBuy: true, force: true), isFalse);
    expect(unlocked(entitled: false, canBuy: false, force: true), isFalse);
  });
}
