import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { authMiddleware, AuthRequest } from '../middleware/auth';
import { docClient, TableNames } from '../config/database';
import { PutCommand, GetCommand, QueryCommand, ScanCommand, UpdateCommand, DeleteCommand } from '@aws-sdk/lib-dynamodb';
import {
  ImportedSeason,
  PlayerSeasonStats,
  PlayerCareerStats,
  Leaderboard,
  LeaderboardEntry,
  PlayerComparison,
  TeamHistoricalStats,
  TeamLeaderboard,
  EncyclopediaSummary,
  BATTING_STAT_CATEGORIES,
  PITCHING_STAT_CATEGORIES,
} from '../types';

const router = Router();

// ============================================
// Encyclopedia Summary / Dashboard
// ============================================

// GET /encyclopedia/:leagueId/summary - Get encyclopedia dashboard summary
router.get('/:leagueId/summary', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId } = req.params;

    // Get imported seasons
    const seasonsResult = await docClient.send(new QueryCommand({
      TableName: TableNames.ENCYCLOPEDIA_SEASONS,
      KeyConditionExpression: 'leagueId = :leagueId',
      ExpressionAttributeValues: { ':leagueId': leagueId },
    }));

    const importedSeasons = (seasonsResult.Items || []) as ImportedSeason[];
    const seasonYears = importedSeasons.map(s => s.year).sort((a, b) => b - a);

    // Get player count
    const playerCountResult = await docClient.send(new QueryCommand({
      TableName: TableNames.ENCYCLOPEDIA_PLAYER_STATS,
      IndexName: 'LeagueIndex',
      KeyConditionExpression: 'leagueId = :leagueId',
      ExpressionAttributeValues: { ':leagueId': leagueId },
      Select: 'COUNT',
    }));

    // Get team count
    const teamCountResult = await docClient.send(new QueryCommand({
      TableName: TableNames.ENCYCLOPEDIA_TEAM_STATS,
      KeyConditionExpression: 'leagueId = :leagueId',
      ExpressionAttributeValues: { ':leagueId': leagueId },
      Select: 'COUNT',
    }));

    // Get top batting leaders (AVG, HR, RBI - top 3 each)
    const currentYear = seasonYears[0] || new Date().getFullYear();

    const topBattingLeaders = {
      avg: await getTopLeaders(leagueId, 'AVG', 'batter', currentYear, 3),
      hr: await getTopLeaders(leagueId, 'HR', 'batter', currentYear, 3),
      rbi: await getTopLeaders(leagueId, 'RBI', 'batter', currentYear, 3),
    };

    const topPitchingLeaders = {
      era: await getTopLeaders(leagueId, 'ERA', 'pitcher', currentYear, 3),
      wins: await getTopLeaders(leagueId, 'W', 'pitcher', currentYear, 3),
      so: await getTopLeaders(leagueId, 'SO', 'pitcher', currentYear, 3),
    };

    // Get team standings
    const teamStandings = await getTeamLeaderboard(leagueId, 'W', 5);

    const summary: EncyclopediaSummary = {
      leagueId,
      totalSeasons: importedSeasons.length,
      totalPlayers: playerCountResult.Count || 0,
      totalTeams: teamCountResult.Count || 0,
      currentSeasonYear: currentYear,
      importedSeasons: seasonYears,
      topBattingLeaders,
      topPitchingLeaders,
      teamStandings,
      lastUpdated: new Date().toISOString(),
    };

    res.json(summary);
  } catch (error) {
    console.error('Error fetching encyclopedia summary:', error);
    res.status(500).json({ error: 'Failed to fetch encyclopedia summary' });
  }
});

// ============================================
// Season Import Management
// ============================================

// GET /encyclopedia/:leagueId/seasons - Get all imported seasons
router.get('/:leagueId/seasons', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId } = req.params;

    const result = await docClient.send(new QueryCommand({
      TableName: TableNames.ENCYCLOPEDIA_SEASONS,
      KeyConditionExpression: 'leagueId = :leagueId',
      ExpressionAttributeValues: { ':leagueId': leagueId },
    }));

    res.json({ seasons: result.Items || [] });
  } catch (error) {
    console.error('Error fetching seasons:', error);
    res.status(500).json({ error: 'Failed to fetch seasons' });
  }
});

