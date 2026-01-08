import { DraftFormat } from '../types';

/**
 * Calculate the team that picks at a given overall pick number
 */
export function getTeamForPick(
  overallPick: number,
  teamCount: number,
  draftOrder: string[],
  format: DraftFormat
): { teamId: string; round: number; pickInRound: number } {
  const round = Math.ceil(overallPick / teamCount);
  const pickInRound = ((overallPick - 1) % teamCount) + 1;

  let teamIndex: number;
  if (format === 'serpentine' && round % 2 === 0) {
    // Reverse order on even rounds
    teamIndex = teamCount - pickInRound;
  } else {
    teamIndex = pickInRound - 1;
  }

  return {
    teamId: draftOrder[teamIndex],
    round,
    pickInRound,
  };
}

/**
 * Generate full draft order for all picks
 */
export function generateDraftSchedule(
  teamCount: number,
  totalRounds: number,
  draftOrder: string[],
  format: DraftFormat
): Array<{ overallPick: number; round: number; pickInRound: number; teamId: string }> {
  const schedule: Array<{ overallPick: number; round: number; pickInRound: number; teamId: string }> = [];
  const totalPicks = teamCount * totalRounds;

  for (let pick = 1; pick <= totalPicks; pick++) {
    const { teamId, round, pickInRound } = getTeamForPick(pick, teamCount, draftOrder, format);
    schedule.push({ overallPick: pick, round, pickInRound, teamId });
  }

  return schedule;
}

/**
 * Shuffle array using Fisher-Yates algorithm
 */
export function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

/**
 * Generate random draft order
 */
export function generateRandomDraftOrder(teamIds: string[]): string[] {
  return shuffleArray(teamIds);
}

/**
 * Generate weighted lottery order
 * Lower index = better odds (e.g., worst team at index 0 has best odds)
 */
export function generateWeightedLotteryOrder(
  teamIds: string[],
  weights?: number[]
): string[] {
  const defaultWeights = teamIds.map((_, i) => teamIds.length - i);
  const useWeights = weights || defaultWeights;

  const totalWeight = useWeights.reduce((sum, w) => sum + w, 0);
  const result: string[] = [];
  const remaining = [...teamIds];
  const remainingWeights = [...useWeights];

  while (remaining.length > 0) {
    const currentTotal = remainingWeights.reduce((sum, w) => sum + w, 0);
    let random = Math.random() * currentTotal;

    for (let i = 0; i < remaining.length; i++) {
      random -= remainingWeights[i];
      if (random <= 0) {
        result.push(remaining[i]);
        remaining.splice(i, 1);
        remainingWeights.splice(i, 1);
        break;
      }
    }
  }

  return result;
}
