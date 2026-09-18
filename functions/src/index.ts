import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {FieldValue, Timestamp, getFirestore} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {defineSecret} from 'firebase-functions/params';
import {HttpsError, onCall, onRequest} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions';

import {
  firebaseUidCandidates,
  premiumStateForEvent,
  RevenueCatEvent,
} from './revenuecat';

initializeApp();

const REGION = 'europe-west1';
const ADMIN_EMAILS = new Set([
  'joa.rycyk@gmail.com',
  'estlin20@gmail.com',
]);
const revenueCatWebhookAuth = defineSecret('REVENUECAT_WEBHOOK_AUTH');

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

export const deleteAccount = onCall({region: REGION}, async (request) => {
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
});

export const refreshAdminClaim = onCall({region: REGION}, async (request) => {
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
  return {success: true, refreshToken: true};
});

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
    if (request.get('authorization') !== revenueCatWebhookAuth.value()) {
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