// POST /encyclopedia/:leagueId/seasons - Import a new season
router.post('/:leagueId/seasons', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId } = req.params;
    const { year, dataSource, playerStats, teamStats } = req.body;

    const seasonId = `season_${uuidv4().slice(0, 8)}`;
    const now = new Date().toISOString();

    const season: ImportedSeason = {
      seasonId,
      leagueId,
      year,
      importDate: now,
      dataSource: dataSource || 'manual',
      status: 'pending',
      metadata: {
        playerCount: playerStats?.length || 0,
        teamCount: teamStats?.length || 0,
        gamesPlayed: 162,
        weeksPlayed: 23,
      },
      importedBy: req.user!.uid,
    };

    // Save season record
    await docClient.send(new PutCommand({
      TableName: TableNames.ENCYCLOPEDIA_SEASONS,
      Item: season,
    }));

    // Import player statistics if provided
    if (playerStats && Array.isArray(playerStats)) {
      for (const stat of playerStats) {
        await docClient.send(new PutCommand({
          TableName: TableNames.ENCYCLOPEDIA_PLAYER_STATS,
          Item: {
            ...stat,
            leagueId,
            seasonYear: year,
            statsId: `${stat.playerId}_${year}`,
          },
        }));
      }
    }

    // Import team statistics if provided
    if (teamStats && Array.isArray(teamStats)) {
      for (const stat of teamStats) {
        await docClient.send(new PutCommand({
          TableName: TableNames.ENCYCLOPEDIA_TEAM_STATS,
          Item: {
            ...stat,
            leagueId,
            seasonYear: year,
            statsId: `${stat.teamId}_${year}`,
          },
        }));
      }
    }

    // Update season status to complete
    await docClient.send(new UpdateCommand({
      TableName: TableNames.ENCYCLOPEDIA_SEASONS,
      Key: { leagueId, seasonId },
      UpdateExpression: 'SET #status = :status',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: { ':status': 'complete' },
    }));

    season.status = 'complete';
    res.status(201).json(season);
  } catch (error) {
    console.error('Error importing season:', error);
    res.status(500).json({ error: 'Failed to import season' });
  }
});

// DELETE /encyclopedia/:leagueId/seasons/:seasonId - Delete an imported season
router.delete('/:leagueId/seasons/:seasonId', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId, seasonId } = req.params;

    // Get season to find the year
    const seasonResult = await docClient.send(new GetCommand({
      TableName: TableNames.ENCYCLOPEDIA_SEASONS,
      Key: { leagueId, seasonId },
    }));

    if (!seasonResult.Item) {
      return res.status(404).json({ error: 'Season not found' });
    }

    const year = seasonResult.Item.year;

    // Delete season record
    await docClient.send(new DeleteCommand({
      TableName: TableNames.ENCYCLOPEDIA_SEASONS,
      Key: { leagueId, seasonId },
    }));

    // Note: In production, you'd also delete related player/team stats for this year

    res.json({ message: 'Season deleted successfully' });
  } catch (error) {
    console.error('Error deleting season:', error);
    res.status(500).json({ error: 'Failed to delete season' });
  }
});

// ============================================
// Player Leaderboards
// ============================================

// GET /encyclopedia/:leagueId/leaderboards/:statCode - Get leaderboard for a stat
router.get('/:leagueId/leaderboards/:statCode', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId, statCode } = req.params;
    const {
      type = 'seasonal',
      season,
      limit = '10',
      offset = '0',
      search,
    } = req.query;

    const displayCount = parseInt(limit as string, 10);
    const skipCount = parseInt(offset as string, 10);
    const seasonYear = season ? parseInt(season as string, 10) : undefined;

    // Find stat category
    const statCategory = [...BATTING_STAT_CATEGORIES, ...PITCHING_STAT_CATEGORIES]
      .find(c => c.code === statCode.toUpperCase());

    if (!statCategory) {
      return res.status(400).json({ error: 'Invalid stat code' });
    }

    let entries: LeaderboardEntry[] = [];

    if (type === 'career') {
      entries = await getCareerLeaderboard(leagueId, statCode.toUpperCase(), statCategory.playerType, displayCount, skipCount);
    } else {
      entries = await getSeasonalLeaderboard(leagueId, statCode.toUpperCase(), statCategory.playerType, seasonYear, displayCount, skipCount);
    }

    // Search for specific player if requested
    let searchedPlayer: LeaderboardEntry | undefined;
    if (search) {
      searchedPlayer = await findPlayerInLeaderboard(leagueId, statCode.toUpperCase(), search as string, type as string, seasonYear);
    }

    const leaderboard: Leaderboard = {
      leaderboardId: `lb_${leagueId}_${statCode}_${type}`,
      leagueId,
      statCategory: statCategory.name,
      statCode: statCode.toUpperCase(),
      playerType: statCategory.playerType,
      leaderboardType: type as any,
      seasonYear,
      entries,
      totalEntries: entries.length,
      minimumQualifier: statCategory.minimumQualifier,
      generatedAt: new Date().toISOString(),
    };

    res.json({
      leaderboard,
      searchedPlayer,
      statInfo: statCategory,
    });
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

// GET /encyclopedia/:leagueId/leaderboards - Get all available leaderboard categories
router.get('/:leagueId/leaderboards', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    res.json({
      batting: BATTING_STAT_CATEGORIES,
      pitching: PITCHING_STAT_CATEGORIES,
    });
  } catch (error) {
    console.error('Error fetching leaderboard categories:', error);
    res.status(500).json({ error: 'Failed to fetch leaderboard categories' });
  }
});

