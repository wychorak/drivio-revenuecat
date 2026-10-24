import {deepEqual, equal} from 'node:assert/strict';
import {test} from 'node:test';
import {Timestamp} from 'firebase-admin/firestore';

import {
  hasBackendPremium,
  trapAllowance,
  usageFields,
  warsawDayKey,
} from './daily_traps';

test('daily allowance resets at Warsaw midnight in summer and winter', () => {
  equal(warsawDayKey(new Date('2026-09-25T21:59:59Z')), '2026-09-25');
  equal(warsawDayKey(new Date('2026-09-25T22:00:00Z')), '2026-09-26');
  equal(warsawDayKey(new Date('2026-12-25T22:59:59Z')), '2026-12-25');
  equal(warsawDayKey(new Date('2026-12-25T23:00:00Z')), '2026-12-26');
});

test('three free views plus two rewarded views a day', () => {
  const day = '2026-09-25';
  deepEqual(trapAllowance(undefined, day), {
    dayKey: day,
    views: 0,
    freeRemaining: 3,
    totalRemaining: 3,
    rewardGranted: false,
    rewardsGranted: 0,
    rewardTransactionIds: [],
    canWatchAd: false,
  });
  const oneFreeLeft = trapAllowance({dayKey: day, views: 2}, day);
  equal(oneFreeLeft.freeRemaining, 1);
  equal(oneFreeLeft.canWatchAd, false);
  const freeUsed = trapAllowance({dayKey: day, views: 3}, day);
  equal(freeUsed.totalRemaining, 0);
  equal(freeUsed.canWatchAd, true);
  const firstReward = trapAllowance({dayKey: day, views: 3, rewardsGranted: 1}, day);
  equal(firstReward.totalRemaining, 1);
  equal(firstReward.canWatchAd, false);
  const secondAdNeeded = trapAllowance({dayKey: day, views: 4, rewardsGranted: 1}, day);
  equal(secondAdNeeded.canWatchAd, true);
  const allUsed = trapAllowance({dayKey: day, views: 5, rewardsGranted: 2}, day);
  equal(allUsed.totalRemaining, 0);
  equal(allUsed.canWatchAd, false);
  equal(trapAllowance({dayKey: day, views: 5, rewardsGranted: 9}, day)
    .rewardsGranted, 2);
  equal(trapAllowance(allUsed, '2026-09-26').totalRemaining, 3);
});

test('legacy boolean reward counts as one rewarded view', () => {
  const day = '2026-09-25';
  const legacy = trapAllowance({dayKey: day, views: 3, rewardGranted: true}, day);
  equal(legacy.rewardsGranted, 1);
  equal(legacy.totalRemaining, 1);
  deepEqual(usageFields({...legacy, views: 4}), {
    dayKey: day,
    views: 4,
    rewardGranted: true,
    rewardsGranted: 1,
    rewardTransactionIds: [],
  });
});

test('premium checks expiration, including lifetime access', () => {
  const now = new Date('2026-09-25T10:00:00Z');
  equal(hasBackendPremium({isPremium: true, premiumUntil: null}, now), true);
  equal(hasBackendPremium({isPremium: true,
    premiumUntil: Timestamp.fromDate(new Date('2026-09-26T10:00:00Z'))}, now), true);
  equal(hasBackendPremium({isPremium: true,
    premiumUntil: Timestamp.fromDate(new Date('2026-09-24T10:00:00Z'))}, now), false);
  equal(hasBackendPremium({isPremium: false}, now), false);
});
