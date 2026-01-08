import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { authMiddleware } from '../middleware/auth';
import * as LeagueModel from '../models/League';
import * as TeamModel from '../models/Team';
import { generateInviteCode } from '../utils/inviteCode';
import { League, LeagueSettings, Team, DraftOrder, DraftOrderEntry } from '../types';

const router = Router();

const DEFAULT_ROSTER: LeagueSettings['roster'] = {
  C: 1,
  '1B': 1,
  '2B': 1,
  '3B': 1,
  SS: 1,
  OF: 3,
  UTIL: 1,
  SP: 2,
  RP: 2,
  BN: 5,
};

// Create new league
router.post('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { name, maxTeams = 12, draftFormat = 'serpentine', pickTimer = 90, rounds = 23 } = req.body;

    if (!name) {
      res.status(400).json({ error: 'League name is required' });
      return;
    }

    const leagueId = `lg_${uuidv4().slice(0, 8)}`;
    const now = new Date().toISOString();

    const league: League = {
      leagueId,
      name,
      commissionerId: req.user!.uid,
      inviteCode: generateInviteCode(),
      status: 'pre_draft',
      settings: {
        maxTeams,
        draftFormat,
        scoringType: 'head_to_head',
        pickTimer,
        rounds,
        tradePicksEnabled: true,
        roster: DEFAULT_ROSTER,
      },
      season: new Date().getFullYear(),
      createdAt: now,
      updatedAt: now,
    };

    await LeagueModel.putLeague(league);
    res.status(201).json(league);
  } catch (error: any) {
    console.error('Error creating league:', error);
    res.status(500).json({ error: 'Failed to create league', message: error.message });
  }
});

// Get user's leagues (as commissioner or team owner)
router.get('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.uid;

    // Get leagues where user is commissioner
    const commissionerLeagues = await LeagueModel.getLeaguesByCommissioner(userId);

    // Get leagues where user has a team
    const userTeams = await TeamModel.getTeamsByOwner(userId);
    const teamLeagueIds = new Set(userTeams.map((t) => t.leagueId));

    // Fetch those leagues
    const teamLeagues: League[] = [];
    for (const leagueId of teamLeagueIds) {
      if (!commissionerLeagues.find((l) => l.leagueId === leagueId)) {
        const league = await LeagueModel.getLeague(leagueId);
        if (league) teamLeagues.push(league);
      }
    }

    // Combine and dedupe
    const allLeagues = [...commissionerLeagues, ...teamLeagues];

    res.json(allLeagues);
  } catch (error: any) {
    console.error('Error getting leagues:', error);
    res.status(500).json({ error: 'Failed to get leagues', message: error.message });
  }
});

// Get league by ID
router.get('/:leagueId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    // Get teams in league
    const teams = await TeamModel.getTeamsByLeague(leagueId);

    res.json({ ...league, teams, teamCount: teams.length });
  } catch (error: any) {
    console.error('Error getting league:', error);
    res.status(500).json({ error: 'Failed to get league', message: error.message });
  }
});

// Update league settings (commissioner only)
router.put('/:leagueId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can update league settings' });
      return;
    }

    if (league.status !== 'pre_draft') {
      res.status(400).json({ error: 'Cannot modify league after draft has started' });
      return;
    }

    const { name, settings } = req.body;

    const updatedLeague: League = {
      ...league,
      name: name || league.name,
      settings: { ...league.settings, ...settings },
      updatedAt: new Date().toISOString(),
    };

    await LeagueModel.putLeague(updatedLeague);
    res.json(updatedLeague);
  } catch (error: any) {
    console.error('Error updating league:', error);
    res.status(500).json({ error: 'Failed to update league', message: error.message });
  }
});

