import { Server, Socket } from 'socket.io';
import * as DraftModel from '../models/Draft';
import * as TeamModel from '../models/Team';
import * as PlayerModel from '../models/Player';
import { getTeamForPick } from '../utils/draftOrder';
import { Draft, DraftPick, Team } from '../types';

interface AuthenticatedSocket extends Socket {
  userId?: string;
}

interface DraftRoom {
  draftId: string;
  connectedUsers: Map<string, { teamId: string; socketId: string }>;
  timerInterval?: NodeJS.Timeout;
}

const draftRooms = new Map<string, DraftRoom>();

export function setupDraftRoom(io: Server, socket: AuthenticatedSocket): void {
  // Join draft room
  socket.on('draft:join', async (data: { draftId: string; teamId: string }) => {
    const { draftId, teamId } = data;

    try {
      const draft = await DraftModel.getDraft(draftId);
      if (!draft) {
        socket.emit('draft:error', { code: 'NOT_FOUND', message: 'Draft not found' });
        return;
      }

      // Verify user owns the team
      const team = await TeamModel.getTeam(teamId);
      if (!team || team.ownerId !== socket.userId) {
        socket.emit('draft:error', { code: 'UNAUTHORIZED', message: 'You do not own this team' });
        return;
      }

      // Join Socket.IO room
      socket.join(draftId);

      // Track connected user
      if (!draftRooms.has(draftId)) {
        draftRooms.set(draftId, {
          draftId,
          connectedUsers: new Map(),
        });
      }

      const room = draftRooms.get(draftId)!;
      room.connectedUsers.set(socket.userId!, { teamId, socketId: socket.id });

      // Get picks and teams
      const picks = await DraftModel.getDraftPicks(draftId);
      const teams = await TeamModel.getTeamsByLeague(draft.leagueId);

      // Calculate time remaining if draft is in progress
      let timeRemaining = 0;
      if (draft.onTheClock && draft.status === 'in_progress') {
        const expires = new Date(draft.onTheClock.clockExpires).getTime();
        timeRemaining = Math.max(0, Math.round((expires - Date.now()) / 1000));
      }

      // Send current state
      socket.emit('draft:state', {
        draft,
        picks,
        teams: teams.map((t) => ({
          teamId: t.teamId,
          name: t.name,
          ownerId: t.ownerId,
          draftPosition: t.draftPosition,
        })),
        timeRemaining,
        connectedUsers: Array.from(room.connectedUsers.entries()).map(([userId, data]) => ({
          userId,
          teamId: data.teamId,
        })),
      });

      // Notify others
      socket.to(draftId).emit('draft:user_connected', {
        userId: socket.userId,
        teamId,
      });

      // Start timer broadcast if draft is in progress and not already running
      if (draft.status === 'in_progress' && !room.timerInterval) {
        startTimerBroadcast(io, draftId, draft);
      }

      console.log(`User ${socket.userId} joined draft ${draftId} as team ${teamId}`);
    } catch (error) {
      console.error('Error joining draft:', error);
      socket.emit('draft:error', { code: 'ERROR', message: 'Failed to join draft' });
    }
  });

  // Leave draft room
  socket.on('draft:leave', (data: { draftId: string }) => {
    const { draftId } = data;
    handleLeave(io, socket, draftId);
  });

  // Make pick via socket
  socket.on('draft:pick', async (data: { draftId: string; teamId: string; playerId: string }) => {
    const { draftId, teamId, playerId } = data;

    try {
      const draft = await DraftModel.getDraft(draftId);
      if (!draft || draft.status !== 'in_progress') {
        socket.emit('draft:error', { code: 'INVALID_STATE', message: 'Draft is not in progress' });
        return;
      }

      // Verify turn
      const { teamId: expectedTeamId } = getTeamForPick(
        draft.currentOverallPick,
        draft.teamCount,
        draft.draftOrder,
        draft.format
      );

      if (teamId !== expectedTeamId) {
        socket.emit('draft:error', { code: 'NOT_YOUR_TURN', message: 'Not your turn to pick' });
        return;
      }

      // Verify ownership
      const team = await TeamModel.getTeam(teamId);
      if (!team || team.ownerId !== socket.userId) {
        socket.emit('draft:error', { code: 'UNAUTHORIZED', message: 'You do not own this team' });
        return;
      }

      // Make the pick
      const result = await makePick(io, draft, team, playerId, false);

      if (!result.success) {
        socket.emit('draft:error', { code: 'PICK_FAILED', message: result.error });
      }
    } catch (error) {
      console.error('Error making pick via socket:', error);
      socket.emit('draft:error', { code: 'ERROR', message: 'Failed to make pick' });
    }
  });

  // Update draft queue
  socket.on('draft:queue_update', async (data: { draftId: string; teamId: string; queue: string[] }) => {
    const { draftId, teamId, queue } = data;

    try {
      const team = await TeamModel.getTeam(teamId);
      if (!team || team.ownerId !== socket.userId) {
        socket.emit('draft:error', { code: 'UNAUTHORIZED', message: 'You do not own this team' });
        return;
      }

      const updatedTeam: Team = {
        ...team,
        draftQueue: queue,
        updatedAt: new Date().toISOString(),
      };

      await TeamModel.putTeam(updatedTeam);

      socket.emit('draft:queue_updated', { queue });
    } catch (error) {
      console.error('Error updating queue:', error);
      socket.emit('draft:error', { code: 'ERROR', message: 'Failed to update queue' });
    }
  });

  // Chat message
  socket.on('draft:chat', (data: { draftId: string; message: string }) => {
    const { draftId, message } = data;

    io.to(draftId).emit('draft:chat_message', {
      userId: socket.userId,
      message,
      timestamp: new Date().toISOString(),
    });
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    // Remove from all draft rooms
    for (const [draftId, room] of draftRooms.entries()) {
      if (room.connectedUsers.has(socket.userId!)) {
        handleLeave(io, socket, draftId);
      }
    }
  });
}

