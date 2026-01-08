import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { authMiddleware } from '../middleware/auth';
import * as DraftModel from '../models/Draft';
import * as LeagueModel from '../models/League';
import * as TeamModel from '../models/Team';
import * as PlayerModel from '../models/Player';
import { generateRandomDraftOrder, generateWeightedLotteryOrder, getTeamForPick } from '../utils/draftOrder';
import { Draft, DraftPick, Team } from '../types';

const router = Router();

// Default draft configuration
function getDefaultConfiguration(mode: string, pickTimer: number): any {
  return {
    // Live mode settings
    pickTimer,
    autoPickOnTimeout: true,
    autoPickStrategy: 'queue',
    pauseEnabled: true,
    maxPauseDuration: 300,
    breakBetweenRounds: 0,

    // Untimed mode settings
    notifyOnTurn: true,
    notifyReminders: [3600, 21600, 86400],
    allowQueuePicks: true,
    maxQueueDepth: 20,

    // Scheduled mode settings
    windowDuration: 120,
    skipOnWindowClose: true,
    catchUpEnabled: true,
    catchUpWindow: 30,
    timezone: 'America/New_York',

    // Timed mode settings
    clockBehavior: 'reset',
    skipThreshold: 3,
    catchUpPolicy: 'immediate',
    catchUpTimeLimit: 60,
    bonusTime: 30,
  };
}

// Create/schedule a draft
router.post('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId, scheduledStart, mode = 'live', configuration } = req.body;

    if (!leagueId) {
      res.status(400).json({ error: 'League ID is required' });
      return;
    }

    const league = await LeagueModel.getLeague(leagueId);
    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can create draft' });
      return;
    }

    // Check if draft already exists
    const existingDraft = await DraftModel.getDraftByLeague(leagueId);
    if (existingDraft) {
      res.status(400).json({ error: 'Draft already exists for this league' });
      return;
    }

    // Get teams and create initial draft order
    const teams = await TeamModel.getTeamsByLeague(leagueId);
    if (teams.length < 2) {
      res.status(400).json({ error: 'Need at least 2 teams to create draft' });
      return;
    }

    const draftId = `dr_${uuidv4().slice(0, 8)}`;
    const now = new Date().toISOString();
    const draftOrder = generateRandomDraftOrder(teams.map((t) => t.teamId));

    // Merge default config with provided config
    const defaultConfig = getDefaultConfiguration(mode, league.settings.pickTimer);
    const mergedConfig = { ...defaultConfig, ...configuration };

    // Initialize time bank for timed mode
    const timeBank: Record<string, number> = {};
    if (mode === 'timed') {
      for (const teamId of draftOrder) {
        timeBank[teamId] = 0;
      }
    }

    const draft: Draft = {
      draftId,
      leagueId,
      seasonYear: league.season,
      mode,
      status: 'scheduled',
      format: league.settings.draftFormat,
      scheduledStart,
      currentRound: 1,
      currentPick: 1,
      currentOverallPick: 1,
      totalRounds: league.settings.rounds,
      teamCount: teams.length,
      pickTimer: league.settings.pickTimer,
      draftOrder,
      configuration: mergedConfig,
      skipQueue: [],
      timeBank,
      statistics: {
        fastestPick: 0,
        slowestPick: 0,
        averagePick: 0,
        autoPickCount: 0,
        skipCount: 0,
        catchUpCount: 0,
      },
      createdAt: now,
      updatedAt: now,
    };

    await DraftModel.putDraft(draft);

    // Update team draft positions
    for (let i = 0; i < draftOrder.length; i++) {
      const team = teams.find((t) => t.teamId === draftOrder[i]);
      if (team) {
        await TeamModel.putTeam({ ...team, draftPosition: i + 1, updatedAt: now });
      }
    }

    res.status(201).json(draft);
  } catch (error: any) {
    console.error('Error creating draft:', error);
    res.status(500).json({ error: 'Failed to create draft', message: error.message });
  }
});

