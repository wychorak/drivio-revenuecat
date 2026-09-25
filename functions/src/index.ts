import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {FieldValue, Timestamp, getFirestore} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {defineSecret} from 'firebase-functions/params';
import {HttpsError, onCall, onRequest} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions';

import {
  firebaseUidCandidates,
  isValidRevenueCatAuthorization,
  premiumStateForEvent,
  RevenueCatEvent,
} from './revenuecat';
import {
  hasBackendPremium,
  REWARDED_DAILY_TRAPS,
  trapAllowance,
  usageFields,
  warsawDayKey,
} from './daily_traps';
import {
  getAdMobKey,
  getAdMobTestKey,
  ssvKeyId,
  verifiedParams,
  verifySignedReward,
} from './admob_ssv';

initializeApp();

const REGION = 'europe-west1';
const ADMIN_EMAILS = new Set([
  'joa.rycyk@gmail.com',
  'estlin20@gmail.com',
]);
const revenueCatWebhookAuth = defineSecret('REVENUECAT_WEBHOOK_AUTH');
const ADMOB_IOS_REWARDED_UNIT_ID =
  'ca-app-pub-8263324816746737/8516770878';

function requireUid(uid: string | undefined): string {
  if (!uid) throw new HttpsError('unauthenticated', 'Wymagane logowanie.');
  return uid;
}

export const getTrapViewStatus = onCall(
  {region: REGION, enforceAppCheck: true},
  async (request) => {
    const uid = requireUid(request.auth?.uid);
    const db = getFirestore();
    const [usage, user] = await Promise.all([
      db.collection('users').doc(uid).collection('usage').doc('trapViews').get(),
      db.collection('users').doc(uid).get(),
    ]);
    const now = new Date();
    return {
      ...trapAllowance(usage.data(), warsawDayKey(now)),
      premium: request.auth?.token.admin === true ||
        hasBackendPremium(user.data(), now),
    };
  },
);

