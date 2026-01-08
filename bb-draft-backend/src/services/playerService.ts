import * as PlayerModel from '../models/Player';
import * as MlbApi from './mlbApiService';
import { Player, PaginatedResponse } from '../types';

const PITCHER_POSITIONS = ['SP', 'RP', 'P', 'CL'];

export async function syncPlayersFromMlb(): Promise<{ added: number; updated: number }> {
  const mlbPlayers = await MlbApi.fetchAllPlayers();
  let added = 0;
  let updated = 0;

  for (const player of mlbPlayers) {
    const existing = await PlayerModel.getPlayer(player.playerId);
    if (existing) {
      // Update existing player
      await PlayerModel.putPlayer({
        ...existing,
        ...player,
        stats: existing.stats, // Preserve existing stats
        lastUpdated: new Date().toISOString(),
      });
      updated++;
    } else {
      // Add new player
      await PlayerModel.putPlayer(player);
      added++;
    }
  }

  return { added, updated };
}

export async function getPlayer(playerId: string): Promise<Player | null> {
  let player = await PlayerModel.getPlayer(playerId);

  // If player exists but stats are stale (> 24 hours), refresh
  if (player) {
    const lastUpdated = new Date(player.lastUpdated).getTime();
    const now = Date.now();
    const oneDayMs = 24 * 60 * 60 * 1000;

    if (now - lastUpdated > oneDayMs) {
      const refreshed = await MlbApi.fetchPlayerWithStats(player.mlbId);
      if (refreshed) {
        await PlayerModel.putPlayer(refreshed);
        return refreshed;
      }
    }
  }

  return player;
}

export async function getPlayers(options: {
  position?: string;
  type?: 'batters' | 'pitchers';
  search?: string;
  limit?: number;
  lastKey?: string;
}): Promise<PaginatedResponse<Player>> {
  const { position, type, search, limit = 50, lastKey } = options;

  if (search) {
    const players = await PlayerModel.searchPlayers(search, limit);
    return { items: players, count: players.length };
  }

  if (position) {
    return PlayerModel.getPlayers({ position, limit, lastKey });
  }

  // Get all players and filter by type
  const result = await PlayerModel.getPlayers({ limit: 500, lastKey });

  if (type === 'batters') {
    const batters = result.items.filter((p) => !PITCHER_POSITIONS.includes(p.primaryPosition));
    return {
      items: batters.slice(0, limit),
      count: batters.length,
      lastKey: result.lastKey,
    };
  }

  if (type === 'pitchers') {
    const pitchers = result.items.filter((p) => PITCHER_POSITIONS.includes(p.primaryPosition));
    return {
      items: pitchers.slice(0, limit),
      count: pitchers.length,
      lastKey: result.lastKey,
    };
  }

  return result;
}

export async function getBatters(limit = 100): Promise<Player[]> {
  const result = await getPlayers({ type: 'batters', limit });
  return result.items;
}

export async function getPitchers(limit = 100): Promise<Player[]> {
  const result = await getPlayers({ type: 'pitchers', limit });
  return result.items;
}

export async function refreshPlayerStats(playerId: string): Promise<Player | null> {
  const player = await PlayerModel.getPlayer(playerId);
  if (!player) return null;

  const refreshed = await MlbApi.fetchPlayerWithStats(player.mlbId);
  if (refreshed) {
    await PlayerModel.putPlayer(refreshed);
    return refreshed;
  }

  return player;
}

// Eligibility Management
export interface EligibilityStatus {
  playerId: string;
  leagueId: string;
  eligibility: 'eligible' | 'onTeam' | 'notEligible';
  note?: string;
  ownerTeamId?: string;
  updatedAt: string;
  updatedBy?: string;
}

export async function getPlayerEligibility(
  playerId: string,
  leagueId: string
): Promise<EligibilityStatus> {
  const eligibility = await PlayerModel.getPlayerEligibility(playerId, leagueId);

  if (!eligibility) {
    return {
      playerId,
      leagueId,
      eligibility: 'eligible',
      updatedAt: new Date().toISOString(),
    };
  }

  return eligibility;
}

export async function setPlayerEligibility(
  playerId: string,
  leagueId: string,
  data: {
    eligibility: 'eligible' | 'onTeam' | 'notEligible';
    note?: string;
    ownerTeamId?: string;
  }
): Promise<EligibilityStatus> {
  const eligibilityRecord: EligibilityStatus = {
    playerId,
    leagueId,
    eligibility: data.eligibility,
    note: data.note,
    ownerTeamId: data.ownerTeamId,
    updatedAt: new Date().toISOString(),
  };

  await PlayerModel.setPlayerEligibility(eligibilityRecord);
  return eligibilityRecord;
}

export async function bulkSetEligibility(
  leagueId: string,
  players: Array<{
    playerId: string;
    eligibility: 'eligible' | 'onTeam' | 'notEligible';
    note?: string;
    ownerTeamId?: string;
  }>
): Promise<EligibilityStatus[]> {
  const results: EligibilityStatus[] = [];

  for (const player of players) {
    const result = await setPlayerEligibility(player.playerId, leagueId, {
      eligibility: player.eligibility,
      note: player.note,
      ownerTeamId: player.ownerTeamId,
    });
    results.push(result);
  }

  return results;
}

export async function getLeagueEligibilities(
  leagueId: string
): Promise<Record<string, EligibilityStatus>> {
  return PlayerModel.getLeagueEligibilities(leagueId);
}

// Get player with all advanced stats (Statcast, WAR, etc.)
export async function getPlayerWithAdvancedStats(playerId: string): Promise<Player | null> {
  const player = await PlayerModel.getPlayer(playerId);
  if (!player) return null;

  // In a real implementation, this would fetch from Baseball Savant, FanGraphs, etc.
  // For now, return the player with whatever stats we have
  return player;
}
