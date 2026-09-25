import {equal, notEqual} from 'node:assert/strict';
import {generateKeyPairSync, sign} from 'node:crypto';
import {test} from 'node:test';

import {ssvKeyId, verifySignedReward} from './admob_ssv';

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
