import {createVerify} from 'node:crypto';

const KEYS_URL = 'https://www.gstatic.com/admob/reward/verifier-keys.json';
const KEY_CACHE_MS = 60 * 60 * 1000;
const TEST_KEYS_URL =
  'https://www.gstatic.com/admob/reward/verifier-keys-test.json';
let cachedKeys: Map<string, string> | null = null;
let cachedAt = 0;
let cachedTestKeys: Map<string, string> | null = null;
let cachedTestAt = 0;

export interface VerifiedReward {
  uid: string | null;
  customData: string | null;
  transactionId: string;
  timestamp: Date;
}

/**
 * Returns the signed query parameters when [rawUrl] carries a valid AdMob
 * signature, or null for unsigned or tampered callbacks.
 */
export function verifiedParams(
  rawUrl: string,
  keyPem: string,
): URLSearchParams | null {
  const query = rawUrl.split('?', 2)[1];
  if (!query || query.length > 8192) return null;
  // AdMob signs the exact query bytes before the final signature/key_id pair.
  const match = /^(.*)&signature=([^&]+)&key_id=([0-9]+)$/.exec(query);
  if (!match) return null;
  const [, signedPayload, encodedSignature] = match;
  let signature: Buffer;
  try {
    // The signature may arrive percent-encoded (e.g. "=" padding as %3D).
    // Node's base64 decoder silently skips "%", which would corrupt it.
    signature = Buffer.from(decodeURIComponent(encodedSignature), 'base64url');
  } catch (_) {
    return null;
  }
  const verified = signedPayloadVariants(signedPayload).some((payload) => {
    try {
      const verifier = createVerify('SHA256');
      verifier.update(payload, 'utf8');
      verifier.end();
      return verifier.verify(keyPem, signature);
    } catch (_) {
      return false;
    }
  });
  return verified ? new URLSearchParams(signedPayload) : null;
}

/**
 * Candidate strings for the bytes AdMob signed. AdMob signs the query after
 * percent-decoding (a reward item "Odblokowanie pułapki" is signed as is,
 * but arrives as "Odblokowanie%20pu%C5%82apki"), so the decoded form is the
 * one that matches; the raw forms cover ASCII-only callbacks. Every variant
 * still needs a valid Google signature, so accepting them adds no forgery
 * risk.
 */
function signedPayloadVariants(raw: string): string[] {
  const variants = [raw, raw.replace(/%20/g, '+')];
  try {
    variants.push(decodeURIComponent(raw.replace(/\+/g, '%20')));
  } catch (_) {
    // Malformed escapes: only the raw forms apply.
  }
  return [...new Set(variants)];
}

/**
 * Returns the reward only for a signed callback from [expectedUnitId] with
 * well-formed ids. AdMob's "Verify URL" check is signed but uses sample
 * values, so it verifies without producing a reward.
 */
export function verifySignedReward(
  rawUrl: string,
  expectedUnitId: string,
  keyPem: string,
): VerifiedReward | null {
  const params = verifiedParams(rawUrl, keyPem);
  if (!params) return null;
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
  const keys = await fetchKeys(KEYS_URL);
  if (keys.size === 0) throw new Error('AdMob key list is empty');
  cachedKeys = keys;
  cachedAt = Date.now();
  return keys.get(keyId) ?? null;
}

/**
 * Returns the PEM for a key from AdMob's test key list. The console's
 * "Verify URL" check can be signed with these keys; a callback signed with
 * one must be acknowledged but never grant a reward.
 */
export async function getAdMobTestKey(keyId: string): Promise<string | null> {
  if (cachedTestKeys?.has(keyId) &&
      Date.now() - cachedTestAt < KEY_CACHE_MS) {
    return cachedTestKeys.get(keyId) ?? null;
  }
  cachedTestKeys = await fetchKeys(TEST_KEYS_URL);
  cachedTestAt = Date.now();
  return cachedTestKeys.get(keyId) ?? null;
}

async function fetchKeys(url: string): Promise<Map<string, string>> {
  const response = await fetch(url, {signal: AbortSignal.timeout(5000)});
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
  return keys;
}