// ============================================
// Player Career Statistics
// ============================================

// GET /encyclopedia/:leagueId/players/:playerId/career - Get player career stats
router.get('/:leagueId/players/:playerId/career', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId, playerId } = req.params;

    // Get all season stats for this player
    const result = await docClient.send(new QueryCommand({
      TableName: TableNames.ENCYCLOPEDIA_PLAYER_STATS,
      IndexName: 'PlayerIndex',
      KeyConditionExpression: 'playerId = :playerId AND leagueId = :leagueId',
      ExpressionAttributeValues: {
        ':playerId': playerId,
        ':leagueId': leagueId,
      },
    }));

    const seasonStats = (result.Items || []) as PlayerSeasonStats[];

    if (seasonStats.length === 0) {
      return res.status(404).json({ error: 'Player not found' });
    }

    // Aggregate career stats
    const careerStats = aggregateCareerStats(playerId, seasonStats);

    res.json(careerStats);
  } catch (error) {
    console.error('Error fetching player career stats:', error);
    res.status(500).json({ error: 'Failed to fetch player career stats' });
  }
});

// GET /encyclopedia/:leagueId/players/:playerId/seasons - Get player season-by-season stats
router.get('/:leagueId/players/:playerId/seasons', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId, playerId } = req.params;

    const result = await docClient.send(new QueryCommand({
      TableName: TableNames.ENCYCLOPEDIA_PLAYER_STATS,
      IndexName: 'PlayerIndex',
      KeyConditionExpression: 'playerId = :playerId AND leagueId = :leagueId',
      ExpressionAttributeValues: {
        ':playerId': playerId,
        ':leagueId': leagueId,
      },
    }));

    const seasons = (result.Items || []).sort((a: any, b: any) => b.seasonYear - a.seasonYear);

    res.json({ seasons });
  } catch (error) {
    console.error('Error fetching player seasons:', error);
    res.status(500).json({ error: 'Failed to fetch player seasons' });
  }
});

// ============================================
// MLB vs League Comparison
// ============================================

// GET /encyclopedia/:leagueId/compare/:playerId - Get MLB vs League comparison
router.get('/:leagueId/compare/:playerId', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId, playerId } = req.params;
    const { season, type = 'single_season' } = req.query;
    const seasonYear = season ? parseInt(season as string, 10) : new Date().getFullYear();

    // Get league stats
    const leagueStatsResult = await docClient.send(new QueryCommand({
      TableName: TableNames.ENCYCLOPEDIA_PLAYER_STATS,
      IndexName: 'PlayerIndex',
      KeyConditionExpression: 'playerId = :playerId AND leagueId = :leagueId',
      ExpressionAttributeValues: {
        ':playerId': playerId,
        ':leagueId': leagueId,
      },
    }));

    const leagueStats = (leagueStatsResult.Items || []) as PlayerSeasonStats[];

    if (leagueStats.length === 0) {
      return res.status(404).json({ error: 'Player stats not found' });
    }

    // Get MLB stats (from player cache)
    const mlbStatsResult = await docClient.send(new GetCommand({
      TableName: TableNames.PLAYERS,
      Key: { playerId },
    }));

    const mlbPlayer = mlbStatsResult.Item;

    // Build comparison
    let comparison: PlayerComparison;

    if (type === 'career') {
      comparison = buildCareerComparison(playerId, leagueStats, mlbPlayer);
    } else {
      const seasonStat = leagueStats.find(s => s.seasonYear === seasonYear);
      if (!seasonStat) {
        return res.status(404).json({ error: 'Season stats not found' });
      }
      comparison = buildSeasonComparison(playerId, seasonStat, mlbPlayer, seasonYear);
    }

    res.json(comparison);
  } catch (error) {
    console.error('Error fetching comparison:', error);
    res.status(500).json({ error: 'Failed to fetch comparison' });
  }
});

// ============================================
// Team Historical Statistics
// ============================================

// GET /encyclopedia/:leagueId/teams - Get all team historical stats
router.get('/:leagueId/teams', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId } = req.params;

    const result = await docClient.send(new QueryCommand({
      TableName: TableNames.ENCYCLOPEDIA_TEAM_STATS,
      KeyConditionExpression: 'leagueId = :leagueId',
      ExpressionAttributeValues: { ':leagueId': leagueId },
    }));

    // Group by team and aggregate
    const teamStatsMap = new Map<string, any[]>();
    for (const item of result.Items || []) {
      const teamId = item.teamId;
      if (!teamStatsMap.has(teamId)) {
        teamStatsMap.set(teamId, []);
      }
      teamStatsMap.get(teamId)!.push(item);
    }

    const teams: TeamHistoricalStats[] = [];
    for (const [teamId, seasons] of teamStatsMap) {
      teams.push(aggregateTeamStats(teamId, seasons));
    }

    // Sort by dynasty score
    teams.sort((a, b) => b.dynastyScore - a.dynastyScore);

    res.json({ teams });
  } catch (error) {
    console.error('Error fetching team stats:', error);
    res.status(500).json({ error: 'Failed to fetch team stats' });
  }
});

