import { GetCommand, PutCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { getDocClient } from '../config/database';
import { Draft, DraftPick } from '../types';

const DRAFTS_TABLE = 'bb_draft_drafts';
const PICKS_TABLE = 'bb_draft_picks';

// Draft operations
export async function getDraft(draftId: string): Promise<Draft | null> {
  const client = getDocClient();
  const result = await client.send(
    new GetCommand({
      TableName: DRAFTS_TABLE,
      Key: { draftId },
    })
  );
  return (result.Item as Draft) || null;
}

export async function putDraft(draft: Draft): Promise<void> {
  const client = getDocClient();
  await client.send(
    new PutCommand({
      TableName: DRAFTS_TABLE,
      Item: draft,
    })
  );
}

export async function getDraftByLeague(leagueId: string): Promise<Draft | null> {
  const client = getDocClient();
  const result = await client.send(
    new QueryCommand({
      TableName: DRAFTS_TABLE,
      IndexName: 'leagueId-index',
      KeyConditionExpression: 'leagueId = :lid',
      ExpressionAttributeValues: { ':lid': leagueId },
    })
  );

  if (result.Items && result.Items.length > 0) {
    return result.Items[0] as Draft;
  }
  return null;
}

// Draft Pick operations
export async function getDraftPick(draftId: string, overallPick: number): Promise<DraftPick | null> {
  const client = getDocClient();
  const result = await client.send(
    new GetCommand({
      TableName: PICKS_TABLE,
      Key: { draftId, overallPick },
    })
  );
  return (result.Item as DraftPick) || null;
}

export async function putDraftPick(pick: DraftPick): Promise<void> {
  const client = getDocClient();
  await client.send(
    new PutCommand({
      TableName: PICKS_TABLE,
      Item: pick,
    })
  );
}

export async function getDraftPicks(draftId: string): Promise<DraftPick[]> {
  const client = getDocClient();
  const result = await client.send(
    new QueryCommand({
      TableName: PICKS_TABLE,
      KeyConditionExpression: 'draftId = :did',
      ExpressionAttributeValues: { ':did': draftId },
    })
  );
  return (result.Items as DraftPick[]) || [];
}

export async function isPlayerDrafted(draftId: string, playerId: string): Promise<boolean> {
  const client = getDocClient();
  const result = await client.send(
    new QueryCommand({
      TableName: PICKS_TABLE,
      IndexName: 'playerId-index',
      KeyConditionExpression: 'playerId = :pid',
      FilterExpression: 'draftId = :did',
      ExpressionAttributeValues: {
        ':pid': playerId,
        ':did': draftId,
      },
    })
  );
  return (result.Items?.length || 0) > 0;
}
