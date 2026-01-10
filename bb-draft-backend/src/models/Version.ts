import { GetCommand, PutCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { getDocClient, TABLES } from '../config/database';
import { getPSTDate, formatVersion } from '../utils/dateUtils';

export interface VersionRecord {
  date: string;        // Partition key: yyyymmdd
  counter: number;     // Daily counter (1-9999)
  lastUpdated: string; // ISO timestamp
}

export interface VersionResponse {
  version: string;     // Full formatted version: X.X.X-yyyymmdd-####
  date: string;        // Date portion: yyyymmdd
  counter: number;     // Counter value
}

/**
 * Get the current version record for today (PST)
 * Does NOT increment the counter
 */
export async function getCurrentVersion(majorMinorPatch: string = '0.0.0'): Promise<VersionResponse> {
  const client = getDocClient();
  const today = getPSTDate();

  const result = await client.send(
    new GetCommand({
      TableName: TABLES.VERSIONS,
      Key: { date: today },
    })
  );

  const record = result.Item as VersionRecord | undefined;
  const counter = record?.counter ?? 0;

  return {
    version: formatVersion(majorMinorPatch, today, counter),
    date: today,
    counter,
  };
}

/**
 * Get the next version and atomically increment the counter
 * If no record exists for today, creates one with counter = 1
 * If record exists, increments the counter
 */
export async function getNextVersion(majorMinorPatch: string = '0.0.0'): Promise<VersionResponse> {
  const client = getDocClient();
  const today = getPSTDate();
  const now = new Date().toISOString();

  // Use atomic update to increment counter
  // ADD will create the attribute if it doesn't exist (starting at 0) then add 1
  const result = await client.send(
    new UpdateCommand({
      TableName: TABLES.VERSIONS,
      Key: { date: today },
      UpdateExpression: 'SET #counter = if_not_exists(#counter, :zero) + :inc, #lastUpdated = :now',
      ExpressionAttributeNames: {
        '#counter': 'counter',
        '#lastUpdated': 'lastUpdated',
      },
      ExpressionAttributeValues: {
        ':zero': 0,
        ':inc': 1,
        ':now': now,
      },
      ReturnValues: 'ALL_NEW',
    })
  );

  const record = result.Attributes as VersionRecord;

  return {
    version: formatVersion(majorMinorPatch, today, record.counter),
    date: today,
    counter: record.counter,
  };
}
