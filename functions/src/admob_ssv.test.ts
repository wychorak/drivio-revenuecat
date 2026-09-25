import {equal, notEqual} from 'node:assert/strict';
import {generateKeyPairSync, sign} from 'node:crypto';
import {test} from 'node:test';

import {ssvKeyId, verifiedParams, verifySignedReward} from './admob_ssv';

const UNIT = 'ca-app-pub-8263324816746737/8516770878';

test('valid signature grants only the configured rewarded unit', () => {
  const {privateKey, publicKey} = generateKeyPairSync('ec', {
    namedCurve: 'prime256v1',
  });
  const payload = [
    'ad_unit=8516770878',
    'custom_data=trap-view-v1',
    'reward_amount=1',
    'timestamp=1790323200000',
    'transaction_id=1234567890abcdef',
    'user_id=firebase_uid',
  ].join('&');
  const signature = sign('SHA256', Buffer.from(payload), privateKey)
    .toString('base64url');
  const url = `/admobRewardSsv?${payload}&signature=${signature}&key_id=123`;
  equal(ssvKeyId(url), '123');
  const result = verifySignedReward(url, UNIT,
    publicKey.export({type: 'spki', format: 'pem'}).toString());
  notEqual(result, null);
  equal(result?.uid, 'firebase_uid');
  equal(result?.customData, 'trap-view-v1');
  equal(result?.transactionId, '1234567890abcdef');
  equal(verifySignedReward(url.replace('user_id=firebase_uid', 'user_id=attacker'),
    UNIT, publicKey.export({type: 'spki', format: 'pem'}).toString()), null);
  equal(verifySignedReward(url, 'ca-app-pub-1/999',
    publicKey.export({type: 'spki', format: 'pem'}).toString()), null);
});

test('signed AdMob URL check without optional user data is valid but untargeted', () => {
  const {privateKey, publicKey} = generateKeyPairSync('ec', {
    namedCurve: 'prime256v1',
  });
  const payload = [
    'ad_unit=8516770878',
    'reward_amount=1',
    'timestamp=1790323200000',
    'transaction_id=1234567890abcdef',
  ].join('&');
  const signature = sign('SHA256', Buffer.from(payload), privateKey)
    .toString('base64url');
  const pem = publicKey.export({type: 'spki', format: 'pem'}).toString();
  const url = `/admobRewardSsv?${payload}&signature=${signature}&key_id=123`;
  const result = verifySignedReward(url, UNIT, pem);
  equal(result?.uid, null);
  equal(result?.customData, null);
  equal(verifySignedReward(url.replace('reward_amount=1', 'reward_amount=9'),
    UNIT, pem), null);
});

test('AdMob "Verify URL" sample is signed but never grants a reward', () => {
  const {privateKey, publicKey} = generateKeyPairSync('ec', {
    namedCurve: 'prime256v1',
  });
  const payload = [
    'ad_network=5450213213286189855',
    'ad_unit=1234567890',
    'reward_amount=1',
    'reward_item=Reward',
    'timestamp=150777823',
    'transaction_id=12345678',
    'user_id=1234567',
  ].join('&');
  const signature = sign('SHA256', Buffer.from(payload), privateKey)
    .toString('base64url');
  const pem = publicKey.export({type: 'spki', format: 'pem'}).toString();
  const url = `/admobRewardSsv?${payload}&signature=${signature}&key_id=123`;
  notEqual(verifiedParams(url, pem), null);
  equal(verifySignedReward(url, UNIT, pem), null);
  equal(verifiedParams(url.replace('ad_unit=1234567890', 'ad_unit=8516770878'),
    pem), null);
});

// Real "Verify URL" callback captured from AdMob, signed with Google's
// production key 3335741209. AdMob signs the decoded query, so the
// percent-encoded reward item must be decoded before verifying.
const ADMOB_VERIFY_URL =
  '/admobRewardSsv?ad_network=5450213213286189855&ad_unit=1234567890&reward_amount=1&reward_item=Odblokowanie%20pu%C5%82apki&timestamp=1790368140021&transaction_id=123456789&signature=MEQCIBYBhBjuiTygD-Ut7pLNhlwO7nGVjhNUwGgDxjnSVM8zAiACnmc0o7rWmbCISEv5w6D9LQceSZezNFAQD18qqIuipA&key_id=3335741209';
const ADMOB_KEY_3335741209 = "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+nzvoGqvDeB9+SzE6igTl7TyK4JB\nbglwir9oTcQta8NuG26ZpZFxt+F2NDk7asTE6/2Yc8i1ATcGIqtuS5hv0Q==\n-----END PUBLIC KEY-----";

test('real AdMob Verify URL callback is signed but grants nothing', () => {
  notEqual(verifiedParams(ADMOB_VERIFY_URL, ADMOB_KEY_3335741209), null);
  equal(verifySignedReward(ADMOB_VERIFY_URL, UNIT, ADMOB_KEY_3335741209), null);
  equal(verifiedParams(
    ADMOB_VERIFY_URL.replace('reward_amount=1', 'reward_amount=2'),
    ADMOB_KEY_3335741209,
  ), null);
});
