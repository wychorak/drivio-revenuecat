import 'package:cloud_functions/cloud_functions.dart';

class TrapViewStatus {
  const TrapViewStatus({
    required this.allowed,
    required this.premium,
    required this.freeRemaining,
    required this.totalRemaining,
    required this.rewardGranted,
    required this.canWatchAd,
  });

  final bool allowed;
  final bool premium;
  final int freeRemaining;
  final int totalRemaining;
  final bool rewardGranted;
  final bool canWatchAd;

  factory TrapViewStatus.fromMap(Map<Object?, Object?> data) {
    return TrapViewStatus(
      allowed: data['allowed'] == true,
      premium: data['premium'] == true,
      freeRemaining: (data['freeRemaining'] as num?)?.toInt() ?? 0,
      totalRemaining: (data['totalRemaining'] as num?)?.toInt() ?? 0,
      rewardGranted: data['rewardGranted'] == true,
      canWatchAd: data['canWatchAd'] == true,
    );
  }
}

class DailyLimitService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  Future<TrapViewStatus> consumeTrapView() async {
    final response = await _functions
        .httpsCallable('consumeDailyTrapView')
        .call();
    return TrapViewStatus.fromMap(Map<Object?, Object?>.from(response.data));
  }

  Future<TrapViewStatus> getStatus() async {
    final response = await _functions.httpsCallable('getTrapViewStatus').call();
    return TrapViewStatus.fromMap(Map<Object?, Object?>.from(response.data));
  }
}
