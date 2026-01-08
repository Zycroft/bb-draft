import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { authMiddleware } from '../middleware/auth';
import * as TeamModel from '../models/Team';
import * as LeagueModel from '../models/League';
import { Team } from '../types';

const router = Router();

// Create team in a league
router.post('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId, name, abbreviation } = req.body;

    if (!leagueId || !name) {
      res.status(400).json({ error: 'League ID and team name are required' });
      return;
    }

    // Verify league exists
    const league = await LeagueModel.getLeague(leagueId);
    if (!league) {
      res.status(404).json({ error: 'League not found' });
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

    const teamId = `tm_${uuidv4().slice(0, 8)}`;
    const now = new Date().toISOString();

    const team: Team = {
      teamId,
      leagueId,
      ownerId: req.user!.uid,
      name,
      abbreviation,
      createdAt: now,
      updatedAt: now,
      roster: [],
      draftQueue: [],
    };

    await TeamModel.putTeam(team);
    res.status(201).json(team);
  } catch (error: any) {
    console.error('Error creating team:', error);
    res.status(500).json({ error: 'Failed to create team', message: error.message });
  }
});

// Get team by ID
router.get('/:teamId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { teamId } = req.params;
    const team = await TeamModel.getTeam(teamId);

    if (!team) {
      res.status(404).json({ error: 'Team not found' });
      return;
    }

    res.json(team);
  } catch (error: any) {
    console.error('Error getting team:', error);
    res.status(500).json({ error: 'Failed to get team', message: error.message });
  }
});

// Update team (owner only)
router.put('/:teamId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { teamId } = req.params;
    const team = await TeamModel.getTeam(teamId);

    if (!team) {
      res.status(404).json({ error: 'Team not found' });
      return;
    }

    if (team.ownerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only team owner can update team' });
      return;
    }

    const { name, abbreviation } = req.body;

    const updatedTeam: Team = {
      ...team,
      name: name || team.name,
      abbreviation: abbreviation || team.abbreviation,
      updatedAt: new Date().toISOString(),
    };

    await TeamModel.putTeam(updatedTeam);
    res.json(updatedTeam);
  } catch (error: any) {
    console.error('Error updating team:', error);
    res.status(500).json({ error: 'Failed to update team', message: error.message });
  }
});

// Get team roster
router.get('/:teamId/roster', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { teamId } = req.params;
    const team = await TeamModel.getTeam(teamId);

    if (!team) {
      res.status(404).json({ error: 'Team not found' });
      return;
    }

    res.json(team.roster);
  } catch (error: any) {
    console.error('Error getting roster:', error);
    res.status(500).json({ error: 'Failed to get roster', message: error.message });
  }
});

// Update draft queue (owner only)
router.put('/:teamId/queue', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { teamId } = req.params;
    const { queue } = req.body;

    if (!Array.isArray(queue)) {
      res.status(400).json({ error: 'Queue must be an array of player IDs' });
      return;
    }

    const team = await TeamModel.getTeam(teamId);

    if (!team) {
      res.status(404).json({ error: 'Team not found' });
      return;
    }

    if (team.ownerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only team owner can update draft queue' });
      return;
    }

    const updatedTeam: Team = {
      ...team,
      draftQueue: queue,
      updatedAt: new Date().toISOString(),
    };

    await TeamModel.putTeam(updatedTeam);
    res.json({ queue: updatedTeam.draftQueue });
  } catch (error: any) {
    console.error('Error updating queue:', error);
    res.status(500).json({ error: 'Failed to update queue', message: error.message });
  }
});

// Delete team (owner or commissioner only)
router.delete('/:teamId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { teamId } = req.params;
    const team = await TeamModel.getTeam(teamId);

    if (!team) {
      res.status(404).json({ error: 'Team not found' });
      return;
    }

    // Check if user is owner or commissioner
    const league = await LeagueModel.getLeague(team.leagueId);
    const isOwner = team.ownerId === req.user!.uid;
    const isCommissioner = league?.commissionerId === req.user!.uid;

    if (!isOwner && !isCommissioner) {
      res.status(403).json({ error: 'Only team owner or commissioner can delete team' });
      return;
    }

    // Cannot delete team after draft started
    if (league && league.status !== 'pre_draft') {
      res.status(400).json({ error: 'Cannot delete team after draft has started' });
      return;
    }

    await TeamModel.deleteTeam(teamId);
    res.json({ message: 'Team deleted' });
  } catch (error: any) {
    console.error('Error deleting team:', error);
    res.status(500).json({ error: 'Failed to delete team', message: error.message });
  }
});

export default router;
