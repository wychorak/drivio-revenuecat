import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivio/services/ad_service.dart';

final adReadinessProvider = FutureProvider<bool>((ref) {
  return AdService.instance.initialize();
});

final adPrivacyOptionsRequiredProvider = FutureProvider<bool>((ref) {
  return AdService.instance.isPrivacyOptionsRequired();
});
