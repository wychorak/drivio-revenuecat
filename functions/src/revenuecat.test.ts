import {deepEqual, equal} from 'node:assert/strict';
import {test} from 'node:test';

import {
  firebaseUidCandidates,
  premiumStateForEvent,
} from './revenuecat';

test('prefers Firebase ids and removes RevenueCat anonymous ids', () => {
  deepEqual(
    firebaseUidCandidates({
      app_user_id: '$RCAnonymousID:abc',
      original_app_user_id: 'firebase-user',
      aliases: ['firebase-user', 'second-user'],
    }),
    ['firebase-user', 'second-user'],
  );
});

test('cancellation remains active until its expiration date', () => {
  const state = premiumStateForEvent(
    {
      type: 'CANCELLATION',
      product_id: 'driviomonth',
      entitlement_ids: ['drivio pro relase'],
      expiration_at_ms: 2_000,
    },
    1_000,
  );
  equal(state?.isPremium, true);
  equal(state?.premiumPlan, 'monthly');
});

test('expiration revokes premium', () => {
  const state = premiumStateForEvent({
    type: 'EXPIRATION',
    product_id: 'drivioweek',
    entitlement_ids: ['drivio pro relase'],
    expiration_at_ms: 2_000,
  });
  equal(state?.isPremium, false);
});

test('lifetime product stays active without an expiration date', () => {
  const state = premiumStateForEvent({
    type: 'NON_RENEWING_PURCHASE',
    product_id: 'driviolifetime',
    entitlement_ids: ['drivio pro relase'],
    expiration_at_ms: null,
  });
  equal(state?.isPremium, true);
  equal(state?.premiumUntil, null);
});
