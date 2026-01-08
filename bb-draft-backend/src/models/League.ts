import { GetCommand, PutCommand, QueryCommand, ScanCommand, DeleteCommand } from '@aws-sdk/lib-dynamodb';
import { getDocClient } from '../config/database';
import { League } from '../types';

const TABLE_NAME = 'bb_draft_leagues';

export async function getLeague(leagueId: string): Promise<League | null> {
  const client = getDocClient();
  const result = await client.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { leagueId },
    })
  );
  return (result.Item as League) || null;
}

export async function putLeague(league: League): Promise<void> {
  const client = getDocClient();
  await client.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: league,
    })
  );
}

export async function deleteLeague(leagueId: string): Promise<void> {
  const client = getDocClient();
  await client.send(
    new DeleteCommand({
      TableName: TABLE_NAME,
      Key: { leagueId },
    })
  );
}

export async function getLeagueByInviteCode(inviteCode: string): Promise<League | null> {
  const client = getDocClient();
  const result = await client.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'inviteCode-index',
      KeyConditionExpression: 'inviteCode = :code',
      ExpressionAttributeValues: { ':code': inviteCode },
    })
  );

  if (result.Items && result.Items.length > 0) {
    return result.Items[0] as League;
  }
  return null;
}

export async function getLeaguesByCommissioner(commissionerId: string): Promise<League[]> {
  const client = getDocClient();
  const result = await client.send(
    new ScanCommand({
      TableName: TABLE_NAME,
      FilterExpression: 'commissionerId = :commId',
      ExpressionAttributeValues: { ':commId': commissionerId },
    })
  );
  return (result.Items as League[]) || [];
}

export async function getAllLeagues(): Promise<League[]> {
  const client = getDocClient();
  const result = await client.send(
    new ScanCommand({
      TableName: TABLE_NAME,
    })
  );
  return (result.Items as League[]) || [];
}
