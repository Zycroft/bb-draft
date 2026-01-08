import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { authMiddleware } from '../middleware/auth';
import * as LeagueModel from '../models/League';
import * as TeamModel from '../models/Team';
import { Trade, TradeAsset, TradeStatus } from '../types';
import { docClient, TABLES } from '../config/database';
import { PutCommand, GetCommand, QueryCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const router = Router();

// Helper to get trade by ID
async function getTrade(tradeId: string): Promise<Trade | null> {
  try {
    const result = await docClient.send(
      new GetCommand({
        TableName: TABLES.TRADES,
        Key: { tradeId },
      })
    );
    return (result.Item as Trade) || null;
  } catch {
    return null;
  }
}

// Helper to save trade
async function putTrade(trade: Trade): Promise<void> {
  await docClient.send(
    new PutCommand({
      TableName: TABLES.TRADES,
      Item: trade,
    })
  );
}

// Helper to get trades by league
async function getTradesByLeague(leagueId: string): Promise<Trade[]> {
  try {
    const result = await docClient.send(
      new QueryCommand({
        TableName: TABLES.TRADES,
        IndexName: 'leagueId-index',
        KeyConditionExpression: 'leagueId = :leagueId',
        ExpressionAttributeValues: { ':leagueId': leagueId },
      })
    );
    return (result.Items as Trade[]) || [];
  } catch {
    return [];
  }
}

// Propose a new trade
router.post('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId, receivingTeamId, sending, receiving } = req.body;

    // Validate required fields
    if (!leagueId || !receivingTeamId || !sending || !receiving) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }

    const league = await LeagueModel.getLeague(leagueId);
    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    // Check if trading is enabled
    if (!league.settings.tradePicksEnabled) {
      res.status(400).json({ error: 'Trading is not enabled in this league' });
      return;
    }

    // Get proposing team (user's team in this league)
    const proposingTeam = await TeamModel.getTeamByOwnerAndLeague(req.user!.uid, leagueId);
    if (!proposingTeam) {
      res.status(403).json({ error: 'You do not have a team in this league' });
      return;
    }

    // Validate receiving team
    const receivingTeam = await TeamModel.getTeam(receivingTeamId);
    if (!receivingTeam || receivingTeam.leagueId !== leagueId) {
      res.status(404).json({ error: 'Receiving team not found in this league' });
      return;
    }

    if (receivingTeam.teamId === proposingTeam.teamId) {
      res.status(400).json({ error: 'Cannot trade with yourself' });
      return;
    }

    // Create the trade
    const tradeId = `tr_${uuidv4().slice(0, 8)}`;
    const now = new Date().toISOString();

    const trade: Trade = {
      tradeId,
      leagueId,
      status: 'pending',
      proposedAt: now,
      proposingTeam: {
        teamId: proposingTeam.teamId,
        teamName: proposingTeam.name,
        accepted: true, // Proposer auto-accepts
        sending: sending as TradeAsset[],
        receiving: receiving as TradeAsset[],
      },
      receivingTeam: {
        teamId: receivingTeam.teamId,
        teamName: receivingTeam.name,
        accepted: false,
        sending: receiving as TradeAsset[], // Mirror - what they send is what proposer receives
        receiving: sending as TradeAsset[],
      },
      // Trade expires in 48 hours
      expiresAt: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
    };

    await putTrade(trade);
    res.status(201).json(trade);
  } catch (error: any) {
    console.error('Error creating trade:', error);
    res.status(500).json({ error: 'Failed to create trade', message: error.message });
  }
});

// Get trades for a league
router.get('/league/:leagueId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;
    const { status } = req.query;

    const league = await LeagueModel.getLeague(leagueId);
    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    let trades = await getTradesByLeague(leagueId);

    // Filter by status if provided
    if (status) {
      trades = trades.filter((t) => t.status === status);
    }

    // Sort by most recent first
    trades.sort((a, b) => new Date(b.proposedAt).getTime() - new Date(a.proposedAt).getTime());

    res.json(trades);
  } catch (error: any) {
    console.error('Error getting trades:', error);
    res.status(500).json({ error: 'Failed to get trades', message: error.message });
  }
});

// Get trades involving user's team
router.get('/my-trades/:leagueId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { leagueId } = req.params;

    const team = await TeamModel.getTeamByOwnerAndLeague(req.user!.uid, leagueId);
    if (!team) {
      res.status(404).json({ error: 'You do not have a team in this league' });
      return;
    }

    const allTrades = await getTradesByLeague(leagueId);

    // Filter to trades involving user's team
    const myTrades = allTrades.filter(
      (t) => t.proposingTeam.teamId === team.teamId || t.receivingTeam.teamId === team.teamId
    );

    // Sort by most recent first
    myTrades.sort((a, b) => new Date(b.proposedAt).getTime() - new Date(a.proposedAt).getTime());

    res.json(myTrades);
  } catch (error: any) {
    console.error('Error getting my trades:', error);
    res.status(500).json({ error: 'Failed to get trades', message: error.message });
  }
});

// Get single trade
router.get('/:tradeId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { tradeId } = req.params;

    const trade = await getTrade(tradeId);
    if (!trade) {
      res.status(404).json({ error: 'Trade not found' });
      return;
    }

    res.json(trade);
  } catch (error: any) {
    console.error('Error getting trade:', error);
    res.status(500).json({ error: 'Failed to get trade', message: error.message });
  }
});