// GET /encyclopedia/:leagueId/teams/:teamId - Get single team historical stats
router.get('/:leagueId/teams/:teamId', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId, teamId } = req.params;

    const result = await docClient.send(new QueryCommand({
      TableName: TableNames.ENCYCLOPEDIA_TEAM_STATS,
      IndexName: 'TeamIndex',
      KeyConditionExpression: 'teamId = :teamId AND leagueId = :leagueId',
      ExpressionAttributeValues: {
        ':teamId': teamId,
        ':leagueId': leagueId,
      },
    }));

    const seasons = result.Items || [];

    if (seasons.length === 0) {
      return res.status(404).json({ error: 'Team not found' });
    }

    const teamStats = aggregateTeamStats(teamId, seasons);

    res.json(teamStats);
  } catch (error) {
    console.error('Error fetching team stats:', error);
    res.status(500).json({ error: 'Failed to fetch team stats' });
  }
});

// GET /encyclopedia/:leagueId/teams/leaderboard/:category - Get team leaderboard
router.get('/:leagueId/teams/leaderboard/:category', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId, category } = req.params;
    const { limit = '10' } = req.query;
    const displayCount = parseInt(limit as string, 10);

    const entries = await getTeamLeaderboard(leagueId, category, displayCount);

    const leaderboard: TeamLeaderboard = {
      leaderboardId: `team_lb_${leagueId}_${category}`,
      leagueId,
      category: category as any,
      statCode: category,
      entries,
      generatedAt: new Date().toISOString(),
    };

    res.json(leaderboard);
  } catch (error) {
    console.error('Error fetching team leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch team leaderboard' });
  }
});

// ============================================
// Search
// ============================================

// GET /encyclopedia/:leagueId/search - Search players and teams
router.get('/:leagueId/search', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { leagueId } = req.params;
    const { q, type = 'all' } = req.query;

    if (!q || (q as string).length < 2) {
      return res.status(400).json({ error: 'Search query must be at least 2 characters' });
    }

    const searchTerm = (q as string).toLowerCase();
    const results: { players: any[]; teams: any[] } = { players: [], teams: [] };

    // Search players
    if (type === 'all' || type === 'players') {
      const playerResult = await docClient.send(new ScanCommand({
        TableName: TableNames.ENCYCLOPEDIA_PLAYER_STATS,
        FilterExpression: 'leagueId = :leagueId AND contains(#playerName, :search)',
        ExpressionAttributeNames: { '#playerName': 'playerName' },
        ExpressionAttributeValues: {
          ':leagueId': leagueId,
          ':search': searchTerm,
        },
        Limit: 20,
      }));

      // Deduplicate by playerId
      const playerMap = new Map<string, any>();
      for (const item of playerResult.Items || []) {
        if (!playerMap.has(item.playerId)) {
          playerMap.set(item.playerId, item);
        }
      }
      results.players = Array.from(playerMap.values());
    }

    // Search teams
    if (type === 'all' || type === 'teams') {
      const teamResult = await docClient.send(new ScanCommand({
        TableName: TableNames.ENCYCLOPEDIA_TEAM_STATS,
        FilterExpression: 'leagueId = :leagueId AND contains(#teamName, :search)',
        ExpressionAttributeNames: { '#teamName': 'teamName' },
        ExpressionAttributeValues: {
          ':leagueId': leagueId,
          ':search': searchTerm,
        },
        Limit: 20,
      }));

      // Deduplicate by teamId
      const teamMap = new Map<string, any>();
      for (const item of teamResult.Items || []) {
        if (!teamMap.has(item.teamId)) {
          teamMap.set(item.teamId, item);
        }
      }
      results.teams = Array.from(teamMap.values());
    }

    res.json(results);
  } catch (error) {
    console.error('Error searching encyclopedia:', error);
    res.status(500).json({ error: 'Failed to search encyclopedia' });
  }
});

// ============================================
// Helper Functions
// ============================================

async function getTopLeaders(
  leagueId: string,
  statCode: string,
  playerType: 'batter' | 'pitcher',
  seasonYear: number,
  limit: number
): Promise<LeaderboardEntry[]> {
  // In production, you'd query indexed data
  // For now, return placeholder data
  return [];
}

async function getTeamLeaderboard(
  leagueId: string,
  category: string,
  limit: number
): Promise<any[]> {
  // In production, aggregate team stats
  return [];
}

