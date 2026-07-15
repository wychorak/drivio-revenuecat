import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivio/models/user_model.dart';
import 'package:drivio/services/firestore_service.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/revenuecat_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final userDataProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).getUserData(uid);
});

final isPremiumProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final customerInfo = ref.watch(revenueCatCustomerInfoProvider);
  final revenueCat = ref.watch(premiumServiceProvider);

  return customerInfo.when(
    data: revenueCat.hasPremium,
    loading: () => _hasFirestorePremium(userAsync),
    error: (_, _) => _hasFirestorePremium(userAsync),
  );
});

bool _hasFirestorePremium(AsyncValue<UserModel?> userAsync) {
  return userAsync.when(
    data: (user) {
      if (user == null || !user.isPremium) return false;
      if (user.premiumUntil != null &&
          user.premiumUntil!.isBefore(DateTime.now())) {
        return false;
      }
      return true;
    },
    loading: () => false,
    error: (_, _) => false,
  );
}
