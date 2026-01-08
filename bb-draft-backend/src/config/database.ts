import { DynamoDBClient, CreateTableCommand, DescribeTableCommand } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

let dynamoClient: DynamoDBClient;
let docClient: DynamoDBDocumentClient;

export async function initializeDynamoDB(): Promise<void> {
  dynamoClient = new DynamoDBClient({
    endpoint: process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000',
    region: process.env.DYNAMODB_REGION || 'us-east-1',
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'local',
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'local',
    },
  });

  docClient = DynamoDBDocumentClient.from(dynamoClient, {
    marshallOptions: {
      removeUndefinedValues: true,
    },
  });
}

export function getDynamoClient(): DynamoDBClient {
  return dynamoClient;
}

export function getDocClient(): DynamoDBDocumentClient {
  return docClient;
}

// Export docClient directly for easier imports
export { docClient };

// Table definitions
const tables = [
  {
    TableName: 'bb_draft_users',
    KeySchema: [{ AttributeName: 'userId', KeyType: 'HASH' }],
    AttributeDefinitions: [{ AttributeName: 'userId', AttributeType: 'S' }],
    BillingMode: 'PAY_PER_REQUEST',
  },
  {
    TableName: 'bb_draft_leagues',
    KeySchema: [{ AttributeName: 'leagueId', KeyType: 'HASH' }],
    AttributeDefinitions: [
      { AttributeName: 'leagueId', AttributeType: 'S' },
      { AttributeName: 'inviteCode', AttributeType: 'S' },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: 'inviteCode-index',
        KeySchema: [{ AttributeName: 'inviteCode', KeyType: 'HASH' }],
        Projection: { ProjectionType: 'ALL' },
      },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  },
  {
    TableName: 'bb_draft_teams',
    KeySchema: [{ AttributeName: 'teamId', KeyType: 'HASH' }],
    AttributeDefinitions: [
      { AttributeName: 'teamId', AttributeType: 'S' },
      { AttributeName: 'leagueId', AttributeType: 'S' },
      { AttributeName: 'ownerId', AttributeType: 'S' },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: 'leagueId-index',
        KeySchema: [{ AttributeName: 'leagueId', KeyType: 'HASH' }],
        Projection: { ProjectionType: 'ALL' },
      },
      {
        IndexName: 'ownerId-index',
        KeySchema: [{ AttributeName: 'ownerId', KeyType: 'HASH' }],
        Projection: { ProjectionType: 'ALL' },
      },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  },
  {
    TableName: 'bb_draft_drafts',
    KeySchema: [{ AttributeName: 'draftId', KeyType: 'HASH' }],
    AttributeDefinitions: [
      { AttributeName: 'draftId', AttributeType: 'S' },
      { AttributeName: 'leagueId', AttributeType: 'S' },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: 'leagueId-index',
        KeySchema: [{ AttributeName: 'leagueId', KeyType: 'HASH' }],
        Projection: { ProjectionType: 'ALL' },
      },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  },
  {
    TableName: 'bb_draft_picks',
    KeySchema: [
      { AttributeName: 'draftId', KeyType: 'HASH' },
      { AttributeName: 'overallPick', KeyType: 'RANGE' },
    ],
    AttributeDefinitions: [
      { AttributeName: 'draftId', AttributeType: 'S' },
      { AttributeName: 'overallPick', AttributeType: 'N' },
      { AttributeName: 'playerId', AttributeType: 'S' },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: 'playerId-index',
        KeySchema: [{ AttributeName: 'playerId', KeyType: 'HASH' }],
        Projection: { ProjectionType: 'ALL' },
      },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  },
  {
    TableName: 'bb_draft_players',
    KeySchema: [{ AttributeName: 'playerId', KeyType: 'HASH' }],
    AttributeDefinitions: [
      { AttributeName: 'playerId', AttributeType: 'S' },
      { AttributeName: 'primaryPosition', AttributeType: 'S' },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: 'position-index',
        KeySchema: [{ AttributeName: 'primaryPosition', KeyType: 'HASH' }],
        Projection: { ProjectionType: 'ALL' },
      },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  },
  {
    TableName: 'bb_draft_trades',
    KeySchema: [{ AttributeName: 'tradeId', KeyType: 'HASH' }],
    AttributeDefinitions: [
      { AttributeName: 'tradeId', AttributeType: 'S' },
      { AttributeName: 'leagueId', AttributeType: 'S' },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: 'leagueId-index',
        KeySchema: [{ AttributeName: 'leagueId', KeyType: 'HASH' }],
        Projection: { ProjectionType: 'ALL' },
      },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  },
  // Encyclopedia tables
  {
    TableName: 'bb_draft_encyclopedia_seasons',
    KeySchema: [
      { AttributeName: 'leagueId', KeyType: 'HASH' },
      { AttributeName: 'seasonId', KeyType: 'RANGE' },
    ],
    AttributeDefinitions: [
      { AttributeName: 'leagueId', AttributeType: 'S' },
      { AttributeName: 'seasonId', AttributeType: 'S' },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  },
  {
    TableName: 'bb_draft_encyclopedia_player_stats',
    KeySchema: [
      { AttributeName: 'statsId', KeyType: 'HASH' },
    ],
    AttributeDefinitions: [
      { AttributeName: 'statsId', AttributeType: 'S' },
      { AttributeName: 'leagueId', AttributeType: 'S' },
      { AttributeName: 'playerId', AttributeType: 'S' },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: 'LeagueIndex',
        KeySchema: [{ AttributeName: 'leagueId', KeyType: 'HASH' }],
        Projection: { ProjectionType: 'ALL' },
      },
      {
        IndexName: 'PlayerIndex',
        KeySchema: [
          { AttributeName: 'playerId', KeyType: 'HASH' },
          { AttributeName: 'leagueId', KeyType: 'RANGE' },
        ],
        Projection: { ProjectionType: 'ALL' },
      },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  },
  {
    TableName: 'bb_draft_encyclopedia_team_stats',
    KeySchema: [
      { AttributeName: 'leagueId', KeyType: 'HASH' },
      { AttributeName: 'statsId', KeyType: 'RANGE' },
    ],
    AttributeDefinitions: [
      { AttributeName: 'leagueId', AttributeType: 'S' },
      { AttributeName: 'statsId', AttributeType: 'S' },
      { AttributeName: 'teamId', AttributeType: 'S' },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: 'TeamIndex',
        KeySchema: [
          { AttributeName: 'teamId', KeyType: 'HASH' },
          { AttributeName: 'leagueId', KeyType: 'RANGE' },
        ],
        Projection: { ProjectionType: 'ALL' },
      },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  },
];

// Exported table names constant
export const TABLES = {
  USERS: 'bb_draft_users',
  LEAGUES: 'bb_draft_leagues',
  TEAMS: 'bb_draft_teams',
  DRAFTS: 'bb_draft_drafts',
  PICKS: 'bb_draft_picks',
  PLAYERS: 'bb_draft_players',
  TRADES: 'bb_draft_trades',
  ENCYCLOPEDIA_SEASONS: 'bb_draft_encyclopedia_seasons',
  ENCYCLOPEDIA_PLAYER_STATS: 'bb_draft_encyclopedia_player_stats',
  ENCYCLOPEDIA_TEAM_STATS: 'bb_draft_encyclopedia_team_stats',
};

// Alias for backward compatibility
export const TableNames = TABLES;

async function tableExists(tableName: string): Promise<boolean> {
  try {
    await dynamoClient.send(new DescribeTableCommand({ TableName: tableName }));
    return true;
  } catch (error: any) {
    if (error.name === 'ResourceNotFoundException') {
      return false;
    }
    throw error;
  }
}

export async function createTables(): Promise<void> {
  for (const table of tables) {
    const exists = await tableExists(table.TableName);
    if (!exists) {
      console.log(`Creating table: ${table.TableName}`);
      await dynamoClient.send(new CreateTableCommand(table as any));
      console.log(`Table created: ${table.TableName}`);
    } else {
      console.log(`Table already exists: ${table.TableName}`);
    }
  }
}