// Get draft by ID
router.get('/:draftId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const draft = await DraftModel.getDraft(draftId);

    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    // Get picks
    const picks = await DraftModel.getDraftPicks(draftId);

    res.json({ ...draft, picks });
  } catch (error: any) {
    console.error('Error getting draft:', error);
    res.status(500).json({ error: 'Failed to get draft', message: error.message });
  }
});

// Start draft (commissioner only)
router.post('/:draftId/start', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const draft = await DraftModel.getDraft(draftId);

    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    const league = await LeagueModel.getLeague(draft.leagueId);
    if (league?.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can start draft' });
      return;
    }

    if (draft.status !== 'scheduled') {
      res.status(400).json({ error: 'Draft is not in scheduled status' });
      return;
    }

    const now = new Date();
    const clockExpires = new Date(now.getTime() + draft.pickTimer * 1000);

    const updatedDraft: Draft = {
      ...draft,
      status: 'in_progress',
      actualStart: now.toISOString(),
      onTheClock: {
        teamId: draft.draftOrder[0],
        clockStarted: now.toISOString(),
        clockExpires: clockExpires.toISOString(),
      },
      updatedAt: now.toISOString(),
    };

    await DraftModel.putDraft(updatedDraft);

    // Update league status
    if (league) {
      await LeagueModel.putLeague({ ...league, status: 'drafting', updatedAt: now.toISOString() });
    }

    res.json(updatedDraft);
  } catch (error: any) {
    console.error('Error starting draft:', error);
    res.status(500).json({ error: 'Failed to start draft', message: error.message });
  }
});

// Make a pick
router.post('/:draftId/pick', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const { teamId, playerId } = req.body;

    const draft = await DraftModel.getDraft(draftId);
    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    if (draft.status !== 'in_progress') {
      res.status(400).json({ error: 'Draft is not in progress' });
      return;
    }

    // Verify it's this team's turn
    const { teamId: expectedTeamId } = getTeamForPick(
      draft.currentOverallPick,
      draft.teamCount,
      draft.draftOrder,
      draft.format
    );

    if (teamId !== expectedTeamId) {
      res.status(400).json({ error: 'Not your turn to pick' });
      return;
    }

    // Verify user owns this team
    const team = await TeamModel.getTeam(teamId);
    if (!team || team.ownerId !== req.user!.uid) {
      res.status(403).json({ error: 'You do not own this team' });
      return;
    }

    // Verify player not already drafted
    const alreadyDrafted = await DraftModel.isPlayerDrafted(draftId, playerId);
    if (alreadyDrafted) {
      res.status(400).json({ error: 'Player has already been drafted' });
      return;
    }

    // Get player info
    const player = await PlayerModel.getPlayer(playerId);
    if (!player) {
      res.status(404).json({ error: 'Player not found' });
      return;
    }

    const now = new Date();
    const pickDuration = draft.onTheClock
      ? Math.round((now.getTime() - new Date(draft.onTheClock.clockStarted).getTime()) / 1000)
      : 0;

    // Create pick
    const pick: DraftPick = {
      draftId,
      overallPick: draft.currentOverallPick,
      round: draft.currentRound,
      pickInRound: draft.currentPick,
      teamId,
      playerId,
      playerName: player.fullName,
      position: player.primaryPosition,
      mlbTeam: player.mlbTeam,
      timestamp: now.toISOString(),
      pickDuration,
      wasAutoPick: false,
      wasCatchUp: false,
      wasFromQueue: false,
    };

    await DraftModel.putDraftPick(pick);

    // Update team roster
    const updatedTeam: Team = {
      ...team,
      roster: [
        ...team.roster,
        {
          playerId,
          position: player.primaryPosition,
          acquisitionType: 'draft',
          acquisitionDate: now.toISOString(),
        },
      ],
      updatedAt: now.toISOString(),
    };
    await TeamModel.putTeam(updatedTeam);

    // Advance draft
    const nextOverallPick = draft.currentOverallPick + 1;
    const totalPicks = draft.teamCount * draft.totalRounds;

    if (nextOverallPick > totalPicks) {
      // Draft complete
      const completedDraft: Draft = {
        ...draft,
        status: 'completed',
        currentOverallPick: nextOverallPick,
        onTheClock: undefined,
        completedAt: now.toISOString(),
        updatedAt: now.toISOString(),
      };
      await DraftModel.putDraft(completedDraft);

      // Update league status
      const league = await LeagueModel.getLeague(draft.leagueId);
      if (league) {
        await LeagueModel.putLeague({ ...league, status: 'in_season', updatedAt: now.toISOString() });
      }

      res.json({ pick, draft: completedDraft, completed: true });
      return;
    }

    // Set up next pick
    const nextPick = getTeamForPick(nextOverallPick, draft.teamCount, draft.draftOrder, draft.format);
    const clockExpires = new Date(now.getTime() + draft.pickTimer * 1000);

    const updatedDraft: Draft = {
      ...draft,
      currentOverallPick: nextOverallPick,
      currentRound: nextPick.round,
      currentPick: nextPick.pickInRound,
      onTheClock: {
        teamId: nextPick.teamId,
        clockStarted: now.toISOString(),
        clockExpires: clockExpires.toISOString(),
      },
      updatedAt: now.toISOString(),
    };

    await DraftModel.putDraft(updatedDraft);

    res.json({ pick, draft: updatedDraft, completed: false });
  } catch (error: any) {
    console.error('Error making pick:', error);
    res.status(500).json({ error: 'Failed to make pick', message: error.message });
  }
});

