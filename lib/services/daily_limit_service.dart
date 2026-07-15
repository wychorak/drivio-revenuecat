import 'package:drivio/config/app_config.dart';
import 'package:drivio/services/firestore_service.dart';

class DailyLimitService {
  final FirestoreService _firestoreService;

  DailyLimitService(this._firestoreService);

  /// Atomically consumes one view. Premium users are never counted.
  Future<bool> consumeTrapView(String uid, bool isPremium) async {
    if (isPremium) return true;
    return _firestoreService.consumeTrapView(uid, AppConfig.freeDailyTrapLimit);
  }

  /// Returns how many trap views the user has left today.
  Future<int> getRemainingViews(String uid) async {
    final viewsToday = await _firestoreService.getTrapViewsToday(uid);
    final remaining = AppConfig.freeDailyTrapLimit - viewsToday;
    return remaining < 0 ? 0 : remaining;
  }
}
