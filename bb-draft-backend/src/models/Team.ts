import { GetCommand, PutCommand, QueryCommand, DeleteCommand } from '@aws-sdk/lib-dynamodb';
import { getDocClient } from '../config/database';
import { Team } from '../types';

const TABLE_NAME = 'bb_draft_teams';

export async function getTeam(teamId: string): Promise<Team | null> {
  const client = getDocClient();
  const result = await client.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { teamId },
    })
  );
  return (result.Item as Team) || null;
}

export async function putTeam(team: Team): Promise<void> {
  const client = getDocClient();
  await client.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: team,
    })
  );
}

export async function deleteTeam(teamId: string): Promise<void> {
  const client = getDocClient();
  await client.send(
    new DeleteCommand({
      TableName: TABLE_NAME,
      Key: { teamId },
    })
  );
}

export async function getTeamsByLeague(leagueId: string): Promise<Team[]> {
  const client = getDocClient();
  const result = await client.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'leagueId-index',
      KeyConditionExpression: 'leagueId = :lid',
      ExpressionAttributeValues: { ':lid': leagueId },
    })
  );
  return (result.Items as Team[]) || [];
}

export async function getTeamsByOwner(ownerId: string): Promise<Team[]> {
  const client = getDocClient();
  const result = await client.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'ownerId-index',
      KeyConditionExpression: 'ownerId = :oid',
      ExpressionAttributeValues: { ':oid': ownerId },
    })
  );
  return (result.Items as Team[]) || [];
}

export async function getTeamByOwnerAndLeague(ownerId: string, leagueId: string): Promise<Team | null> {
  const teams = await getTeamsByOwner(ownerId);
  return teams.find((t) => t.leagueId === leagueId) || null;
}