// Pause draft
router.post('/:draftId/pause', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const draft = await DraftModel.getDraft(draftId);

    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    const league = await LeagueModel.getLeague(draft.leagueId);
    if (league?.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can pause draft' });
      return;
    }

    if (draft.status !== 'in_progress') {
      res.status(400).json({ error: 'Draft is not in progress' });
      return;
    }

    const updatedDraft: Draft = {
      ...draft,
      status: 'paused',
      updatedAt: new Date().toISOString(),
    };

    await DraftModel.putDraft(updatedDraft);
    res.json(updatedDraft);
  } catch (error: any) {
    console.error('Error pausing draft:', error);
    res.status(500).json({ error: 'Failed to pause draft', message: error.message });
  }
});

// Resume draft
router.post('/:draftId/resume', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const draft = await DraftModel.getDraft(draftId);

    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    const league = await LeagueModel.getLeague(draft.leagueId);
    if (league?.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can resume draft' });
      return;
    }

    if (draft.status !== 'paused') {
      res.status(400).json({ error: 'Draft is not paused' });
      return;
    }

    const now = new Date();
    const clockExpires = new Date(now.getTime() + draft.pickTimer * 1000);
    const currentTeam = getTeamForPick(
      draft.currentOverallPick,
      draft.teamCount,
      draft.draftOrder,
      draft.format
    );

    const updatedDraft: Draft = {
      ...draft,
      status: 'in_progress',
      onTheClock: {
        teamId: currentTeam.teamId,
        clockStarted: now.toISOString(),
        clockExpires: clockExpires.toISOString(),
      },
      updatedAt: now.toISOString(),
    };

    await DraftModel.putDraft(updatedDraft);
    res.json(updatedDraft);
  } catch (error: any) {
    console.error('Error resuming draft:', error);
    res.status(500).json({ error: 'Failed to resume draft', message: error.message });
  }
});

// Get all picks
router.get('/:draftId/picks', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const picks = await DraftModel.getDraftPicks(draftId);
    res.json(picks);
  } catch (error: any) {
    console.error('Error getting picks:', error);
    res.status(500).json({ error: 'Failed to get picks', message: error.message });
  }
});