async function getCareerLeaderboard(
  leagueId: string,
  statCode: string,
  playerType: 'batter' | 'pitcher',
  limit: number,
  offset: number
): Promise<LeaderboardEntry[]> {
  // Query all player stats and aggregate
  const result = await docClient.send(new QueryCommand({
    TableName: TableNames.ENCYCLOPEDIA_PLAYER_STATS,
    IndexName: 'LeagueIndex',
    KeyConditionExpression: 'leagueId = :leagueId',
    ExpressionAttributeValues: { ':leagueId': leagueId },
  }));

  // Aggregate by player
  const playerMap = new Map<string, { playerId: string; playerName: string; teams: Set<string>; seasons: number; totalValue: number; count: number }>();

  for (const item of result.Items || []) {
    const stats = playerType === 'batter' ? item.batting : item.pitching;
    if (!stats) continue;

    const value = getStatValue(stats, statCode);
    if (value === undefined) continue;

    if (!playerMap.has(item.playerId)) {
      playerMap.set(item.playerId, {
        playerId: item.playerId,
        playerName: item.playerName,
        teams: new Set(),
        seasons: 0,
        totalValue: 0,
        count: 0,
      });
    }

    const player = playerMap.get(item.playerId)!;
    player.teams.add(item.teamName);
    player.seasons++;
    player.totalValue += value;
    player.count++;
  }

  // Convert to entries and sort
  const statCategory = [...BATTING_STAT_CATEGORIES, ...PITCHING_STAT_CATEGORIES].find(c => c.code === statCode);
  const isRate = statCategory?.isRate || false;
  const sortAsc = statCategory?.sortDirection === 'asc';

  const entries: LeaderboardEntry[] = Array.from(playerMap.values())
    .map((p, idx) => ({
      rank: idx + 1,
      playerId: p.playerId,
      playerName: p.playerName,
      teams: Array.from(p.teams),
      seasons: p.seasons,
      value: isRate ? p.totalValue / p.count : p.totalValue,
    }))
    .sort((a, b) => sortAsc ? a.value - b.value : b.value - a.value)
    .slice(offset, offset + limit)
    .map((entry, idx) => ({ ...entry, rank: offset + idx + 1 }));

  return entries;
}

async function getSeasonalLeaderboard(
  leagueId: string,
  statCode: string,
  playerType: 'batter' | 'pitcher',
  seasonYear: number | undefined,
  limit: number,
  offset: number
): Promise<LeaderboardEntry[]> {
  let filterExpression = 'leagueId = :leagueId';
  const expressionValues: any = { ':leagueId': leagueId };

  if (seasonYear) {
    filterExpression += ' AND seasonYear = :year';
    expressionValues[':year'] = seasonYear;
  }

  const result = await docClient.send(new ScanCommand({
    TableName: TableNames.ENCYCLOPEDIA_PLAYER_STATS,
    FilterExpression: filterExpression,
    ExpressionAttributeValues: expressionValues,
  }));

  const statCategory = [...BATTING_STAT_CATEGORIES, ...PITCHING_STAT_CATEGORIES].find(c => c.code === statCode);
  const sortAsc = statCategory?.sortDirection === 'asc';

  const entries: LeaderboardEntry[] = [];

  for (const item of result.Items || []) {
    const stats = playerType === 'batter' ? item.batting : item.pitching;
    if (!stats) continue;

    const value = getStatValue(stats, statCode);
    if (value === undefined || !item.playerId || !item.playerName) continue;

    entries.push({
      rank: 0,
      playerId: item.playerId,
      playerName: item.playerName,
      teamId: item.teamId,
      teamName: item.teamName,
      value,
    });
  }

  entries.sort((a, b) => sortAsc ? a.value - b.value : b.value - a.value);
  const sliced = entries.slice(offset, offset + limit);
  sliced.forEach((entry, idx) => { entry.rank = offset + idx + 1; });

  return sliced;
}

async function findPlayerInLeaderboard(
  leagueId: string,
  statCode: string,
  search: string,
  type: string,
  seasonYear?: number
): Promise<LeaderboardEntry | undefined> {
  // Search for player and return their rank
  return undefined;
}

function getStatValue(stats: any, statCode: string): number | undefined {
  const mapping: Record<string, string> = {
    'AVG': 'avg',
    'HR': 'homeRuns',
    'RBI': 'rbi',
    'R': 'runs',
    'H': 'hits',
    '2B': 'doubles',
    '3B': 'triples',
    'SB': 'stolenBases',
    'OBP': 'obp',
    'SLG': 'slg',
    'OPS': 'ops',
    'BB': 'walks',
    'TB': 'totalBases',
    'G': 'gamesPlayed',
    'AB': 'atBats',
    'ERA': 'era',
    'W': 'wins',
    'SO': 'strikeouts',
    'SV': 'saves',
    'WHIP': 'whip',
    'IP': 'inningsPitched',
    'WPCT': 'winPct',
    'CG': 'completeGames',
    'SHO': 'shutouts',
    'GS': 'gamesStarted',
    'HLD': 'holds',
    'K9': 'k9',
    'BB9': 'bb9',
    'KBB': 'kbb',
  };

  const field = mapping[statCode];
  return field ? stats[field] : undefined;
}

