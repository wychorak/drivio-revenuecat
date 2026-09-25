import {deepEqual, equal} from 'node:assert/strict';
import {test} from 'node:test';
import {Timestamp} from 'firebase-admin/firestore';

import {hasBackendPremium, trapAllowance, warsawDayKey} from './daily_traps';

test('daily allowance resets at Warsaw midnight in summer and winter', () => {
  equal(warsawDayKey(new Date('2026-09-25T21:59:59Z')), '2026-09-25');
  equal(warsawDayKey(new Date('2026-09-25T22:00:00Z')), '2026-09-26');
  equal(warsawDayKey(new Date('2026-12-25T22:59:59Z')), '2026-12-25');
  equal(warsawDayKey(new Date('2026-12-25T23:00:00Z')), '2026-12-26');
});

test('two free views plus exactly one rewarded view', () => {
  const day = '2026-09-25';
  deepEqual(trapAllowance(undefined, day), {
    dayKey: day,
    views: 0,
    freeRemaining: 2,
    totalRemaining: 2,
    rewardGranted: false,
    canWatchAd: false,
  });
  const twoUsed = trapAllowance({dayKey: day, views: 2}, day);
  equal(twoUsed.freeRemaining, 0);
  equal(twoUsed.totalRemaining, 0);
  equal(twoUsed.canWatchAd, true);
  const rewarded = trapAllowance({dayKey: day, views: 2, rewardGranted: true}, day);
  equal(rewarded.totalRemaining, 1);
  equal(rewarded.canWatchAd, false);
  equal(trapAllowance({dayKey: day, views: 3, rewardGranted: true}, day)
    .totalRemaining, 0);
  equal(trapAllowance({dayKey: day, views: 3, rewardGranted: true},
    '2026-09-26').totalRemaining, 2);
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