// Run draft lottery
router.post('/:draftId/lottery', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const { type = 'random', weights } = req.body;

    const draft = await DraftModel.getDraft(draftId);
    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    const league = await LeagueModel.getLeague(draft.leagueId);
    if (league?.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can run lottery' });
      return;
    }

    if (draft.status !== 'scheduled') {
      res.status(400).json({ error: 'Can only run lottery before draft starts' });
      return;
    }

    const teams = await TeamModel.getTeamsByLeague(draft.leagueId);
    const teamIds = teams.map((t) => t.teamId);

    let newOrder: string[];
    if (type === 'weighted' && weights) {
      newOrder = generateWeightedLotteryOrder(teamIds, weights);
    } else {
      newOrder = generateRandomDraftOrder(teamIds);
    }

    const now = new Date().toISOString();

    // Update draft order
    const updatedDraft: Draft = {
      ...draft,
      draftOrder: newOrder,
      updatedAt: now,
    };
    await DraftModel.putDraft(updatedDraft);

    // Update team positions
    for (let i = 0; i < newOrder.length; i++) {
      const team = teams.find((t) => t.teamId === newOrder[i]);
      if (team) {
        await TeamModel.putTeam({ ...team, draftPosition: i + 1, updatedAt: now });
      }
    }

    res.json({ draftOrder: newOrder });
  } catch (error: any) {
    console.error('Error running lottery:', error);
    res.status(500).json({ error: 'Failed to run lottery', message: error.message });
  }
});

// Get skip queue
router.get('/:draftId/skips', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const draft = await DraftModel.getDraft(draftId);

    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    res.json({
      skips: draft.skipQueue || [],
      catchUpAvailable: (draft.skipQueue || []).filter(s => s.catchUpStatus === 'available'),
    });
  } catch (error: any) {
    console.error('Error getting skips:', error);
    res.status(500).json({ error: 'Failed to get skips', message: error.message });
  }
});

// Make a catch-up pick
router.post('/:draftId/catchup', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const { teamId, playerId, skipId } = req.body;

    const draft = await DraftModel.getDraft(draftId);
    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    if (draft.status !== 'in_progress') {
      res.status(400).json({ error: 'Draft is not in progress' });
      return;
    }

    // Verify user owns this team
    const team = await TeamModel.getTeam(teamId);
    if (!team || team.ownerId !== req.user!.uid) {
      res.status(403).json({ error: 'You do not own this team' });
      return;
    }

    // Find the skip entry
    const skipIndex = draft.skipQueue.findIndex(
      s => s.skipId === skipId && s.teamId === teamId && s.catchUpStatus === 'available'
    );

    if (skipIndex === -1) {
      res.status(400).json({ error: 'No available catch-up pick found' });
      return;
    }

    const skip = draft.skipQueue[skipIndex];

    // Verify player not already drafted
    const alreadyDrafted = await DraftModel.isPlayerDrafted(draftId, playerId);
    if (alreadyDrafted) {
      res.status(400).json({ error: 'Player has already been drafted' });
      return;
    }

    // Get player info
    const player = await PlayerModel.getPlayer(playerId);
    if (!player) {
      res.status(404).json({ error: 'Player not found' });
      return;
    }

    const now = new Date();

    // Create the catch-up pick
    const pick: DraftPick = {
      draftId,
      overallPick: skip.overallPick,
      round: skip.round,
      pickInRound: skip.pickInRound,
      teamId,
      playerId,
      playerName: player.fullName,
      position: player.primaryPosition,
      mlbTeam: player.mlbTeam,
      timestamp: now.toISOString(),
      pickDuration: 0,
      wasAutoPick: false,
      wasCatchUp: true,
      wasFromQueue: false,
    };

    await DraftModel.putDraftPick(pick);

    // Update team roster
    const updatedTeam: Team = {
      ...team,
      roster: [
        ...team.roster,
        {
          playerId,
          position: player.primaryPosition,
          acquisitionType: 'draft',
          acquisitionDate: now.toISOString(),
        },
      ],
      updatedAt: now.toISOString(),
    };
    await TeamModel.putTeam(updatedTeam);

    // Update skip status
    draft.skipQueue[skipIndex] = {
      ...skip,
      catchUpStatus: 'completed',
      catchUpCompletedAt: now.toISOString(),
      playerId,
    };

    // Update draft statistics
    draft.statistics.catchUpCount = (draft.statistics.catchUpCount || 0) + 1;

    const updatedDraft: Draft = {
      ...draft,
      updatedAt: now.toISOString(),
    };

    await DraftModel.putDraft(updatedDraft);

    res.json({ pick, draft: updatedDraft });
  } catch (error: any) {
    console.error('Error making catch-up pick:', error);
    res.status(500).json({ error: 'Failed to make catch-up pick', message: error.message });
  }
});