function handleLeave(io: Server, socket: AuthenticatedSocket, draftId: string): void {
  socket.leave(draftId);

  const room = draftRooms.get(draftId);
  if (room) {
    const userData = room.connectedUsers.get(socket.userId!);
    room.connectedUsers.delete(socket.userId!);

    if (userData) {
      io.to(draftId).emit('draft:user_disconnected', {
        userId: socket.userId,
        teamId: userData.teamId,
      });
    }

    // Stop timer if no one is connected
    if (room.connectedUsers.size === 0 && room.timerInterval) {
      clearInterval(room.timerInterval);
      room.timerInterval = undefined;
    }
  }

  console.log(`User ${socket.userId} left draft ${draftId}`);
}

function startTimerBroadcast(io: Server, draftId: string, draft: Draft): void {
  const room = draftRooms.get(draftId);
  if (!room) return;

  room.timerInterval = setInterval(async () => {
    // Refresh draft state
    const currentDraft = await DraftModel.getDraft(draftId);
    if (!currentDraft || currentDraft.status !== 'in_progress' || !currentDraft.onTheClock) {
      if (room.timerInterval) {
        clearInterval(room.timerInterval);
        room.timerInterval = undefined;
      }
      return;
    }

    const expires = new Date(currentDraft.onTheClock.clockExpires).getTime();
    const timeRemaining = Math.max(0, Math.round((expires - Date.now()) / 1000));

    io.to(draftId).emit('draft:clock_tick', {
      timeRemaining,
      onTheClock: currentDraft.onTheClock,
    });

    // Auto-pick if time expired
    if (timeRemaining <= 0) {
      await handleAutoPick(io, currentDraft);
    }
  }, 1000);
}

async function handleAutoPick(io: Server, draft: Draft): Promise<void> {
  if (!draft.onTheClock) return;

  const teamId = draft.onTheClock.teamId;
  const team = await TeamModel.getTeam(teamId);
  if (!team) return;

  // Check if auto-pick is enabled, otherwise skip
  const autoPickEnabled = draft.configuration?.autoPickOnTimeout ?? true;

  if (!autoPickEnabled) {
    // Skip this pick instead of auto-picking
    await handleSkip(io, draft, teamId, 'timer_expired');
    return;
  }

  // Get available players
  const picks = await DraftModel.getDraftPicks(draft.draftId);
  const draftedPlayerIds = new Set(picks.map((p) => p.playerId));

  // Try to pick from queue first
  let playerId: string | null = null;
  let wasFromQueue = false;
  let queuePosition: number | undefined;

  for (let i = 0; i < team.draftQueue.length; i++) {
    if (!draftedPlayerIds.has(team.draftQueue[i])) {
      playerId = team.draftQueue[i];
      wasFromQueue = true;
      queuePosition = i + 1;
      break;
    }
  }

  // If no queue or all queued players taken, pick best available
  if (!playerId) {
    const allPlayers = await PlayerModel.getPlayers({ limit: 500 });
    const available = allPlayers.items.filter((p) => !draftedPlayerIds.has(p.playerId));
    if (available.length > 0) {
      playerId = available[0].playerId;
    }
  }

  if (playerId) {
    await makePick(io, draft, team, playerId, true, wasFromQueue, queuePosition);
  }
}

