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
  /// Matches the entitlement identifier configured in the RevenueCat
  /// dashboard. If this string and the dashboard disagree, purchases succeed
  /// and nothing unlocks — the single most common way this integration fails.
  static const entitlement = 'all_chapters';

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

  /// True when chapters beyond the first should be playable — either because
  /// the unlock was bought, or because the store could not be reached at all.
  bool get unlocked => _forceLock ? false : (_entitled || !_configured);

  bool get configured => _configured;
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

  void _apply(CustomerInfo info) {
    final now = info.entitlements.active.containsKey(entitlement);
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
      final result = await Purchases.purchasePackage(_package!);
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
