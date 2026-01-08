import axios from 'axios';
import { Player, PlayerStats, BatterStats, PitcherStats } from '../types';

const MLB_API_BASE = 'https://statsapi.mlb.com/api/v1';
const CURRENT_SEASON = 2025;

interface MlbPlayerResponse {
  people: MlbPerson[];
}

interface MlbPerson {
  id: number;
  fullName: string;
  firstName: string;
  lastName: string;
  primaryPosition: {
    code: string;
    name: string;
    abbreviation: string;
  };
  currentTeam?: {
    id: number;
    name: string;
    abbreviation?: string;
  };
  primaryNumber?: string;
  batSide?: { code: string };
  pitchHand?: { code: string };
  birthDate?: string;
  height?: string;
  weight?: number;
  active: boolean;
  stats?: MlbStat[];
}

interface MlbStat {
  group: { displayName: string };
  type: { displayName: string };
  splits: MlbSplit[];
}

interface MlbSplit {
  season: string;
  stat: any;
}

const PITCHER_POSITIONS = ['P', 'SP', 'RP', 'CL'];

function mapPosition(mlbPosition: string): string {
  const positionMap: Record<string, string> = {
    'P': 'P',
    '1': 'P',
    '2': 'C',
    '3': '1B',
    '4': '2B',
    '5': '3B',
    '6': 'SS',
    '7': 'OF',
    '8': 'OF',
    '9': 'OF',
    'Y': 'DH',
    'O': 'OF',
  };
  return positionMap[mlbPosition] || mlbPosition;
}

export async function fetchAllPlayers(season = CURRENT_SEASON): Promise<Player[]> {
  try {
    const response = await axios.get<MlbPlayerResponse>(
      `${MLB_API_BASE}/sports/1/players`,
      { params: { season } }
    );

    const players: Player[] = response.data.people.map((person) => ({
      playerId: `mlb_${person.id}`,
      mlbId: person.id,
      fullName: person.fullName,
      firstName: person.firstName,
      lastName: person.lastName,
      primaryPosition: mapPosition(person.primaryPosition?.abbreviation || 'UTIL'),
      mlbTeam: person.currentTeam?.abbreviation || 'FA',
      mlbTeamId: person.currentTeam?.id || 0,
      jerseyNumber: person.primaryNumber,
      batSide: person.batSide?.code || 'R',
      pitchHand: person.pitchHand?.code || 'R',
      birthDate: person.birthDate,
      height: person.height,
      weight: person.weight,
      active: person.active,
      lastUpdated: new Date().toISOString(),
    }));

    return players;
  } catch (error) {
    console.error('Error fetching MLB players:', error);
    throw error;
  }
}

export async function fetchPlayerWithStats(mlbId: number, season = CURRENT_SEASON): Promise<Player | null> {
  try {
    const response = await axios.get<MlbPlayerResponse>(
      `${MLB_API_BASE}/people/${mlbId}`,
      {
        params: {
          hydrate: `stats(group=[hitting,pitching],type=[season],season=${season})`,
        },
      }
    );

    if (!response.data.people || response.data.people.length === 0) {
      return null;
    }

    const person = response.data.people[0];
    const position = mapPosition(person.primaryPosition?.abbreviation || 'UTIL');
    const isPitcher = PITCHER_POSITIONS.includes(position);

    let stats: PlayerStats | undefined;

    if (person.stats) {
      if (isPitcher) {
        const pitchingStats = person.stats.find((s) => s.group.displayName === 'pitching');
        if (pitchingStats?.splits?.[0]?.stat) {
          const s = pitchingStats.splits[0].stat;
          stats = {
            pitching: {
              wins: s.wins || 0,
              losses: s.losses || 0,
              era: s.era || '0.00',
              games: s.gamesPlayed || 0,
              gamesStarted: s.gamesStarted || 0,
              saves: s.saves || 0,
              inningsPitched: s.inningsPitched || '0.0',
              hits: s.hits || 0,
              runs: s.runs || 0,
              earnedRuns: s.earnedRuns || 0,
              homeRuns: s.homeRuns || 0,
              walks: s.baseOnBalls || 0,
              strikeouts: s.strikeOuts || 0,
              whip: s.whip || '0.00',
              avg: s.avg || '.000',
            },
          };
        }
      } else {
        const hittingStats = person.stats.find((s) => s.group.displayName === 'hitting');
        if (hittingStats?.splits?.[0]?.stat) {
          const s = hittingStats.splits[0].stat;
          stats = {
            batting: {
              gamesPlayed: s.gamesPlayed || 0,
              atBats: s.atBats || 0,
              runs: s.runs || 0,
              hits: s.hits || 0,
              doubles: s.doubles || 0,
              triples: s.triples || 0,
              homeRuns: s.homeRuns || 0,
              rbi: s.rbi || 0,
              stolenBases: s.stolenBases || 0,
              caughtStealing: s.caughtStealing || 0,
              walks: s.baseOnBalls || 0,
              strikeouts: s.strikeOuts || 0,
              avg: s.avg || '.000',
              obp: s.obp || '.000',
              slg: s.slg || '.000',
              ops: s.ops || '.000',
            },
          };
        }
      }
    }

    const player: Player = {
      playerId: `mlb_${person.id}`,
      mlbId: person.id,
      fullName: person.fullName,
      firstName: person.firstName,
      lastName: person.lastName,
      primaryPosition: position,
      mlbTeam: person.currentTeam?.abbreviation || 'FA',
      mlbTeamId: person.currentTeam?.id || 0,
      jerseyNumber: person.primaryNumber,
      batSide: person.batSide?.code || 'R',
      pitchHand: person.pitchHand?.code || 'R',
      birthDate: person.birthDate,
      height: person.height,
      weight: person.weight,
      active: person.active,
      stats,
      lastUpdated: new Date().toISOString(),
    };

    return player;
  } catch (error) {
    console.error(`Error fetching player ${mlbId}:`, error);
    return null;
  }
}

export async function fetchTeamRoster(teamId: number, season = CURRENT_SEASON): Promise<number[]> {
  try {
    const response = await axios.get(
      `${MLB_API_BASE}/teams/${teamId}/roster`,
      { params: { rosterType: 'active', season } }
    );

    return response.data.roster?.map((p: any) => p.person.id) || [];
  } catch (error) {
    console.error(`Error fetching roster for team ${teamId}:`, error);
    return [];
  }
}

export async function fetchAllTeams(): Promise<{ id: number; name: string; abbreviation: string }[]> {
  try {
    const response = await axios.get(`${MLB_API_BASE}/teams`, {
      params: { sportId: 1, season: CURRENT_SEASON },
    });

    return response.data.teams.map((team: any) => ({
      id: team.id,
      name: team.name,
      abbreviation: team.abbreviation,
    }));
  } catch (error) {
    console.error('Error fetching teams:', error);
    return [];
  }
}
