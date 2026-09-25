import {Timestamp} from 'firebase-admin/firestore';

export const FREE_DAILY_TRAPS = 2;
export const REWARDED_DAILY_TRAPS = 1;

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
  rewardGranted: boolean;
  canWatchAd: boolean;
}

export function trapAllowance(
  data: FirebaseFirestore.DocumentData | undefined,
  dayKey: string,
): TrapAllowance {
  const active = data?.dayKey === dayKey;
  const views = active && Number.isInteger(data?.views)
    ? Math.max(0, Math.min(3, data!.views))
    : 0;
  const rewardGranted = active && data?.rewardGranted === true;
  return {
    dayKey,
    views,
    freeRemaining: Math.max(0, FREE_DAILY_TRAPS - views),
    totalRemaining: Math.max(
      0,
      FREE_DAILY_TRAPS + (rewardGranted ? REWARDED_DAILY_TRAPS : 0) - views,
    ),
    rewardGranted,
    canWatchAd: !rewardGranted && views >= FREE_DAILY_TRAPS,
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
