import { GetCommand, PutCommand, ScanCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { getDocClient } from '../config/database';
import { Player, PaginatedResponse } from '../types';

const TABLE_NAME = 'bb_draft_players';

export async function getPlayer(playerId: string): Promise<Player | null> {
  const client = getDocClient();
  const result = await client.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { playerId },
    })
  );
  return (result.Item as Player) || null;
}

export async function putPlayer(player: Player): Promise<void> {
  const client = getDocClient();
  await client.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: player,
    })
  );
}

export async function putPlayers(players: Player[]): Promise<void> {
  // Batch write in chunks of 25 (DynamoDB limit)
  const client = getDocClient();
  for (let i = 0; i < players.length; i += 25) {
    const batch = players.slice(i, i + 25);
    await Promise.all(batch.map((player) => putPlayer(player)));
  }
}

export async function getPlayers(
  options: {
    position?: string;
    limit?: number;
    lastKey?: string;
  } = {}
): Promise<PaginatedResponse<Player>> {
  const client = getDocClient();
  const { position, limit = 50, lastKey } = options;

  if (position) {
    // Use GSI for position filtering
    const result = await client.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        IndexName: 'position-index',
        KeyConditionExpression: 'primaryPosition = :pos',
        ExpressionAttributeValues: { ':pos': position },
        Limit: limit,
        ExclusiveStartKey: lastKey ? JSON.parse(Buffer.from(lastKey, 'base64').toString()) : undefined,
      })
    );

    return {
      items: (result.Items as Player[]) || [],
      count: result.Count || 0,
      lastKey: result.LastEvaluatedKey
        ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
        : undefined,
    };
  }

  // Scan all players
  const result = await client.send(
    new ScanCommand({
      TableName: TABLE_NAME,
      Limit: limit,
      ExclusiveStartKey: lastKey ? JSON.parse(Buffer.from(lastKey, 'base64').toString()) : undefined,
    })
  );

  return {
    items: (result.Items as Player[]) || [],
    count: result.Count || 0,
    lastKey: result.LastEvaluatedKey
      ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
      : undefined,
  };
}

export async function getBatters(limit = 100): Promise<Player[]> {
  const client = getDocClient();
  const result = await client.send(
    new ScanCommand({
      TableName: TABLE_NAME,
      FilterExpression: 'NOT contains(:pitcherPositions, primaryPosition)',
      ExpressionAttributeValues: {
        ':pitcherPositions': ['SP', 'RP', 'P'],
      },
      Limit: limit,
    })
  );
  return (result.Items as Player[]) || [];
}

export async function getPitchers(limit = 100): Promise<Player[]> {
  const client = getDocClient();
  const result = await client.send(
    new ScanCommand({
      TableName: TABLE_NAME,
      FilterExpression: 'contains(:pitcherPositions, primaryPosition)',
      ExpressionAttributeValues: {
        ':pitcherPositions': ['SP', 'RP', 'P'],
      },
      Limit: limit,
    })
  );
  return (result.Items as Player[]) || [];
}

export async function searchPlayers(query: string, limit = 50): Promise<Player[]> {
  const client = getDocClient();
  const lowerQuery = query.toLowerCase();

  const result = await client.send(
    new ScanCommand({
      TableName: TABLE_NAME,
      FilterExpression: 'contains(#searchName, :query)',
      ExpressionAttributeNames: { '#searchName': 'searchName' },
      ExpressionAttributeValues: { ':query': lowerQuery },
      Limit: limit,
    })
  );

  return (result.Items as Player[]) || [];
}

// Eligibility Storage - stored on the player record with league-specific keys
// Format: eligibility_{leagueId} attribute on player record

interface EligibilityStatus {
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
): Promise<EligibilityStatus | null> {
  const player = await getPlayer(playerId);
  if (!player) return null;

  const eligibilityKey = `eligibility_${leagueId}`;
  const eligibilityData = (player as any)[eligibilityKey];

  if (!eligibilityData) return null;

  return {
    playerId,
    leagueId,
    ...eligibilityData,
  };
}

export async function setPlayerEligibility(
  data: EligibilityStatus
): Promise<void> {
  const client = getDocClient();
  const eligibilityKey = `eligibility_${data.leagueId}`;

  // Use UpdateCommand to set just the eligibility attribute
  const { UpdateCommand } = await import('@aws-sdk/lib-dynamodb');

  await client.send(
    new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { playerId: data.playerId },
      UpdateExpression: 'SET #eligKey = :eligData',
      ExpressionAttributeNames: {
        '#eligKey': eligibilityKey,
      },
      ExpressionAttributeValues: {
        ':eligData': {
          eligibility: data.eligibility,
          note: data.note,
          ownerTeamId: data.ownerTeamId,
          updatedAt: data.updatedAt,
          updatedBy: data.updatedBy,
        },
      },
    })
  );
}

export async function getLeagueEligibilities(
  leagueId: string
): Promise<Record<string, EligibilityStatus>> {
  const client = getDocClient();
  const eligibilityKey = `eligibility_${leagueId}`;

  // Scan for all players that have eligibility set for this league
  const result = await client.send(
    new ScanCommand({
      TableName: TABLE_NAME,
      FilterExpression: 'attribute_exists(#eligKey)',
      ExpressionAttributeNames: {
        '#eligKey': eligibilityKey,
      },
    })
  );

  const eligibilities: Record<string, EligibilityStatus> = {};

  for (const item of result.Items || []) {
    const player = item as Player & { [key: string]: any };
    const eligData = player[eligibilityKey];
    if (eligData) {
      eligibilities[player.playerId] = {
        playerId: player.playerId,
        leagueId,
        ...eligData,
      };
    }
  }

  return eligibilities;
}
