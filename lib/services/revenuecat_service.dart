import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivio/config/app_config.dart';

enum PremiumPurchaseEventType { pending, purchased, restored, canceled, error }

class PremiumPurchaseEvent {
  final PremiumPurchaseEventType type;
  final String? message;

  const PremiumPurchaseEvent({required this.type, this.message});
}

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  static const List<String> productOrder = [
    AppConfig.iapWeekly,
    AppConfig.iapMonthly,
    AppConfig.iapLifetime,
  ];

  static const Set<String> productIds = {
    AppConfig.iapWeekly,
    AppConfig.iapMonthly,
    AppConfig.iapLifetime,
  };

  final StreamController<CustomerInfo> _customerInfo =
      StreamController<CustomerInfo>.broadcast();
  final StreamController<PremiumPurchaseEvent> _events =
      StreamController<PremiumPurchaseEvent>.broadcast();

  bool _configured = false;
  bool _usingTestStore = false;
  String? _configurationIssue;
  Future<void>? _initializing;
  String? _activeUid;

  bool _purchaseInFlight = false;
  bool get isConfigured => _configured;
  bool get isUsingTestStore => _usingTestStore;
  String? get configurationIssue => _configurationIssue;
  String? get activeUid => _activeUid;
  bool get shouldUseIAP =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  Stream<CustomerInfo> get customerInfoUpdates => _customerInfo.stream;
  Stream<PremiumPurchaseEvent> get purchaseEvents => _events.stream;

  Future<void> initialize() async {
    if (_configured || !shouldUseIAP) return;
    final inFlight = _initializing;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final initialization = _configure();
    _initializing = initialization;
    try {
      await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _configure() async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      _configurationIssue = defaultTargetPlatform == TargetPlatform.android
          ? 'Brakuje klucza RevenueCat dla Androida.'
          : 'Brakuje klucza RevenueCat dla tej platformy.';
      debugPrint('RevenueCat: $_configurationIssue');
      return;
    }

    try {
      _usingTestStore = apiKey.startsWith('test_');
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      _configured = true;
      _configurationIssue = null;
      try {
        _onCustomerInfo(await Purchases.getCustomerInfo());
      } catch (error) {
        debugPrint('RevenueCat: initial customer info unavailable: $error');
      }
    } catch (error, stackTrace) {
      _configurationIssue = 'Nie udało się połączyć z RevenueCat.';
      debugPrint('RevenueCat initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String get _apiKey {
    const testFromDefine = String.fromEnvironment('REVENUECAT_TEST_API_KEY');
    final testKey = testFromDefine.isNotEmpty
        ? testFromDefine
        : dotenv.env['REVENUECAT_TEST_API_KEY'] ?? '';
    if (kDebugMode && testKey.isNotEmpty) return testKey;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      const fromDefine = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
      return fromDefine.isNotEmpty
          ? fromDefine
          : dotenv.env['REVENUECAT_IOS_API_KEY'] ??
                AppConfig.revenueCatIosPublicKey;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      const fromDefine = String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');
      return fromDefine.isNotEmpty
          ? fromDefine
          : dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '';
    }
    return '';
  }

  void _onCustomerInfo(CustomerInfo info) {
    if (!_customerInfo.isClosed) _customerInfo.add(info);
  }

  Future<List<Package>> getProducts() async {
    await initialize();
    if (!_configured) {
      throw StateError(
        _configurationIssue ?? 'Sklep RevenueCat nie jest skonfigurowany.',
      );
    }

    final offerings = await Purchases.getOfferings();
    final offering =
        offerings.all[AppConfig.revenueCatOfferingId] ?? offerings.current;
    if (offering == null) {
      throw StateError(
        'Brak offeringu RevenueCat: ${AppConfig.revenueCatOfferingId}',
      );
    }

    final packages = offering.availablePackages
        .where((item) => productIds.contains(item.storeProduct.identifier))
        .toList();
    packages.sort(
      (a, b) => productOrder
          .indexOf(a.storeProduct.identifier)
          .compareTo(productOrder.indexOf(b.storeProduct.identifier)),
    );
    return packages;
  }

  Future<void> purchase({required String uid, required Package product}) async {
    await initialize();
    if (!_configured) {
      throw StateError('Sklep RevenueCat nie jest skonfigurowany.');
    }
    await syncUser(uid);
    if (_purchaseInFlight) {
      return;
    }
    _purchaseInFlight = true;
    try {
      _events.add(
        const PremiumPurchaseEvent(
          type: PremiumPurchaseEventType.pending,
          message: 'Otwieranie płatności w sklepie…',
        ),
      );

      try {
        if (!productIds.contains(product.storeProduct.identifier)) {
          throw StateError('Nieznany produkt App Store.');
        }
        final result = await Purchases.purchase(
          PurchaseParams.package(product),
        );
        _onCustomerInfo(result.customerInfo);
        if (!hasPremium(result.customerInfo)) {
          throw StateError(
            'Zakup zakończony, ale entitlement Premium nie został aktywowany.',
          );
        }
        _events.add(
          const PremiumPurchaseEvent(
            type: PremiumPurchaseEventType.purchased,
            message: 'Premium zostało aktywowane.',
          ),
        );
      } on PlatformException catch (error) {
        final code = PurchasesErrorHelper.getErrorCode(error);
        if (code == PurchasesErrorCode.purchaseCancelledError) {
          _events.add(
            const PremiumPurchaseEvent(type: PremiumPurchaseEventType.canceled),
          );
          return;
        }
        rethrow;
      }
    } finally {
      _purchaseInFlight = false;
    }
  }

  Future<void> restorePurchases(String uid) async {
    await initialize();
    if (!_configured) {
      throw StateError('Sklep RevenueCat nie jest skonfigurowany.');
    }
    await syncUser(uid);
    final info = await Purchases.restorePurchases();
    _onCustomerInfo(info);
    _events.add(
      PremiumPurchaseEvent(
        type: PremiumPurchaseEventType.restored,
        message: hasPremium(info)
            ? 'Zakupy zostały przywrócone.'
            : 'Nie znaleziono aktywnego Premium dla tego konta sklepu.',
      ),
    );
  }

  Future<void> syncUser(String? uid) async {
    await initialize();
    if (!_configured || uid == _activeUid) return;

    if (_activeUid != null) {
      final info = await Purchases.getCustomerInfo();
      if (!info.originalAppUserId.startsWith(r'$RCAnonymousID:')) {
        await Purchases.logOut();
      }
    }
    _activeUid = uid;
    if (uid != null && uid.isNotEmpty) {
      final result = await Purchases.logIn(uid);
      _onCustomerInfo(result.customerInfo);
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    await initialize();
    return _configured ? Purchases.getCustomerInfo() : null;
  }

  bool hasPremium(CustomerInfo info) {
    return info.entitlements.active.containsKey(
      AppConfig.revenueCatEntitlementId,
    );
  }

  Future<void> openStripePayment(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Nie udało się otworzyć płatności.');
    }
  }
}