// Update draft configuration (commissioner only)
router.put('/:draftId/configuration', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const { configuration } = req.body;

    const draft = await DraftModel.getDraft(draftId);
    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    const league = await LeagueModel.getLeague(draft.leagueId);
    if (league?.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can update configuration' });
      return;
    }

    if (draft.status !== 'scheduled') {
      res.status(400).json({ error: 'Cannot update configuration after draft starts' });
      return;
    }

    const updatedDraft: Draft = {
      ...draft,
      configuration: { ...draft.configuration, ...configuration },
      updatedAt: new Date().toISOString(),
    };

    await DraftModel.putDraft(updatedDraft);
    res.json(updatedDraft);
  } catch (error: any) {
    console.error('Error updating configuration:', error);
    res.status(500).json({ error: 'Failed to update configuration', message: error.message });
  }
});

// Get draft grid (formatted for UI)
router.get('/:draftId/grid', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const draft = await DraftModel.getDraft(draftId);

    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    const picks = await DraftModel.getDraftPicks(draftId);
    const teams = await TeamModel.getTeamsByLeague(draft.leagueId);

    // Build grid structure
    const rounds: any[] = [];
    for (let round = 1; round <= draft.totalRounds; round++) {
      const roundPicks = picks.filter(p => p.round === round);
      const isComplete = roundPicks.length === draft.teamCount;

      rounds.push({
        roundNumber: round,
        status: isComplete ? 'completed' : round === draft.currentRound ? 'in_progress' : 'pending',
        picks: roundPicks,
      });
    }

    const grid = {
      gridId: `grid-${draftId}`,
      leagueId: draft.leagueId,
      seasonYear: draft.seasonYear,
      draftFormat: draft.format,
      totalRounds: draft.totalRounds,
      teamCount: draft.teamCount,
      currentRound: draft.currentRound,
      currentPick: draft.currentPick,
      currentOverallPick: draft.currentOverallPick,
      draftStatus: draft.status,
      onTheClock: draft.onTheClock,
      teams: teams.map(t => ({
        teamId: t.teamId,
        teamName: t.name,
        abbreviation: t.abbreviation,
        draftPosition: t.draftPosition,
      })),
      rounds,
      skipQueue: draft.skipQueue,
      lastUpdated: draft.updatedAt,
    };

    res.json(grid);
  } catch (error: any) {
    console.error('Error getting grid:', error);
    res.status(500).json({ error: 'Failed to get grid', message: error.message });
  }
});

// Get available players for draft
router.get('/:draftId/available', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { draftId } = req.params;
    const { position, limit = 100 } = req.query;

    const draft = await DraftModel.getDraft(draftId);
    if (!draft) {
      res.status(404).json({ error: 'Draft not found' });
      return;
    }

    const picks = await DraftModel.getDraftPicks(draftId);
    const draftedPlayerIds = new Set(picks.map(p => p.playerId));

    // Get all players
    const result = await PlayerModel.getPlayers({
      position: position as string,
      limit: 500
    });

    // Filter out drafted players
    const available = result.items.filter(p => !draftedPlayerIds.has(p.playerId));

    res.json({
      items: available.slice(0, parseInt(limit as string)),
      count: available.length,
      draftedCount: picks.length,
    });
  } catch (error: any) {
    console.error('Error getting available players:', error);
    res.status(500).json({ error: 'Failed to get available players', message: error.message });
  }
});

export default router;
