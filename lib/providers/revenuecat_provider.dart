import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:drivio/services/revenuecat_service.dart';

final premiumServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService.instance;
});

final productsProvider = FutureProvider<List<Package>>((ref) async {
  return ref.watch(premiumServiceProvider).getProducts();
});

final premiumPurchaseEventsProvider = StreamProvider<PremiumPurchaseEvent>((
  ref,
) {
  return ref.watch(premiumServiceProvider).purchaseEvents;
});

final revenueCatCustomerInfoProvider = StreamProvider<CustomerInfo>((
  ref,
) async* {
  final service = ref.watch(premiumServiceProvider);
  final initial = await service.getCustomerInfo();
  if (initial == null) return;
  yield initial;
  yield* service.customerInfoUpdates;
});

final revenueCatPremiumProvider = Provider<bool>((ref) {
  final info = ref.watch(revenueCatCustomerInfoProvider).value;
  if (info == null) return false;
  return ref.watch(premiumServiceProvider).hasPremium(info);
});