function aggregateCareerStats(playerId: string, seasonStats: PlayerSeasonStats[]): PlayerCareerStats {
  const playerName = seasonStats[0]?.playerName || '';
  const teams = [...new Set(seasonStats.map(s => s.teamName))];
  const seasonsPlayed = seasonStats.length;

  // Aggregate batting stats
  let battingCareer: any = null;
  const battingSeasons = seasonStats.filter(s => s.batting);
  if (battingSeasons.length > 0) {
    battingCareer = {
      gamesPlayed: battingSeasons.reduce((sum, s) => sum + (s.batting?.gamesPlayed || 0), 0),
      atBats: battingSeasons.reduce((sum, s) => sum + (s.batting?.atBats || 0), 0),
      runs: battingSeasons.reduce((sum, s) => sum + (s.batting?.runs || 0), 0),
      hits: battingSeasons.reduce((sum, s) => sum + (s.batting?.hits || 0), 0),
      doubles: battingSeasons.reduce((sum, s) => sum + (s.batting?.doubles || 0), 0),
      triples: battingSeasons.reduce((sum, s) => sum + (s.batting?.triples || 0), 0),
      homeRuns: battingSeasons.reduce((sum, s) => sum + (s.batting?.homeRuns || 0), 0),
      rbi: battingSeasons.reduce((sum, s) => sum + (s.batting?.rbi || 0), 0),
      stolenBases: battingSeasons.reduce((sum, s) => sum + (s.batting?.stolenBases || 0), 0),
      caughtStealing: battingSeasons.reduce((sum, s) => sum + (s.batting?.caughtStealing || 0), 0),
      walks: battingSeasons.reduce((sum, s) => sum + (s.batting?.walks || 0), 0),
      strikeouts: battingSeasons.reduce((sum, s) => sum + (s.batting?.strikeouts || 0), 0),
      totalBases: battingSeasons.reduce((sum, s) => sum + (s.batting?.totalBases || 0), 0),
      seasons: battingSeasons.length,
    };

    // Calculate rate stats
    if (battingCareer.atBats > 0) {
      battingCareer.avg = battingCareer.hits / battingCareer.atBats;
      battingCareer.slg = battingCareer.totalBases / battingCareer.atBats;
    }
    const pa = battingCareer.atBats + battingCareer.walks;
    if (pa > 0) {
      battingCareer.obp = (battingCareer.hits + battingCareer.walks) / pa;
    }
    battingCareer.ops = (battingCareer.obp || 0) + (battingCareer.slg || 0);

    battingCareer.avgPerSeason = {
      gamesPlayed: battingCareer.gamesPlayed / battingSeasons.length,
      homeRuns: battingCareer.homeRuns / battingSeasons.length,
      rbi: battingCareer.rbi / battingSeasons.length,
      runs: battingCareer.runs / battingSeasons.length,
      stolenBases: battingCareer.stolenBases / battingSeasons.length,
    };
  }

  // Aggregate pitching stats
  let pitchingCareer: any = null;
  const pitchingSeasons = seasonStats.filter(s => s.pitching);
  if (pitchingSeasons.length > 0) {
    pitchingCareer = {
      wins: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.wins || 0), 0),
      losses: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.losses || 0), 0),
      games: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.games || 0), 0),
      gamesStarted: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.gamesStarted || 0), 0),
      completeGames: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.completeGames || 0), 0),
      shutouts: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.shutouts || 0), 0),
      saves: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.saves || 0), 0),
      holds: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.holds || 0), 0),
      inningsPitched: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.inningsPitched || 0), 0),
      hits: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.hits || 0), 0),
      runs: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.runs || 0), 0),
      earnedRuns: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.earnedRuns || 0), 0),
      homeRuns: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.homeRuns || 0), 0),
      walks: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.walks || 0), 0),
      strikeouts: pitchingSeasons.reduce((sum, s) => sum + (s.pitching?.strikeouts || 0), 0),
      seasons: pitchingSeasons.length,
    };

    // Calculate rate stats
    if (pitchingCareer.inningsPitched > 0) {
      pitchingCareer.era = (pitchingCareer.earnedRuns * 9) / pitchingCareer.inningsPitched;
      pitchingCareer.whip = (pitchingCareer.walks + pitchingCareer.hits) / pitchingCareer.inningsPitched;
      pitchingCareer.k9 = (pitchingCareer.strikeouts * 9) / pitchingCareer.inningsPitched;
      pitchingCareer.bb9 = (pitchingCareer.walks * 9) / pitchingCareer.inningsPitched;
    }
    if (pitchingCareer.walks > 0) {
      pitchingCareer.kbb = pitchingCareer.strikeouts / pitchingCareer.walks;
    }
    const decisions = pitchingCareer.wins + pitchingCareer.losses;
    if (decisions > 0) {
      pitchingCareer.winPct = pitchingCareer.wins / decisions;
    }

    pitchingCareer.avgPerSeason = {
      wins: pitchingCareer.wins / pitchingSeasons.length,
      strikeouts: pitchingCareer.strikeouts / pitchingSeasons.length,
      saves: pitchingCareer.saves / pitchingSeasons.length,
      inningsPitched: pitchingCareer.inningsPitched / pitchingSeasons.length,
    };
  }

  // Find season bests
  const seasonBests: any = {};
  for (const season of seasonStats) {
    if (season.batting) {
      updateSeasonBest(seasonBests, 'AVG', season.batting.avg, season.seasonYear, 'desc');
      updateSeasonBest(seasonBests, 'HR', season.batting.homeRuns, season.seasonYear, 'desc');
      updateSeasonBest(seasonBests, 'RBI', season.batting.rbi, season.seasonYear, 'desc');
      updateSeasonBest(seasonBests, 'OPS', season.batting.ops, season.seasonYear, 'desc');
    }
    if (season.pitching) {
      updateSeasonBest(seasonBests, 'ERA', season.pitching.era, season.seasonYear, 'asc');
      updateSeasonBest(seasonBests, 'W', season.pitching.wins, season.seasonYear, 'desc');
      updateSeasonBest(seasonBests, 'SO', season.pitching.strikeouts, season.seasonYear, 'desc');
    }
  }

  return {
    playerId,
    playerName,
    leagueId: seasonStats[0]?.leagueId || '',
    seasonsPlayed,
    teams,
    isActive: true,
    batting: battingCareer,
    pitching: pitchingCareer,
    seasonBests,
    rankings: {},
  };
}