// Join league via invite code
router.post('/:leagueId/join', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const { inviteCode, teamName } = req.body;

    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.inviteCode !== inviteCode) {
      res.status(400).json({ error: 'Invalid invite code' });
      return;
    }

    // Check if user already has a team in this league
    const existingTeam = await TeamModel.getTeamByOwnerAndLeague(req.user!.uid, leagueId);
    if (existingTeam) {
      res.status(400).json({ error: 'You already have a team in this league' });
      return;
    }

    // Check if league is full
    const teams = await TeamModel.getTeamsByLeague(leagueId);
    if (teams.length >= league.settings.maxTeams) {
      res.status(400).json({ error: 'League is full' });
      return;
    }

    // Create team
    const teamId = `tm_${uuidv4().slice(0, 8)}`;
    const now = new Date().toISOString();

    const team: Team = {
      teamId,
      leagueId,
      ownerId: req.user!.uid,
      name: teamName || `Team ${teams.length + 1}`,
      createdAt: now,
      updatedAt: now,
      roster: [],
      draftQueue: [],
    };

    await TeamModel.putTeam(team);
    res.status(201).json({ league, team });
  } catch (error: any) {
    console.error('Error joining league:', error);
    res.status(500).json({ error: 'Failed to join league', message: error.message });
  }
});

// Join league by invite code (alternative endpoint)
router.post('/join', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { inviteCode, teamName } = req.body;

    if (!inviteCode) {
      res.status(400).json({ error: 'Invite code is required' });
      return;
    }

    const league = await LeagueModel.getLeagueByInviteCode(inviteCode);

    if (!league) {
      res.status(404).json({ error: 'Invalid invite code' });
      return;
    }

    // Check if user already has a team in this league
    const existingTeam = await TeamModel.getTeamByOwnerAndLeague(req.user!.uid, league.leagueId);
    if (existingTeam) {
      res.status(400).json({ error: 'You already have a team in this league' });
      return;
    }

    // Check if league is full
    const teams = await TeamModel.getTeamsByLeague(league.leagueId);
    if (teams.length >= league.settings.maxTeams) {
      res.status(400).json({ error: 'League is full' });
      return;
    }

    // Create team
    const teamId = `tm_${uuidv4().slice(0, 8)}`;
    const now = new Date().toISOString();

    const team: Team = {
      teamId,
      leagueId: league.leagueId,
      ownerId: req.user!.uid,
      name: teamName || `Team ${teams.length + 1}`,
      createdAt: now,
      updatedAt: now,
      roster: [],
      draftQueue: [],
    };

    await TeamModel.putTeam(team);
    res.status(201).json({ league, team });
  } catch (error: any) {
    console.error('Error joining league:', error);
    res.status(500).json({ error: 'Failed to join league', message: error.message });
  }
});

// Regenerate invite code (commissioner only)
router.post('/:leagueId/regenerate-code', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can regenerate invite code' });
      return;
    }

    const updatedLeague: League = {
      ...league,
      inviteCode: generateInviteCode(),
      updatedAt: new Date().toISOString(),
    };

    await LeagueModel.putLeague(updatedLeague);
    res.json({ inviteCode: updatedLeague.inviteCode });
  } catch (error: any) {
    console.error('Error regenerating invite code:', error);
    res.status(500).json({ error: 'Failed to regenerate invite code', message: error.message });
  }
});

// Delete league (commissioner only)
router.delete('/:leagueId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can delete league' });
      return;
    }

    if (league.status !== 'pre_draft') {
      res.status(400).json({ error: 'Cannot delete league after draft has started' });
      return;
    }

    // Delete all teams in league
    const teams = await TeamModel.getTeamsByLeague(leagueId);
    for (const team of teams) {
      await TeamModel.deleteTeam(team.teamId);
    }

    await LeagueModel.deleteLeague(leagueId);
    res.json({ message: 'League deleted' });
  } catch (error: any) {
    console.error('Error deleting league:', error);
    res.status(500).json({ error: 'Failed to delete league', message: error.message });
  }
});

// ============================================
// Draft Order Management
// ============================================

