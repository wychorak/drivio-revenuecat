export const PREMIUM_ENTITLEMENT_ID = 'drivio pro relase';

const inactiveEventTypes = new Set(['EXPIRATION', 'REFUND']);

export interface RevenueCatEvent {
  id?: string;
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  aliases?: string[];
  entitlement_ids?: string[] | null;
  product_id?: string | null;
  expiration_at_ms?: number | null;
  grace_period_expiration_at_ms?: number | null;
  period_type?: string | null;
  environment?: string | null;
  store?: string | null;
  event_timestamp_ms?: number;
}

export interface PremiumState {
  isPremium: boolean;
  premiumUntil: Date | null;
  premiumPlan: string | null;
}

export function isValidRevenueCatAuthorization(
  authorizationHeader: string | undefined,
  secret: string,
): boolean {
  const normalizedSecret = secret.trim();
  if (authorizationHeader == null || normalizedSecret.length === 0) return false;
  return authorizationHeader === `Bearer ${normalizedSecret}`;
}

export function firebaseUidCandidates(event: RevenueCatEvent): string[] {
  const values = [
    event.app_user_id,
    event.original_app_user_id,
    ...(event.aliases ?? []),
  ];
  return [...new Set(values)]
    .filter((value): value is string => typeof value === 'string')
    .map((value) => value.trim())
    .filter(
      (value) =>
        value.length > 0 &&
        value.length <= 128 &&
        !value.startsWith('$RCAnonymousID:'),
    );
}

export function planForProduct(productId?: string | null): string | null {
  switch (productId) {
    case 'drivioweek':
      return 'weekly';
    case 'driviomonth':
      return 'monthly';
    case 'driviolifetime':
      return 'lifetime';
    default:
      return null;
  }
}

export function premiumStateForEvent(
  event: RevenueCatEvent,
  nowMs = Date.now(),
): PremiumState | null {
  const entitlements = event.entitlement_ids ?? [];
  const plan = planForProduct(event.product_id);
  if (!entitlements.includes(PREMIUM_ENTITLEMENT_ID) && plan == null) {
    return null;
  }

  const type = event.type?.toUpperCase() ?? '';
  const endMs =
    event.grace_period_expiration_at_ms ?? event.expiration_at_ms ?? null;
  const isLifetime = plan === 'lifetime' && endMs == null;
  const isPremium =
    !inactiveEventTypes.has(type) && (isLifetime || (endMs ?? 0) > nowMs);

  return {
    isPremium,
    premiumUntil: endMs == null ? null : new Date(endMs),
    premiumPlan: plan,
  };
}
