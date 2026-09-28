import 'package:flutter_test/flutter_test.dart';
import 'package:drivio/services/daily_limit_service.dart';

void main() {
  test('free account receives one free and two rewarded daily views', () {
    final fresh = TrapViewStatus.fromMap({
      'allowed': true,
      'premium': false,
      'views': 0,
      'rewardsGranted': 0,
      'freeRemaining': 1,
      'totalRemaining': 1,
      'rewardGranted': false,
      'canWatchAd': false,
    });
    expect(fresh.views, 0);
    expect(fresh.freeRemaining, 1);
    expect(fresh.rewardsGranted, 0);

    final afterFree = TrapViewStatus.fromMap({
      'views': 1,
      'rewardsGranted': 0,
      'freeRemaining': 0,
      'totalRemaining': 0,
      'canWatchAd': true,
    });
    expect(afterFree.views, 1);
    expect(afterFree.canWatchAd, isTrue);

    final afterFirstAd = TrapViewStatus.fromMap({
      'views': 2,
      'rewardsGranted': 1,
      'rewardGranted': true,
      'freeRemaining': 0,
      'totalRemaining': 0,
      'canWatchAd': true,
    });
    expect(afterFirstAd.rewardsGranted, 1);
    expect(afterFirstAd.canWatchAd, isTrue);
  });
}