// Get draft order
router.get('/:leagueId/draft-order', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    const teams = await TeamModel.getTeamsByLeague(leagueId);

    // Build draft order from teams' draftPosition
    const order: DraftOrderEntry[] = teams
      .filter((t) => t.draftPosition !== undefined)
      .sort((a, b) => (a.draftPosition || 0) - (b.draftPosition || 0))
      .map((t) => ({
        position: t.draftPosition!,
        teamId: t.teamId,
        teamName: t.name,
      }));

    // If no positions set yet, create default order by join date
    if (order.length === 0) {
      teams
        .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime())
        .forEach((t, idx) => {
          order.push({
            position: idx + 1,
            teamId: t.teamId,
            teamName: t.name,
          });
        });
    }

    const draftOrder: DraftOrder = {
      leagueId,
      seasonYear: league.season,
      orderMethod: 'manual',
      serpentine: league.settings.draftFormat === 'serpentine',
      order,
      lastModified: league.updatedAt,
      modifiedBy: league.commissionerId,
      status: league.status === 'pre_draft' ? 'unlocked' : 'locked',
    };

    res.json(draftOrder);
  } catch (error: any) {
    console.error('Error getting draft order:', error);
    res.status(500).json({ error: 'Failed to get draft order', message: error.message });
  }
});

// Set draft order manually (commissioner only)
router.put('/:leagueId/draft-order', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const { order } = req.body;

    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can set draft order' });
      return;
    }

    if (league.status !== 'pre_draft') {
      res.status(400).json({ error: 'Cannot modify draft order after draft has started' });
      return;
    }

    if (!order || !Array.isArray(order)) {
      res.status(400).json({ error: 'Order array is required' });
      return;
    }

    // Update each team's draft position
    for (const entry of order) {
      const team = await TeamModel.getTeam(entry.teamId);
      if (team && team.leagueId === leagueId) {
        await TeamModel.putTeam({
          ...team,
          draftPosition: entry.position,
          updatedAt: new Date().toISOString(),
        });
      }
    }

    res.json({ message: 'Draft order updated', order });
  } catch (error: any) {
    console.error('Error setting draft order:', error);
    res.status(500).json({ error: 'Failed to set draft order', message: error.message });
  }
});

// Randomize draft order (commissioner only)
router.post('/:leagueId/draft-order/randomize', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can randomize draft order' });
      return;
    }

    if (league.status !== 'pre_draft') {
      res.status(400).json({ error: 'Cannot randomize draft order after draft has started' });
      return;
    }

    const teams = await TeamModel.getTeamsByLeague(leagueId);

    // Fisher-Yates shuffle
    const shuffled = [...teams];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }

    // Update positions
    const order: DraftOrderEntry[] = [];
    for (let i = 0; i < shuffled.length; i++) {
      const team = shuffled[i];
      await TeamModel.putTeam({
        ...team,
        draftPosition: i + 1,
        updatedAt: new Date().toISOString(),
      });
      order.push({
        position: i + 1,
        teamId: team.teamId,
        teamName: team.name,
      });
    }

    res.json({ message: 'Draft order randomized', order });
  } catch (error: any) {
    console.error('Error randomizing draft order:', error);
    res.status(500).json({ error: 'Failed to randomize draft order', message: error.message });
  }
});

// Swap two teams in draft order (commissioner only)
router.post('/:leagueId/draft-order/swap', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const { teamId1, teamId2 } = req.body;

    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can swap draft positions' });
      return;
    }

    if (league.status !== 'pre_draft') {
      res.status(400).json({ error: 'Cannot swap draft positions after draft has started' });
      return;
    }

    const team1 = await TeamModel.getTeam(teamId1);
    const team2 = await TeamModel.getTeam(teamId2);

    if (!team1 || !team2 || team1.leagueId !== leagueId || team2.leagueId !== leagueId) {
      res.status(400).json({ error: 'Invalid team IDs' });
      return;
    }

    const pos1 = team1.draftPosition;
    const pos2 = team2.draftPosition;

    await TeamModel.putTeam({
      ...team1,
      draftPosition: pos2,
      updatedAt: new Date().toISOString(),
    });

    await TeamModel.putTeam({
      ...team2,
      draftPosition: pos1,
      updatedAt: new Date().toISOString(),
    });

    res.json({
      message: 'Draft positions swapped',
      team1: { teamId: teamId1, newPosition: pos2 },
      team2: { teamId: teamId2, newPosition: pos1 },
    });
  } catch (error: any) {
    console.error('Error swapping draft positions:', error);
    res.status(500).json({ error: 'Failed to swap draft positions', message: error.message });
  }
});

