import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/revenuecat_provider.dart';

export 'package:drivio/providers/revenuecat_provider.dart';

final premiumIapBootstrapProvider = Provider<void>((ref) {
  final devLogin = ref.watch(devLoginProvider);
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(premiumServiceProvider);

  authState.whenData((user) {
    unawaited(service.syncUser(devLogin ? null : user?.uid));
  });
});
