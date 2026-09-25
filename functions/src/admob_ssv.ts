import {createVerify} from 'node:crypto';

const KEYS_URL = 'https://www.gstatic.com/admob/reward/verifier-keys.json';
const KEY_CACHE_MS = 60 * 60 * 1000;
let cachedKeys: Map<string, string> | null = null;
let cachedAt = 0;

export interface VerifiedReward {
  uid: string | null;
  customData: string | null;
  transactionId: string;
  timestamp: Date;
}

export function verifySignedReward(
  rawUrl: string,
  expectedUnitId: string,
  keyPem: string,
): VerifiedReward | null {
  const query = rawUrl.split('?', 2)[1];
  if (!query || query.length > 8192) return null;
  // AdMob signs the exact query bytes before the final signature/key_id pair.
  const match = /^(.*)&signature=([^&]+)&key_id=([0-9]+)$/.exec(query);
  if (!match) return null;
  const [, signedPayload, encodedSignature] = match;
  const params = new URLSearchParams(signedPayload);
  const expectedNumericId = expectedUnitId.split('/')[1];
  if (!expectedNumericId || params.get('ad_unit') !== expectedNumericId) {
    return null;
  }
  const uid = params.get('user_id');
  const transactionId = params.get('transaction_id');
  const timestampMs = Number(params.get('timestamp'));
  if ((uid && !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) ||
      !transactionId || !/^[A-Fa-f0-9]{16,128}$/.test(transactionId) ||
      !Number.isSafeInteger(timestampMs)) {
    return null;
  }
  try {
    const verifier = createVerify('SHA256');
    verifier.update(signedPayload, 'utf8');
    verifier.end();
    const signature = Buffer.from(encodedSignature, 'base64url');
    if (!verifier.verify(keyPem, signature)) return null;
  } catch (_) {
    return null;
  }
  return {
    uid,
    customData: params.get('custom_data'),
    transactionId,
    timestamp: new Date(timestampMs),
  };
}

export function ssvKeyId(rawUrl: string): string | null {
  const query = rawUrl.split('?', 2)[1];
  const match = query && /&signature=[^&]+&key_id=([0-9]+)$/.exec(query);
  return match?.[1] ?? null;
}

export async function getAdMobKey(keyId: string): Promise<string | null> {
  if (cachedKeys?.has(keyId) && Date.now() - cachedAt < KEY_CACHE_MS) {
    return cachedKeys.get(keyId) ?? null;
  }
  const response = await fetch(KEYS_URL, {
    signal: AbortSignal.timeout(5000),
  });
  if (!response.ok) throw new Error(`AdMob keys HTTP ${response.status}`);
  const body = await response.json() as {
    keys?: Array<{keyId?: number; pem?: string}>;
  };
  const keys = new Map<string, string>();
  for (const key of body.keys ?? []) {
    if (Number.isSafeInteger(key.keyId) && typeof key.pem === 'string') {
      keys.set(String(key.keyId), key.pem);
    }
  }
  if (keys.size === 0) throw new Error('AdMob key list is empty');
  cachedKeys = keys;
  cachedAt = Date.now();
  return keys.get(keyId) ?? null;
}
