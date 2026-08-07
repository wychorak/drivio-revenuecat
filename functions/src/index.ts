import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { initializeApp } from 'firebase-admin/app';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

initializeApp();

const MAX_SESSION_AGE_SECONDS = 5 * 60;

async function deleteDocumentsByOwner(
  collection: string,
  ownerField: string,
  uid: string,
): Promise<void> {
  const firestore = getFirestore();
  while (true) {
    const snapshot = await firestore
      .collection(collection)
      .where(ownerField, '==', uid)
      .limit(400)
      .get();
    if (snapshot.empty) return;

    const batch = firestore.batch();
    for (const document of snapshot.docs) batch.delete(document.ref);
    await batch.commit();
  }
}

export const deleteAccount = onCall(
  { region: 'europe-west1', enforceAppCheck: true },
  async (request) => {
    const uid = request.auth?.uid;
    const authTime = request.auth?.token.auth_time;
    if (!uid || typeof authTime !== 'number') {
      throw new HttpsError('unauthenticated', 'Authentication is required.');
    }

    const sessionAge = Math.floor(Date.now() / 1000) - authTime;
    if (sessionAge > MAX_SESSION_AGE_SECONDS) {
      throw new HttpsError(
        'failed-precondition',
        'A recent sign-in is required before account deletion.',
      );
    }

    await Promise.all([
      deleteDocumentsByOwner('comments', 'userId', uid),
      deleteDocumentsByOwner('reports', 'reporterId', uid),
      deleteDocumentsByOwner('traps', 'createdBy', uid),
    ]);

    const firestore = getFirestore();
    await firestore.recursiveDelete(firestore.collection('users').doc(uid));
    await getStorage().bucket().deleteFiles({ prefix: `traps/${uid}/` });
    await getAuth().deleteUser(uid);

    return { deleted: true };
  },
);
