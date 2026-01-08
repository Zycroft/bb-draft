import { Router, Request, Response } from 'express';
import { authMiddleware, optionalAuthMiddleware } from '../middleware/auth';
import * as PlayerService from '../services/playerService';

const router = Router();

// Get all players with optional filters
router.get('/', optionalAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const { position, search, limit, lastKey } = req.query;

    const result = await PlayerService.getPlayers({
      position: position as string,
      search: search as string,
      limit: limit ? parseInt(limit as string) : undefined,
      lastKey: lastKey as string,
    });

    res.json(result);
  } catch (error: any) {
    console.error('Error getting players:', error);
    res.status(500).json({ error: 'Failed to get players', message: error.message });
  }
});

// Get batters only
router.get('/batters', optionalAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const { limit } = req.query;
    const batters = await PlayerService.getBatters(limit ? parseInt(limit as string) : undefined);
    res.json({ items: batters, count: batters.length });
  } catch (error: any) {
    console.error('Error getting batters:', error);
    res.status(500).json({ error: 'Failed to get batters', message: error.message });
  }
});

// Get pitchers only
router.get('/pitchers', optionalAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const { limit } = req.query;
    const pitchers = await PlayerService.getPitchers(limit ? parseInt(limit as string) : undefined);
    res.json({ items: pitchers, count: pitchers.length });
  } catch (error: any) {
    console.error('Error getting pitchers:', error);
    res.status(500).json({ error: 'Failed to get pitchers', message: error.message });
  }
});

// Search players by name
router.get('/search', optionalAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const { q, limit } = req.query;
    if (!q) {
      res.status(400).json({ error: 'Search query required' });
      return;
    }

    const result = await PlayerService.getPlayers({
      search: q as string,
      limit: limit ? parseInt(limit as string) : undefined,
    });

    res.json(result);
  } catch (error: any) {
    console.error('Error searching players:', error);
    res.status(500).json({ error: 'Failed to search players', message: error.message });
  }
});

// Get single player by ID
router.get('/:playerId', optionalAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const { playerId } = req.params;
    const player = await PlayerService.getPlayer(playerId);

    if (!player) {
      res.status(404).json({ error: 'Player not found' });
      return;
    }

    res.json(player);
  } catch (error: any) {
    console.error('Error getting player:', error);
    res.status(500).json({ error: 'Failed to get player', message: error.message });
  }
});

// Sync players from MLB API (admin only - for now just auth required)
router.post('/sync', authMiddleware, async (req: Request, res: Response) => {
  try {
    const result = await PlayerService.syncPlayersFromMlb();
    res.json({ message: 'Sync complete', ...result });
  } catch (error: any) {
    console.error('Error syncing players:', error);
    res.status(500).json({ error: 'Failed to sync players', message: error.message });
  }
});

// Refresh single player stats
router.post('/:playerId/refresh', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { playerId } = req.params;
    const player = await PlayerService.refreshPlayerStats(playerId);

    if (!player) {
      res.status(404).json({ error: 'Player not found' });
      return;
    }

    res.json(player);
  } catch (error: any) {
    console.error('Error refreshing player:', error);
    res.status(500).json({ error: 'Failed to refresh player', message: error.message });
  }
});

// Get player eligibility status for a league
router.get('/:playerId/eligibility/:leagueId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { playerId, leagueId } = req.params;
    const eligibility = await PlayerService.getPlayerEligibility(playerId, leagueId);
    res.json(eligibility);
  } catch (error: any) {
    console.error('Error getting eligibility:', error);
    res.status(500).json({ error: 'Failed to get eligibility', message: error.message });
  }
});

// Set player eligibility status for a league
router.put('/:playerId/eligibility/:leagueId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { playerId, leagueId } = req.params;
    const { eligibility, note, ownerTeamId } = req.body;

    if (!eligibility || !['eligible', 'onTeam', 'notEligible'].includes(eligibility)) {
      res.status(400).json({ error: 'Invalid eligibility status' });
      return;
    }

    const result = await PlayerService.setPlayerEligibility(playerId, leagueId, {
      eligibility,
      note,
      ownerTeamId,
    });

    res.json(result);
  } catch (error: any) {
    console.error('Error setting eligibility:', error);
    res.status(500).json({ error: 'Failed to set eligibility', message: error.message });
  }
});

// Bulk set eligibility for multiple players
router.put('/eligibility/:leagueId/bulk', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const { players } = req.body; // Array of { playerId, eligibility, note?, ownerTeamId? }

    if (!Array.isArray(players)) {
      res.status(400).json({ error: 'Players array required' });
      return;
    }

    const results = await PlayerService.bulkSetEligibility(leagueId, players);
    res.json({ updated: results.length, results });
  } catch (error: any) {
    console.error('Error bulk setting eligibility:', error);
    res.status(500).json({ error: 'Failed to bulk set eligibility', message: error.message });
  }
});

// Get all player eligibilities for a league
router.get('/eligibility/:leagueId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const eligibilities = await PlayerService.getLeagueEligibilities(leagueId);
    res.json(eligibilities);
  } catch (error: any) {
    console.error('Error getting league eligibilities:', error);
    res.status(500).json({ error: 'Failed to get eligibilities', message: error.message });
  }
});

// Get players with advanced stats (Statcast, WAR, etc.)
router.get('/:playerId/advanced', optionalAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const { playerId } = req.params;
    const player = await PlayerService.getPlayerWithAdvancedStats(playerId);

    if (!player) {
      res.status(404).json({ error: 'Player not found' });
      return;
    }

    res.json(player);
  } catch (error: any) {
    console.error('Error getting advanced stats:', error);
    res.status(500).json({ error: 'Failed to get advanced stats', message: error.message });
  }
});

export default router;
