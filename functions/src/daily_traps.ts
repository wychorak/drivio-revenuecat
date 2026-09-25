import {Timestamp} from 'firebase-admin/firestore';

/** One trap a day without ads, two more unlocked by rewarded ads. */
export const FREE_DAILY_TRAPS = 1;
export const REWARDED_DAILY_TRAPS = 2;
const MAX_DAILY_TRAPS = FREE_DAILY_TRAPS + REWARDED_DAILY_TRAPS;

const warsawDate = new Intl.DateTimeFormat('en-GB', {
  timeZone: 'Europe/Warsaw',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

export function warsawDayKey(date: Date): string {
  const parts = Object.fromEntries(
    warsawDate.formatToParts(date).map((part) => [part.type, part.value]),
  );
  return `${parts.year}-${parts.month}-${parts.day}`;
}

export interface TrapAllowance {
  dayKey: string;
  views: number;
  freeRemaining: number;
  totalRemaining: number;
  /** True once any rewarded view was granted today (kept for older apps). */
  rewardGranted: boolean;
  rewardsGranted: number;
  rewardTransactionIds: string[];
  canWatchAd: boolean;
}

function rewardCount(data: FirebaseFirestore.DocumentData): number {
  if (Number.isInteger(data.rewardsGranted)) {
    return Math.max(0, Math.min(REWARDED_DAILY_TRAPS, data.rewardsGranted));
  }
  // Documents written before multiple rewards stored a single boolean.
  return data.rewardGranted === true ? 1 : 0;
}

export function trapAllowance(
  data: FirebaseFirestore.DocumentData | undefined,
  dayKey: string,
): TrapAllowance {
  const active = data?.dayKey === dayKey;
  const views = active && Number.isInteger(data?.views)
    ? Math.max(0, Math.min(MAX_DAILY_TRAPS, data!.views))
    : 0;
  const rewardsGranted = active ? rewardCount(data!) : 0;
  const rewardTransactionIds = active && Array.isArray(data?.rewardTransactionIds)
    ? data!.rewardTransactionIds
      .filter((id: unknown): id is string => typeof id === 'string')
      .slice(0, REWARDED_DAILY_TRAPS)
    : [];
  const totalRemaining = Math.max(0, FREE_DAILY_TRAPS + rewardsGranted - views);
  return {
    dayKey,
    views,
    freeRemaining: Math.max(0, FREE_DAILY_TRAPS - views),
    totalRemaining,
    rewardGranted: rewardsGranted > 0,
    rewardsGranted,
    rewardTransactionIds,
    canWatchAd: totalRemaining === 0 && rewardsGranted < REWARDED_DAILY_TRAPS,
  };
}

/** Fields persisted for [allowance]; `set` replaces the whole usage doc. */
export function usageFields(allowance: TrapAllowance) {
  return {
    dayKey: allowance.dayKey,
    views: allowance.views,
    rewardGranted: allowance.rewardsGranted > 0,
    rewardsGranted: allowance.rewardsGranted,
    rewardTransactionIds: allowance.rewardTransactionIds,
  };
}

export function hasBackendPremium(
  data: FirebaseFirestore.DocumentData | undefined,
  now: Date,
): boolean {
  if (data?.isPremium !== true) return false;
  const until = data.premiumUntil;
  return until == null || (until instanceof Timestamp && until.toMillis() > now.getTime());
}
