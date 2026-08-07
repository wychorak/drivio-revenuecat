import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-drivio-rules';
let testEnv;

const auth = (
  uid,
  email = uid + '@example.com',
  emailVerified = true,
  claims = {},
) =>
  testEnv.authenticatedContext(uid, {
    email,
    email_verified: emailVerified,
    ...claims,
  }).firestore();

const adminDb = () =>
  auth('release-admin', 'admin@example.com', true, { admin: true });

const baseUser = (uid, email = uid + '@example.com') => ({
  uid,
  email,
  displayName: uid,
  isPremium: false,
  premiumUntil: null,
  savedTraps: [],
  savedSchools: [],
  blockedUsers: [],
  dailyTrapViews: {},
  photoUrl: null,
  createdAt: Timestamp.fromMillis(1_700_000_000_000),
});

async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

before(async () => {
  const rules = await readFile(new URL('../firestore.rules', import.meta.url), 'utf8');
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

describe('users', () => {
  test('user cannot enable Premium on their own document', async () => {
    await seed('users/alice', baseUser('alice'));

    await assertFails(
      updateDoc(doc(auth('alice'), 'users/alice'), { isPremium: true }),
    );
  });

  test('user cannot modify another user document', async () => {
    await seed('users/bob', baseUser('bob'));

    await assertFails(
      updateDoc(doc(auth('alice'), 'users/bob'), { displayName: 'Attacker' }),
    );
  });

  test('email and moderation fields remain immutable and roles cannot be added', async () => {
    await seed('users/alice', baseUser('alice'));

    await assertFails(
      updateDoc(doc(auth('alice'), 'users/alice'), {
        email: 'changed@example.com',
      }),
    );
    await assertFails(
      updateDoc(doc(auth('alice'), 'users/alice'), { isBlocked: true }),
    );
    await assertFails(
      updateDoc(doc(auth('alice'), 'users/alice'), { role: 'admin' }),
    );
  });

  test('blocked user cannot delete and recreate their profile', async () => {
    await seed('users/alice', {
      ...baseUser('alice'),
      isBlocked: true,
    });

    await assertFails(
      deleteDoc(doc(auth('alice'), 'users/alice')),
    );
  });

  test('Apple/Google user document may omit email and displayName', async () => {
    const providerDb = testEnv.authenticatedContext('provider-user', {
      email_verified: true,
    }).firestore();

    await assertSucceeds(
      setDoc(doc(providerDb, 'users/provider-user'), {
        uid: 'provider-user',
        isPremium: false,
        premiumUntil: null,
        savedTraps: [],
        savedSchools: [],
        blockedUsers: [],
        dailyTrapViews: {},
        createdAt: serverTimestamp(),
      }),
    );
  });

  test('owner may update only mutable profile data', async () => {
    await seed('users/alice', baseUser('alice'));

    await assertSucceeds(
      updateDoc(doc(auth('alice'), 'users/alice'), {
        displayName: 'Alice Driver',
        savedTraps: ['trap-1'],
      }),
    );
  });
});

describe('comments', () => {
  test('user cannot impersonate another author', async () => {
    await assertFails(
      setDoc(doc(auth('alice'), 'comments/spoofed'), {
        itemId: 'trap-1',
        itemType: 'trap',
        userId: 'bob',
        userDisplayName: 'Bob',
        text: 'To nie jest komentarz Boba',
        createdAt: serverTimestamp(),
        reported: false,
      }),
    );
  });

  test('owner may edit text but cannot change author data or creation time', async () => {
    await assertSucceeds(
      setDoc(doc(auth('alice'), 'comments/comment-1'), {
        itemId: 'trap-1',
        itemType: 'trap',
        userId: 'alice',
        userDisplayName: 'Alice',
        text: 'Pierwsza wersja',
        timestamp: serverTimestamp(),
        reported: false,
      }),
    );

    await assertSucceeds(
      updateDoc(doc(auth('alice'), 'comments/comment-1'), {
        text: 'Poprawiona wersja',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(auth('alice'), 'comments/comment-1'), {
        userDisplayName: 'Admin',
      }),
    );
    await assertFails(
      updateDoc(doc(auth('bob'), 'comments/comment-1'), {
        text: 'Przejęty komentarz',
      }),
    );
  });

  test('unknown fields and oversized text are rejected', async () => {
    await assertFails(
      setDoc(doc(auth('alice'), 'comments/oversized'), {
        itemId: 'trap-1',
        itemType: 'trap',
        userId: 'alice',
        text: 'x'.repeat(1001),
        timestamp: serverTimestamp(),
        reported: false,
        arbitrary: true,
      }),
    );
  });
});

describe('daily limits', () => {
  test('top-level dailyLimits cannot be reset or given arbitrary fields', async () => {
    await seed('dailyLimits/alice', {
      userId: 'alice',
      count: 5,
      day: '2026-07-30',
      updatedAt: Timestamp.now(),
    });

    await assertFails(
      updateDoc(doc(auth('alice'), 'dailyLimits/alice'), {
        count: 0,
        arbitrary: 'field',
      }),
    );
  });

  test('legacy usage counter permits +1 transaction but denies reset', async () => {
    const periodStartedAt = Timestamp.now();
    await seed('users/alice/usage/trapViews', {
      views: 2,
      periodStartedAt,
      updatedAt: periodStartedAt,
    });

    const aliceDb = auth('alice');
    const usageRef = doc(aliceDb, 'users/alice/usage/trapViews');

    await assertSucceeds(
      runTransaction(aliceDb, async (transaction) => {
        const snapshot = await transaction.get(usageRef);
        transaction.update(usageRef, {
          views: snapshot.data().views + 1,
          updatedAt: serverTimestamp(),
        });
      }),
    );

    await assertFails(
      updateDoc(usageRef, {
        views: 0,
        updatedAt: serverTimestamp(),
      }),
    );
  });
});

describe('reports and admin access', () => {
  test('user creates only their own report; normal users cannot read reports', async () => {
    const aliceDb = auth('alice');
    const reportRef = doc(aliceDb, 'reports/report-1');

    await assertSucceeds(
      setDoc(reportRef, {
        itemId: 'comment-1',
        itemType: 'comment',
        reason: 'Obraźliwa treść',
        reporterId: 'alice',
        timestamp: serverTimestamp(),
      }),
    );
    await assertFails(getDoc(reportRef));
    await assertSucceeds(
      getDoc(doc(adminDb(), 'reports/report-1')),
    );
  });

  test('reporter impersonation and arbitrary fields are rejected', async () => {
    await assertFails(
      setDoc(doc(auth('alice'), 'reports/spoofed'), {
        itemId: 'trap-1',
        itemType: 'trap',
        reason: 'Nieprawidłowa lokalizacja',
        reporterId: 'bob',
        createdAt: serverTimestamp(),
        internalNote: 'client-controlled',
      }),
    );
  });

  test('admin access requires a backend-managed custom claim', async () => {
    await seed('reports/report-1', {
      itemId: 'trap-1',
      itemType: 'trap',
      reason: 'Test',
      reporterId: 'alice',
      createdAt: Timestamp.now(),
    });

    await assertFails(
      getDoc(doc(auth('email-only', 'admin@example.com', true), 'reports/report-1')),
    );
    await assertSucceeds(getDoc(doc(adminDb(), 'reports/report-1')));
  });
});

describe('public catalog and privileged writes', () => {
  test('traps and schools are publicly readable', async () => {
    await seed('traps/trap-1', { title: 'Public trap' });
    await seed('schools/school-1', { name: 'Public school' });
    const publicDb = testEnv.unauthenticatedContext().firestore();

    await assertSucceeds(getDoc(doc(publicDb, 'traps/trap-1')));
    await assertSucceeds(getDoc(doc(publicDb, 'schools/school-1')));
  });

  test('only a custom-claim admin may create traps', async () => {
    const trap = {
      lat: 52.2297,
      lng: 21.0122,
      title: 'Łuk z ograniczoną widocznością',
      description: 'Opis pułapki wystarczająco długi do walidacji.',
      difficulty: 3,
      photoUrl: null,
      videoUrl: null,
      ruleDescription: 'Zachowaj szczególną ostrożność.',
      createdBy: 'release-admin',
      city: 'Warszawa',
      createdAt: serverTimestamp(),
      savesCount: 0,
    };

    await assertFails(
      setDoc(doc(auth('alice'), 'traps/user-write'), {
        ...trap,
        createdBy: 'alice',
      }),
    );
    await assertSucceeds(
      setDoc(doc(adminDb(), 'traps/admin-write'), trap),
    );
  });
});

describe('iapTransactions', () => {
  test('clients cannot forge purchase transactions', async () => {
    await assertFails(
      setDoc(doc(auth('alice'), 'iapTransactions/fake-purchase'), {
        userId: 'alice',
        productId: 'driviolifetime',
        status: 'active',
      }),
    );
  });
});