export const consumeDailyTrapView = onCall(
  {region: REGION, enforceAppCheck: true},
  async (request) => {
    const uid = requireUid(request.auth?.uid);
    const db = getFirestore();
    const userRef = db.collection('users').doc(uid);
    const usageRef = userRef.collection('usage').doc('trapViews');
    return db.runTransaction(async (transaction) => {
      const [user, usage] = await Promise.all([
        transaction.get(userRef),
        transaction.get(usageRef),
      ]);
      const now = new Date();
      const allowance = trapAllowance(usage.data(), warsawDayKey(now));
      if (request.auth?.token.admin === true ||
          hasBackendPremium(user.data(), now)) {
        return {...allowance, allowed: true, premium: true};
      }
      if (allowance.totalRemaining === 0) {
        return {...allowance, allowed: false, premium: false};
      }
      const updated = usageFields({...allowance, views: allowance.views + 1});
      transaction.set(usageRef, {
        ...updated,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return {
        ...trapAllowance(updated, allowance.dayKey),
        allowed: true,
        premium: false,
      };
    });
  },
);

// Configure this URL as the rewarded interstitial unit's SSV callback in AdMob.
// Only Google's signed callback may grant the third daily trap view.
export const admobRewardSsv = onRequest(
  {region: REGION},
  async (request, response) => {
    if (request.method !== 'GET') {
      response.status(405).send('Method Not Allowed');
      return;
    }
    const keyId = ssvKeyId(request.originalUrl);
    if (!keyId) {
      response.status(400).send('Missing signature');
      return;
    }
    let keyPem: string | null;
    try {
      keyPem = await getAdMobKey(keyId);
    } catch (error) {
      logger.error('Could not fetch AdMob verification keys', error);
      response.status(503).send('Verification unavailable');
      return;
    }
    if (!keyPem) {
      // The AdMob console's "Verify URL" check may be signed with a test key.
      // Acknowledge a valid test signature, but never grant a reward for it.
      let testKeyPem: string | null = null;
      try {
        testKeyPem = await getAdMobTestKey(keyId);
      } catch (error) {
        logger.error('Could not fetch AdMob test verification keys', error);
      }
      if (testKeyPem && verifiedParams(request.originalUrl, testKeyPem)) {
        logger.info('Verified AdMob test callback', {keyId});
        response.status(200).send('Verified test callback; no reward');
        return;
      }
      logger.warn('Rejected AdMob callback with unknown key', {keyId});
      response.status(403).send('Unknown key');
      return;
    }
    if (!verifiedParams(request.originalUrl, keyPem)) {
      logger.warn('Rejected AdMob callback with invalid signature');
      response.status(403).send('Invalid signature');
      return;
    }
    const reward = verifySignedReward(
      request.originalUrl,
      ADMOB_IOS_REWARDED_UNIT_ID,
      keyPem,
    );
    // AdMob's "Verify URL" check is signed but uses sample ad unit and
    // transaction values and omits user/custom data. It must succeed, but
    // must never grant an actual view.
    if (!reward || !reward.uid || reward.customData !== 'trap-view-v1') {
      response.status(200).send('Verified callback; no reward target');
      return;
    }
    const now = new Date();
    if (Math.abs(now.getTime() - reward.timestamp.getTime()) > 60 * 60 * 1000 ||
        warsawDayKey(now) !== warsawDayKey(reward.timestamp)) {
      response.status(200).send('Expired reward');
      return;
    }
    const usageRef = getFirestore().collection('users').doc(reward.uid)
      .collection('usage').doc('trapViews');
    try {
      await getFirestore().runTransaction(async (transaction) => {
        const usage = await transaction.get(usageRef);
        const allowance = trapAllowance(usage.data(), warsawDayKey(now));
        // AdMob may retry a callback, so each transaction counts only once.
        if (allowance.rewardsGranted >= REWARDED_DAILY_TRAPS ||
            allowance.rewardTransactionIds.includes(reward.transactionId)) {
          return;
        }
        transaction.set(usageRef, {
          ...usageFields({
            ...allowance,
            rewardsGranted: allowance.rewardsGranted + 1,
            rewardTransactionIds: [
              ...allowance.rewardTransactionIds,
              reward.transactionId,
            ],
          }),
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      logger.error('Could not grant rewarded trap view', error);
      response.status(503).send('Reward unavailable');
      return;
    }
    response.status(200).send('OK');
  },
);

async function deleteQuery(
  collection: string,
  ownerField: string,
  uid: string,
): Promise<void> {
  const db = getFirestore();
  while (true) {
    const snapshot = await db
      .collection(collection)
      .where(ownerField, '==', uid)
      .limit(400)
      .get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((document) => batch.delete(document.ref));
    await batch.commit();
    if (snapshot.size < 400) return;
  }
}

export const deleteAccount = onCall(
  {region: REGION, enforceAppCheck: true},
  async (request) => {
    const uid = request.auth?.uid;
    if (uid == null) {
      throw new HttpsError('unauthenticated', 'Wymagane logowanie.');
    }

    const authTime = Number(request.auth?.token.auth_time ?? 0) * 1000;
    if (!authTime || Date.now() - authTime > 5 * 60 * 1000) {
      throw new HttpsError(
        'failed-precondition',
        'Zaloguj się ponownie przed usunięciem konta.',
      );
    }

    await Promise.all([
      deleteQuery('comments', 'userId', uid),
      deleteQuery('reports', 'reporterId', uid),
      deleteQuery('traps', 'createdBy', uid),
      getStorage().bucket().deleteFiles({prefix: `traps/${uid}/`}),
    ]);

    const userRef = getFirestore().collection('users').doc(uid);
    await getFirestore().recursiveDelete(userRef);
    await getAuth().deleteUser(uid);
    return {success: true};
  },
);

export const refreshAdminClaim = onCall(
  {region: REGION, enforceAppCheck: true},
  async (request) => {
    const uid = request.auth?.uid;
    if (uid == null) {
      throw new HttpsError('unauthenticated', 'Wymagane logowanie.');
    }

    const user = await getAuth().getUser(uid);
    const email = user.email?.trim().toLowerCase() ?? '';
    if (!ADMIN_EMAILS.has(email) || !user.emailVerified) {
      throw new HttpsError('permission-denied', 'Brak uprawnień administratora.');
    }

    await getAuth().setCustomUserClaims(uid, {
      ...(user.customClaims ?? {}),
      admin: true,
    });
    await getFirestore().collection('users').doc(uid).set(
      {
        isPremium: true,
        premiumUntil: null,
        premiumPlan: 'admin',
        premiumSource: 'admin',
        premiumUpdatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    return {success: true, refreshToken: true};
  },
);

async function resolveFirebaseUid(event: RevenueCatEvent): Promise<string | null> {
  for (const candidate of firebaseUidCandidates(event)) {
    try {
      await getAuth().getUser(candidate);
      return candidate;
    } catch (error) {
      const code = (error as {code?: string}).code;
      if (code !== 'auth/user-not-found') throw error;
    }
  }
  return null;
}

export const revenueCatWebhook = onRequest(
  {region: REGION, secrets: [revenueCatWebhookAuth]},
  async (request, response) => {
    if (request.method !== 'POST') {
      response.status(405).send('Method Not Allowed');
      return;
    }
    if (!isValidRevenueCatAuthorization(
      request.get('authorization'),
      revenueCatWebhookAuth.value(),
    )) {
      response.status(401).send('Unauthorized');
      return;
    }

    const event = request.body?.event as RevenueCatEvent | undefined;
    if (event?.id == null || event.type == null) {
      response.status(400).send('Invalid webhook payload');
      return;
    }

    const state = premiumStateForEvent(event);
    if (state == null) {
      response.status(200).send('Ignored');
      return;
    }
    const uid = await resolveFirebaseUid(event);
    if (uid == null) {
      logger.warn('RevenueCat event has no Firebase UID', {eventId: event.id});
      response.status(200).send('No Firebase user');
      return;
    }

    const db = getFirestore();
    const eventRef = db.collection('revenueCatEvents').doc(event.id);
    const userRef = db.collection('users').doc(uid);
    await db.runTransaction(async (transaction) => {
      if ((await transaction.get(eventRef)).exists) return;
      const userSnapshot = await transaction.get(userRef);
      const incomingTimestamp = event.event_timestamp_ms ?? 0;
      const currentTimestamp = Number(
        userSnapshot.data()?.revenueCatEventTimestampMs ?? 0,
      );
      transaction.set(eventRef, {
        userId: uid,
        type: event.type,
        productId: event.product_id ?? null,
        environment: event.environment ?? null,
        receivedAt: FieldValue.serverTimestamp(),
        eventTimestamp: event.event_timestamp_ms == null
          ? null
          : Timestamp.fromMillis(event.event_timestamp_ms),
        ignoredAsStale: incomingTimestamp < currentTimestamp,
      });
      if (incomingTimestamp < currentTimestamp) return;
      transaction.set(
        userRef,
        {
          isPremium: state.isPremium,
          premiumUntil: state.premiumUntil == null
            ? null
            : Timestamp.fromDate(state.premiumUntil),
          premiumPlan: state.premiumPlan,
          premiumProductId: event.product_id ?? null,
          premiumSource: 'revenuecat',
          premiumStore: event.store?.toLowerCase() ?? null,
          premiumUpdatedAt: FieldValue.serverTimestamp(),
          revenueCatEventTimestampMs: incomingTimestamp,
        },
        {merge: true},
      );
    });

    response.status(200).send('OK');
  },
);