// Accept a trade
router.post('/:tradeId/accept', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { tradeId } = req.params;

    const trade = await getTrade(tradeId);
    if (!trade) {
      res.status(404).json({ error: 'Trade not found' });
      return;
    }

    if (trade.status !== 'pending') {
      res.status(400).json({ error: `Cannot accept trade with status: ${trade.status}` });
      return;
    }

    // Check if user owns the receiving team
    const team = await TeamModel.getTeamByOwnerAndLeague(req.user!.uid, trade.leagueId);
    if (!team || team.teamId !== trade.receivingTeam.teamId) {
      res.status(403).json({ error: 'You can only accept trades for your own team' });
      return;
    }

    // Check if trade has expired
    if (trade.expiresAt && new Date(trade.expiresAt) < new Date()) {
      trade.status = 'expired';
      await putTrade(trade);
      res.status(400).json({ error: 'Trade has expired' });
      return;
    }

    const league = await LeagueModel.getLeague(trade.leagueId);

    // Update trade status
    trade.receivingTeam.accepted = true;
    trade.status = 'accepted';

    // If commissioner approval is not required, execute immediately
    // For now, we'll auto-execute
    trade.status = 'executed';
    trade.executedAt = new Date().toISOString();

    await putTrade(trade);

    res.json({ message: 'Trade accepted and executed', trade });
  } catch (error: any) {
    console.error('Error accepting trade:', error);
    res.status(500).json({ error: 'Failed to accept trade', message: error.message });
  }
});

// Reject a trade
router.post('/:tradeId/reject', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { tradeId } = req.params;

    const trade = await getTrade(tradeId);
    if (!trade) {
      res.status(404).json({ error: 'Trade not found' });
      return;
    }

    if (trade.status !== 'pending') {
      res.status(400).json({ error: `Cannot reject trade with status: ${trade.status}` });
      return;
    }

    // Check if user owns the receiving team
    const team = await TeamModel.getTeamByOwnerAndLeague(req.user!.uid, trade.leagueId);
    if (!team || team.teamId !== trade.receivingTeam.teamId) {
      res.status(403).json({ error: 'You can only reject trades for your own team' });
      return;
    }

    trade.status = 'rejected';
    await putTrade(trade);

    res.json({ message: 'Trade rejected', trade });
  } catch (error: any) {
    console.error('Error rejecting trade:', error);
    res.status(500).json({ error: 'Failed to reject trade', message: error.message });
  }
});

// Cancel a trade (proposer only)
router.post('/:tradeId/cancel', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { tradeId } = req.params;

    const trade = await getTrade(tradeId);
    if (!trade) {
      res.status(404).json({ error: 'Trade not found' });
      return;
    }

    if (trade.status !== 'pending') {
      res.status(400).json({ error: `Cannot cancel trade with status: ${trade.status}` });
      return;
    }

    // Check if user owns the proposing team
    const team = await TeamModel.getTeamByOwnerAndLeague(req.user!.uid, trade.leagueId);
    if (!team || team.teamId !== trade.proposingTeam.teamId) {
      res.status(403).json({ error: 'Only the proposing team can cancel the trade' });
      return;
    }

    trade.status = 'cancelled';
    trade.cancelledAt = new Date().toISOString();
    await putTrade(trade);

    res.json({ message: 'Trade cancelled', trade });
  } catch (error: any) {
    console.error('Error cancelling trade:', error);
    res.status(500).json({ error: 'Failed to cancel trade', message: error.message });
  }
});

// Commissioner: Veto a trade
router.post('/:tradeId/veto', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { tradeId } = req.params;
    const { reason } = req.body;

    const trade = await getTrade(tradeId);
    if (!trade) {
      res.status(404).json({ error: 'Trade not found' });
      return;
    }

    const league = await LeagueModel.getLeague(trade.leagueId);
    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can veto trades' });
      return;
    }

    if (trade.status !== 'pending' && trade.status !== 'accepted') {
      res.status(400).json({ error: `Cannot veto trade with status: ${trade.status}` });
      return;
    }

    trade.status = 'cancelled';
    trade.cancelledAt = new Date().toISOString();
    trade.commissionerApproval = {
      approved: false,
      reviewedAt: new Date().toISOString(),
      reviewedBy: req.user!.uid,
      notes: reason || 'Vetoed by commissioner',
    };
    await putTrade(trade);

    res.json({ message: 'Trade vetoed', trade });
  } catch (error: any) {
    console.error('Error vetoing trade:', error);
    res.status(500).json({ error: 'Failed to veto trade', message: error.message });
  }
});

// Commissioner: Approve a pending trade
router.post('/:tradeId/approve', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { tradeId } = req.params;

    const trade = await getTrade(tradeId);
    if (!trade) {
      res.status(404).json({ error: 'Trade not found' });
      return;
    }

    const league = await LeagueModel.getLeague(trade.leagueId);
    if (!league) {
      res.status(404).json({ error: 'League not found' });
      return;
    }

    if (league.commissionerId !== req.user!.uid) {
      res.status(403).json({ error: 'Only commissioner can approve trades' });
      return;
    }

    if (trade.status !== 'accepted') {
      res.status(400).json({ error: 'Can only approve trades that have been accepted by both parties' });
      return;
    }

    trade.status = 'executed';
    trade.executedAt = new Date().toISOString();
    trade.commissionerApproval = {
      approved: true,
      reviewedAt: new Date().toISOString(),
      reviewedBy: req.user!.uid,
    };
    await putTrade(trade);

    res.json({ message: 'Trade approved and executed', trade });
  } catch (error: any) {
    console.error('Error approving trade:', error);
    res.status(500).json({ error: 'Failed to approve trade', message: error.message });
  }
});

export default router;