function updateSeasonBest(bests: any, code: string, value: number | undefined, year: number, direction: 'asc' | 'desc') {
  if (value === undefined || value === null) return;

  if (!bests[code]) {
    bests[code] = { value, year };
  } else {
    const isBetter = direction === 'desc' ? value > bests[code].value : value < bests[code].value;
    if (isBetter) {
      bests[code] = { value, year };
    }
  }
}

function aggregateTeamStats(teamId: string, seasons: any[]): TeamHistoricalStats {
  const teamName = seasons[0]?.teamName || '';
  const leagueId = seasons[0]?.leagueId || '';

  // Aggregate regular season
  const regularSeason = {
    wins: seasons.reduce((sum, s) => sum + (s.wins || 0), 0),
    losses: seasons.reduce((sum, s) => sum + (s.losses || 0), 0),
    gamesPlayed: 0,
    pointsFor: seasons.reduce((sum, s) => sum + (s.pointsFor || 0), 0),
    pointsAgainst: seasons.reduce((sum, s) => sum + (s.pointsAgainst || 0), 0),
    winningPercentage: 0,
    pointDifferential: 0,
  };
  regularSeason.gamesPlayed = regularSeason.wins + regularSeason.losses;
  regularSeason.winningPercentage = regularSeason.gamesPlayed > 0
    ? regularSeason.wins / regularSeason.gamesPlayed
    : 0;
  regularSeason.pointDifferential = regularSeason.pointsFor - regularSeason.pointsAgainst;

  // Aggregate postseason
  const playoffSeasons = seasons.filter(s => s.playoffAppearance);
  const postseason = {
    appearances: playoffSeasons.length,
    wins: seasons.reduce((sum, s) => sum + (s.playoffWins || 0), 0),
    losses: seasons.reduce((sum, s) => sum + (s.playoffLosses || 0), 0),
    winningPercentage: 0,
  };
  const postseasonGames = postseason.wins + postseason.losses;
  postseason.winningPercentage = postseasonGames > 0 ? postseason.wins / postseasonGames : 0;

  // Championships
  const championshipSeasons = seasons.filter(s => s.champion);
  const championshipAppearances = seasons.filter(s => s.championshipAppearance);
  const championships = {
    appearances: championshipAppearances.length,
    wins: championshipSeasons.length,
    losses: championshipAppearances.length - championshipSeasons.length,
    winningPercentage: championshipAppearances.length > 0
      ? championshipSeasons.length / championshipAppearances.length
      : 0,
    years: championshipSeasons.map(s => s.seasonYear).sort(),
  };

  // Dynasty score
  const dynastyScore = (championships.wins * 10) + (championships.appearances * 5) + (postseason.appearances * 2);

  // Season records
  const seasonRecords = seasons.map(s => ({
    year: s.seasonYear,
    wins: s.wins || 0,
    losses: s.losses || 0,
    winningPercentage: (s.wins || 0) / ((s.wins || 0) + (s.losses || 0)) || 0,
    standingsPosition: s.standingsPosition || 0,
    playoffResult: s.playoffResult,
    champion: s.champion || false,
    pointsFor: s.pointsFor || 0,
    pointsAgainst: s.pointsAgainst || 0,
  })).sort((a, b) => b.year - a.year);

  return {
    teamId,
    teamName,
    leagueId,
    allTime: {
      regularSeason,
      postseason,
      championships,
    },
    seasons: seasonRecords,
    dynastyScore,
  };
}