// ============================================
// Team Management (Commissioner)
// ============================================

// Get all teams in league with details
router.get('/:leagueId/teams', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    const teams = await TeamModel.getTeamsByLeague(leagueId);

    // Sort by draft position if set
    teams.sort((a, b) => (a.draftPosition || 999) - (b.draftPosition || 999));

    res.json(teams);
  } catch (error: any) {
    console.error('Error getting teams:', error);
    res.status(500).json({ error: 'Failed to get teams', message: error.message });
  }
});

// Remove team from league (commissioner only)
router.delete('/:leagueId/teams/:teamId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId, teamId } = req.params;
    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can remove teams' });
      return;
    }

    if (league.status !== 'pre_draft') {
      res.status(400).json({ error: 'Cannot remove teams after draft has started' });
      return;
    }

    const team = await TeamModel.getTeam(teamId);
    if (!team || team.leagueId !== leagueId) {
      res.status(404).json({ error: 'Team not found in this league' });
      return;
    }

    await TeamModel.deleteTeam(teamId);
    res.json({ message: 'Team removed from league' });
  } catch (error: any) {
    console.error('Error removing team:', error);
    res.status(500).json({ error: 'Failed to remove team', message: error.message });
  }
});

// Transfer team ownership (commissioner only)
router.post('/:leagueId/teams/:teamId/transfer', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId, teamId } = req.params;
    const { newOwnerId } = req.body;

    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can transfer team ownership' });
      return;
    }

    if (!newOwnerId) {
      res.status(400).json({ error: 'New owner ID is required' });
      return;
    }

    const team = await TeamModel.getTeam(teamId);
    if (!team || team.leagueId !== leagueId) {
      res.status(404).json({ error: 'Team not found in this league' });
      return;
    }

    // Check if new owner already has a team
    const existingTeam = await TeamModel.getTeamByOwnerAndLeague(newOwnerId, leagueId);
    if (existingTeam) {
      res.status(400).json({ error: 'New owner already has a team in this league' });
      return;
    }

    await TeamModel.putTeam({
      ...team,
      ownerId: newOwnerId,
      updatedAt: new Date().toISOString(),
    });

    res.json({ message: 'Team ownership transferred', teamId, newOwnerId });
  } catch (error: any) {
    console.error('Error transferring team:', error);
    res.status(500).json({ error: 'Failed to transfer team', message: error.message });
  }
});

// ============================================
// League Announcements
// ============================================

// Send league announcement (commissioner only)
router.post('/:leagueId/announcements', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const { title, message } = req.body;

    const league = await LeagueModel.getLeague(leagueId);

    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can send announcements' });
      return;
    }

    if (!message) {
      res.status(400).json({ error: 'Message is required' });
      return;
    }

    const announcement = {
      announcementId: `ann_${uuidv4().slice(0, 8)}`,
      leagueId,
      title: title || 'League Announcement',
      message,
      createdAt: new Date().toISOString(),
      createdBy: req.user!.uid,
    };

    // In a real implementation, this would be stored and trigger notifications
    // For now, just return success
    res.status(201).json(announcement);
  } catch (error: any) {
    console.error('Error sending announcement:', error);
    res.status(500).json({ error: 'Failed to send announcement', message: error.message });
  }
});

export default router;