async function handleSkip(io: Server, draft: Draft, teamId: string, reason: 'timer_expired' | 'disconnected' | 'manual'): Promise<void> {
  const now = new Date();
  const { v4: uuidv4 } = await import('uuid');

  // Create skip entry
  const skip = {
    skipId: `skip_${uuidv4().slice(0, 8)}`,
    draftId: draft.draftId,
    teamId,
    round: draft.currentRound,
    pickInRound: draft.currentPick,
    overallPick: draft.currentOverallPick,
    skippedAt: now.toISOString(),
    reason,
    originalDeadline: draft.onTheClock?.clockExpires || now.toISOString(),
    catchUpEligible: draft.configuration?.catchUpEnabled ?? true,
    catchUpDeadline: draft.configuration?.catchUpEnabled
      ? new Date(now.getTime() + (draft.configuration?.catchUpWindow || 30) * 60 * 1000).toISOString()
      : undefined,
    catchUpStatus: (draft.configuration?.catchUpEnabled ? 'available' : 'forfeited') as 'pending' | 'available' | 'completed' | 'forfeited',
  };

  // Update skip queue and statistics
  const updatedSkipQueue = [...(draft.skipQueue || []), skip];
  const updatedStats = {
    ...draft.statistics,
    skipCount: (draft.statistics?.skipCount || 0) + 1,
  };

  // Advance to next pick
  const nextOverallPick = draft.currentOverallPick + 1;
  const totalPicks = draft.teamCount * draft.totalRounds;

  if (nextOverallPick > totalPicks) {
    // Draft complete (all remaining picks were skipped)
    const completedDraft = {
      ...draft,
      status: 'completed' as const,
      currentOverallPick: nextOverallPick,
      onTheClock: undefined,
      skipQueue: updatedSkipQueue,
      statistics: updatedStats,
      completedAt: now.toISOString(),
      updatedAt: now.toISOString(),
    };
    await DraftModel.putDraft(completedDraft);

    io.to(draft.draftId).emit('draft:skip', { skip });
    io.to(draft.draftId).emit('draft:completed', { draftId: draft.draftId });
    return;
  }

  // Set up next pick
  const { getTeamForPick } = await import('../utils/draftOrder');
  const nextPick = getTeamForPick(nextOverallPick, draft.teamCount, draft.draftOrder, draft.format);
  const clockExpires = new Date(now.getTime() + draft.pickTimer * 1000);

  const updatedDraft = {
    ...draft,
    currentOverallPick: nextOverallPick,
    currentRound: nextPick.round,
    currentPick: nextPick.pickInRound,
    onTheClock: {
      teamId: nextPick.teamId,
      clockStarted: now.toISOString(),
      clockExpires: clockExpires.toISOString(),
    },
    skipQueue: updatedSkipQueue,
    statistics: updatedStats,
    updatedAt: now.toISOString(),
  };

  await DraftModel.putDraft(updatedDraft);

  // Broadcast skip
  io.to(draft.draftId).emit('draft:skip', {
    skip,
    nextPick: {
      teamId: nextPick.teamId,
      round: nextPick.round,
      pickInRound: nextPick.pickInRound,
      overallPick: nextOverallPick,
    },
    timeRemaining: draft.pickTimer,
  });

  // Notify team that catch-up is available
  if (skip.catchUpEligible) {
    io.to(draft.draftId).emit('draft:catch_up_available', {
      teamId,
      skip,
    });
  }
}

async function makePick(
  io: Server,
  draft: Draft,
  team: Team,
  playerId: string,
  wasAutoPick: boolean,
  wasFromQueue: boolean = false,
  queuePosition?: number
): Promise<{ success: boolean; error?: string }> {
  // Verify player not already drafted
  const alreadyDrafted = await DraftModel.isPlayerDrafted(draft.draftId, playerId);
  if (alreadyDrafted) {
    return { success: false, error: 'Player has already been drafted' };
  }

  // Get player info
  const player = await PlayerModel.getPlayer(playerId);
  if (!player) {
    return { success: false, error: 'Player not found' };
  }

  const now = new Date();
  const pickDuration = draft.onTheClock
    ? Math.round((now.getTime() - new Date(draft.onTheClock.clockStarted).getTime()) / 1000)
    : 0;

  // Create pick
  const pick: DraftPick = {
    draftId: draft.draftId,
    overallPick: draft.currentOverallPick,
    round: draft.currentRound,
    pickInRound: draft.currentPick,
    teamId: team.teamId,
    playerId,
    playerName: player.fullName,
    position: player.primaryPosition,
    mlbTeam: player.mlbTeam,
    timestamp: now.toISOString(),
    pickDuration,
    wasAutoPick,
    wasCatchUp: false,
    wasFromQueue,
    queuePosition,
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

    io.to(draft.draftId).emit('draft:pick_made', {
      pick,
      nextPick: null,
      timeRemaining: 0,
    });

    io.to(draft.draftId).emit('draft:completed', {
      draftId: draft.draftId,
    });

    // Clean up room
    const room = draftRooms.get(draft.draftId);
    if (room?.timerInterval) {
      clearInterval(room.timerInterval);
    }

    return { success: true };
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

  // Broadcast pick
  io.to(draft.draftId).emit('draft:pick_made', {
    pick,
    nextPick: {
      teamId: nextPick.teamId,
      round: nextPick.round,
      pickInRound: nextPick.pickInRound,
      overallPick: nextOverallPick,
    },
    timeRemaining: draft.pickTimer,
  });

  if (wasAutoPick) {
    io.to(draft.draftId).emit('draft:auto_pick', {
      pick,
      reason: 'Timer expired',
    });
  }

  return { success: true };
}