function buildSeasonComparison(
  playerId: string,
  leagueStat: PlayerSeasonStats,
  mlbPlayer: any,
  seasonYear: number
): PlayerComparison {
  const batting = leagueStat.batting && mlbPlayer?.stats?.batting
    ? buildBattingComparison(leagueStat.batting, mlbPlayer.stats.batting)
    : undefined;

  const pitching = leagueStat.pitching && mlbPlayer?.stats?.pitching
    ? buildPitchingComparison(leagueStat.pitching, mlbPlayer.stats.pitching)
    : undefined;

  const matchScore = calculateMatchScore(batting, pitching);
  const consistencyRating = getConsistencyRating(matchScore);

  return {
    comparisonId: `comp_${playerId}_${seasonYear}`,
    playerId,
    playerName: leagueStat.playerName,
    leagueId: leagueStat.leagueId,
    seasonYear,
    comparisonType: 'single_season',
    batting,
    pitching,
    matchScore,
    consistencyRating,
    generatedAt: new Date().toISOString(),
  };
}

function buildCareerComparison(
  playerId: string,
  leagueStats: PlayerSeasonStats[],
  mlbPlayer: any
): PlayerComparison {
  // Aggregate league stats
  const careerStats = aggregateCareerStats(playerId, leagueStats);

  const batting = careerStats.batting && mlbPlayer?.stats?.batting
    ? buildBattingComparison(careerStats.batting, mlbPlayer.stats.batting)
    : undefined;

  const pitching = careerStats.pitching && mlbPlayer?.stats?.pitching
    ? buildPitchingComparison(careerStats.pitching, mlbPlayer.stats.pitching)
    : undefined;

  const matchScore = calculateMatchScore(batting, pitching);
  const consistencyRating = getConsistencyRating(matchScore);

  return {
    comparisonId: `comp_${playerId}_career`,
    playerId,
    playerName: careerStats.playerName,
    leagueId: careerStats.leagueId,
    comparisonType: 'career',
    batting,
    pitching,
    matchScore,
    consistencyRating,
    generatedAt: new Date().toISOString(),
  };
}

function buildBattingComparison(league: any, mlb: any): any {
  return {
    avg: buildStatComparison(league.avg, parseFloat(mlb.avg) || 0),
    hr: buildStatComparison(league.homeRuns, mlb.homeRuns || 0),
    rbi: buildStatComparison(league.rbi, mlb.rbi || 0),
    runs: buildStatComparison(league.runs, mlb.runs || 0),
    sb: buildStatComparison(league.stolenBases, mlb.stolenBases || 0),
    hits: buildStatComparison(league.hits, mlb.hits || 0),
    walks: buildStatComparison(league.walks, mlb.walks || 0),
    ops: buildStatComparison(league.ops, parseFloat(mlb.ops) || 0),
  };
}

function buildPitchingComparison(league: any, mlb: any): any {
  return {
    era: buildStatComparison(league.era, parseFloat(mlb.era) || 0),
    wins: buildStatComparison(league.wins, mlb.wins || 0),
    strikeouts: buildStatComparison(league.strikeouts, mlb.strikeouts || 0),
    saves: buildStatComparison(league.saves, mlb.saves || 0),
    whip: buildStatComparison(league.whip, parseFloat(mlb.whip) || 0),
    ip: buildStatComparison(league.inningsPitched, parseFloat(mlb.inningsPitched) || 0),
  };
}

function buildStatComparison(league: number, mlb: number): any {
  const difference = league - mlb;
  const percentVariance = mlb !== 0 ? ((league - mlb) / mlb) * 100 : 0;

  return {
    mlb,
    league,
    difference,
    percentVariance,
  };
}

function calculateMatchScore(batting: any, pitching: any): number {
  const comparisons: number[] = [];

  if (batting) {
    for (const stat of Object.values(batting)) {
      if (stat && typeof (stat as any).percentVariance === 'number') {
        comparisons.push(Math.abs((stat as any).percentVariance));
      }
    }
  }

  if (pitching) {
    for (const stat of Object.values(pitching)) {
      if (stat && typeof (stat as any).percentVariance === 'number') {
        comparisons.push(Math.abs((stat as any).percentVariance));
      }
    }
  }

  if (comparisons.length === 0) return 0;

  const avgVariance = comparisons.reduce((a, b) => a + b, 0) / comparisons.length;
  return Math.max(0, 100 - avgVariance);
}

function getConsistencyRating(matchScore: number): 'A' | 'B' | 'C' | 'D' | 'F' {
  if (matchScore >= 90) return 'A';
  if (matchScore >= 80) return 'B';
  if (matchScore >= 70) return 'C';
  if (matchScore >= 60) return 'D';
  return 'F';
}

export default router;
