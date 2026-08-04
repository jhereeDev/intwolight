import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat, wrapped so the rest of the game never sees it.
///
/// Keys are supplied at build time and are **public** SDK keys — RevenueCat
/// designs these to ship inside the client, so they are not secrets. They are
/// still passed by --dart-define rather than committed, so a fork of this repo
/// does not bill Jhere's account:
///
///   flutter build ipa --release \
///     --dart-define=RC_IOS_KEY=appl_xxx \
///     --dart-define=RC_ANDROID_KEY=goog_xxx
///
/// ⚠️ **Unconfigured means unlocked, deliberately.** If the keys are missing,
/// the network is down, or RevenueCat errors, the game does NOT lock its
/// chapters. Failing closed would mean a bad build, a flaky connection or an
/// outage silently paywalls people who have already paid — including App
/// Review, which is a guaranteed rejection under Guideline 3.1.1. Losing a
/// sale to a misconfiguration is much cheaper than that.
class Store extends ChangeNotifier {
  /// Entitlement identifier as configured in the RevenueCat dashboard.
  ///
  /// A mismatch between this string and the dashboard is the single most
  /// common way this integration fails: the purchase succeeds, money changes
  /// hands, and nothing unlocks. Two defences:
  ///   1. it is overridable at build time, so a dashboard rename does not
  ///      need a code change and a re-review;
  ///   2. [_entitledIn] falls back to *any* active entitlement. This app sells
  ///      exactly one thing, so "owns something" and "owns the unlock" are the
  ///      same statement — and a paying customer locked out by a typo is far
  ///      worse than a customer let in by a loose check.
  static const entitlement = String.fromEnvironment('RC_ENTITLEMENT',
      defaultValue: 'In Two Lights Pro');

  static const _iosKey = String.fromEnvironment('RC_IOS_KEY');
  static const _androidKey = String.fromEnvironment('RC_ANDROID_KEY');

  /// QA only: force the locked state so the unlock screen can be inspected
  /// without real keys, and so App Review can be shown the paywall on demand.
  /// Defaults false, so a normal build can never ship locked by accident.
  ///   flutter run --dart-define=RC_FORCE_LOCK=true
  static const _forceLock = bool.fromEnvironment('RC_FORCE_LOCK');

  bool _configured = false;
  bool _entitled = false;
  Package? _package;
  String? _price;
  String? _lastError;

  /// True when chapters beyond the first should be playable — because the
  /// unlock was bought, or because there is no way to buy it right now.
  ///
  /// ⚠️ **"Nothing to sell" counts as unreachable.** This used to fail open
  /// only when the SDK was *unconfigured*, which missed the state this app is
  /// actually in before the Paid Applications agreement goes Active: keys
  /// valid, SDK configured, offering empty because no product exists yet. That
  /// combination locked 28 of 41 levels behind a button that says
  /// "STORE UNAVAILABLE" and does nothing — a broken game, and a guaranteed
  /// Guideline 3.1.1 rejection for App Review, who would have hit exactly that.
  bool get unlocked => computeUnlocked(
      entitled: _entitled, canBuy: canBuy, forceLock: _forceLock);

  /// Pulled out as a pure function because it is the money path, and the
  /// instance version depends on SDK state no test can construct.
  static bool computeUnlocked({
    required bool entitled,
    required bool canBuy,
    required bool forceLock,
  }) =>
      forceLock ? false : (entitled || !canBuy);

  bool get configured => _configured;

  /// RevenueCat's Test Store keys start with `test_`. They simulate purchases
  /// with no App Store Connect setup, which is how this flow gets verified
  /// before the Paid Applications agreement exists — but a build that ships
  /// with one takes no money and cannot restore a real purchase.
  ///
  /// ⚠️ **A test key only works in a debug or profile build.** In release the
  /// SDK itself puts up a "Wrong API Key" dialog and then *closes the app* —
  /// verified on device 2026-08-03. So test the purchase flow with
  /// `flutter run --dart-define=RC_ANDROID_KEY=test_...` and never assume a
  /// release build will behave the same.
  ///
  /// It is surfaced rather than merely logged: if a test key ever reaches
  /// production the unlock screen says so on its face, which is a bad minute
  /// instead of a bad month of silently zero revenue.
  static bool get usingTestStore =>
      _iosKey.startsWith('test_') || _androidKey.startsWith('test_');
  bool get canBuy => _configured && _package != null;
  String get price => _price ?? '';
  String? get lastError => _lastError;

  Future<void> init() async {
    if (_iosKey.isEmpty && _androidKey.isEmpty) {
      debugPrint('Store: no RevenueCat keys — running unlocked. '
          'Pass --dart-define=RC_IOS_KEY=... to enable purchases.');
      return;
    }
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final key = defaultTargetPlatform == TargetPlatform.iOS ? _iosKey : _androidKey;
      if (key.isEmpty) return;
      await Purchases.configure(PurchasesConfiguration(key));
      _configured = true;
      if (usingTestStore) {
        debugPrint('Store: ⚠️  TEST STORE key in use — purchases are '
            'simulated and no money is taken. Swap in the appl_/goog_ keys '
            'before shipping.');
      }

      Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await Purchases.getCustomerInfo());
      await _loadOffering();
    } catch (e) {
      // Stay unconfigured, therefore unlocked. See the note above.
      _configured = false;
      _lastError = '$e';
      debugPrint('Store: init failed, running unlocked — $e');
    }
    notifyListeners();
  }

  Future<void> _loadOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null || current.availablePackages.isEmpty) return;
      _package = current.availablePackages.first;
      _price = _package!.storeProduct.priceString;
    } catch (e) {
      _lastError = '$e';
    }
  }

  static bool _entitledIn(CustomerInfo info) {
    if (info.entitlements.active.containsKey(entitlement)) return true;
    if (info.entitlements.active.isNotEmpty) {
      debugPrint('Store: "$entitlement" not found, but '
          '${info.entitlements.active.keys.join(", ")} is active — unlocking. '
          'Fix the identifier to silence this.');
      return true;
    }
    return false;
  }

  void _apply(CustomerInfo info) {
    final now = _entitledIn(info);
    if (now != _entitled) {
      _entitled = now;
      notifyListeners();
    }
  }

  /// Returns true if the unlock is now owned.
  Future<bool> buy() async {
    if (_package == null) return false;
    _lastError = null;
    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(_package!));
      _apply(result.customerInfo);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      // A cancel is not an error worth showing.
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        _lastError = e.message;
      }
    } catch (e) {
      _lastError = '$e';
    }
    notifyListeners();
    return _entitled;
  }

  /// Apple requires a restore path for any non-consumable purchase
  /// (Guideline 3.1.1). It is not optional and its absence is a rejection.
  Future<bool> restore() async {
    _lastError = null;
    try {
      _apply(await Purchases.restorePurchases());
    } catch (e) {
      _lastError = '$e';
    }
    notifyListeners();
    return _entitled;
  }
}
