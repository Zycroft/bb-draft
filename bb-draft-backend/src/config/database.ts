import { DynamoDBClient, CreateTableCommand, DescribeTableCommand } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

// Table names
export const TABLES = {
  USERS: 'bb_draft_users',
  VERSIONS: 'bb_draft_versions',
};

// Alias for backward compatibility
export const TableNames = TABLES;

let dynamoClient: DynamoDBClient;
let docClient: DynamoDBDocumentClient;

async function ensureTableExists(tableName: string, keySchema: { name: string; type: 'S' | 'N' }): Promise<void> {
  try {
    await dynamoClient.send(new DescribeTableCommand({ TableName: tableName }));
    console.log(`Table ${tableName} exists`);
  } catch (error: any) {
    if (error.name === 'ResourceNotFoundException') {
      console.log(`Creating table ${tableName}...`);
      await dynamoClient.send(new CreateTableCommand({
        TableName: tableName,
        KeySchema: [
          { AttributeName: keySchema.name, KeyType: 'HASH' },
        ],
        AttributeDefinitions: [
          { AttributeName: keySchema.name, AttributeType: keySchema.type },
        ],
        BillingMode: 'PAY_PER_REQUEST',
      }));
      console.log(`Table ${tableName} created`);
    } else {
      throw error;
    }
  }
}

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

  // Ensure required tables exist
  await ensureTableExists(TABLES.VERSIONS, { name: 'date', type: 'S' });
}

export function getDynamoClient(): DynamoDBClient {
  return dynamoClient;
}

export function getDocClient(): DynamoDBDocumentClient {
  return docClient;
}

// Export docClient directly for easier imports
export { docClient };
